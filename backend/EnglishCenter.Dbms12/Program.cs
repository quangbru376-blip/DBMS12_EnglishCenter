using EnglishCenter.Dbms12;

try
{
    if(args.Length==2&&args[0]=="--provision")Environment.ExitCode=await OwnerProvision.RunAsync(Path.GetFullPath(args[1]));
    else if(args.Length==2&&args[0]=="--check-profile")Environment.ExitCode=await OwnerInspect.RunAsync(args[1]);
    else if(args.Length==2&&args[0]=="--verify-security")Environment.ExitCode=await SqlSecurityVerification.RunAsync(args[1]);
    else if(args.Length==2&&args[0]=="--migrate-security")Environment.ExitCode=await OwnerSecurityMigration.RunAsync(args[1]);
    else if(args.Length==2&&args[0]=="--rehearse-security-migration")Environment.ExitCode=await OwnerSecurityMigration.RunAsync(args[1],true);
    else if(args.Length==2&&args[0]=="--refresh-security-fixture")Environment.ExitCode=await OwnerSecurityMigration.RefreshFixtureAsync(args[1]);
    else if(args.Length==3&&args[0]=="--profile"&&args[2]=="--managed-stdin")Environment.ExitCode=await Dbms12Host.Managed(AppProfile.Load(Path.GetFullPath(args[1])));
    else
    {
        Console.Error.WriteLine("DBMS12: use the dedicated local launcher. No default database or web host is started.");Environment.ExitCode=2;
    }
}
catch(Exception e)
{
    // Startup failures are secret-free; no connection strings, credentials or SQL parameters.
    Console.Error.WriteLine("DBMS12 startup refused: "+e.GetType().Name);Environment.ExitCode=1;
    if(e is Microsoft.Data.SqlClient.SqlException sql)Console.Error.WriteLine($"SQL diagnostic: number={sql.Number}; procedure={sql.Procedure}; line={sql.LineNumber}");
    if(args.FirstOrDefault() is "--verify-security" or "--rehearse-security-migration" or "--migrate-security"&&e is InvalidOperationException)Console.Error.WriteLine(e.Message);
}
