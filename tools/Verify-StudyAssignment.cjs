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
const assigned=new Set(),counts=[],transactionOwners=new Map(),primaryDemos=new Set();
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
 const study=member.transactionStudy;assert(study,'Missing transaction study '+member.id);
 const owned=member.objects.procedure;
 for(const [field,expected]of [
  ['commandProcedures',owned.filter(n=>manifest.operations[n]?.kind==='command')],
  ['authProcedures',owned.filter(n=>manifest.operations[n]?.kind==='auth')],
  ['infrastructureProcedures',owned.filter(n=>!manifest.operations[n])]
 ]){
  assert.deepEqual([...study[field]].sort(),expected.sort(),member.id+' wrong '+field);
 }
 for(const name of study.commandProcedures){
  assert(!transactionOwners.has(name),'Transaction assigned twice '+name);transactionOwners.set(name,member.id);
 }
 assert.equal(study.primaryDemos.length,2,member.id+' needs two primary transaction demos');
 for(const name of study.primaryDemos){
  assert(study.commandProcedures.includes(name),'Primary demo not an owned command '+name);
  assert(!primaryDemos.has(name),'Primary demo assigned twice '+name);primaryDemos.add(name);
  assert(fs.existsSync(path.join(root,'database/practice/stored-procedures',name+'.sql')),'Missing primary practice '+name);
 }
 row.commandTransactions=study.commandProcedures.length;row.primaryTransactionDemos=study.primaryDemos.length;
 row.transactionScopes=owned.length;counts.push(row);
}
assert.deepEqual(counts.map(r=>r.total),[27,26,26,26]);
assert.equal(assigned.size,defined.size);for(const name of defined.keys())assert(assigned.has(name),'Missing '+name);
assert.equal(Object.keys(manifest.operations).filter(name=>assigned.has('procedure:'+name)).length,56);
const commands=Object.keys(manifest.operations).filter(n=>manifest.operations[n].kind==='command');
assert.equal(commands.length,29);assert.deepEqual([...transactionOwners.keys()].sort(),commands.sort());assert.equal(primaryDemos.size,8);
const catalog=JSON.parse(fs.readFileSync(path.join(root,'database/practice/catalog.json'),'utf8'));
const exercises=plan.transactionExercises;assert.equal(exercises.length,5);
assert.deepEqual(exercises.map(x=>x.procedure).sort(),catalog.cases.filter(c=>c.group==='transactions').map(c=>c.name).sort());
for(const exercise of exercises){
 assert.equal(exercise.owner,transactionOwners.get(exercise.procedure),'Wrong transaction exercise owner');
 assert.equal(exercise.file,'database/practice/transactions/'+exercise.procedure+'.sql');
 const body=fs.readFileSync(path.join(root,exercise.file),'utf8');
 for(const token of ['@CommitLab bit=0','@ForceFailure bit=0'])assert(body.includes(token),'Missing transaction mode '+exercise.file);
}
const concurrency=plan.concurrencyStudy,ids=plan.members.map(m=>m.id);
assert.equal(concurrency.owner,transactionOwners.get(concurrency.businessProcedure));
assert.deepEqual([concurrency.owner,concurrency.partner,...concurrency.reviewers].sort(),[...ids].sort());
for(const field of ['sessionA','sessionB'])assert(fs.existsSync(path.join(root,concurrency[field])),'Missing concurrency script');
const markdown=fs.readFileSync(path.join(root,'docs/study/DATABASE_OBJECTS_4_MEMBERS.md'),'utf8');
const transactionMarkdown=fs.readFileSync(path.join(root,'docs/study/TRANSACTIONS_4_MEMBERS.md'),'utf8');
for(const member of plan.members){
 const section=markdown.split('## '+member.id+' — ')[1]?.split('\n## ')[0];assert(section,'Missing member section '+member.id);
 for(const type of types)for(const name of member.objects[type])assert(section.includes('`'+name+'`'),member.id+' missing Markdown object '+name);
 assert(section.includes('**Transaction được giao rõ:**'),member.id+' missing transaction assignment');
 for(const name of member.transactionStudy.commandProcedures)assert(transactionMarkdown.includes('|'+member.id+'|`'+name+'`|'),'Missing transaction Markdown row '+name);
}
console.log(JSON.stringify({pass:true,total:defined.size,objectsAssignedExactlyOnce:true,commandTransactionsAssignedExactlyOnce:transactionOwners.size,primaryTransactionDemos:primaryDemos.size,primaryDemosPerMember:2,explicitCommitExercises:exercises.length,concurrencyOwner:concurrency.owner,concurrencyPartner:concurrency.partner,scope:['12 tables','61 procedures','7 functions','9 views','12 triggers','3 table types','1 sequence'],counts,source:'manifest.installOrder'},null,2));
