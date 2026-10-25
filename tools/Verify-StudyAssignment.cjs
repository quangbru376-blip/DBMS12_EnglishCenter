// Read-only check of the study allocation against the exact installed SQL source.
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),sql=path.join(root,'database/dbms12-compact');
const manifest=JSON.parse(fs.readFileSync(path.join(sql,'manifest.json'),'utf8'));
const plan=JSON.parse(fs.readFileSync(path.join(root,'docs/study/DATABASE_OBJECTS_4_MEMBERS.json'),'utf8'));
const types=['table','procedure','function','view','trigger','tableType','sequence'];
const names={TABLE:'table',PROCEDURE:'procedure',FUNCTION:'function',VIEW:'view',TRIGGER:'trigger',TYPE:'tableType',SEQUENCE:'sequence'};
const defined=new Map();
for(const file of manifest.installOrder){
 const content=fs.readFileSync(path.join(sql,file),'utf8');
 for(const match of content.matchAll(/^CREATE(?: OR ALTER)?\s+(TABLE|PROCEDURE|FUNCTION|VIEW|TRIGGER|TYPE|SEQUENCE)\s+dbo\.\[?(\w+)\]?/gm)){
  const kind=names[match[1]],name=match[2],key=kind+':'+name;
  assert(!defined.has(key),'Duplicate definition '+key);
  defined.set(key,{kind,name,file,line:content.slice(0,match.index).split('\n').length});
 }
}
assert.deepEqual(types.map(t=>[...defined.values()].filter(x=>x.kind===t).length),[12,61,7,9,12,3,1]);
assert.equal(defined.size,105);
const assigned=new Set(),counts=[];
assert.equal(plan.members.length,4);
for(const member of plan.members){
 assert.deepEqual(Object.keys(member.objects).sort(),[...types].sort());
 const row={member:member.id,topic:member.topic,total:0,byType:{}};
 for(const type of types){
  row.byType[type]=member.objects[type].length;row.total+=row.byType[type];
  for(const name of member.objects[type]){
   const key=type+':'+name;assert(defined.has(key),'Unknown object '+key);assert(!assigned.has(key),'Assigned twice '+key);assigned.add(key);
  }
 }
 counts.push(row);
}
assert.deepEqual(counts.map(r=>r.total),[27,26,26,26]);
assert.equal(assigned.size,defined.size);for(const name of defined.keys())assert(assigned.has(name),'Missing '+name);
assert.equal(Object.keys(manifest.operations).filter(name=>assigned.has('procedure:'+name)).length,56);
const markdown=fs.readFileSync(path.join(root,'docs/study/DATABASE_OBJECTS_4_MEMBERS.md'),'utf8');
for(const member of plan.members){
 const section=markdown.split('## '+member.id+' — ')[1]?.split('\n## ')[0];assert(section,'Missing member section '+member.id);
 for(const type of types)for(const name of member.objects[type])assert(section.includes('`'+name+'`'),member.id+' missing Markdown object '+name);
}
console.log(JSON.stringify({pass:true,total:defined.size,objectsAssignedExactlyOnce:true,scope:['12 tables','61 procedures','7 functions','9 views','12 triggers','3 table types','1 sequence'],counts,source:'manifest.installOrder'},null,2));
