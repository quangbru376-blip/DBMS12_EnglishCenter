using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace EnglishCenter.Dbms12;

internal sealed record AppProfile(string Database,int DatabaseId,Guid DatabaseGuid,Guid FileGuid,string Workspace,string ManifestSha256,MachineSettings Machine)
{
    internal const string Origin="https://localhost:8446";
    internal const string Issuer="english-center-dbms12-project";
    internal const string Audience="english-center-dbms12-project-ui";
    internal static string Package=>Path.Combine(AppContext.BaseDirectory,"Resources/Dbms12");
    internal const int ProcedureCount=61;
    internal string PrivateRoot=>Path.Combine(Workspace,".local");
    internal string RuntimeRoot=>Path.Combine(PrivateRoot,"runtime");
    internal string WebRoot=>Path.Combine(PrivateRoot,"web");
    internal string Connection=>new SqlConnectionStringBuilder
    {
        DataSource=Machine.SqlServer,InitialCatalog=Database,IntegratedSecurity=true,
        Encrypt=true,TrustServerCertificate=false,HostNameInCertificate=Machine.SqlHostName,Pooling=false,
        Enlist=false,ConnectRetryCount=0,ConnectTimeout=5,ApplicationName="EnglishCenter DBMS12"
    }.ConnectionString;
    internal static AppProfile Load(string path)
    {
        var p=JsonSerializer.Deserialize<AppProfile>(File.ReadAllText(path))??throw new InvalidOperationException("Missing DBMS12 profile.");
        ProjectLayout.Validate(p.Workspace);p.Machine.Validate();
        if(!Regex.IsMatch(p.Database,@"\AEnglishCenter_DBMS12_PROJECT_[0-9a-f]{32}\z")||p.DatabaseId<=4||p.DatabaseGuid==Guid.Empty||p.FileGuid==Guid.Empty)
            throw new InvalidOperationException("Invalid isolated DBMS12 binding.");
        if(!Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(Path.Combine(Package,"manifest.json")))).Equals(p.ManifestSha256,StringComparison.Ordinal))
            throw new InvalidOperationException("DBMS12 SQL package changed.");
        return p;
    }
    internal async Task VerifyAsync(SqlConnection db,CancellationToken token)
    {
        await using var cmd=new SqlCommand("""
SELECT DB_NAME(),DB_ID(),(SELECT file_guid FROM sys.database_files WHERE file_id=1),
(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0),(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0),
USER_NAME(),IS_SRVROLEMEMBER('sysadmin'),IS_ROLEMEMBER('dbms12_runtime');
""",db){CommandTimeout=10};
        await using var r=await cmd.ExecuteReaderAsync(token);
        if(!await r.ReadAsync(token)||r.GetString(0)!=Database||Convert.ToInt32(r.GetValue(1))!=DatabaseId||r.GetGuid(2)!=FileGuid||r.GetInt32(3)!=12||r.GetInt32(4)!=ProcedureCount||r.GetString(5)!="Dbms12ProjectRuntime"||r.GetInt32(6)!=0||r.GetInt32(7)!=1)
            throw new InvalidOperationException("DBMS12 catalog/schema/runtime identity mismatch.");
    }
    internal X509Certificate2 Certificate()
    {
        if(!OperatingSystem.IsWindows())throw new PlatformNotSupportedException();
        using var identity=WindowsIdentity.GetCurrent();
        if(identity.Name!=Environment.MachineName+"\\"+Machine.RuntimeUser||new WindowsPrincipal(identity).IsInRole(WindowsBuiltInRole.Administrator))throw new InvalidOperationException("Expected non-admin runtime identity.");
        using var publicCert=X509CertificateLoader.LoadCertificateFromFile(Machine.HttpsCertificatePath);
        using var store=new X509Store(StoreName.My,StoreLocation.CurrentUser);store.Open(OpenFlags.ReadOnly);
        var matches=store.Certificates.Find(X509FindType.FindByThumbprint,publicCert.Thumbprint,false);
        if(matches.Count!=1||!matches[0].HasPrivateKey||!matches[0].MatchesHostname("localhost",false,false)||DateTime.UtcNow>=matches[0].NotAfter.ToUniversalTime())throw new InvalidOperationException("Missing trusted local HTTPS certificate.");
        return matches[0];
    }
    internal byte[] SigningKey()
    {
        if(!OperatingSystem.IsWindows())throw new PlatformNotSupportedException();
        Directory.CreateDirectory(RuntimeRoot);
        var path=Path.Combine(RuntimeRoot,"jwt.dpapi");var entropy=Encoding.UTF8.GetBytes("EnglishCenter.Dbms12.Project.Jwt.v1");
        if(!File.Exists(path))
        {
            var fresh=RandomNumberGenerator.GetBytes(32);
            try{using var f=new FileStream(path,FileMode.CreateNew,FileAccess.Write,FileShare.None);f.Write(ProtectedData.Protect(fresh,entropy,DataProtectionScope.CurrentUser));}
            finally{CryptographicOperations.ZeroMemory(fresh);}
        }
        var key=ProtectedData.Unprotect(File.ReadAllBytes(path),entropy,DataProtectionScope.CurrentUser);
        return key.Length==32?key:throw new InvalidOperationException("Invalid DBMS12 signing key.");
    }
}
