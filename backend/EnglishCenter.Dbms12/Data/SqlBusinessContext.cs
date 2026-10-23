namespace EnglishCenter.Dbms12.Data;

// Only roles obtained from usp_CurrentSession may select one of these fixed SQL statements.
internal static class SqlBusinessContext
{
    internal static string Switch(string role)=>role switch
    {
        "Admin"=>"EXECUTE AS USER='Dbms12Admin';",
        "Admissions"=>"EXECUTE AS USER='Dbms12Admissions';",
        "AcademicAffairs"=>"EXECUTE AS USER='Dbms12AcademicAffairs';",
        "Teacher"=>"EXECUTE AS USER='Dbms12Teacher';",
        "Accountant"=>"EXECUTE AS USER='Dbms12Accountant';",
        "Director"=>"EXECUTE AS USER='Dbms12Director';",
        "Student"=>"EXECUTE AS USER='Dbms12Student';",
        _=>throw new InvalidOperationException("Unknown verified SQL role.")
    };
}
