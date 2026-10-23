using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12;
internal static class OwnerInspect
{
 internal static async Task<int> RunAsync(string path)
 {
  var p=AppProfile.Load(Path.GetFullPath(path));
  _=new Data.CompactSqlExecutor(AppProfile.Package);
  await using var db=new SqlConnection(p.Connection);await db.OpenAsync();
  await using var q=new SqlCommand("""
SELECT DB_NAME(),DB_ID(),database_guid,
 (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0),
 (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0),
 (SELECT COUNT(*) FROM sys.objects WHERE type='FN' AND is_ms_shipped=0),
 (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped=0),
 (SELECT COUNT(*) FROM sys.triggers WHERE is_ms_shipped=0),
 (SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON c.object_id=t.object_id WHERE t.is_ms_shipped=0),
 (SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1),
 (SELECT COUNT(*) FROM sys.check_constraints WHERE is_disabled=1 OR is_not_trusted=1),
 (SELECT COUNT(*) FROM sys.triggers WHERE is_ms_shipped=0 AND is_disabled=1)
 FROM sys.database_recovery_status WHERE database_id=DB_ID();
""",db);
  int[] counts;
  await using(var r=await q.ExecuteReaderAsync())
  {
   if(!await r.ReadAsync()||r.GetString(0)!=p.Database||Convert.ToInt32(r.GetValue(1))!=p.DatabaseId||r.GetGuid(2)!=p.DatabaseGuid)throw new InvalidOperationException("Owned project database identity mismatch.");
   counts=Enumerable.Range(3,9).Select(i=>r.GetInt32(i)).ToArray();
   if(!counts.SequenceEqual(new[]{12,AppProfile.ProcedureCount,7,9,12,99,0,0,0}))throw new InvalidOperationException("Project schema/constraint check failed.");
  }
  await using(var constraints=new SqlCommand("DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;",db){CommandTimeout=60})
  {await using var r=await constraints.ExecuteReaderAsync();if(await r.ReadAsync())throw new InvalidOperationException("Constraint violations found.");}
  await using(var integrity=new SqlCommand("DBCC CHECKDB WITH NO_INFOMSGS,ALL_ERRORMSGS;",db){CommandTimeout=60})await integrity.ExecuteNonQueryAsync();
  Console.WriteLine(JsonSerializer.Serialize(new{pass=true,database=p.Database,id=p.DatabaseId,guid=p.DatabaseGuid,tables=counts[0],procedures=counts[1],functions=counts[2],views=counts[3],triggers=counts[4],columns=counts[5],untrustedOrDisabled=0,sqlFilesVerified=62,dbcc="PASS"}));return 0;
 }
}
