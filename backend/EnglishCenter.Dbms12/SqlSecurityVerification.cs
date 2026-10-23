using System.Data;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12;

internal static class SqlSecurityVerification
{
    internal static async Task<int> RunAsync(string path)
    {
        var p=AppProfile.Load(Path.GetFullPath(path));
        if(!System.Text.RegularExpressions.Regex.IsMatch(p.Workspace,@"[\\/]\.local[\\/]security-redesign[\\/]fixture-[0-9a-f]{32}$"))throw new InvalidOperationException("Write tests require a dedicated security fixture workspace.");
        _=new Data.CompactSqlExecutor(AppProfile.Package);
        await using var db=new SqlConnection(p.Connection);await db.OpenAsync();
        await Guard(db,p);
        using var manifest=JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(AppProfile.Package,"manifest.json")));
        var roles=manifest.RootElement.GetProperty("businessRoles").EnumerateObject().ToArray();
        var checks=new List<string>();
        var tables=new List<(string Table,string Column)>();
        var updateColumns=new Dictionary<string,string>();
        await using(var cmd=new SqlCommand("SELECT t.name,c.name FROM sys.tables t JOIN sys.columns c ON c.object_id=t.object_id WHERE t.is_ms_shipped=0 AND c.is_identity=0 AND c.system_type_id<>189 ORDER BY t.name,c.column_id;",db))
        {await using var r=await cmd.ExecuteReaderAsync();while(await r.ReadAsync())updateColumns.TryAdd(r.GetString(0),r.GetString(1));}
        await using(var cmd=new SqlCommand("SELECT t.name,c.name FROM sys.tables t JOIN sys.columns c ON c.object_id=t.object_id WHERE t.is_ms_shipped=0 ORDER BY t.name,c.column_id;",db))
        {await using var r=await cmd.ExecuteReaderAsync();while(await r.ReadAsync())tables.Add((r.GetString(0),r.GetString(1)));}
        foreach(var role in roles)
        {
            var nativeRole=role.Value[0].GetString()!;var user=role.Value[1].GetString()!;
            await Expect(db,user,$"IF IS_ROLEMEMBER('{nativeRole}')<>1 OR IS_ROLEMEMBER('db_owner')=1 THROW 51997,N'Membership mismatch',1;",0);
            checks.Add("membership:"+role.Name);
            foreach(var table in tables.Select(x=>x.Table).Distinct())
            {
                var col=updateColumns[table];
                foreach(var statement in new[]{ $"SELECT TOP(0) * FROM dbo.[{table}];",$"INSERT dbo.[{table}] DEFAULT VALUES;",$"UPDATE dbo.[{table}] SET [{col}]=[{col}] WHERE 1=0;",$"DELETE dbo.[{table}] WHERE 1=0;" })
                {await Expect(db,user,statement,229);checks.Add("table-denied:"+role.Name+":"+table);}
            }
            foreach(var (table,col) in tables)
            {await Expect(db,user,$"SELECT TOP(0) [{col}] FROM dbo.[{table}];",229);checks.Add("column-denied:"+role.Name+":"+table+":"+col);}
            foreach(var op in manifest.RootElement.GetProperty("operations").EnumerateObject())
            {
                var allowed=op.Value.GetProperty("context").GetString()=="business"&&op.Value.GetProperty("sqlRoles").EnumerateArray().Any(x=>x.GetString()==role.Name);
                var declarations="";var args=new List<string>();
                foreach(var arg in op.Value.GetProperty("parameters").EnumerateArray())
                {
                    var name=arg.GetProperty("name").GetString();var type=arg.GetProperty("type").GetString();
                    if(arg.GetProperty("structured").GetBoolean()){declarations+=$"DECLARE {name} {type};";args.Add($"{name}={name}");}
                    else args.Add($"{name}=NULL");
                }
                await Expect(db,user,declarations+$"EXEC dbo.{op.Name} "+string.Join(',',args)+";",allowed?51201:229);
                checks.Add((allowed?"module-session-guard:":"module-denied:")+role.Name+":"+op.Name);
            }
            foreach(var helper in new[]{"usp_SecuritySession","usp_RecordFailure","usp_PasswordSnapshot","usp_BeginWrite"})
            {await Expect(db,user,$"EXEC dbo.{helper};",229);checks.Add("private-helper-denied:"+role.Name+":"+helper);}
            await Expect(db,user,"EXECUTE AS USER='Dbms12ProjectRuntime';",15517);
            checks.Add("cannot-impersonate-runtime:"+role.Name);
        }
        // Each negative THROW may abort its transaction; use a separate rolled-back fixture per case.
        for(var caseNo=0;caseNo<7;caseNo++)
        {
            await using(var begin=new SqlCommand("BEGIN TRANSACTION; DECLARE @Now datetime2(3)=SYSUTCDATETIME(); INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at) SELECT CRYPT_GEN_RANDOM(32),account_id,@Now,@Now FROM dbo.Account WHERE email IN ('s1@dbms12.example','teacher@dbms12.example','finance@dbms12.example');",db))await begin.ExecuteNonQueryAsync();
            try
            {
                var tokens=new Dictionary<string,(byte[] Sid,long Epoch)>();
                await using(var q=new SqlCommand("SELECT a.role_code,s.sid,a.security_version FROM dbo.AuthSession s JOIN dbo.Account a ON a.account_id=s.account_id WHERE a.email IN ('s1@dbms12.example','teacher@dbms12.example','finance@dbms12.example');",db))
                {await using var r=await q.ExecuteReaderAsync();while(await r.ReadAsync())tokens[r.GetString(0)]=(r.GetFieldValue<byte[]>(1),r.GetInt64(2));}
                switch(caseNo)
                {
                    case 0:
                        await NativeRead(db,"Dbms12Student","usp_StudentHome",tokens["Student"],rows=>rows.All(row=>!row.ContainsKey("password_hash")));
                        checks.Add("student-own-home");break;
                    case 1:
                        await NativeRead(db,"Dbms12Student","usp_InvoiceRead",tokens["Student"],rows=>rows.Count==0,new(){["@RegistrationId"]=2});
                        checks.Add("student-other-invoice-empty");break;
                    case 2:
                        await NativeRead(db,"Dbms12Teacher","usp_ClassRoster",tokens["Teacher"],rows=>rows.Count>0,new(){["@ClassId"]=2});
                        checks.Add("teacher-own-roster");break;
                    case 3:
                        await NativeRead(db,"Dbms12Student","usp_StudentGrades",tokens["Teacher"],_=>false,expected:51203);
                        checks.Add("wrong-role-SID-denied");break;
                    case 4:
                        int otherClass;
                        await using(var insert=new SqlCommand("INSERT dbo.Class(class_code,course_id,teacher_account_id,capacity) VALUES(@Code,1,9,15); SELECT CONVERT(int,SCOPE_IDENTITY());",db))
                        {insert.Parameters.AddWithValue("@Code","SEC-"+Guid.NewGuid().ToString("N"));otherClass=Convert.ToInt32(await insert.ExecuteScalarAsync());}
                        await NativeRead(db,"Dbms12Teacher","usp_ClassRoster",tokens["Teacher"],_=>false,new(){["@ClassId"]=otherClass},51203);
                        checks.Add("teacher-other-class-denied");break;
                    case 5:
                        await NativeRead(db,"Dbms12Student","usp_StudentHome",tokens["Student"],_=>false,new(){["@Actor"]=8},8144);
                        checks.Add("forged-actor-parameter-rejected");break;
                    case 6:
                        await NativeRead(db,"Dbms12Student","usp_StudentHome",(tokens["Student"].Sid,tokens["Student"].Epoch+1),_=>false,expected:51201);
                        checks.Add("wrong-epoch-denied");break;
                }
            }
            finally {await using var rollback=new SqlCommand("IF XACT_STATE()<>0 ROLLBACK;",db);await rollback.ExecuteNonQueryAsync();}
        }
        // Demonstrate REVOKE independently of existing permissions and DENY.
        await using(var demo=new SqlCommand("""
BEGIN TRANSACTION;
CREATE USER Dbms12RevokeProof WITHOUT LOGIN;
GRANT SELECT ON OBJECT::dbo.v_DirectorAggregate TO Dbms12RevokeProof;
EXECUTE AS USER='Dbms12RevokeProof';
IF HAS_PERMS_BY_NAME('dbo.v_DirectorAggregate','OBJECT','SELECT')<>1 THROW 51997,N'GRANT failed',1;
REVERT;
REVOKE SELECT ON OBJECT::dbo.v_DirectorAggregate FROM Dbms12RevokeProof;
EXECUTE AS USER='Dbms12RevokeProof';
IF HAS_PERMS_BY_NAME('dbo.v_DirectorAggregate','OBJECT','SELECT')<>0 THROW 51997,N'REVOKE failed',1;
REVERT;
DENY SELECT ON OBJECT::dbo.v_DirectorAggregate TO Dbms12RevokeProof;
EXECUTE AS USER='Dbms12RevokeProof';
IF HAS_PERMS_BY_NAME('dbo.v_DirectorAggregate','OBJECT','SELECT')<>0 THROW 51997,N'DENY failed',1;
REVERT;
ROLLBACK;
""",db))await demo.ExecuteNonQueryAsync();
        checks.Add("grant-revoke-deny-rolled-back");
        await SqlContextVerification.Verify(db,p,checks);
        var output=Path.Combine(p.Workspace,"docs/evidence");Directory.CreateDirectory(output);
        await File.WriteAllTextAsync(Path.Combine(output,"sql-native-security.json"),JsonSerializer.Serialize(new{pass=true,database=p.Database,id=p.DatabaseId,guid=p.DatabaseGuid,roles=7,procedures=61,total=checks.Count,checks},new JsonSerializerOptions{WriteIndented=true}));
        Console.WriteLine(JsonSerializer.Serialize(new{pass=true,roles=7,procedures=61,checks=checks.Count}));return 0;
    }
    internal static async Task Guard(SqlConnection db,AppProfile p)
    {
        await using var q=new SqlCommand("SELECT DB_NAME(),DB_ID(),database_guid,(SELECT file_guid FROM sys.database_files WHERE file_id=1) FROM sys.database_recovery_status WHERE database_id=DB_ID();",db);
        await using var r=await q.ExecuteReaderAsync();
        if(!await r.ReadAsync()||r.GetString(0)!=p.Database||Convert.ToInt32(r.GetValue(1))!=p.DatabaseId||r.GetGuid(2)!=p.DatabaseGuid||r.GetGuid(3)!=p.FileGuid)throw new InvalidOperationException("Exact PROJECT database guard failed.");
    }
    private static async Task Expect(SqlConnection db,string user,string sql,int error)
    {
        await using(var begin=new SqlCommand($"BEGIN TRANSACTION; EXECUTE AS USER='{user}';",db))await begin.ExecuteNonQueryAsync();
        try
        {
            try{await using var cmd=new SqlCommand(sql,db);await cmd.ExecuteNonQueryAsync();if(error!=0)throw new InvalidOperationException("Expected SQL denial "+user+" "+error+" "+sql);}
            catch(SqlException e) when(e.Number==error) { }
            catch(SqlException e) { throw new InvalidOperationException($"Native test expected {error}, actual {e.Number}, user {user}: {sql}",e); }
        }
        finally {await using var cleanup=new SqlCommand("REVERT; IF XACT_STATE()<>0 ROLLBACK;",db);await cleanup.ExecuteNonQueryAsync();}
    }
    private static async Task NativeRead(SqlConnection db,string user,string proc,(byte[] Sid,long Epoch) session,Func<List<Dictionary<string,object?>>,bool> check,Dictionary<string,object?>? extra=null,int expected=0)
    {
        await using(var context=new SqlCommand($"EXECUTE AS USER='{user}';",db))await context.ExecuteNonQueryAsync();
        try
        {
            await using var cmd=new SqlCommand("dbo."+proc,db){CommandType=CommandType.StoredProcedure};
            cmd.Parameters.Add("@Sid",SqlDbType.Binary,32).Value=session.Sid;cmd.Parameters.Add("@Epoch",SqlDbType.BigInt).Value=session.Epoch;
            if(extra is not null)foreach(var (k,v) in extra)cmd.Parameters.AddWithValue(k,v);
            try
            {
                var rows=new List<Dictionary<string,object?>>();await using var r=await cmd.ExecuteReaderAsync();
                while(await r.ReadAsync()){var row=new Dictionary<string,object?>();for(var i=0;i<r.FieldCount;i++)row[r.GetName(i)]=r.GetValue(i);rows.Add(row);}
                if(expected!=0||!check(rows))throw new InvalidOperationException("Native ownership check failed: "+proc);
            }
            catch(SqlException e) when(e.Number==expected) { }
        }
        finally {await using var revert=new SqlCommand("REVERT;",db);await revert.ExecuteNonQueryAsync();}
    }
}
