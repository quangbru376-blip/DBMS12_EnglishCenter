using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12.Data;

internal sealed class Dbms12Repository(AppProfile profile)
{
    private readonly CompactSqlExecutor executor=new(AppProfile.Package);
    internal System.Text.Json.JsonElement Operation(string name)=>executor.Operation(name);
    internal async Task<List<Dictionary<string,object?>>> RunAsync(string name,Dictionary<string,object?> args,CancellationToken token)
    {
        await using var db=new SqlConnection(profile.Connection);
        await db.OpenAsync(token);
        await profile.VerifyAsync(db,token);
        return await executor.Execute(db,name,args,token);
    }
    internal async Task<string?> CurrentPasswordAsync(Dictionary<string,object?> session,CancellationToken token)
    {
        await using var db=new SqlConnection(profile.Connection);await db.OpenAsync(token);await profile.VerifyAsync(db,token);
        var rows=await executor.PasswordSnapshot(db,session,token);
        return rows.SingleOrDefault()?.GetValueOrDefault("password_hash") as string;
    }
}
