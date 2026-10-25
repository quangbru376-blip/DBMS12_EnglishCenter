using System.Data;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12;

// Explicit fixture-only proof: never invoked by the web host or a normal launcher.
internal static class SqlTransactionVerification
{
    private sealed record Session(byte[] Sid,long Epoch);
    internal static async Task<int> RunAsync(string path)
    {
        var p=AppProfile.Load(Path.GetFullPath(path));
        if(!Regex.IsMatch(p.Workspace,@"[\\/]\.local[\\/]security-redesign[\\/]fixture-[0-9a-f]{32}$"))throw new InvalidOperationException("Transaction writes require a dedicated fixture.");
        if(File.Exists(Path.Combine(p.Workspace,"docs/evidence/sql-transactions.json")))throw new InvalidOperationException("Transaction proof already completed; use a fresh fixture, do not rerun the cohort.");
        await using var owner=new SqlConnection(p.Connection);await owner.OpenAsync();await SqlSecurityVerification.Guard(owner,p);
        var sessions=new Dictionary<string,Session>();var checks=new List<string>();
        var users=new Dictionary<string,int>{{"Student",7},{"Admissions",2},{"AcademicAffairs",3},{"Accountant",5}};
        try
        {
            foreach(var (role,id) in users)
            {
                var sid=RandomNumberGenerator.GetBytes(32);
                await Sql(owner,"INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at) VALUES(@Sid,@Id,SYSUTCDATETIME(),SYSUTCDATETIME());",new(){["@Sid"]=sid,["@Id"]=id});
                sessions.Add(role,new(sid,Convert.ToInt64(await Scalar(owner,"SELECT security_version FROM dbo.Account WHERE account_id=@Id;",new(){["@Id"]=id}))));
            }
            Dictionary<string,object?> Args(string role,Dictionary<string,object?> fields)
            {
                var digestFields=fields.ToDictionary(k=>k.Key,v=>v.Value is DataTable t?(object)t.Rows.Cast<DataRow>().Select(r=>r.ItemArray).ToArray():v.Value);
                var args=new Dictionary<string,object?>(fields){["@Sid"]=sessions[role].Sid,["@Epoch"]=sessions[role].Epoch,["@RequestId"]=Guid.NewGuid(),["@Digest"]=SHA256.HashData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(digestFields)))};
                return args;
            }
            async Task<List<Dictionary<string,object?>>> Run(string proc,Dictionary<string,object?> args)
            {
                await using var db=new SqlConnection(p.Connection);await db.OpenAsync();await SqlSecurityVerification.Guard(db,p);
                await Sql(db,"EXECUTE AS USER='Dbms12ProjectRuntime';");
                try{return await new Data.CompactSqlExecutor(AppProfile.Package).Execute(db,proc,args);}
                finally
                {
                    if(Convert.ToInt32(await Scalar(db,"SELECT @@TRANCOUNT;"))!=0)throw new InvalidOperationException("Transaction leaked from "+proc);
                    if((string?)await Scalar(db,"SELECT USER_NAME();")!="Dbms12ProjectRuntime")throw new InvalidOperationException("Principal leaked from "+proc);
                    await Sql(db,"REVERT;");
                }
            }
            async Task RollbackProof(string proc,string action,Dictionary<string,object?> args,Func<Task<bool>> stateUnchanged)
            {
                var trigger="txn_proof_"+Guid.NewGuid().ToString("N");
                if(!Regex.IsMatch(action,@"\ADBMS12\.[A-Z.]+\z"))throw new InvalidOperationException("Proof action allowlist.");
                await Sql(owner,$"CREATE TRIGGER dbo.[{trigger}] ON dbo.AuditLog AFTER INSERT AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM inserted WHERE action_code='{action}' AND result_code='SUCCESS') THROW 51998,N'Fixture transaction rollback proof',1; END;");
                try
                {
                    try{await Run(proc,args);throw new InvalidOperationException("Expected injected audit failure: "+proc);}
                    catch(SqlException e) when(e.Number==51998) { }
                    if(!await stateUnchanged())throw new InvalidOperationException("Business data survived rollback: "+proc);
                    if(Convert.ToInt32(await Scalar(owner,"SELECT COUNT(*) FROM dbo.ReplayOperation WHERE request_id=@RequestId;",new(){["@RequestId"]=args["@RequestId"]}))!=0)throw new InvalidOperationException("Replay receipt survived rollback.");
                    checks.Add("rollback:"+proc);
                }
                finally{await Sql(owner,$"DROP TRIGGER dbo.[{trigger}];");}
            }
            static int Target(List<Dictionary<string,object?>> rows)=>Convert.ToInt32(rows[0]["target_id"]);
            var code="TXN-"+Guid.NewGuid().ToString("N")[..10];
            var courseArgs=Args("AcademicAffairs",new(){["@Code"]=code,["@Name"]="Khóa minh chứng transaction",["@Tuition"]="1000000",["@Lessons"]=1,["@Weight"]="40"});
            await RollbackProof("usp_CourseCreate","DBMS12.ACADEMIC.COURSE.CREATE",courseArgs,async()=>Convert.ToInt32(await Scalar(owner,"SELECT COUNT(*) FROM dbo.Course WHERE course_code=@Code;",new(){["@Code"]=code}))==0);
            var course=Target(await Run("usp_CourseCreate",Args("AcademicAffairs",new(){["@Code"]=code,["@Name"]="Khóa minh chứng transaction",["@Tuition"]="1000000",["@Lessons"]=1,["@Weight"]="40"})));checks.Add("commit:usp_CourseCreate");
            var registrationArgs=Args("Student",new(){["@CourseId"]=course});
            await RollbackProof("usp_RegistrationCreate","DBMS12.STUDENT.REGISTRATION.CREATE",registrationArgs,async()=>Convert.ToInt32(await Scalar(owner,"SELECT COUNT(*) FROM dbo.Registration WHERE course_id=@Id;",new(){["@Id"]=course}))==0);
            registrationArgs=Args("Student",new(){["@CourseId"]=course});var registration=Target(await Run("usp_RegistrationCreate",registrationArgs));checks.Add("commit:usp_RegistrationCreate");
            var replay=await Run("usp_RegistrationCreate",registrationArgs);
            if(Target(replay)!=registration||replay[0]["replayed"] is not true)throw new InvalidOperationException("Owned replay did not commit/return the existing operation.");checks.Add("replay-owned-transaction-clean");
            var version=(byte[])(await Scalar(owner,"SELECT row_version FROM dbo.Registration WHERE registration_id=@Id;",new(){["@Id"]=registration}))!;
            await Run("usp_RegistrationConfirm",Args("Student",new(){["@RegistrationId"]=registration,["@ExpectedVersion"]=version}));
            async Task<Dictionary<string,object?>> AdmissionArgs()=>Args("Admissions",new(){["@RegistrationId"]=registration,["@ExpectedVersion"]=await Scalar(owner,"SELECT row_version FROM dbo.Registration WHERE registration_id=@Id;",new(){["@Id"]=registration})});
            await RollbackProof("usp_AdmissionApprove","DBMS12.ADMISSIONS.REGISTRATION.APPROVE",await AdmissionArgs(),async()=>
                (string?)await Scalar(owner,"SELECT status FROM dbo.Registration WHERE registration_id=@Id;",new(){["@Id"]=registration})=="CONFIRMED"
                &&Convert.ToInt32(await Scalar(owner,"SELECT COUNT(*) FROM dbo.Invoice WHERE registration_id=@Id;",new(){["@Id"]=registration}))==0);
            await Run("usp_AdmissionApprove",await AdmissionArgs());checks.Add("commit:usp_AdmissionApprove");
            var invoice=Convert.ToInt32(await Scalar(owner,"SELECT invoice_id FROM dbo.Invoice WHERE registration_id=@Id;",new(){["@Id"]=registration}));
            async Task<Dictionary<string,object?>> CollectArgs()=>Args("Accountant",new(){["@InvoiceId"]=invoice,["@ExpectedVersion"]=await Scalar(owner,"SELECT row_version FROM dbo.Invoice WHERE invoice_id=@Id;",new(){["@Id"]=invoice}),["@Method"]="CASH",["@Reference"]=null});
            await RollbackProof("usp_InvoiceCollect","DBMS12.FINANCE.INVOICE.COLLECT",await CollectArgs(),async()=>await Scalar(owner,"SELECT paid_at FROM dbo.Invoice WHERE invoice_id=@Id;",new(){["@Id"]=invoice}) is DBNull);
            var first=await CollectArgs();var second=await CollectArgs();
            async Task<int> Race(Dictionary<string,object?> args){try{await Run("usp_InvoiceCollect",args);return 0;}catch(SqlException e) when(e.Number==51214){return e.Number;}}
            var results=await Task.WhenAll(Race(first),Race(second));
            if(results.Count(x=>x==0)!=1||results.Count(x=>x==51214)!=1)throw new InvalidOperationException("Concurrent collect must have one winner and one stale-version rejection.");
            if(Convert.ToInt32(await Scalar(owner,"SELECT COUNT(*) FROM dbo.AuditLog WHERE action_code='DBMS12.FINANCE.INVOICE.COLLECT' AND root_entity_id=@Id AND result_code='SUCCESS';",new(){["@Id"]=invoice}))!=1)throw new InvalidOperationException("Duplicate collect audit.");
            checks.Add("commit:usp_InvoiceCollect");checks.Add("concurrency:two-collectors-one-commit-one-conflict");
            var classId=Target(await Run("usp_ClassCreate",Args("AcademicAffairs",new(){["@Code"]=code+"-CLASS",["@CourseId"]=course,["@TeacherId"]=9,["@Capacity"]=(byte)1})));
            var schedules=new DataTable();schedules.Columns.Add("item_no",typeof(int));schedules.Columns.Add("schedule_type",typeof(string));schedules.Columns.Add("start_at",typeof(DateTime));schedules.Columns.Add("end_at",typeof(DateTime));schedules.Columns.Add("room",typeof(string));
            var start=DateTime.UtcNow.AddDays(60);schedules.Rows.Add(1,"LESSON",start,start.AddHours(1),code);schedules.Rows.Add(2,"FINAL_EXAM",start.AddDays(1),start.AddDays(1).AddHours(1),code);
            async Task<object?> ClassVersion()=>await Scalar(owner,"SELECT row_version FROM dbo.Class WHERE class_id=@Id;",new(){["@Id"]=classId});
            await Run("usp_ScheduleBatch",Args("AcademicAffairs",new(){["@ClassId"]=classId,["@ClassVersion"]=await ClassVersion(),["@Items"]=schedules}));
            await Run("usp_ClassOpen",Args("AcademicAffairs",new(){["@ClassId"]=classId,["@ExpectedVersion"]=await ClassVersion()}));
            async Task<Dictionary<string,object?>> PlacementArgs()=>Args("AcademicAffairs",new(){["@RegistrationId"]=registration,["@RegistrationVersion"]=await Scalar(owner,"SELECT row_version FROM dbo.Registration WHERE registration_id=@Id;",new(){["@Id"]=registration}),["@ClassId"]=classId,["@ClassVersion"]=await ClassVersion()});
            await RollbackProof("usp_PlacementCreate","DBMS12.ACADEMIC.PLACEMENT.CREATE",await PlacementArgs(),async()=>Convert.ToInt32(await Scalar(owner,"SELECT COUNT(*) FROM dbo.StudentClassAssignment WHERE registration_id=@Id;",new(){["@Id"]=registration}))==0);
            await Run("usp_PlacementCreate",await PlacementArgs());checks.Add("commit:usp_PlacementCreate");
            if(Convert.ToInt32(await Scalar(owner,"SELECT COUNT(*) FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.registration_id=@Id;",new(){["@Id"]=registration}))!=1)throw new InvalidOperationException("Placement must create exactly one grade stub.");
            var output=Path.Combine(p.Workspace,"docs/evidence");Directory.CreateDirectory(output);
            await File.WriteAllTextAsync(Path.Combine(output,"sql-transactions.json"),JsonSerializer.Serialize(new{pass=true,fixtureOnly=true,transactionOwner="SQL",businessCommitProofs=5,forcedRollbackProofs=5,concurrentWriters=2,concurrentSuccesses=1,checks},new JsonSerializerOptions{WriteIndented=true}));
            Console.WriteLine("SQL transaction proofs PASS:5 commits,5 audit-failure rollbacks,replay,2 concurrent collectors/1 effect.");return 0;
        }
        finally
        {
            foreach(var (role,session) in sessions)
            {
                await Sql(owner,"DELETE dbo.AuthSession WHERE sid=@Sid AND account_id=@Id;",new(){["@Sid"]=session.Sid,["@Id"]=users[role]});CryptographicOperations.ZeroMemory(session.Sid);
            }
        }
    }
    private static async Task Sql(SqlConnection db,string sql,Dictionary<string,object?>? args=null)
    {await using var c=new SqlCommand(sql,db){CommandTimeout=30};if(args is not null)foreach(var (k,v) in args)c.Parameters.AddWithValue(k,v??DBNull.Value);await c.ExecuteNonQueryAsync();}
    private static async Task<object?> Scalar(SqlConnection db,string sql,Dictionary<string,object?>? args=null)
    {await using var c=new SqlCommand(sql,db){CommandTimeout=30};if(args is not null)foreach(var (k,v) in args)c.Parameters.AddWithValue(k,v??DBNull.Value);return await c.ExecuteScalarAsync();}
}
