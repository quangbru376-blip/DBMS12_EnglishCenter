using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace EnglishCenter.Dbms12;

// A narrowly scoped proof for the folder-only change from the reviewed D15 package.
internal static class SqlLayoutPackage
{
    internal const string PreviousManifest="F24FCEA4C9D7049CEC843BC57C29DB00518091C87310E36789561E9466291D7F";
    internal static string Verify()
    {
        using var baseline=JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory,"Resources/SqlLayoutBaseline.json")));
        var oldText=baseline.RootElement.GetProperty("manifestText").GetString()!;
        if(Hash(Encoding.UTF8.GetBytes(oldText))!=PreviousManifest)throw new InvalidOperationException("SQL layout baseline pin mismatch.");
        var old=JsonNode.Parse(oldText)!;
        var paths=baseline.RootElement.GetProperty("paths").EnumerateObject().ToDictionary(x=>x.Name,x=>x.Value.GetString()!,StringComparer.Ordinal);
        if(paths.Count!=62||paths.Values.Distinct(StringComparer.Ordinal).Count()!=62||!paths.Keys.Order().SequenceEqual(old["files"]!.AsObject().Select(x=>x.Key).Order()))throw new InvalidOperationException("SQL layout must map all62files exactly once.");
        JsonNode? Remap(JsonNode? node)
        {
            if(node is JsonObject obj)
            {
                var result=new JsonObject();foreach(var (key,value) in obj)result.Add(paths.GetValueOrDefault(key,key),Remap(value));return result;
            }
            if(node is JsonArray array)return new JsonArray(array.Select(Remap).ToArray());
            if(node is JsonValue scalar&&scalar.TryGetValue<string>(out var text)&&text is not null)return JsonValue.Create(paths.GetValueOrDefault(text,text));
            return node?.DeepClone();
        }
        var oldInstall=baseline.RootElement.GetProperty("installSql").GetString()!;
        if(!Hash(Encoding.UTF8.GetBytes(oldInstall)).Equals(old["files"]!["Install.sql"]!.GetValue<string>(),StringComparison.OrdinalIgnoreCase))throw new InvalidOperationException("Old installer hash mismatch.");
        var install=oldInstall;
        foreach(var (from,to) in paths)install=install.Replace(":r .\\"+from.Replace('/','\\'),":r .\\"+to.Replace('/','\\'),StringComparison.Ordinal);
        if(File.ReadAllText(Path.Combine(AppProfile.Package,"Install.sql"))!=install)throw new InvalidOperationException("Installer changed beyond include paths.");
        var expected=Remap(old)!;expected["files"]!["Install.sql"]=Hash(Encoding.UTF8.GetBytes(install));
        var manifestFile=Path.Combine(AppProfile.Package,"manifest.json");var current=JsonNode.Parse(File.ReadAllText(manifestFile))!;
        foreach(var node in new[]{expected,current})foreach(var (key,value) in node["files"]!.AsObject().ToArray())node["files"]![key]=value!.GetValue<string>().ToUpperInvariant();
        if(!JsonNode.DeepEquals(expected,current))throw new InvalidOperationException("SQL layout changed install order, operations or SQL content.");
        _=new Data.CompactSqlExecutor(AppProfile.Package); // Verifies every actual file and the path boundary.
        return Hash(File.ReadAllBytes(manifestFile));
    }
    private static string Hash(byte[] bytes)=>Convert.ToHexString(SHA256.HashData(bytes));
}
