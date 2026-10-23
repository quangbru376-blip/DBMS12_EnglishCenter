using System.Data;
using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace EnglishCenter.Dbms12;

internal static class RequestFields
{
    internal static async Task<JsonElement> Body(HttpContext context)
    {
        if(!context.Request.HasJsonContentType())throw ApiProblem.Invalid();
        using var doc=await JsonDocument.ParseAsync(context.Request.Body,new JsonDocumentOptions{MaxDepth=12},context.RequestAborted);
        if(doc.RootElement.ValueKind!=JsonValueKind.Object)throw ApiProblem.Invalid();
        var names=doc.RootElement.EnumerateObject().Select(p=>p.Name).ToArray();
        if(names.Distinct(StringComparer.Ordinal).Count()!=names.Length)throw ApiProblem.Invalid();
        return doc.RootElement.Clone();
    }
    internal static void Only(JsonElement body,params string[] names)
    { var properties=body.EnumerateObject().ToArray();if(properties.Any(p=>!names.Contains(p.Name,StringComparer.Ordinal))||properties.Select(p=>p.Name).Distinct(StringComparer.Ordinal).Count()!=properties.Length)throw ApiProblem.Invalid(); }
    internal static string String(JsonElement body,string name,int max=1000,bool empty=false)
    {
        if(!body.TryGetProperty(name,out var p)||p.ValueKind!=JsonValueKind.String)throw ApiProblem.Invalid();
        var s=p.GetString()!;if(s.Length>max||(!empty&&string.IsNullOrWhiteSpace(s)))throw ApiProblem.Invalid();return s;
    }
    internal static string PublicName(string parameter)=>char.ToLowerInvariant(parameter[1])+parameter[2..];
    internal static string Email(JsonElement body)
    {
        var s=String(body,"email",254);
        if(s.Any(c=>c>127)||!System.Net.Mail.MailAddress.TryCreate(s,out var address)||address.Address!=s)throw ApiProblem.Invalid();
        return s;
    }
    internal static object? ConvertValue(JsonElement value,string type)
    {
        if(value.ValueKind==JsonValueKind.Null)return null;
        if(type.StartsWith("dbo.",StringComparison.Ordinal))return Table(value,type);
        if(type.StartsWith("varchar",StringComparison.Ordinal)||type.StartsWith("nvarchar",StringComparison.Ordinal))
        {
            if(value.ValueKind!=JsonValueKind.String)throw ApiProblem.Invalid();
            var text=value.GetString()!;var max=int.Parse(Regex.Match(type,@"\((\d+)\)").Groups[1].Value,CultureInfo.InvariantCulture);
            if(text.Length>max)throw ApiProblem.Invalid();
            if(type.StartsWith("varchar",StringComparison.Ordinal)&&text.Any(c=>c>127))throw ApiProblem.Invalid();
            return text;
        }
        if(type.StartsWith("binary",StringComparison.Ordinal))
        {
            if(value.ValueKind!=JsonValueKind.String)throw ApiProblem.Invalid();
            var bytes=System.Convert.FromBase64String(value.GetString()!);if(bytes.Length!=8)throw ApiProblem.Invalid();return bytes;
        }
        if(type=="int"||type=="tinyint")
        {
            if(value.ValueKind!=JsonValueKind.Number||!value.TryGetInt32(out var n)||(type=="tinyint"&&(n<0||n>255)))throw ApiProblem.Invalid();return n;
        }
        if(value.ValueKind!=JsonValueKind.String)throw ApiProblem.Invalid();
        if(type=="date")return DateTime.ParseExact(value.GetString()!,"yyyy-MM-dd",CultureInfo.InvariantCulture);
        if(type.StartsWith("datetime2",StringComparison.Ordinal))
        {
            var text=value.GetString()!;
            if(!Regex.IsMatch(text,@"(?:Z|[+-]\d{2}:\d{2})$"))throw ApiProblem.Invalid();
            return DateTimeOffset.Parse(text,CultureInfo.InvariantCulture,DateTimeStyles.RoundtripKind).UtcDateTime;
        }
        if(type.StartsWith("time",StringComparison.Ordinal))return TimeSpan.ParseExact(value.GetString()!,["hh\\:mm","hh\\:mm\\:ss"],CultureInfo.InvariantCulture);
        throw ApiProblem.Invalid();
    }
    private static DataTable Table(JsonElement value,string type)
    {
        if(value.ValueKind!=JsonValueKind.Array||value.GetArrayLength()>400)throw ApiProblem.Invalid();
        var table=new DataTable(type);
        (string Name,Type Type,string Api)[] cols=type switch
        {
            "dbo.ScheduleBatch"=>[("item_no",typeof(int),"itemNo"),("schedule_type",typeof(string),"scheduleType"),("start_at",typeof(DateTime),"start"),("end_at",typeof(DateTime),"end"),("room",typeof(string),"room")],
            "dbo.AttendanceBatch"=>[("class_assignment_id",typeof(int),"assignmentId"),("present",typeof(bool),"present"),("expected_version",typeof(byte[]),"expectedVersion")],
            "dbo.GradeManifest"=>[("report_id",typeof(int),"reportId"),("expected_version",typeof(byte[]),"expectedVersion")],
            _=>throw ApiProblem.Invalid()
        };
        foreach(var c in cols)table.Columns.Add(c.Name,c.Type);
        foreach(var row in value.EnumerateArray())
        {
            if(row.ValueKind!=JsonValueKind.Object)throw ApiProblem.Invalid();Only(row,cols.Select(c=>c.Api).ToArray());
            var values=new object[cols.Length];
            for(var i=0;i<cols.Length;i++)
            {
                if(!row.TryGetProperty(cols[i].Api,out var p))throw ApiProblem.Invalid();
                if(p.ValueKind==JsonValueKind.Null&&(cols[i].Api!="expectedVersion"||type=="dbo.GradeManifest"))throw ApiProblem.Invalid();
                values[i]=p.ValueKind==JsonValueKind.Null?DBNull.Value:cols[i].Type==typeof(int)?ConvertValue(p,"int")!:cols[i].Type==typeof(bool)?p.ValueKind is JsonValueKind.True or JsonValueKind.False?p.GetBoolean():throw ApiProblem.Invalid():
                    cols[i].Type==typeof(byte[])?ConvertValue(p,"binary(8)")!:cols[i].Type==typeof(DateTime)?ConvertValue(p,"datetime2(3)")!:ConvertValue(p,cols[i].Api=="scheduleType"?"varchar(16)":"nvarchar(50)")!;
            }
            table.Rows.Add(values);
        }
        return table;
    }
}
