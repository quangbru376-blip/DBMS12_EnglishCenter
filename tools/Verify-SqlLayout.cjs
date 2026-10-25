// Proves this reorganization changes paths, not executable SQL or operation contracts.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),folder=path.join(root,'database/dbms12-compact');
const expectedOld='F24FCEA4C9D7049CEC843BC57C29DB00518091C87310E36789561E9466291D7F';
const sha=text=>crypto.createHash('sha256').update(text).digest('hex').toUpperCase();
function verify(){
 const baseline=JSON.parse(fs.readFileSync(path.join(root,'backend/EnglishCenter.Dbms12/Resources/SqlLayoutBaseline.json'),'utf8'));
 assert.equal(sha(baseline.manifestText),expectedOld);assert.equal(baseline.manifestSha256,expectedOld);
 const old=JSON.parse(baseline.manifestText),{paths}=baseline;
 assert.deepEqual(Object.keys(paths).sort(),Object.keys(old.files).sort());assert.equal(new Set(Object.values(paths)).size,62);
 function mapped(value){if(typeof value==='string')return paths[value]??value;if(Array.isArray(value))return value.map(mapped);if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[paths[k]??k,mapped(v)]));return value;}
 let install=baseline.installSql;assert.equal(sha(install),old.files['Install.sql'].toUpperCase());
 for(const [from,to]of Object.entries(paths))install=install.replaceAll(':r .\\'+from.replaceAll('/','\\'),':r .\\'+to.replaceAll('/','\\'));
 assert.equal(fs.readFileSync(path.join(folder,'Install.sql'),'utf8'),install);
 const expected=mapped(old);expected.files['Install.sql']=sha(install).toLowerCase();
 const current=JSON.parse(fs.readFileSync(path.join(folder,'manifest.json'),'utf8'));
 // Existing manifest hashes use lower-case; compare hashes without changing their meaning.
 for(const f of Object.keys(expected.files))expected.files[f]=expected.files[f].toUpperCase();
 const normalized=structuredClone(current);for(const f of Object.keys(normalized.files))normalized.files[f]=normalized.files[f].toUpperCase();
 assert.deepEqual(normalized,expected,'Manifest may only rename paths and repin Install include paths.');
 for(const [from,to]of Object.entries(paths)){
  const full=path.resolve(folder,to);assert(full.startsWith(folder+path.sep));assert.equal(sha(fs.readFileSync(full)),current.files[to].toUpperCase(),to);
  if(from!=='Install.sql')assert.equal(current.files[to].toUpperCase(),old.files[from].toUpperCase(),'SQL body changed: '+to);
  if(from!==to)assert(!fs.existsSync(path.join(folder,from)),'Duplicate old source '+from);
 }
 return {pass:true,pinnedSqlFiles:62,byteIdenticalSqlFiles:61,installOnlyIncludePathsChanged:true,installOrderAndContractsPreserved:true};
}
if(require.main===module)console.log(JSON.stringify(verify()));
module.exports={verify};
