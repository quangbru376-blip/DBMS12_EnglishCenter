using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using EnglishCenter.Dbms12.Data;

namespace EnglishCenter.Dbms12;

internal sealed record OperationRoute(string Path,string Operation,bool Write);
internal static class Dbms12Routes
{
    internal static readonly OperationRoute[] Operations=
    [
        new("courses","usp_CourseList",false),new("courses/create","usp_CourseCreate",true),new("courses/update","usp_CourseUpdate",true),
        new("registrations","usp_RegistrationList",false),new("registrations/create","usp_RegistrationCreate",true),new("registrations/confirm","usp_RegistrationConfirm",true),new("registrations/cancel-own","usp_RegistrationCancelOwn",true),
        new("admissions/approve","usp_AdmissionApprove",true),new("admissions/reject","usp_AdmissionReject",true),new("admissions/cancel","usp_AdmissionCancel",true),
        new("invoices/detail","usp_InvoiceRead",false),new("invoices","usp_InvoiceSearch",false),new("invoices/collect","usp_InvoiceCollect",true),new("invoices/correct","usp_InvoiceCorrect",true),
        new("classes","usp_ClassList",false),new("classes/roster","usp_ClassRoster",false),new("classes/create","usp_ClassCreate",true),new("classes/edit","usp_ClassEdit",true),
        new("classes/open","usp_ClassOpen",true),new("classes/start","usp_ClassStart",true),new("classes/complete","usp_ClassComplete",true),new("classes/cancel","usp_ClassCancel",true),new("placements","usp_PlacementCreate",true),
        new("schedules","usp_ScheduleList",false),new("schedules/preview","usp_WeeklySchedulePreview",false),new("schedules/batch","usp_ScheduleBatch",true),new("schedules/move","usp_ScheduleMove",true),new("schedules/held","usp_ScheduleHeld",true),
        new("attendance","usp_AttendanceRead",false),new("attendance/save","usp_AttendanceSave",true),new("grades/save","usp_GradeSave",true),
        new("grades/submit","usp_GradeSubmit",true),new("grades/return","usp_GradeReturn",true),new("grades/finalize","usp_GradeFinalize",true),new("grades/own","usp_StudentGrades",false),
        new("teachers","usp_TeacherOptions",false),new("profile/update","usp_ProfileUpdate",true),new("home","usp_StudentHome",false),
        new("accounts","usp_AdminAccountList",false),new("accounts/create","usp_AccountCreateStaff",true),new("accounts/status","usp_AccountSetStatus",true),new("accounts/reset-password","usp_AccountResetPassword",true),
        new("audit","usp_AuditList",false),new("reports/finance","usp_FinanceReport",false),new("reports/director","usp_DirectorReport",false),new("operations","usp_ReplayLookup",false)
    ];
    private static readonly HashSet<string> PrivateParameters=new(["@Sid","@Epoch","@RequestId","@Digest","@PasswordHash"],StringComparer.Ordinal);
    internal static void Map(WebApplication app,Dbms12Repository repo,Dbms12Identity identity)
    {
        foreach(var route in Operations)
        {
            if(route.Write)app.MapPost("/api/dbms12/"+route.Path,(Func<HttpContext,Task<IResult>>)(c=>Write(c,repo,identity,route))).WithMetadata(new Dbms12RoutePolicy());
            else app.MapGet("/api/dbms12/"+route.Path,(Func<HttpContext,Task<IResult>>)(c=>Read(c,repo,route))).WithMetadata(new Dbms12RoutePolicy());
        }
        app.MapGet("/api/dbms12/reports/finance.csv",async(HttpContext c)=>
        {
            var rows=await ReadRows(c,repo,"usp_FinanceExport");
            var facts=rows.Where(r=>r.ContainsKey("invoice_id")).ToArray();
            var columns=facts.FirstOrDefault()?.Keys.ToArray()??["invoice_id","invoice_number","amount"];
            static string Cell(object? value)
            {
                var s=Convert.ToString(value,CultureInfo.InvariantCulture)??"";
                if(s.TrimStart().StartsWith('=')||s.TrimStart().StartsWith('+')||s.TrimStart().StartsWith('-')||s.TrimStart().StartsWith('@')||s.StartsWith('\t')||s.StartsWith('\r'))s="'"+s;
                return "\""+s.Replace("\"","\"\"",StringComparison.Ordinal)+"\"";
            }
            var csv=string.Join(',',columns.Select(Cell))+"\r\n"+string.Join("\r\n",facts.Select(r=>string.Join(',',columns.Select(k=>Cell(r.GetValueOrDefault(k))))));
            return Results.File(Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv)).ToArray(),"text/csv; charset=utf-8","bao-cao-hoc-phi.csv");
        }).WithMetadata(new Dbms12RoutePolicy());
    }
    private static IEnumerable<JsonElement> PublicParameters(JsonElement op)=>op.GetProperty("parameters").EnumerateArray().Where(p=>!PrivateParameters.Contains(p.GetProperty("name").GetString()!));
    private static async Task<IResult> Write(HttpContext c,Dbms12Repository repo,Dbms12Identity identity,OperationRoute route)
    {
        var current=Dbms12Identity.Required(c);var op=repo.Operation(route.Operation);
        if(route.Operation=="usp_ProfileUpdate"&&(string)current.Row["role_code"]! !="Student")throw ApiProblem.Forbidden();
        var body=await RequestFields.Body(c);var parameters=PublicParameters(op).ToArray();
        RequestFields.Only(body,parameters.Select(p=>RequestFields.PublicName(p.GetProperty("name").GetString()!)).ToArray());
        if(!Guid.TryParseExact(c.Request.Headers["Idempotency-Key"],"D",out var requestId)||requestId==Guid.Empty)throw ApiProblem.Invalid();
        var args=current.Arguments();
        foreach(var p in parameters)
        {
            var name=p.GetProperty("name").GetString()!;var field=RequestFields.PublicName(name);
            if(body.TryGetProperty(field,out var value))args[name]=RequestFields.ConvertValue(value,p.GetProperty("type").GetString()!);
            else if(p.GetProperty("default").ValueKind==JsonValueKind.Null)throw ApiProblem.Invalid();
        }
        if(route.Operation=="usp_AccountCreateStaff")args["@Email"]=RequestFields.Email(body);
        string? temporary=null;
        if(route.Operation is "usp_AccountCreateStaff" or "usp_AccountResetPassword")
        {
            temporary=Convert.ToBase64String(RandomNumberGenerator.GetBytes(24));args["@PasswordHash"]=identity.Hash(temporary);
        }
        var canonical=JsonSerializer.Serialize(body.EnumerateObject().OrderBy(p=>p.Name,StringComparer.Ordinal).ToDictionary(p=>p.Name,p=>p.Value));
        args["@RequestId"]=requestId;args["@Digest"]=SHA256.HashData(Encoding.UTF8.GetBytes(route.Operation+"\n"+canonical));
        var result=await repo.RunAsync(route.Operation,args,c.RequestAborted);
        var replayed=result.Count>0&&result[0].TryGetValue("replayed",out var replay)&&replay is true;
        return Results.Json(new{rows=Normalize(result),temporaryPassword=replayed?null:temporary});
    }
    private static async Task<IResult> Read(HttpContext c,Dbms12Repository repo,OperationRoute route)=>Results.Json(new{rows=Normalize(await ReadRows(c,repo,route.Operation))});
    private static async Task<List<Dictionary<string,object?>>> ReadRows(HttpContext c,Dbms12Repository repo,string operation)
    {
        var args=Dbms12Identity.Required(c).Arguments();var op=repo.Operation(operation);
        var pars=PublicParameters(op).ToArray();var allowed=pars.Select(p=>RequestFields.PublicName(p.GetProperty("name").GetString()!)).ToHashSet(StringComparer.Ordinal);
        if(operation=="usp_ReplayLookup")allowed.Add("requestId");
        if(c.Request.Query.Any(p=>!allowed.Contains(p.Key)||p.Value.Count!=1))throw ApiProblem.Invalid();
        foreach(var p in pars)
        {
            var name=p.GetProperty("name").GetString()!;var field=RequestFields.PublicName(name);var type=p.GetProperty("type").GetString()!;
            if(c.Request.Query.TryGetValue(field,out var text))
            {
                var json=type=="int"||type=="tinyint"?JsonSerializer.SerializeToElement(int.Parse(text.ToString(),CultureInfo.InvariantCulture)):JsonSerializer.SerializeToElement(text.ToString());
                args[name]=RequestFields.ConvertValue(json,type);
            }
            else if(p.GetProperty("default").ValueKind==JsonValueKind.Null)throw ApiProblem.Invalid();
        }
        if(operation=="usp_ReplayLookup")
        {
            if(!Guid.TryParseExact(c.Request.Query["requestId"],"D",out var id))throw ApiProblem.Invalid();args["@RequestId"]=id;
        }
        return await repo.RunAsync(operation,args,c.RequestAborted);
    }
    internal static List<Dictionary<string,object?>> Normalize(List<Dictionary<string,object?>> rows)=>rows.Select(r=>r.ToDictionary(p=>p.Key,p=>p.Value switch
    {
        long n=>(object)n.ToString(CultureInfo.InvariantCulture),
        DateTime d=>p.Key is "date_of_birth" or "due_date"?d.ToString("yyyy-MM-dd",CultureInfo.InvariantCulture):DateTime.SpecifyKind(d,DateTimeKind.Utc).ToString("O",CultureInfo.InvariantCulture),
        _=>p.Value
    })).ToList();
}
