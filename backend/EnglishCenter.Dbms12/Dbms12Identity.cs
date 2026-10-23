using System.Security.Claims;
using System.Security.Cryptography;
using EnglishCenter.Dbms12.Common.Security;
using EnglishCenter.Dbms12.Common.Time;
using EnglishCenter.Dbms12.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;

namespace EnglishCenter.Dbms12;

internal sealed record CurrentIdentity(VerifiedSessionToken Token,Dictionary<string,object?> Row)
{
    internal Dictionary<string,object?> Arguments()=>new(){["@Sid"]=Token.CopySid(),["@Epoch"]=Token.SecurityVersion};
}
internal sealed class Dbms12Identity:IDisposable
{
    internal const string Cookie="__Host-ec12p-auth";
    private readonly byte[] key;
    private readonly JwtSessionIssuer issuer;
    private readonly JwtSessionValidator validator;
    private readonly Dbms12Repository repository;
    private readonly CredentialHasher hasher;
    internal LoginIpLimiter Limiter { get; }=new();
    internal Dbms12Identity(AppProfile profile,Dbms12Repository repository)
    {
        this.repository=repository;key=profile.SigningKey();
        var signing=new SymmetricSecurityKey(key){CryptoProviderFactory=new CryptoProviderFactory{CacheSignatureProviders=false}};
        issuer=new(new SigningCredentials(signing,"HS256"),AppProfile.Issuer,AppProfile.Audience);
        validator=new([signing],["HS256"],AppProfile.Issuer,AppProfile.Audience,new BusinessClock(TimeProvider.System),4096);
        hasher=new(new PasswordPolicy(OfflinePasswordBlocklist.Load(Path.Combine(AppContext.BaseDirectory,"Resources/PasswordBlocklist"))));
    }
    internal string Hash(string password)=>hasher.Hash(password);
    internal static CookieOptions CookieOptions()=>new(){HttpOnly=true,Secure=true,SameSite=SameSiteMode.Strict,Path="/",IsEssential=true};
    internal async Task<CurrentIdentity?> ResolveAsync(HttpContext context)
    {
        if(!context.Request.Cookies.TryGetValue(Cookie,out var encoded))return null;
        var token=validator.Validate(encoded);
        if(token is null){context.Response.Cookies.Delete(Cookie,CookieOptions());throw ApiProblem.Unauthorized();}
        var rows=await repository.RunAsync("usp_CurrentSession",new(){["@Sid"]=token.CopySid(),["@Epoch"]=token.SecurityVersion},context.RequestAborted);
        if(rows.Count!=1||Convert.ToInt32(rows[0]["account_id"])!=token.AccountId||(string)rows[0]["session_scope"]! !=token.Scope)
            throw ApiProblem.Unauthorized();
        var identity=new CurrentIdentity(token,rows[0]);
        context.Items[typeof(CurrentIdentity)]=identity;
        context.User=new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier,token.AccountId+":"+Base64UrlEncoder.Encode(token.CopySid()))],"Dbms12Cookie"));
        return identity;
    }
    internal static CurrentIdentity Required(HttpContext context)=>context.Items[typeof(CurrentIdentity)] as CurrentIdentity??throw ApiProblem.Unauthorized();
    internal async Task<Dictionary<string,object?>> LoginAsync(HttpContext context,string email,string password)
    {
        if(!Limiter.TryAcquire(context.Connection.RemoteIpAddress!,out _))throw new ApiProblem(429,"RATE_LIMITED","Bạn thử đăng nhập quá nhiều lần. Vui lòng chờ rồi thử lại.");
        var snapshot=await repository.RunAsync("usp_LoginRead",new(){["@Email"]=email},context.RequestAborted);
        var row=snapshot.SingleOrDefault();
        var accepted=row is not null&&hasher.Verify(row["password_hash"] as string,password)!=PasswordVerificationResult.Failed;
        // Unknown accounts still pay a real PasswordHasher cost without storing a fake account.
        if(row is null)_=hasher.Verify(hasher.Hash(Convert.ToHexString(RandomNumberGenerator.GetBytes(20))),password);
        var sid=RandomNumberGenerator.GetBytes(32);
        var epoch=row is null?0:Convert.ToInt64(row["security_version"]);
        var result=await repository.RunAsync("usp_LoginRecord",new()
        {
            ["@AccountId"]=row is null?null:row["account_id"],["@ObservedHash"]=row?["password_hash"],
            ["@ObservedEpoch"]=row is null?null:epoch,["@Accepted"]=accepted,["@Sid"]=sid
        },context.RequestAborted);
        if(!(bool)result[0]["authenticated"]!)throw new ApiProblem(401,"AUTHENTICATION_FAILED","Email hoặc mật khẩu không đúng, hoặc tài khoản chưa được phép đăng nhập.");
        var current=(await repository.RunAsync("usp_CurrentSession",new(){["@Sid"]=sid,["@Epoch"]=epoch},context.RequestAborted)).Single();
        var deadline=Utc(current["absolute_deadline"]);
        var window=(string)current["session_scope"]! =="NORMAL"?SessionIssuanceWindow.Normal(deadline.AddHours(-2)):SessionIssuanceWindow.Restricted(DateTimeOffset.UtcNow,deadline);
        var options=CookieOptions();options.Expires=window.AbsoluteExpiresAt;
        context.Response.Cookies.Append(Cookie,issuer.Issue(Convert.ToInt32(current["account_id"]),epoch,sid,window),options);
        return current;
    }
    internal async Task ChangePasswordAsync(HttpContext context,string oldPassword,string newPassword)
    {
        var current=Required(context);
        var oldHash=await repository.CurrentPasswordAsync(current.Arguments(),context.RequestAborted);
        if(hasher.Verify(oldHash,oldPassword)==PasswordVerificationResult.Failed)throw new ApiProblem(400,"PASSWORD_INCORRECT","Mật khẩu hiện tại không đúng.");
        if(oldPassword==newPassword)throw ApiProblem.Invalid();
        var args=current.Arguments();args["@ObservedHash"]=oldHash;args["@NewHash"]=Hash(newPassword);
        await repository.RunAsync("usp_PasswordChange",args,context.RequestAborted);
        context.Response.Cookies.Delete(Cookie,CookieOptions());
    }
    internal static DateTimeOffset Utc(object? value)=>new(DateTime.SpecifyKind((DateTime)value!,DateTimeKind.Utc));
    public void Dispose(){Limiter.Dispose();CryptographicOperations.ZeroMemory(key);}
}
