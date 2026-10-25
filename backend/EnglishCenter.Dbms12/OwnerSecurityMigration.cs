using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12;

internal static class OwnerSecurityMigration
{
    private const string LegacyManifest="8C0C1C991B6F76B1BFFC6FABC73B0F0C6791523F7F11F0BDD7DEA9C864BDFE42";
    private static readonly Dictionary<string,string> LegacyProcedureHashes=new(StringComparer.Ordinal)
    {
        ["usp_RegistrationCreate"]="B061208B5EEFF2AA5FC482990A7029A96E4ACD00524B19ADA3588BE1A425BAAF",
        ["usp_AdmissionApprove"]="5BDFC7AFA9BCC612FEA0FBDE3A5F8EF6D963DA7A1A1D72BDE9AA9F1DE46EE400",
        ["usp_InvoiceCollect"]="F2F921F516D1438148EFDFAF930409C3F4A68947389422CB5B73A4F1CEB07CE8",
        ["usp_PlacementCreate"]="A75538F2A274FC1C42A0496B876A776BCB4059254D2CAB69A7E79DCA30DBD3F7",
        ["usp_ScheduleBatch"]="1A25681E76B639FB6AA6EBD9A95B07C1C48046DD7D34C8F5CB8739B3C2A39828",
        ["usp_ScheduleMove"]="27437D5032D9D4DD3F33E6C0CBA105D77B7F6BD92708CF577D20973BB5B08885",
        ["usp_AttendanceSave"]="11CB33EEB6E8FD2FD48164C3C36800F00F63F8B37C730B2C8E5A11F14B1620FB",
        ["usp_GradeSave"]="A300DA7F912AD4DE0AA551D611D801DD79FCC297FCA8D4D304A080C0595042E6",
        ["usp_GradeSubmit"]="C5A387C19702CA0839D91871B54C66910DB1AE27104073F427CF3699350C37E8",
        ["usp_GradeReturn"]="A57EC9797BFEEE4AC3BBA8FFC95CD413D54311FF2651E6B8B7633144FD85CDF5",
        ["usp_GradeFinalize"]="ED6A7057250704DDECA05D9C1BD54A1CD61F25B28E606486E901DAD194E6B774",
    };
    private sealed record Permission(string State,string PermissionName,string Scope,string Principal);
    private sealed record Definition(string Name,string Sql);
    private sealed record RowFingerprint(string Table,long Rows,string Sha256);
    internal static async Task<int> RebindLayoutAsync(string path)
    {
        path=Path.GetFullPath(path);
        var p=JsonSerializer.Deserialize<AppProfile>(await File.ReadAllTextAsync(path))??throw new InvalidOperationException("Missing layout profile.");
        ProjectLayout.Validate(p.Workspace);p.Machine.Validate();
        if(p.ManifestSha256!=SqlLayoutPackage.PreviousManifest||path!=Path.GetFullPath(Path.Combine(p.Workspace,".local/config/profile.json"))
            ||!Regex.IsMatch(p.Database,@"\AEnglishCenter_DBMS12_PROJECT_[0-9a-f]{32}\z")||p.DatabaseId<=4||p.DatabaseGuid==Guid.Empty||p.FileGuid==Guid.Empty)throw new InvalidOperationException("Layout rebind only accepts the pinned D15 PROJECT profile.");
        if(System.Net.NetworkInformation.IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners().Any(x=>x.Port==8446))throw new InvalidOperationException("Stop PROJECT normally before rebinding SQL paths.");
        var newHash=SqlLayoutPackage.Verify();
        await using var db=new SqlConnection(p.Connection);await db.OpenAsync();await SqlSecurityVerification.Guard(db,p);
        await using var tx=(SqlTransaction)await db.BeginTransactionAsync();
        using var manifest=JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(AppProfile.Package,"manifest.json")));
        var expected=new Dictionary<string,string>(StringComparer.Ordinal);
        foreach(var entry in manifest.RootElement.GetProperty("installOrder").EnumerateArray())
            foreach(var batch in Regex.Split(await File.ReadAllTextAsync(Path.Combine(AppProfile.Package,entry.GetString()!)),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
            {
                var name=Regex.Match(batch,@"CREATE OR ALTER PROCEDURE dbo\.(\w+)",RegexOptions.IgnoreCase);
                if(name.Success)expected.Add(name.Groups[1].Value,NormalizeDefinition(batch));
            }
        var definitions=await Definitions(db,tx);
        if(expected.Count!=61||definitions.Count!=61||definitions.Any(d=>!expected.TryGetValue(d.Name,out var body)||body!=NormalizeDefinition(d.Sql)))throw new InvalidOperationException("Live procedures differ from unchanged SQL; no profile rebind.");
        var before=await Fingerprints(db,tx);var metadata=await TransactionMetadata(db,tx);
        if(before.Count!=12||Convert.ToInt32(await Scalar(db,tx,"SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id WHERE t.is_ms_shipped=0;"))!=99)throw new InvalidOperationException("Expected12tables/99columns.");
        if(!before.SequenceEqual(await Fingerprints(db,tx))||metadata!=await TransactionMetadata(db,tx))throw new InvalidOperationException("Unexpected database change during read-only layout check.");
        var folder=Path.Combine(p.PrivateRoot,"operator/sql-layout-rebind",DateTime.UtcNow.ToString("yyyyMMddTHHmmssZ")+"-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(folder);
        await File.WriteAllTextAsync(Path.Combine(folder,"profile-before.json"),JsonSerializer.Serialize(p));
        var updated=p with{ManifestSha256=newHash};
        await File.WriteAllTextAsync(Path.Combine(folder,"profile-after.json"),JsonSerializer.Serialize(updated,new JsonSerializerOptions{WriteIndented=true}));
        await tx.CommitAsync(); // Read-only transaction; no DDL/DML was executed.
        var staged=path+".sql-layout.tmp";File.Copy(Path.Combine(folder,"profile-after.json"),staged,false);File.Move(staged,path,true);
        await File.WriteAllTextAsync(Path.Combine(folder,"complete.json"),JsonSerializer.Serialize(new{pass=true,pathOnly=true,noDatabaseWrites=true,unchangedRows=true,unchangedMetadata=true,procedures=61,byteIdenticalSqlFiles=61}));
        Console.WriteLine(JsonSerializer.Serialize(new{pass=true,pathOnly=true,noDatabaseWrites=true,procedures=61,receipt=folder}));return 0;
    }
    internal static async Task<int> TransactionsAsync(string path,bool rehearsal)
    {
        path=Path.GetFullPath(path);
        var p=JsonSerializer.Deserialize<AppProfile>(await File.ReadAllTextAsync(path))??throw new InvalidOperationException("Missing migration profile.");
        ProjectLayout.Validate(p.Workspace);p.Machine.Validate();
        using var baseline=JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory,"Resources/SqlTransactionsBaseline.json")));
        const string expectedOld="F72E0E99CF46889121709CB32A45130E405A9566855F6CC967C0A92432D20749";
        if(baseline.RootElement.GetProperty("manifestSha256").GetString()!=expectedOld||p.ManifestSha256!=expectedOld
            ||path!=Path.GetFullPath(Path.Combine(p.Workspace,".local/config/profile.json"))
            ||!Regex.IsMatch(p.Database,@"\AEnglishCenter_DBMS12_PROJECT_[0-9a-f]{32}\z"))throw new InvalidOperationException("Only the pinned pre-transaction PROJECT profile can be migrated.");
        if(System.Net.NetworkInformation.IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners().Any(x=>x.Port==8446))throw new InvalidOperationException("Stop PROJECT normally before transaction migration.");
        _=new Data.CompactSqlExecutor(AppProfile.Package);
        using var manifest=JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(AppProfile.Package,"manifest.json")));
        if(manifest.RootElement.GetProperty("transactionOwnership").GetString()!="SQL_PROCEDURE")throw new InvalidOperationException("Expected SQL-owned transaction package.");
        await using var db=new SqlConnection(p.Connection);await db.OpenAsync();await SqlSecurityVerification.Guard(db,p);
        var folder=Path.Combine(p.PrivateRoot,"operator/sql-transaction-migrations",DateTime.UtcNow.ToString("yyyyMMddTHHmmssZ")+"-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(folder);
        await File.WriteAllTextAsync(Path.Combine(folder,"profile-before.json"),JsonSerializer.Serialize(p));
        await using var tx=(SqlTransaction)await db.BeginTransactionAsync();var committed=false;
        try
        {
            var definitions=await Definitions(db,tx);
            var expected=baseline.RootElement.GetProperty("procedures");
            if(definitions.Count!=61||expected.EnumerateObject().Count()!=61)throw new InvalidOperationException("Expected exactly61 old procedures.");
            if(Convert.ToInt32(await Scalar(db,tx,"SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0;"))!=12
                ||Convert.ToInt32(await Scalar(db,tx,"SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id WHERE t.is_ms_shipped=0;"))!=99)throw new InvalidOperationException("Expected12tables/99columns; migration refused.");
            foreach(var d in definitions)if(!expected.TryGetProperty(d.Name,out var hash)||Digest(NormalizeDefinition(d.Sql))!=hash.GetString())throw new InvalidOperationException("Old procedure drift; no migration performed: "+d.Name);
            var before=await Fingerprints(db,tx);
            var securityBefore=await TransactionMetadata(db,tx);
            var seq=Convert.ToString(await Scalar(db,tx,"SELECT CONVERT(varchar(40),current_value) FROM sys.sequences WHERE name='InvoiceNumberSequence';"));
            var rollbackHeader=$":ON ERROR EXIT\nSET XACT_ABORT ON;\nIF DB_NAME()<>'{p.Database}' OR DB_ID()<>{p.DatabaseId} OR NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid='{p.DatabaseGuid}') OR NOT EXISTS(SELECT 1 FROM sys.database_files WHERE file_id=1 AND file_guid='{p.FileGuid}') THROW 51999,N'Rollback identity mismatch',1;\nBEGIN TRANSACTION;\nGO\n";
            var rollbackSql=rollbackHeader+string.Join("\nGO\n",definitions.Select(d=>Regex.Replace(d.Sql,@"^(?:CREATE(?:\s+OR\s+ALTER)?|ALTER)\s+PROCEDURE\b","CREATE OR ALTER PROCEDURE",RegexOptions.IgnoreCase|RegexOptions.Multiline)))+"\nGO\nCOMMIT TRANSACTION;\n-- Restore the matching old profile AND source package only after successful rollback.\n";
            await File.WriteAllTextAsync(Path.Combine(folder,"rollback.sql"),rollbackSql);
            foreach(var entry in manifest.RootElement.GetProperty("installOrder").EnumerateArray())
            {
                var name=entry.GetString()!;
                if(name.StartsWith("stored-procedures/",StringComparison.Ordinal))
                    foreach(var batch in Regex.Split(await File.ReadAllTextAsync(Path.Combine(AppProfile.Package,name)),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
                        if(!string.IsNullOrWhiteSpace(batch))await NonQuery(db,tx,batch);
            }
            var updatedDefinitions=await Definitions(db,tx);
            if(updatedDefinitions.Count!=61||updatedDefinitions.Any(d=>!d.Sql.Contains("@SqlOwnTransaction",StringComparison.Ordinal)))throw new InvalidOperationException("Not all61procedures own a transaction scope.");
            if(!before.SequenceEqual(await Fingerprints(db,tx))||securityBefore!=await TransactionMetadata(db,tx)
                ||seq!=Convert.ToString(await Scalar(db,tx,"SELECT CONVERT(varchar(40),current_value) FROM sys.sequences WHERE name='InvoiceNumberSequence';")))throw new InvalidOperationException("Data, permissions, non-procedure definitions or invoice sequence changed.");
            var updated=p with{ManifestSha256=Digest(await File.ReadAllBytesAsync(Path.Combine(AppProfile.Package,"manifest.json")))};
            await File.WriteAllTextAsync(Path.Combine(folder,"profile-after.json"),JsonSerializer.Serialize(updated,new JsonSerializerOptions{WriteIndented=true}));
            await File.WriteAllTextAsync(Path.Combine(folder,"prepared.json"),JsonSerializer.Serialize(new{before,unchangedRows=true,securityUnchanged=true,sequenceUnchanged=true,procedures=61,rehearsal}));
            if(rehearsal)
            {
                foreach(var batch in Regex.Split(rollbackSql.Replace(":ON ERROR EXIT","",StringComparison.Ordinal),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
                    if(!string.IsNullOrWhiteSpace(batch))await NonQuery(db,tx,batch);
                if(!SameDefinitions(definitions,await Definitions(db,tx))||!before.SequenceEqual(await Fingerprints(db,tx))||securityBefore!=await TransactionMetadata(db,tx))throw new InvalidOperationException("Generated rollback script did not restore the old contract.");
                await tx.RollbackAsync();
                if(!SameDefinitions(definitions,await Definitions(db,null)))throw new InvalidOperationException("Rehearsal rollback did not restore definitions.");
            }
            else
            {
                await tx.CommitAsync();committed=true;
                var staged=path+".sql-transactions.tmp";File.Copy(Path.Combine(folder,"profile-after.json"),staged,false);File.Move(staged,path,true);
            }
            await File.WriteAllTextAsync(Path.Combine(folder,"complete.json"),JsonSerializer.Serialize(new{pass=true,rehearsal,committed,generatedRollbackScriptExecuted=rehearsal,unchangedRows=true,securityUnchanged=true,sequenceUnchanged=true,procedures=61}));
            Console.WriteLine(JsonSerializer.Serialize(new{pass=true,rehearsal,committed,unchangedRows=true,securityUnchanged=true,procedures=61,receipt=folder}));return 0;
        }
        catch
        {
            if(!committed&&tx.Connection is not null)await tx.RollbackAsync();
            await File.WriteAllTextAsync(Path.Combine(folder,"failed.json"),JsonSerializer.Serialize(new{committed,profileMayRequireRecovery=committed}));throw;
        }
    }
    private static async Task<string> TransactionMetadata(SqlConnection db,SqlTransaction tx)
    {
        const string sql="""
DECLARE @Metadata nvarchar(max)=(SELECT
 JSON_QUERY((SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions ORDER BY class,major_id,minor_id,grantee_principal_id,permission_name FOR JSON PATH)) AS permissions,
 JSON_QUERY((SELECT principal_id,name,type,authentication_type FROM sys.database_principals ORDER BY principal_id FOR JSON PATH)) AS principals,
 JSON_QUERY((SELECT role_principal_id,member_principal_id FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id FOR JSON PATH)) AS memberships,
 JSON_QUERY((SELECT o.name,o.type,m.definition FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.type<>'P' ORDER BY o.object_id FOR JSON PATH)) AS nonProcedures,
 JSON_QUERY((SELECT name,is_disabled FROM sys.triggers ORDER BY object_id FOR JSON PATH)) AS triggers
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);SELECT @Metadata;
""";
        return Digest((string)(await Scalar(db,tx,sql)??throw new InvalidOperationException("Missing metadata fingerprint.")));
    }
    internal static async Task<int> RefreshFixtureAsync(string path)
    {
        path=Path.GetFullPath(path);
        var p=JsonSerializer.Deserialize<AppProfile>(await System.IO.File.ReadAllTextAsync(path))??throw new InvalidOperationException("Missing fixture profile.");
        ProjectLayout.Validate(p.Workspace);p.Machine.Validate();
        if(!Regex.IsMatch(p.Workspace,@"[\\/]\.local[\\/]security-redesign[\\/]fixture-[0-9a-f]{32}$")||!Regex.IsMatch(p.Database,@"\AEnglishCenter_DBMS12_PROJECT_[0-9a-f]{32}\z"))throw new InvalidOperationException("Module refresh is only for a dedicated security fixture.");
        if(System.Net.NetworkInformation.IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners().Any(x=>x.Port==8446))throw new InvalidOperationException("Stop fixture host normally first.");
        _=new Data.CompactSqlExecutor(AppProfile.Package);
        using var m=JsonDocument.Parse(await System.IO.File.ReadAllTextAsync(Path.Combine(AppProfile.Package,"manifest.json")));
        await using var db=new SqlConnection(p.Connection);await db.OpenAsync();await SqlSecurityVerification.Guard(db,p);
        await using var tx=(SqlTransaction)await db.BeginTransactionAsync();
        if((await Definitions(db,tx)).Count!=61)throw new InvalidOperationException("Expected native-security fixture.");
        var before=await Fingerprints(db,tx);
        foreach(var entry in m.RootElement.GetProperty("installOrder").EnumerateArray())
        {
            var name=entry.GetString()!;
            if(name.StartsWith("stored-procedures/",StringComparison.Ordinal))
                foreach(var batch in Regex.Split(await System.IO.File.ReadAllTextAsync(Path.Combine(AppProfile.Package,name)),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
                    if(!string.IsNullOrWhiteSpace(batch))await NonQuery(db,tx,batch);
        }
        if(!before.SequenceEqual(await Fingerprints(db,tx)))throw new InvalidOperationException("Fixture module refresh changed data.");
        var updated=p with{ManifestSha256=Digest(await System.IO.File.ReadAllBytesAsync(Path.Combine(AppProfile.Package,"manifest.json")))};
        var receipt=Path.Combine(p.PrivateRoot,"operator/module-refresh-"+DateTime.UtcNow.ToString("yyyyMMddTHHmmssZ"));Directory.CreateDirectory(receipt);
        await System.IO.File.WriteAllTextAsync(Path.Combine(receipt,"before.json"),JsonSerializer.Serialize(p));
        await System.IO.File.WriteAllTextAsync(Path.Combine(receipt,"after.json"),JsonSerializer.Serialize(updated));
        await tx.CommitAsync();System.IO.File.Copy(Path.Combine(receipt,"after.json"),path,true);
        Console.WriteLine(JsonSerializer.Serialize(new{pass=true,fixtureOnly=true,unchangedRows=true}));return 0;
    }
    internal static async Task<int> RunAsync(string path,bool rehearsal=false)
    {
        path=Path.GetFullPath(path);
        var p=JsonSerializer.Deserialize<AppProfile>(await File.ReadAllTextAsync(path))??throw new InvalidOperationException("Missing migration profile.");
        ProjectLayout.Validate(p.Workspace);p.Machine.Validate();
        if(!Regex.IsMatch(p.Database,@"\AEnglishCenter_DBMS12_PROJECT_[0-9a-f]{32}\z")||p.ManifestSha256!=LegacyManifest||path!=Path.GetFullPath(Path.Combine(p.Workspace,".local/config/profile.json")))throw new InvalidOperationException("Migration only accepts the pinned legacy PROJECT profile.");
        if(System.Net.NetworkInformation.IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners().Any(x=>x.Port==8446))throw new InvalidOperationException("Stop the PROJECT host normally before migration.");
        _=new Data.CompactSqlExecutor(AppProfile.Package);
        using var manifest=JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(AppProfile.Package,"manifest.json")));
        await using var db=new SqlConnection(p.Connection);await db.OpenAsync();await SqlSecurityVerification.Guard(db,p);
        if(Convert.ToInt32(await Scalar(db,null,"SELECT IS_SRVROLEMEMBER('sysadmin');"))!=1)throw new InvalidOperationException("Owner SQL sysadmin is required for this guarded migration.");
        var folder=Path.Combine(p.PrivateRoot,"operator/security-migrations",DateTime.UtcNow.ToString("yyyyMMddTHHmmssZ")+"_"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(folder);
        // These are definitions and permission metadata only. Rows/credentials are never exported.
        System.IO.File.Copy(path,Path.Combine(folder,"profile-before.json"),false);
        await using var tx=(SqlTransaction)await db.BeginTransactionAsync();
        var committed=false;
        var rolledBack=false;
        try
        {
            await NonQuery(db,tx,"SELECT COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);");
            var definitions=await Definitions(db,tx);
            if(definitions.Count!=11||Convert.ToInt32(await Scalar(db,tx,"SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0;"))!=12)throw new InvalidOperationException("Legacy schema mismatch.");
            var expected=LegacyProcedureHashes;
            foreach(var d in definitions)
                if(!expected.TryGetValue(d.Name,out var hash)||Digest(NormalizeDefinition(d.Sql))!=hash)throw new InvalidOperationException("Legacy procedure drift; migration refused.");
            foreach(var role in manifest.RootElement.GetProperty("businessRoles").EnumerateObject())
                foreach(var value in role.Value.EnumerateArray())
                    if(await Scalar(db,tx,"SELECT DATABASE_PRINCIPAL_ID(@Name);",new(){["@Name"]=value.GetString()}) is not DBNull)throw new InvalidOperationException("New principal name already exists; migration refused.");
            var permissions=await Permissions(db,tx);
            var before=await Fingerprints(db,tx);
            var sequenceBefore=Convert.ToString(await Scalar(db,tx,"SELECT CONVERT(varchar(40),current_value) FROM sys.sequences WHERE name='InvoiceNumberSequence' AND schema_id=SCHEMA_ID('dbo');"));
            await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"definitions-before.json"),JsonSerializer.Serialize(definitions));
            await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"permissions-before.json"),JsonSerializer.Serialize(permissions));
            var rollback=RollbackScript(p,manifest.RootElement,definitions,permissions);
            await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"rollback.sql"),rollback);
            foreach(var permission in permissions)await NonQuery(db,tx,PermissionSql(permission,"REVOKE"));
            foreach(var entry in manifest.RootElement.GetProperty("installOrder").EnumerateArray())
            {
                var name=entry.GetString()!;
                // Only modules and permissions, never schema, sample, types, views, functions, triggers or keys.
                if(name=="security/08_permissions.sql"||name.StartsWith("stored-procedures/",StringComparison.Ordinal))
                    foreach(var batch in Regex.Split(await System.IO.File.ReadAllTextAsync(Path.Combine(AppProfile.Package,name)),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
                        if(!string.IsNullOrWhiteSpace(batch))await NonQuery(db,tx,batch);
            }
            if(Convert.ToInt32(await Scalar(db,tx,"SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0;"))!=AppProfile.ProcedureCount)throw new InvalidOperationException("Migrated procedure count mismatch.");
            var after=await Fingerprints(db,tx);
            if(!before.SequenceEqual(after))throw new InvalidOperationException("Migration changed data; transaction will roll back.");
            if(sequenceBefore!=Convert.ToString(await Scalar(db,tx,"SELECT CONVERT(varchar(40),current_value) FROM sys.sequences WHERE name='InvoiceNumberSequence' AND schema_id=SCHEMA_ID('dbo');")))throw new InvalidOperationException("Migration advanced the invoice sequence.");
            await VerifyNoTableRights(db,tx);
            var newHash=Digest(await System.IO.File.ReadAllBytesAsync(Path.Combine(AppProfile.Package,"manifest.json")));
            var updated=p with {ManifestSha256=newHash};
            await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"profile-after.json"),JsonSerializer.Serialize(updated,new JsonSerializerOptions{WriteIndented=true}));
            await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"prepared.json"),JsonSerializer.Serialize(new{database=p.Database,id=p.DatabaseId,guid=p.DatabaseGuid,fileGuid=p.FileGuid,before,after,legacyProcedures=11,newProcedures=61,unchangedRows=true,invoiceSequenceUnchanged=true}));
            if(rehearsal)
            {
                foreach(var batch in Regex.Split(rollback.Replace(":ON ERROR EXIT","",StringComparison.Ordinal),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
                    if(!string.IsNullOrWhiteSpace(batch))await NonQuery(db,tx,batch);
                var restoredDefinitions=await Definitions(db,tx);var restoredPermissions=await Permissions(db,tx);
                await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"permissions-after-rollback-script.json"),JsonSerializer.Serialize(restoredPermissions));
                await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"definitions-after-rollback-script.json"),JsonSerializer.Serialize(restoredDefinitions));
                if(!SameDefinitions(definitions,restoredDefinitions)||!permissions.SequenceEqual(restoredPermissions)||!before.SequenceEqual(await Fingerprints(db,tx)))throw new InvalidOperationException("Generated rollback script did not restore the legacy contract exactly.");
                await tx.RollbackAsync();
                rolledBack=true;
                if(!definitions.SequenceEqual(await Definitions(db,null))||!permissions.SequenceEqual(await Permissions(db,null)))throw new InvalidOperationException("Migration rollback metadata mismatch.");
                await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"rehearsal.json"),JsonSerializer.Serialize(new{pass=true,generatedRollbackScriptExecuted=true,rolledBack=true,unchangedRows=true,definitionsAndPermissionsRestored=true}));
                Console.WriteLine(JsonSerializer.Serialize(new{pass=true,rehearsal=true,rolledBack=true,unchangedRows=true,receipt=folder}));return 0;
            }
            await tx.CommitAsync();committed=true;
            // If this atomic file promotion fails, the prepared receipt and profiles are retained for recovery.
            var staged=path+".security-v2.tmp";System.IO.File.Copy(Path.Combine(folder,"profile-after.json"),staged,false);System.IO.File.Move(staged,path,true);
            await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"complete.json"),JsonSerializer.Serialize(new{pass=true,database=p.Database,unchangedRows=true,profilePromoted=true,procedures=61}));
            Console.WriteLine(JsonSerializer.Serialize(new{pass=true,database=p.Database,id=p.DatabaseId,procedures=61,tables=12,columns=99,unchangedRows=true,receipt=folder}));return 0;
        }
        catch
        {
            if(!committed&&!rolledBack)await tx.RollbackAsync();
            await System.IO.File.WriteAllTextAsync(Path.Combine(folder,"failed.json"),JsonSerializer.Serialize(new{committed,profileMayRequireRecovery=committed}));
            throw;
        }
    }
    private static string Q(string value)=>"["+value.Replace("]","]]",StringComparison.Ordinal)+"]";
    // SQL Server may store CREATE OR ALTER as CREATE followed by extra spaces.
    // Normalize only the DDL introducer and line endings; the entire body remains exact.
    private static string NormalizeDefinition(string sql)=>Regex.Replace(sql.Trim().Replace("\r\n","\n"),@"^(?:CREATE(?:\s+OR\s+ALTER)?|ALTER)\s+PROCEDURE\b","CREATE PROCEDURE",RegexOptions.IgnoreCase|RegexOptions.Multiline);
    private static bool SameDefinitions(List<Definition> left,List<Definition> right)=>left.Select(d=>(d.Name,Sql:NormalizeDefinition(d.Sql))).SequenceEqual(right.Select(d=>(d.Name,Sql:NormalizeDefinition(d.Sql))));
    private static string Digest(string value)=>Digest(Encoding.UTF8.GetBytes(value));
    private static string Digest(byte[] bytes)=>Convert.ToHexString(SHA256.HashData(bytes));
    private static async Task<object?> Scalar(SqlConnection db,SqlTransaction? tx,string sql,Dictionary<string,object?>? args=null)
    {
        await using var cmd=new SqlCommand(sql,db,tx){CommandTimeout=90};if(args is not null)foreach(var (k,v) in args)cmd.Parameters.AddWithValue(k,v??DBNull.Value);return await cmd.ExecuteScalarAsync();
    }
    private static async Task NonQuery(SqlConnection db,SqlTransaction? tx,string sql)
    {await using var cmd=new SqlCommand(sql,db,tx){CommandTimeout=90};await cmd.ExecuteNonQueryAsync();}
    private static async Task<List<Definition>> Definitions(SqlConnection db,SqlTransaction? tx)
    {
        var rows=new List<Definition>();await using var cmd=new SqlCommand("SELECT p.name,m.definition FROM sys.procedures p JOIN sys.sql_modules m ON p.object_id=m.object_id WHERE p.is_ms_shipped=0 ORDER BY p.name;",db,tx);
        await using var r=await cmd.ExecuteReaderAsync();while(await r.ReadAsync())rows.Add(new(r.GetString(0),r.GetString(1)));return rows;
    }
    private static async Task<List<Permission>> Permissions(SqlConnection db,SqlTransaction? tx)
    {
        var rows=new List<Permission>();await using var cmd=new SqlCommand("""
SELECT p.state,p.permission_name,p.class,p.major_id,p.minor_id,r.name,
 OBJECT_SCHEMA_NAME(p.major_id),OBJECT_NAME(p.major_id),COL_NAME(p.major_id,p.minor_id),
 CASE WHEN p.class=3 THEN SCHEMA_NAME(p.major_id) WHEN p.class=6 THEN TYPE_NAME(p.major_id) END
FROM sys.database_permissions p JOIN sys.database_principals r ON p.grantee_principal_id=r.principal_id
WHERE r.name IN ('dbms12_runtime','dbms12_operator','dbms12_report_reader','dbms12_audit_reader')
ORDER BY r.name,p.class,p.major_id,p.minor_id,p.permission_name;
""",db,tx);
        await using var reader=await cmd.ExecuteReaderAsync();while(await reader.ReadAsync())
        {
            var state=reader.GetString(0);var name=reader.GetString(1);var cls=Convert.ToInt32(reader.GetValue(2));
            if(!Regex.IsMatch(name,@"\A[A-Z_ ]+\z")||state is not ("G" or "D"))throw new InvalidOperationException("Unexpected legacy permission state.");
            string scope=cls switch
            {
                0=>"",
                1=>" ON OBJECT::"+Q(reader.GetString(6))+"."+Q(reader.GetString(7))+(reader.GetInt32(4)>0?" ("+Q(reader.GetString(8))+")":""),
                3=>" ON SCHEMA::"+Q(reader.GetString(9)),
                6=>" ON TYPE::dbo."+Q(reader.GetString(9)),
                _=>throw new InvalidOperationException("Unexpected legacy permission class.")
            };
            rows.Add(new(state,name,scope,reader.GetString(5)));
        }
        return rows;
    }
    private static string PermissionSql(Permission p,string action)=>action+" "+p.PermissionName+p.Scope+(action=="REVOKE"?" FROM ":" TO ")+Q(p.Principal)+";";
    private static async Task<List<RowFingerprint>> Fingerprints(SqlConnection db,SqlTransaction tx)
    {
        var names=new List<(string Table,string Key)>();
        await using(var cmd=new SqlCommand("SELECT t.name,c.name FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id AND i.is_primary_key=1 JOIN sys.index_columns ic ON ic.object_id=t.object_id AND ic.index_id=i.index_id AND ic.key_ordinal=1 JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ic.column_id WHERE t.is_ms_shipped=0 ORDER BY t.name;",db,tx))
        {await using var r=await cmd.ExecuteReaderAsync();while(await r.ReadAsync())names.Add((r.GetString(0),r.GetString(1)));}
        var rows=new List<RowFingerprint>();foreach(var (table,key) in names)
        {
            using var hash=IncrementalHash.CreateHash(HashAlgorithmName.SHA256);long count=0;
            await using var cmd=new SqlCommand($"SELECT * FROM dbo.{Q(table)} WITH(TABLOCK,HOLDLOCK) ORDER BY {Q(key)};",db,tx){CommandTimeout=90};
            await using var r=await cmd.ExecuteReaderAsync();while(await r.ReadAsync())
            {var values=new object[r.FieldCount];r.GetValues(values);hash.AppendData(JsonSerializer.SerializeToUtf8Bytes(values.Select(v=>v is DBNull?null:v).ToArray()));count++;}
            rows.Add(new(table,count,Convert.ToHexString(hash.GetHashAndReset())));
        }
        return rows;
    }
    private static async Task VerifyNoTableRights(SqlConnection db,SqlTransaction tx)
    {
        // Includes column grants: a legacy column GRANT could override a table DENY.
        await NonQuery(db,tx,"""
EXECUTE AS USER='Dbms12ProjectRuntime';
IF EXISTS(SELECT 1 FROM sys.tables t JOIN sys.columns c ON c.object_id=t.object_id WHERE t.is_ms_shipped=0 AND
 (HAS_PERMS_BY_NAME('dbo.'+QUOTENAME(t.name),'OBJECT','SELECT',c.name,'COLUMN')=1 OR
 HAS_PERMS_BY_NAME('dbo.'+QUOTENAME(t.name),'OBJECT','UPDATE',c.name,'COLUMN')=1 OR
 HAS_PERMS_BY_NAME('dbo.'+QUOTENAME(t.name),'OBJECT','INSERT')=1 OR HAS_PERMS_BY_NAME('dbo.'+QUOTENAME(t.name),'OBJECT','DELETE')=1))
BEGIN REVERT; THROW 51997,N'Runtime still has direct table rights.',1; END;
REVERT;
""");
    }
    private static string RollbackScript(AppProfile p,JsonElement manifest,List<Definition> definitions,List<Permission> permissions)
    {
        var b=new StringBuilder(":ON ERROR EXIT\nSET XACT_ABORT ON;\n");
        b.AppendLine($"IF DB_NAME()<>'{p.Database}' OR DB_ID()<>{p.DatabaseId} OR NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid='{p.DatabaseGuid}') THROW 51999,N'Rollback identity mismatch',1;\nBEGIN TRANSACTION;\nGO");
        var old=definitions.Select(x=>x.Name).ToHashSet(StringComparer.Ordinal);
        foreach(var entry in manifest.GetProperty("operations").EnumerateObject())if(!old.Contains(entry.Name))b.AppendLine($"DROP PROCEDURE dbo.{Q(entry.Name)};");
        foreach(var name in new[]{"usp_SecuritySession","usp_BeginRead","usp_BeginWrite","usp_RecordFailure","usp_PasswordSnapshot"})b.AppendLine($"DROP PROCEDURE dbo.{name};");
        foreach(var role in manifest.GetProperty("businessRoles").EnumerateObject())
        {
            var roleName=role.Value[0].GetString()!;var user=role.Value[1].GetString()!;
            b.AppendLine($"REVOKE IMPERSONATE ON USER::{Q(user)} FROM dbms12_runtime; ALTER ROLE {Q(roleName)} DROP MEMBER {Q(user)}; DROP USER {Q(user)}; DROP ROLE {Q(roleName)};");
        }
        // Dropping new modules removes their grants. Remove new table DENYs before restoring old grants.
        b.AppendLine("REVOKE VIEW DEFINITION ON SCHEMA::dbo FROM dbms12_runtime;");
        foreach(var table in new[]{"Account","AuthSession","Course","Registration","Class","StudentClassAssignment","Schedule","Attendance","GradeReport","Invoice","AuditLog","ReplayOperation"})
            foreach(var role in new[]{"dbms12_runtime","dbms12_operator","dbms12_report_reader","dbms12_audit_reader"})
                b.AppendLine($"REVOKE SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.{Q(table)} FROM {Q(role)};");
        foreach(var permission in permissions)b.AppendLine(PermissionSql(permission,permission.State=="D"?"DENY":"GRANT"));
        b.AppendLine("GO");foreach(var d in definitions)b.AppendLine(Regex.Replace(d.Sql,@"\bCREATE\s+PROCEDURE\b","CREATE OR ALTER PROCEDURE",RegexOptions.IgnoreCase)+"\nGO");
        b.AppendLine("COMMIT;\n-- After success, stop host and restore profile-before.json + the matching legacy source package together.");return b.ToString();
    }
}
