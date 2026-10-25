using System.Data;
using System.Security.Cryptography;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12;

internal static class SqlContextVerification
{
    internal static async Task Verify(SqlConnection db,AppProfile p,List<string> checks)
    {
        var studentSid=RandomNumberGenerator.GetBytes(32);var teacherSid=RandomNumberGenerator.GetBytes(32);
        long studentEpoch,teacherEpoch;
        await using(var insert=new SqlCommand("""
DECLARE @Now datetime2(3)=SYSUTCDATETIME();
INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at)
SELECT @StudentSid,account_id,@Now,@Now FROM dbo.Account WHERE email='s1@dbms12.example';
INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at)
SELECT @TeacherSid,account_id,@Now,@Now FROM dbo.Account WHERE email='teacher@dbms12.example';
SELECT (SELECT security_version FROM dbo.Account WHERE email='s1@dbms12.example'),
 (SELECT security_version FROM dbo.Account WHERE email='teacher@dbms12.example');
""",db))
        {
            insert.Parameters.Add("@StudentSid",SqlDbType.Binary,32).Value=studentSid;insert.Parameters.Add("@TeacherSid",SqlDbType.Binary,32).Value=teacherSid;
            await using var r=await insert.ExecuteReaderAsync();await r.ReadAsync();studentEpoch=r.GetInt64(0);teacherEpoch=r.GetInt64(1);
        }
        var impersonated=false;
        try
        {
            await using(var user=new SqlCommand("EXECUTE AS USER='Dbms12ProjectRuntime';",db))await user.ExecuteNonQueryAsync();impersonated=true;
            var executor=new Data.CompactSqlExecutor(AppProfile.Package);
            var student=new Dictionary<string,object?>{["@Sid"]=studentSid,["@Epoch"]=studentEpoch};
            var courses=new Dictionary<string,object?>(student){["@Search"]="",["@Page"]=1,["@PageSize"]=20};
            await executor.Execute(db,"usp_CourseList",courses);await BaseContext(db);checks.Add("executor-success-revert");Console.WriteLine("Context success cleanup PASS");
            try
            {
                await executor.Execute(db,"usp_FinanceReport",new(student){["@From"]=DateTime.UtcNow.AddDays(-1),["@Until"]=DateTime.UtcNow.AddDays(1)});
                throw new InvalidOperationException("Student unexpectedly executed finance module.");
            }
            catch(SqlException e) when(e.Number==229) { }
            await BaseContext(db);checks.Add("executor-denial-revert");Console.WriteLine("Context denial cleanup PASS");
            await using(var blocker=new SqlConnection(p.Connection))
            {
                await blocker.OpenAsync();await SqlSecurityVerification.Guard(blocker,p);
                await using(var locked=new SqlCommand("SET LOCK_TIMEOUT 5000; BEGIN TRANSACTION; SELECT COUNT_BIG(*) FROM dbo.Schedule WITH(TABLOCKX,HOLDLOCK);",blocker))await locked.ExecuteNonQueryAsync();
                Console.WriteLine("Context cancellation blocker ready");
                try
                {
                    using var cancel=new CancellationTokenSource(TimeSpan.FromMilliseconds(500));
                    try
                    {
                        var pending=executor.Execute(db,"usp_AttendanceRead",new(){["@Sid"]=teacherSid,["@Epoch"]=teacherEpoch,["@ScheduleId"]=1},cancel.Token);
                        await Task.Delay(1500);
                        if(!pending.IsCompleted)
                        {
                            await using var diagnostic=new SqlConnection(p.Connection);await diagnostic.OpenAsync();
                            await using var state=new SqlCommand("SELECT r.wait_type,OBJECT_NAME(t.objectid,r.database_id) FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t WHERE r.database_id=DB_ID() AND r.session_id<>@@SPID;",diagnostic);
                            await using var reader=await state.ExecuteReaderAsync();while(await reader.ReadAsync())Console.WriteLine("Cancellation diagnostic: wait="+(reader.IsDBNull(0)?"none":reader.GetString(0))+"; module="+(reader.IsDBNull(1)?"control":reader.GetString(1)));
                        }
                        await pending;
                        throw new InvalidOperationException("Expected cancellation while business context was blocked.");
                    }
                    catch(OperationCanceledException) when(cancel.IsCancellationRequested) { }
                }
                finally {await using var rollback=new SqlCommand("IF XACT_STATE()<>0 ROLLBACK;",blocker);await rollback.ExecuteNonQueryAsync();}
            }
            await BaseContext(db);checks.Add("executor-cancellation-revert");Console.WriteLine("Context cancellation cleanup PASS");
            // A shared Course lock allows prevalidation reads, but blocks the dispatched write.
            // This distinguishes cancellation after dispatch from cancellation before the call.
            await using(var blocker=new SqlConnection(p.Connection))
            {
                await blocker.OpenAsync();await SqlSecurityVerification.Guard(blocker,p);
                await using(var locked=new SqlCommand("BEGIN TRANSACTION; SELECT COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);",blocker))await locked.ExecuteNonQueryAsync();
                try
                {
                    var request=Guid.NewGuid();
                    await using var failures=new SqlCommand("SELECT COUNT(*) FROM dbo.AuditLog WHERE action_code='DBMS12.STUDENT.REGISTRATION.CREATE' AND result_code='FAILURE';",blocker);
                    var failureCount=Convert.ToInt32(await failures.ExecuteScalarAsync());
                    using var cancel=new CancellationTokenSource();
                    var pending=executor.Execute(db,"usp_RegistrationCreate",new(student){["@CourseId"]=1,["@RequestId"]=request,["@Digest"]=SHA256.HashData(request.ToByteArray())},cancel.Token);
                    var observed=false;var until=DateTime.UtcNow.AddSeconds(5);
                    while(!pending.IsCompleted&&DateTime.UtcNow<until)
                    {
                        await using var state=new SqlCommand("SELECT COUNT(*) FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t WHERE r.session_id=@Session AND r.blocking_session_id=@@SPID AND OBJECT_NAME(t.objectid,r.database_id)='usp_RegistrationCreate';",blocker);
                        state.Parameters.AddWithValue("@Session",db.ServerProcessId);
                        if(Convert.ToInt32(await state.ExecuteScalarAsync())==1){observed=true;break;}
                        await Task.Delay(50);
                    }
                    cancel.Cancel();
                    try{await pending;throw new InvalidOperationException("Expected uncertain cancelled write.");}
                    catch(ApiProblem e) when(e.Status==503&&e.Code=="COMMAND_OUTCOME_UNKNOWN") { }
                    if(!observed)throw new InvalidOperationException("Did not observe the dispatched write waiting for its lock.");
                    await BaseContext(db);
                    await using var receipt=new SqlCommand("SELECT COUNT(*) FROM dbo.ReplayOperation WHERE request_id=@Request;",blocker);receipt.Parameters.AddWithValue("@Request",request);
                    if(Convert.ToInt32(await receipt.ExecuteScalarAsync())!=0||failureCount!=Convert.ToInt32(await failures.ExecuteScalarAsync()))throw new InvalidOperationException("Cancelled write created a receipt or a false failure audit.");
                    checks.Add("executor-dispatched-write-cancel-unknown-revert");checks.Add("executor-cancel-no-false-failure");
                    Console.WriteLine("Dispatched write cancellation: unknown/no false failure/context clean PASS");
                }
                finally{await using var rollback=new SqlCommand("IF XACT_STATE()<>0 ROLLBACK;",blocker);await rollback.ExecuteNonQueryAsync();}
            }
            await executor.Execute(db,"usp_CourseList",courses);await BaseContext(db);checks.Add("executor-next-request-clean");
        }
        finally
        {
            if(impersonated){await using var revert=new SqlCommand("REVERT;",db);await revert.ExecuteNonQueryAsync();}
            await using var cleanup=new SqlCommand("DELETE dbo.AuthSession WHERE (sid=@StudentSid AND account_id=(SELECT account_id FROM dbo.Account WHERE email='s1@dbms12.example')) OR (sid=@TeacherSid AND account_id=(SELECT account_id FROM dbo.Account WHERE email='teacher@dbms12.example'));",db);
            cleanup.Parameters.Add("@StudentSid",SqlDbType.Binary,32).Value=studentSid;cleanup.Parameters.Add("@TeacherSid",SqlDbType.Binary,32).Value=teacherSid;await cleanup.ExecuteNonQueryAsync();
            CryptographicOperations.ZeroMemory(studentSid);CryptographicOperations.ZeroMemory(teacherSid);
        }
    }
    private static async Task BaseContext(SqlConnection db)
    {
        await using var cmd=new SqlCommand("SELECT USER_NAME(),@@TRANCOUNT;",db);await using var r=await cmd.ExecuteReaderAsync();await r.ReadAsync();
        if(r.GetString(0)!="Dbms12ProjectRuntime"||r.GetInt32(1)!=0)throw new InvalidOperationException("SQL context or transaction leaked between requests.");
    }
}
