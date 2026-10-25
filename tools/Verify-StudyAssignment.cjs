// Read-only check of the study allocation against the exact installed SQL source.
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),sql=path.join(root,'database/dbms12-compact');
const manifest=JSON.parse(fs.readFileSync(path.join(sql,'manifest.json'),'utf8'));
const plan=JSON.parse(fs.readFileSync(path.join(root,'docs/study/DATABASE_OBJECTS_4_MEMBERS.json'),'utf8'));
const procedureCatalog=JSON.parse(fs.readFileSync(path.join(root,'docs/study/STORED_PROCEDURES_CATALOG.json'),'utf8'));
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
 const reporting=member.reportingStudy;assert(reporting,'Missing reporting study '+member.id);
 assert.equal(reporting.primaryProcedures.length,6,member.id+' needs six primary SPs');
 assert.deepEqual([...reporting.primaryProcedures,...reporting.supportingProcedures].sort(),[...member.objects.procedure].sort(),member.id+' reporting coverage');
 assert.equal(new Set([...reporting.primaryProcedures,...reporting.supportingProcedures]).size,member.objects.procedure.length,member.id+' duplicate reporting SP');
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
  assert(reporting.primaryProcedures.includes(name),'Transaction demo must be a primary SP '+name);
  assert(!primaryDemos.has(name),'Primary demo assigned twice '+name);primaryDemos.add(name);
  assert(fs.existsSync(path.join(root,'database/practice/stored-procedures',name+'.sql')),'Missing primary practice '+name);
 }
 row.commandTransactions=study.commandProcedures.length;row.primaryTransactionDemos=study.primaryDemos.length;
 row.primaryProcedures=reporting.primaryProcedures.length;row.supportingProcedures=reporting.supportingProcedures.length;
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
 assert(plan.members.find(m=>m.id===exercise.owner).reportingStudy.primaryProcedures.includes(exercise.procedure),'Existing COMMIT exercise must remain a primary SP');
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
const catalogMarkdown=fs.readFileSync(path.join(root,'docs/study/STORED_PROCEDURES_CATALOG.md'),'utf8');
assert.equal(procedureCatalog.procedures.length,61);assert.equal(procedureCatalog.primary,24);assert.equal(procedureCatalog.supporting,37);
assert.deepEqual(procedureCatalog.procedures.map(p=>p.name).sort(),[...defined.values()].filter(d=>d.kind==='procedure').map(d=>d.name).sort());
assert.equal(procedureCatalog.procedures.filter(p=>p.focus==='primary').length,24);
for(const entry of procedureCatalog.procedures){
 const member=plan.members.find(m=>m.id===entry.owner);assert(member&&member.objects.procedure.includes(entry.name),'Wrong catalog owner '+entry.name);
 assert.equal(entry.focus,member.reportingStudy.primaryProcedures.includes(entry.name)?'primary':'support');
 assert(entry.purpose.length>20,'Missing purpose '+entry.name);
 const definition=defined.get('procedure:'+entry.name);assert.equal(entry.source,'database/dbms12-compact/'+definition.file);assert.equal(entry.line,definition.line);
 assert.equal(entry.practice,'database/practice/stored-procedures/'+entry.name+'.sql');assert(fs.existsSync(path.join(root,entry.practice)));
 const section=catalogMarkdown.split('## '+member.id+' — ')[1]?.split('\n## ')[0];
 const target=entry.focus==='support'?section.match(/<details>[\s\S]*?<\/details>/)?.[0]:section.split('<details>')[0];
 assert(target?.includes('|`'+entry.name+'`|'+entry.purpose+'|'),'Missing catalog task/focus '+entry.name);
}
const summaryTable=markdown.split('\n').filter(line=>line.startsWith('|')).slice(0,7);
assert(summaryTable[0].includes('|**Transaction (trong SP)**|Tổng object|'),'Missing transaction summary column');
for(const line of summaryTable)assert.equal(line.split('|').length,13,'Summary table column mismatch');
for(const member of plan.members){
 const section=markdown.split('## '+member.id+' — ')[1]?.split('\n## ')[0];assert(section,'Missing member section '+member.id);
 for(const type of types)for(const name of member.objects[type])assert(section.includes('`'+name+'`'),member.id+' missing Markdown object '+name);
 assert(section.includes('**Transaction được giao rõ:**'),member.id+' missing transaction assignment');
 const visible=section.replace(/<details>[\s\S]*?<\/details>/g,'');
 const primaryRow=visible.split('\n').find(line=>line.startsWith('|**6 SP chính — học sâu**|'));assert(primaryRow,'Missing visible primary SP row');
 const primaryLinks=[...primaryRow.matchAll(/stored-procedures\/(\w+)\.sql/g)].map(m=>m[1]);
 assert.deepEqual(primaryLinks.sort(),[...member.reportingStudy.primaryProcedures].sort());
 const hidden=section.match(/<details>[\s\S]*?<\/details>/)?.[0];assert(hidden,'Missing supporting appendix');
 for(const name of member.reportingStudy.supportingProcedures)assert(hidden.includes('|`'+name+'`|'),'Missing collapsed supporting SP '+name);
 const commandCount=member.transactionStudy.commandProcedures.length;
 const summaryRow=summaryTable.find(line=>line.startsWith('|'+member.id+'|'));
 assert.equal(summaryRow.split('|')[10],'**'+commandCount+'**',member.id+' wrong transaction summary count');
 const transactionRow=section.split('\n').find(line=>line.startsWith('|**'+commandCount+' Transaction (trong SP)**|'));
 assert(transactionRow,member.id+' missing transaction row inside own assignment table');
 const transactionLinks=[...transactionRow.matchAll(/\.\.\/\.\.\/database\/practice\/stored-procedures\/(\w+)\.sql/g)].map(m=>m[1]);
 assert.deepEqual(transactionLinks.sort(),[...member.transactionStudy.commandProcedures].sort(),member.id+' transaction table coverage');
 for(const name of member.transactionStudy.commandProcedures)assert(transactionMarkdown.includes('|'+member.id+'|`'+name+'`|'),'Missing transaction Markdown row '+name);
}
console.log(JSON.stringify({pass:true,total:defined.size,objectsAssignedExactlyOnce:true,commandTransactionsAssignedExactlyOnce:transactionOwners.size,primaryTransactionDemos:primaryDemos.size,primaryDemosPerMember:2,explicitCommitExercises:exercises.length,concurrencyOwner:concurrency.owner,concurrencyPartner:concurrency.partner,scope:['12 tables','61 procedures','7 functions','9 views','12 triggers','3 table types','1 sequence'],counts,source:'manifest.installOrder'},null,2));
