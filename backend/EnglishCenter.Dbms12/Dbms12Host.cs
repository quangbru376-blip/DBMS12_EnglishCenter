using System.Net;
using System.Security.Cryptography;
using System.Text.Json;
using EnglishCenter.Dbms12.Common.Errors;
using EnglishCenter.Dbms12.Data;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.FileProviders;

namespace EnglishCenter.Dbms12;

internal sealed record Dbms12RoutePolicy(bool Anonymous=false,bool Restricted=false,bool AnonymousOnly=false);
internal static class Dbms12Host
{
    internal static async Task<int> RunAsync(AppProfile profile,CancellationToken token)
    {
        if(!OperatingSystem.IsWindows())return 1;
        using var certificate=profile.Certificate();
        var repository=new Dbms12Repository(profile);
        await using(var db=new SqlConnection(profile.Connection)){await db.OpenAsync(token);await profile.VerifyAsync(db,token);}
        using var identity=new Dbms12Identity(profile,repository);
        var builder=WebApplication.CreateBuilder(new WebApplicationOptions{ContentRootPath=AppContext.BaseDirectory,EnvironmentName=Environments.Production});
        builder.Logging.ClearProviders();
        builder.WebHost.ConfigureKestrel(k=>{k.Limits.MaxRequestBodySize=262144;k.Listen(IPAddress.Loopback,8446,l=>l.UseHttps(certificate));});
        builder.Services.AddDataProtection().SetApplicationName("EnglishCenter.Dbms12.Standalone")
            .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(profile.RuntimeRoot,"csrf"))).ProtectKeysWithDpapi();
        builder.Services.AddAntiforgery(o=>
        {
            o.HeaderName="X-CSRF-TOKEN";o.Cookie.Name="__Host-ec12p-csrf";o.Cookie.HttpOnly=true;
            o.Cookie.SecurePolicy=CookieSecurePolicy.Always;o.Cookie.SameSite=SameSiteMode.Strict;o.Cookie.Path="/";
        });
        await using var app=builder.Build();
        app.Use(async(c,next)=>
        {
            c.Response.Headers.CacheControl="no-store";c.Response.Headers["X-Content-Type-Options"]="nosniff";
            c.Response.Headers["Content-Security-Policy"]="default-src 'self';script-src 'self';style-src 'self' 'unsafe-inline';font-src 'self';img-src 'self' data:;object-src 'none';base-uri 'none';frame-ancestors 'none'";
            try
            {
                if(!c.Request.IsHttps||c.Request.Host.Value!="localhost:8446"||c.Connection.RemoteIpAddress is not { } address||!IPAddress.IsLoopback(address))throw new ApiProblem(400,"INVALID_ORIGIN","Địa chỉ truy cập không hợp lệ.");
                await next(c);
            }
            catch(Exception e) when(!c.Response.HasStarted)
            {
                if(e is SqlException diagnostic)Console.Error.WriteLine(JsonSerializer.Serialize(new{sqlNumber=diagnostic.Number,procedure=diagnostic.Procedure,line=diagnostic.LineNumber}));
                var problem=e switch
                {
                    ApiProblem p=>p,
                    BadHttpRequestException p=>new ApiProblem(p.StatusCode,"INVALID_REQUEST","Yêu cầu không hợp lệ hoặc vượt kích thước cho phép."),
                    SqlException {Number:51201}=>ApiProblem.Unauthorized(),
                    SqlException {Number:51202 or 51203 or 229}=>ApiProblem.Forbidden(),
                    SqlException {Number:2601 or 2627 or 51205 or 51209 or 51212 or 51214 or 51218 or 51225 or 51226 or 51227 or 1205}=>new ApiProblem(409,"CONFLICT","Dữ liệu đã thay đổi hoặc thao tác không còn phù hợp. Hãy tải lại trước khi thực hiện tiếp."),
                    SqlException s when s.Number is >=51000 and <=51999=>new ApiProblem(400,"BUSINESS_RULE","Thao tác chưa đáp ứng điều kiện nghiệp vụ. Vui lòng kiểm tra trạng thái và dữ liệu nhập."),
                    SqlException {Number:547 or 515 or 8115 or 2628}=>ApiProblem.Invalid(),
                    ApiErrorException or JsonException or FormatException or OverflowException or ArgumentException or KeyNotFoundException=>ApiProblem.Invalid(),
                    OperationCanceledException when c.RequestAborted.IsCancellationRequested=>new ApiProblem(499,"REQUEST_CANCELLED","Yêu cầu đã dừng."),
                    _=>new ApiProblem(503,"SERVICE_UNAVAILABLE","Chưa thể xử lý yêu cầu. Không tự gửi lại thao tác; hãy kiểm tra kết quả trước.")
                };
                if(problem.Status==401)c.Response.Cookies.Delete(Dbms12Identity.Cookie,Dbms12Identity.CookieOptions());
                c.Response.StatusCode=problem.Status;
                await c.Response.WriteAsJsonAsync(new{code=problem.Code,message=problem.Message,traceId=c.TraceIdentifier},CancellationToken.None);
            }
        });
        if(!File.Exists(Path.Combine(profile.WebRoot,"index.html")))throw new InvalidOperationException("Missing DBMS12 web build.");
        using var files=new PhysicalFileProvider(profile.WebRoot);
        app.UseStaticFiles(new StaticFileOptions{FileProvider=files});
        app.UseRouting();
        app.Use(async(c,next)=>
        {
            if(c.Request.Path.StartsWithSegments("/api/dbms12"))
            {
                var policy=c.GetEndpoint()?.Metadata.GetMetadata<Dbms12RoutePolicy>()??throw ApiProblem.Forbidden();
                var current=await identity.ResolveAsync(c);
                if(!policy.Anonymous&&current is null)throw ApiProblem.Unauthorized();
                if(policy.AnonymousOnly&&current is not null)throw ApiProblem.Forbidden();
                if(!policy.Restricted&&current?.Token.Scope=="PASSWORD_CHANGE")throw ApiProblem.Forbidden();
                var unsafeMethod=!HttpMethods.IsGet(c.Request.Method)&&!HttpMethods.IsHead(c.Request.Method);
                if(unsafeMethod)
                {
                    if(c.Request.Headers.Origin.Count!=1||c.Request.Headers.Origin[0]!=AppProfile.Origin||c.Request.Headers["X-CSRF-TOKEN"].Count!=1)throw new ApiProblem(403,"CSRF_INVALID","Không xác minh được yêu cầu. Hãy tải lại trang.");
                    try{await c.RequestServices.GetRequiredService<IAntiforgery>().ValidateRequestAsync(c);}
                    catch(AntiforgeryValidationException){throw new ApiProblem(403,"CSRF_INVALID","Không xác minh được yêu cầu. Hãy tải lại trang.");}
                }
            }
            await next(c);
        });
        app.MapGet("/health/ready",async()=>
        {
            try{await using var db=new SqlConnection(profile.Connection);await db.OpenAsync();await profile.VerifyAsync(db,CancellationToken.None);return Results.Text("ready");}
            catch{return Results.StatusCode(503);}
        });
        app.MapGet("/api/dbms12/auth/csrf",(HttpContext c,IAntiforgery csrf)=>Results.Json(new{requestToken=csrf.GetAndStoreTokens(c).RequestToken})).WithMetadata(new Dbms12RoutePolicy(true,true));
        app.MapGet("/api/dbms12/auth/me",(HttpContext c)=>Results.Json(new{rows=Dbms12Routes.Normalize([Dbms12Identity.Required(c).Row])})).WithMetadata(new Dbms12RoutePolicy(false,true));
        app.MapPost("/api/dbms12/auth/login",async(HttpContext c)=>
        {
            var b=await RequestFields.Body(c);RequestFields.Only(b,"email","password");
            var result=await identity.LoginAsync(c,RequestFields.Email(b),RequestFields.String(b,"password",256));
            return Results.Json(new{rows=Dbms12Routes.Normalize([result])});
        }).WithMetadata(new Dbms12RoutePolicy(true,false,true));
        app.MapPost("/api/dbms12/auth/signup",async(HttpContext c)=>
        {
            var b=await RequestFields.Body(c);RequestFields.Only(b,"email","password","name","phone","birthDate","address");
            var args=new Dictionary<string,object?>
            {
                ["@Email"]=RequestFields.Email(b),["@Name"]=RequestFields.String(b,"name",200),["@Phone"]=RequestFields.String(b,"phone",10),
                ["@BirthDate"]=RequestFields.ConvertValue(b.GetProperty("birthDate"),"date"),
                ["@Address"]=b.TryGetProperty("address",out var a)&&a.ValueKind!=JsonValueKind.Null?RequestFields.String(b,"address",255,true):null,
                ["@PasswordHash"]=identity.Hash(RequestFields.String(b,"password",256))
            };
            await repository.RunAsync("usp_StudentSignup",args,c.RequestAborted);return Results.Json(new{created=true},statusCode:201);
        }).WithMetadata(new Dbms12RoutePolicy(true,false,true));
        app.MapPost("/api/dbms12/auth/logout",async(HttpContext c)=>
        {
            var b=await RequestFields.Body(c);RequestFields.Only(b);
            await repository.RunAsync("usp_Logout",Dbms12Identity.Required(c).Arguments(),c.RequestAborted);
            c.Response.Cookies.Delete(Dbms12Identity.Cookie,Dbms12Identity.CookieOptions());return Results.NoContent();
        }).WithMetadata(new Dbms12RoutePolicy(false,true));
        app.MapPost("/api/dbms12/auth/password",async(HttpContext c)=>
        {
            var b=await RequestFields.Body(c);RequestFields.Only(b,"oldPassword","newPassword");
            await identity.ChangePasswordAsync(c,RequestFields.String(b,"oldPassword",256),RequestFields.String(b,"newPassword",256));return Results.NoContent();
        }).WithMetadata(new Dbms12RoutePolicy(false,true));
        Dbms12Routes.Map(app,repository,identity);
        // Every business route is explicitly authenticated and requires NORMAL scope.
        foreach(var endpoint in ((IEndpointRouteBuilder)app).DataSources.SelectMany(s=>s.Endpoints))
            if(endpoint is RouteEndpoint route&&route.RoutePattern.RawText?.StartsWith("/api/dbms12/",StringComparison.Ordinal)==true&&endpoint.Metadata.GetMetadata<Dbms12RoutePolicy>() is null)
                throw new InvalidOperationException("Unprotected DBMS12 endpoint.");
        app.MapFallback(async c=>
        {
            if(c.Request.Path.StartsWithSegments("/api")){c.Response.StatusCode=404;return;}
            if(!c.Request.Path.StartsWithSegments("/dbms12")){c.Response.Redirect("/dbms12");return;}
            c.Response.ContentType="text/html; charset=utf-8";await c.Response.SendFileAsync(Path.Combine(profile.WebRoot,"index.html"),c.RequestAborted);
        });
        await app.RunAsync(token);return 0;
    }
    internal static async Task<int> Managed(AppProfile p)
    {
        using var stop=new CancellationTokenSource();
        var monitor=Task.Run(async()=>{try{await Console.In.ReadLineAsync(stop.Token);stop.Cancel();}catch(OperationCanceledException)when(stop.IsCancellationRequested){}},CancellationToken.None);
        try{return await RunAsync(p,stop.Token);}
        catch(OperationCanceledException)when(stop.IsCancellationRequested){return 0;}
        finally{stop.Cancel();await monitor;}
    }
}
