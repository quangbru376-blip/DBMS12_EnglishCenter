namespace EnglishCenter.Dbms12;

internal sealed class ApiProblem(int status,string code,string message):Exception(message)
{
    internal int Status { get; }=status;
    internal string Code { get; }=code;
    internal static ApiProblem Invalid()=>new(400,"VALIDATION_ERROR","Dữ liệu nhập không hợp lệ. Vui lòng kiểm tra lại.");
    internal static ApiProblem Unauthorized()=>new(401,"AUTHENTICATION_REQUIRED","Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.");
    internal static ApiProblem Forbidden()=>new(403,"FORBIDDEN","Bạn không có quyền thực hiện thao tác này.");
}
