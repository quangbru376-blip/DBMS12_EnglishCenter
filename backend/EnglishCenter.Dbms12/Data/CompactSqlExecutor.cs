using System.Data;
using System.Globalization;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12.Data;
internal sealed class CompactSqlExecutor
{
    private readonly string _folder;
    private readonly JsonDocument _manifest;
    private readonly Dictionary<string,string> _sql=[];
    internal CompactSqlExecutor(string root)
    {
        _folder=Path.GetFullPath(root);
        _manifest=JsonDocument.Parse(File.ReadAllText(Path.Combine(_folder,"manifest.json")));
        foreach(var file in _manifest.RootElement.GetProperty("files").EnumerateObject())
        {
            var path=Path.GetFullPath(Path.Combine(_folder,file.Name));
            if(!path.StartsWith(_folder+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("SQL file path guard");
            var bytes=File.ReadAllBytes(path);
            if(!Convert.ToHexString(SHA256.HashData(bytes)).Equals(file.Value.GetString(),StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("SQL hash mismatch");
            _sql[file.Name]=System.Text.Encoding.UTF8.GetString(bytes);
        }
    }
    internal JsonElement Operation(string name)=>_manifest.RootElement.GetProperty("operations").GetProperty(name);
    internal bool Contains(string name)=>_manifest.RootElement.GetProperty("operations").TryGetProperty(name,out _);
    private string Text(string name)=>_sql[name];
    private static object? Value(Dictionary<string,object?> p,string key)=>p.GetValueOrDefault(key);
    private static async Task<List<Dictionary<string,object?>>> Query(SqlConnection db,string sql,Dictionary<string,object?>? args=null,CancellationToken token=default)
    {
        await using var cmd=new SqlCommand(sql,db){CommandTimeout=90};
        if(args is not null)foreach(var (name,value) in args)
            cmd.Parameters.AddWithValue(name,value??DBNull.Value);
        return await Read(cmd,token);
    }
    private static async Task<List<Dictionary<string,object?>>> Read(SqlCommand cmd,CancellationToken token=default)
    {
        var rows=new List<Dictionary<string,object?>>();
        using var cancellation=token.Register(cmd.Cancel);
        await using var reader=await cmd.ExecuteReaderAsync(token);
        do{while(await reader.ReadAsync(token))
        {
            var row=new Dictionary<string,object?>(StringComparer.Ordinal);
            for(var i=0;i<reader.FieldCount;i++)row.Add(reader.GetName(i),reader.IsDBNull(i)?null:reader.GetValue(i));
            rows.Add(row);
        }}while(await reader.NextResultAsync(token));
        return rows;
    }
    private static void Add(SqlCommand cmd,JsonElement spec,Dictionary<string,object?> args)
    {
        var name=spec.GetProperty("name").GetString()!;
        object? value;
        if(!args.TryGetValue(name,out value))
        {
            var def=spec.GetProperty("default");
            if(def.ValueKind==JsonValueKind.Null)throw new InvalidOperationException("Missing typed SQL argument "+name);
            var token=def.GetString()!;
            value=token.Equals("NULL",StringComparison.OrdinalIgnoreCase)?null:token.StartsWith("N'",StringComparison.Ordinal)?token[2..^1]:token.StartsWith('\'')?token[1..^1]:int.Parse(token,CultureInfo.InvariantCulture);
        }
        var type=spec.GetProperty("type").GetString()!;
        if(type.StartsWith("dbo.",StringComparison.Ordinal))
        {
            var tvp=cmd.Parameters.Add(name,SqlDbType.Structured);tvp.TypeName=type;tvp.Value=value;return;
        }
        var m=Regex.Match(type,@"^(\w+)(?:\((\d+)\))?$");
        var kind=m.Groups[1].Value.ToLowerInvariant() switch
        {
            "int"=>SqlDbType.Int,"bigint"=>SqlDbType.BigInt,"tinyint"=>SqlDbType.TinyInt,"varchar"=>SqlDbType.VarChar,"nvarchar"=>SqlDbType.NVarChar,
            "binary"=>SqlDbType.Binary,"varbinary"=>SqlDbType.VarBinary,"bit"=>SqlDbType.Bit,"datetime2"=>SqlDbType.DateTime2,
            "date"=>SqlDbType.Date,"time"=>SqlDbType.Time,"uniqueidentifier"=>SqlDbType.UniqueIdentifier,_=>throw new InvalidOperationException("SQL type allowlist "+type)
        };
        var p=cmd.Parameters.Add(name,kind);
        if(m.Groups[2].Success && kind is not (SqlDbType.DateTime2 or SqlDbType.Time))p.Size=int.Parse(m.Groups[2].Value,CultureInfo.InvariantCulture);
        if(kind==SqlDbType.Date && value is string date)value=DateTime.ParseExact(date,"yyyy-MM-dd",CultureInfo.InvariantCulture);
        p.Value=value??DBNull.Value;
    }
    internal async Task<List<Dictionary<string,object?>>> PasswordSnapshot(SqlConnection db,Dictionary<string,object?> args,CancellationToken token)
    {
        var existing=await Query(db,"SELECT @@TRANCOUNT AS depth;",token:token);
        if(Convert.ToInt32(existing[0]["depth"])!=0)throw new InvalidOperationException("Password snapshot requires an unowned connection; existing transaction is preserved.");
        try
        {
            var rows=await Query(db,"EXEC dbo.usp_PasswordSnapshot @Sid,@Epoch;",args,token);
            await EnsureCompleted(db);
            return rows;
        }
        catch { await Query(db,"IF XACT_STATE()<>0 ROLLBACK;"); throw; }
    }
    private static async Task EnsureCompleted(SqlConnection db)
    {
        var rows=await Query(db,"SELECT @@TRANCOUNT AS depth;");
        if(rows.Count!=1||Convert.ToInt32(rows[0]["depth"])!=0)
            throw new InvalidOperationException("SQL procedure did not complete its transaction; outcome must remain uncertain.");
    }
    // Only errors known to occur before the SQL procedure COMMIT prove failure.
    // Timeout, transport loss, attention and post-COMMIT cleanup never create a fake failure audit.
    private static bool DefiniteFailure(SqlException error)=>error.Number is >=51000 and <=51999
        or 229 or 2601 or 2627 or 547 or 515 or 8115 or 2628 or 1205;
    private static async Task Revert(SqlConnection db)
    {
        var rows=await Query(db,"REVERT; SELECT USER_NAME() AS principal_name;");
        if(rows.Count!=1||(string?)rows[0]["principal_name"]!="Dbms12ProjectRuntime")throw new InvalidOperationException("SQL context cleanup failed; command outcome must remain uncertain.");
    }
    internal async Task<List<Dictionary<string,object?>>> Execute(SqlConnection db,string name,Dictionary<string,object?> args,CancellationToken token=default)
    {
        var existing=await Query(db,"SELECT @@TRANCOUNT AS depth;",token:token);
        if(Convert.ToInt32(existing[0]["depth"])!=0)throw new InvalidOperationException("Executor requires an unowned connection; existing transaction is preserved.");
        var op=Operation(name);
        if(!op.GetProperty("stored").GetBoolean())throw new InvalidOperationException("Native security requires stored modules.");
        var command=op.GetProperty("kind").GetString()=="command";
        var mutating=op.GetProperty("kind").GetString()!="read"&&name!="usp_LoginRead";
        var action=command?op.GetProperty("action").GetString()!:name=="usp_LoginRecord"?"DBMS12.AUTH.LOGIN.FAILURE":name=="usp_OperatorBootstrap"?"DBMS12.OPERATOR.BOOTSTRAP":name=="usp_MaintenanceCleanup"?"DBMS12.MAINTENANCE.CLEANUP":"DBMS12.AUTH.ACCESS.DENIED";
        var dispatched=false;
        var switched=false;
        try
        {
            if(op.GetProperty("context").GetString()=="business")
            {
                var current=await Query(db,"EXEC dbo.usp_CurrentSession @Sid,@Epoch;",new(){["@Sid"]=Value(args,"@Sid"),["@Epoch"]=Value(args,"@Epoch")},token);
                if(current.Count!=1)throw new InvalidOperationException("Expected verified session.");
                var sql=SqlBusinessContext.Switch((string)current[0]["role_code"]!);
                token.ThrowIfCancellationRequested();
                // Context transitions and cleanup are bounded but not request-cancellable.
                // Every connection is unpooled and disposed, including on transition failure.
                await Query(db,sql);
                switched=true;
            }
            await using var cmd=new SqlCommand("dbo."+name,db){CommandTimeout=90,CommandType=CommandType.StoredProcedure};
            foreach(var p in op.GetProperty("parameters").EnumerateArray())Add(cmd,p,args);
            token.ThrowIfCancellationRequested();
            dispatched=true;
            var result=await Read(cmd,token);
            // Read consumes every result and the final server completion, including SQL COMMIT.
            // Do not turn a completed SQL write into a cancellation afterwards.
            await EnsureCompleted(db);
            return result;
        }
        catch(Exception e) when(token.IsCancellationRequested&&e is SqlException or OperationCanceledException)
        {
            await Query(db,"IF XACT_STATE()<>0 ROLLBACK;");
            if(mutating&&dispatched)throw new ApiProblem(503,"COMMAND_OUTCOME_UNKNOWN","Chưa xác định được kết quả. Không tự gửi lại; hãy kiểm tra kết quả thao tác.");
            throw new OperationCanceledException("SQL read/request cancelled; cleanup completed.",e,token);
        }
        catch(SqlException e)
        {
            await Query(db,"IF XACT_STATE()<>0 ROLLBACK;");
            if(switched){await Revert(db);switched=false;}
            if(DefiniteFailure(e))await Query(db,"EXEC dbo.usp_RecordFailure @Sid,@Epoch,@Action,@Error;",new(){["@Sid"]=Value(args,"@Sid"),["@Epoch"]=Value(args,"@Epoch")??Value(args,"@ObservedEpoch"),["@Action"]=action,["@Error"]=e.Number});
            throw;
        }
        catch
        {
            await Query(db,"IF XACT_STATE()<>0 ROLLBACK;");
            throw;
        }
        finally
        {
            if(switched)await Revert(db);
        }
    }
}
