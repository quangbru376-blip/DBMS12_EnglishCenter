using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using EnglishCenter.Dbms12.Common.Security;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12;

internal static class OwnerProvision
{
    internal static async Task<int> RunAsync(string workspace)
    {
        if(!OperatingSystem.IsWindows())return 1;
        ProjectLayout.Validate(workspace);var machine=MachineSettings.Load(workspace);
        _=new Data.CompactSqlExecutor(AppProfile.Package);
        var root=Path.Combine(workspace,".local");var owner=Path.Combine(root,"operator");
        using var current=WindowsIdentity.GetCurrent();
        var acl=new DirectoryInfo(owner).GetAccessControl();
        if(!acl.AreAccessRulesProtected||acl.GetOwner(typeof(SecurityIdentifier))?.Value!=current.User?.Value)throw new InvalidOperationException("Prepare private operator folder first.");
        var path=Path.Combine(root,"config/profile.json");
        if(File.Exists(path))
        {
            var existing=AppProfile.Load(path);
            Console.WriteLine(JsonSerializer.Serialize(new{phase="DBMS12-provision",alreadyPrepared=true,database=existing.Database}));return 0;
        }
        var resumePath=Path.Combine(owner,"empty-catalog-resume.json");
        if((File.Exists(Path.Combine(owner,"ownership.json"))||File.Exists(Path.Combine(owner,"creation-intent.json")))&&!File.Exists(resumePath))throw new InvalidOperationException("Existing ownership receipt without profile: inspect manually; never auto reset or reseed.");
        using var resume=File.Exists(resumePath)?JsonDocument.Parse(await File.ReadAllTextAsync(resumePath)):null;
        var database=resume?.RootElement.GetProperty("database").GetString()??"EnglishCenter_DBMS12_PROJECT_"+Guid.NewGuid().ToString("N");
        var connection=new SqlConnectionStringBuilder{DataSource=machine.SqlServer,InitialCatalog="master",IntegratedSecurity=true,Encrypt=true,TrustServerCertificate=false,HostNameInCertificate=machine.SqlHostName,Pooling=false}.ConnectionString;
        await using(var master=new SqlConnection(connection))
        {
            await master.OpenAsync();
            // Identifier is generated internally from a GUID, not from HTTP/user data.
            if(!Regex.IsMatch(database,@"\AEnglishCenter_DBMS12_PROJECT_[0-9a-f]{32}\z"))throw new InvalidOperationException("Owned name guard.");
            if(resume is null)
            {
                await File.WriteAllTextAsync(Path.Combine(owner,"creation-intent.json"),JsonSerializer.Serialize(new{database,createdByProject=ProjectLayout.Id,startedUtc=DateTime.UtcNow}));
                await using var create=new SqlCommand($"CREATE DATABASE [{database}] COLLATE Latin1_General_100_BIN2;",master){CommandTimeout=60};await create.ExecuteNonQueryAsync();
            }
            else
            {
                await using var guard=new SqlCommand($"SELECT database_guid FROM sys.database_recovery_status WHERE database_id=DB_ID(@Name) AND database_id=@Id AND NOT EXISTS(SELECT 1 FROM [{database}].sys.tables WHERE is_ms_shipped=0) AND NOT EXISTS(SELECT 1 FROM [{database}].sys.procedures WHERE is_ms_shipped=0);",master);
                guard.Parameters.AddWithValue("@Name",database);guard.Parameters.AddWithValue("@Id",resume.RootElement.GetProperty("id").GetInt32());
                if(await guard.ExecuteScalarAsync() is not Guid actual||actual!=resume.RootElement.GetProperty("guid").GetGuid())throw new InvalidOperationException("Owned empty catalog resume guard.");
            }
        }
        var appConnection=new SqlConnectionStringBuilder(connection){InitialCatalog=database}.ConnectionString;
        await using var db=new SqlConnection(appConnection);await db.OpenAsync();
        int id;Guid guid,file;
        await using(var q=new SqlCommand("SELECT DB_ID(),database_guid,(SELECT file_guid FROM sys.database_files WHERE file_id=1) FROM sys.database_recovery_status WHERE database_id=DB_ID();",db))
        {await using var r=await q.ExecuteReaderAsync();await r.ReadAsync();id=Convert.ToInt32(r.GetValue(0));guid=r.GetGuid(1);file=r.GetGuid(2);}
        await File.WriteAllTextAsync(Path.Combine(owner,"ownership.json"),JsonSerializer.Serialize(new{database,id,guid,fileGuid=file,purpose="Owner-authorized separate DBMS12 application; never replace demo"},new JsonSerializerOptions{WriteIndented=true}));
        var policy=new PasswordPolicy(OfflinePasswordBlocklist.Load(Path.Combine(AppContext.BaseDirectory,"Resources/PasswordBlocklist")));
        var hasher=new CredentialHasher(policy);var generator=new TemporaryPasswordGenerator(policy);
        var fixtureHash=hasher.Hash(generator.Generate());
        await using(var set=new SqlCommand("EXEC sys.sp_set_session_context @key=N'dbms12_sample_hash',@value=@Hash;",db)){set.Parameters.AddWithValue("@Hash",fixtureHash);await set.ExecuteNonQueryAsync();}
        using var manifest=JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(AppProfile.Package,"manifest.json")));
        foreach(var entry in manifest.RootElement.GetProperty("installOrder").EnumerateArray())
        {
            var name=entry.GetString()!;var bytes=await File.ReadAllBytesAsync(Path.Combine(AppProfile.Package,name));
            if(!Convert.ToHexString(SHA256.HashData(bytes)).Equals(manifest.RootElement.GetProperty("files").GetProperty(name).GetString(),StringComparison.OrdinalIgnoreCase))throw new InvalidOperationException("Installer hash mismatch.");
            foreach(var batch in Regex.Split(Encoding.UTF8.GetString(bytes),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
                if(!string.IsNullOrWhiteSpace(batch)){await using var install=new SqlCommand(batch,db){CommandTimeout=60};await install.ExecuteNonQueryAsync();}
        }
        await using(var clear=new SqlCommand("EXEC sys.sp_set_session_context @key=N'dbms12_sample_hash',@value=NULL;",db))await clear.ExecuteNonQueryAsync();
        var accounts=new List<(int Id,string Role,string Email,string Name)>();
        await using(var q=new SqlCommand("SELECT account_id,role_code,email,full_name FROM dbo.Account ORDER BY account_id;",db))
        {await using var r=await q.ExecuteReaderAsync();while(await r.ReadAsync())accounts.Add((r.GetInt32(0),r.GetString(1),r.GetString(2),r.GetString(3)));}
        var ledger=new List<object>();var markdown=new StringBuilder("# Tài khoản DBMS12 riêng — chỉ dùng trên máy chủ sở hữu\n\nCác tài khoản và dữ liệu là mẫu tổng hợp mới, không lấy từ demo cũ.\n\n| Vai trò | Email | Mật khẩu |\n|---|---|---|\n");
        foreach(var a in accounts)
        {
            var password=generator.Generate();var hash=hasher.Hash(password);
            await using var update=new SqlCommand("UPDATE dbo.Account SET password_hash=@Hash,security_version=security_version+1 WHERE account_id=@Id;",db);
            update.Parameters.AddWithValue("@Hash",hash);update.Parameters.AddWithValue("@Id",a.Id);await update.ExecuteNonQueryAsync();
            ledger.Add(new{accountId=a.Id,role=a.Role,email=a.Email,name=a.Name,password});markdown.AppendLine($"| {a.Role} | {a.Email} | {password} |");
        }
        var entropy=Encoding.UTF8.GetBytes("EnglishCenter.Dbms12.Project.Operator.Accounts.v1");
        await File.WriteAllBytesAsync(Path.Combine(owner,"accounts.dpapi"),ProtectedData.Protect(JsonSerializer.SerializeToUtf8Bytes(ledger),entropy,DataProtectionScope.CurrentUser));
        await File.WriteAllTextAsync(Path.Combine(owner,"tai-khoan.md"),markdown.ToString());
        var login=Environment.MachineName+"\\"+machine.RuntimeUser;
        if(!Regex.IsMatch(Environment.MachineName,@"\A[A-Za-z0-9_-]+\z"))throw new InvalidOperationException("Machine identity guard.");
        await using(var grant=new SqlCommand($"CREATE USER [Dbms12ProjectRuntime] FOR LOGIN [{login}]; ALTER ROLE dbms12_runtime ADD MEMBER [Dbms12ProjectRuntime];",db))await grant.ExecuteNonQueryAsync();
        var p=new AppProfile(database,id,guid,file,workspace,Convert.ToHexString(SHA256.HashData(await File.ReadAllBytesAsync(Path.Combine(AppProfile.Package,"manifest.json")))),machine);
        await File.WriteAllTextAsync(path,JsonSerializer.Serialize(p,new JsonSerializerOptions{WriteIndented=true}));
        Console.WriteLine(JsonSerializer.Serialize(new{phase="DBMS12-provision",success=true,database,id,guid,accounts=accounts.Count,credentials="Private owner folder only; no passwords in output"}));return 0;
    }
}
