using System.Text.Json;
using System.Text.RegularExpressions;

namespace EnglishCenter.Dbms12;
internal static class ProjectLayout
{
 internal const string Id="cd991085-f47e-4f5e-915d-69c9a15156a8";
 internal static void Validate(string root)
 {
  if(!Path.IsPathFullyQualified(root)||Path.GetFullPath(root)!=root)throw new InvalidOperationException("Expected absolute project root.");
  using var marker=JsonDocument.Parse(File.ReadAllText(Path.Combine(root,".dbms12-project.json")));
  if(marker.RootElement.GetProperty("projectId").GetString()!=Id)throw new InvalidOperationException("Standalone project marker mismatch.");
 }
}
internal sealed record MachineSettings(string SqlServer,string SqlHostName,string RuntimeUser,string RuntimeCredentialPath,string HttpsCertificatePath)
{
 internal static MachineSettings Load(string root)
 {
  ProjectLayout.Validate(root);
  var m=JsonSerializer.Deserialize<MachineSettings>(File.ReadAllText(Path.Combine(root,"config/machine.json")),new JsonSerializerOptions{PropertyNameCaseInsensitive=true})??throw new InvalidOperationException("Missing machine settings.");
  m.Validate();return m;
 }
 internal void Validate()
 {
  if(!Regex.IsMatch(SqlServer,@"\Alpc:(?:\.|localhost)\\[A-Za-z0-9_]+\z",RegexOptions.IgnoreCase)||SqlHostName!="localhost"||!Regex.IsMatch(RuntimeUser,@"\A[A-Za-z][A-Za-z0-9_]{0,19}\z")||!Path.IsPathFullyQualified(RuntimeCredentialPath)||!Path.IsPathFullyQualified(HttpsCertificatePath))throw new InvalidOperationException("Local Windows/SQL machine settings guard.");
 }
}
