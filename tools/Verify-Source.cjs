const fs=require('fs'),path=require('path'),assert=require('assert/strict'),crypto=require('crypto');
const root=path.resolve(__dirname,'..'),sql=path.join(root,'database/dbms12-compact');const manifest=JSON.parse(fs.readFileSync(path.join(sql,'manifest.json'),'utf8'));let checked=0;
for(const [name,hash]of Object.entries(manifest.files)){const file=path.resolve(sql,name);assert(file.startsWith(sql+path.sep));assert.equal(crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex').toUpperCase(),hash.toUpperCase(),name);checked++;}
assert.equal(checked,62);assert.equal(Object.keys(manifest.operations).length,56);assert.equal(Object.values(manifest.operations).filter(x=>x.stored).length,56);
assert.deepEqual(manifest.schema,{tables:12,columns:99,procedures:61,functions:7,views:9,triggers:12});
const definitions=manifest.installOrder.map(f=>fs.readFileSync(path.join(sql,f),'utf8')).join('\n');
const procedures=[...definitions.matchAll(/CREATE OR ALTER PROCEDURE dbo\.(\w+)/g)].map(m=>m[1]);
assert.equal(new Set(procedures).size,61);assert.equal(procedures.length,61);
assert.equal(manifest.transactionOwnership,'SQL_PROCEDURE');
const bodies=[...definitions.matchAll(/CREATE OR ALTER PROCEDURE dbo\.(\w+)([\s\S]*?)\nGO(?=\r?\n|$)/g)];assert.equal(bodies.length,61);
for(const [,name,body] of bodies){for(const marker of ['SET XACT_ABORT ON;','DECLARE @SqlOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;','BEGIN TRY','BEGIN CATCH','IF @SqlOwnTransaction=1 BEGIN TRANSACTION;','IF @SqlOwnTransaction=1 COMMIT TRANSACTION;','IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;','THROW;'])assert(body.includes(marker),name+' missing '+marker);for(const ret of body.matchAll(/\bRETURN;/g))assert(/IF @SqlOwnTransaction=1 COMMIT TRANSACTION;\s*$/.test(body.slice(0,ret.index)),name+' early return skips COMMIT');}
for(const [name,op] of Object.entries(manifest.operations)){assert(procedures.includes(name));assert(['business','authentication','operator'].includes(op.context));for(const r of op.sqlRoles)assert(manifest.businessRoles[r]);}
assert.equal(Object.keys(manifest.businessRoles).length,7);
const csproj=fs.readFileSync(path.join(root,'backend/EnglishCenter.Dbms12/EnglishCenter.Dbms12.csproj'),'utf8');assert(!csproj.includes('ProjectReference'));for(const match of csproj.matchAll(/(?:Include|Update)="([^"]+)"/g)){const target=match[1];if(target.includes('/'))assert(path.resolve(root,'backend/EnglishCenter.Dbms12',target.split('*')[0]).startsWith(root+path.sep));}
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(x=>x.isDirectory()?walk(path.join(dir,x.name)):[path.join(dir,x.name)]);}
for(const file of walk(path.join(root,'frontend/src')).filter(x=>/\.[jt]sx?$/.test(x))){for(const match of fs.readFileSync(file,'utf8').matchAll(/from ['"](\.[^'"]+)['"]/g))assert(path.resolve(path.dirname(file),match[1]).startsWith(root+path.sep));}
const memory=fs.readdirSync(path.join(root,'memory')).filter(x=>x.endsWith('.md'));assert.equal(memory.length,9);for(const name of memory)assert(fs.readFileSync(path.join(root,'AGENTS.md'),'utf8').includes('memory/'+name));
const blocklist=path.join(root,'backend/EnglishCenter.Dbms12/Resources/PasswordBlocklist');
for(const file of JSON.parse(fs.readFileSync(path.join(blocklist,'manifest.json'),'utf8')).files){assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(blocklist,file.path))).digest('hex').toUpperCase(),file.sha256,'PasswordBlocklist/'+file.path);}
console.log(JSON.stringify({pass:true,memoryFiles:9,sqlFiles:checked,operations:56,storedProcedures:61,businessRoles:7,sqlTransactionScopes:bodies.length,replayReturnBranches:[...definitions.matchAll(/\bRETURN;/g)].length,sourceReferencesStayInsideProject:true}));
