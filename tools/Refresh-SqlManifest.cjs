// Explicit developer action after reviewing a SQL change; never run automatically by the launcher.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const folder=path.resolve(__dirname,'../database/dbms12-compact'),file=path.join(folder,'manifest.json');
const manifest=JSON.parse(fs.readFileSync(file,'utf8'));
for(const name of Object.keys(manifest.files)){
 const target=path.resolve(folder,name);
 if(!target.startsWith(folder+path.sep))throw new Error('SQL path guard');
 manifest.files[name]=crypto.createHash('sha256').update(fs.readFileSync(target)).digest('hex');
}
fs.writeFileSync(file,JSON.stringify(manifest,null,2)+'\n');
console.log('SQL manifest refreshed; review and database migration are separate required steps.');
