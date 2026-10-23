const {chromium}=require('../browser-support.cjs');
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=process.env.EC_DBMS12_TEST_ROOT||path.resolve(__dirname,'../..');
const out=process.env.EC_DBMS12_EVIDENCE_ROOT||path.join(root,'docs/evidence/teacher-class-selection');
fs.mkdirSync(out,{recursive:true});
const account=fs.readFileSync(path.join(root,'.local/operator/tai-khoan.md'),'utf8').split('\n').find(r=>r.startsWith('| Teacher |')).split('|').map(s=>s.trim());
let browser;const checks=[];let writes=0;
async function navigate(page,name){
 let button=page.getByRole('button',{name,exact:true}).first();
 if(!await button.isVisible()){
  await page.getByRole('button',{name:'Mở menu',exact:true}).click();
  button=page.getByRole('dialog').getByRole('button',{name,exact:true});
 }
 await button.click();
}
async function login(context){
 const page=await context.newPage();
 page.on('request',r=>{if(r.method()==='POST'&&r.url().includes('/api/dbms12/')&&!r.url().includes('/auth/'))writes++;});
 await page.goto('https://localhost:8446/dbms12');
 await page.getByLabel('Email',{exact:true}).fill(account[2]);await page.getByLabel('Mật khẩu',{exact:true}).fill(account[3]);
 await page.getByRole('button',{name:'Đăng nhập',exact:true}).click();await page.getByRole('button',{name:'Menu tài khoản',exact:true}).waitFor();
 await page.getByRole('region',{name:'Danh sách lớp học',exact:true}).waitFor();return page;
}
async function logout(page){
 if(await page.getByRole('button',{name:'Menu tài khoản',exact:true}).isVisible()){
  await page.getByRole('button',{name:'Menu tài khoản',exact:true}).click();
  await page.getByRole('button',{name:'Đăng xuất',exact:true}).click();
  await page.getByRole('heading',{name:'Đăng nhập',exact:true}).waitFor();
 }
}
async function choose(page,index){
 const row=page.getByRole('region',{name:'Danh sách lớp học',exact:true}).locator('tbody tr').nth(index);
 const code=(await row.locator('td').first().innerText()).trim();
 await row.getByRole('button',{name:'Chọn',exact:true}).click();
 await page.getByRole('heading',{name:'Chi tiết lớp '+code,exact:true}).waitFor({timeout:5000});
 return code;
}
async function checkReadStates(){
 const context=await browser.newContext({viewport:{width:1280,height:900}});let page,releaseSlow;
 let stage='error',requests=0;let markSlow;
 const started=new Promise(resolve=>{markSlow=resolve;});
 const blocked=new Promise(resolve=>{releaseSlow=resolve;});
 await context.route('**/api/dbms12/classes/roster?*',async route=>{
  requests++;
  if(stage==='error'){stage='empty';await route.fulfill({status:503,json:{message:'Không thể tải danh sách học viên (kiểm thử).'}});}
  else if(stage==='empty'){stage='slow';await route.fulfill({json:{rows:[]}});}
  else if(stage==='slow'){stage='new';markSlow();await blocked;await route.fulfill({json:{rows:[{full_name:'Phản hồi lớp cũ',email:'old@example.test',phone:null}]}});}
  else await route.fulfill({json:{rows:[{full_name:'Học viên lớp mới',email:'new@example.test',phone:null}]}});
 });
 try{
  page=await login(context);await choose(page,1);
  await page.getByRole('alert').filter({hasText:'Không thể tải danh sách học viên (kiểm thử).'}).waitFor();
  await page.getByRole('button',{name:'Tải lại danh sách học viên',exact:true}).click();
  await page.getByText('Chưa có dữ liệu phù hợp.',{exact:true}).waitFor();assert.equal(requests,2);
  await choose(page,0);await started;
  await page.getByRole('status').filter({hasText:'Đang tải danh sách học viên…'}).waitFor();
  await choose(page,1);await page.getByText('Học viên lớp mới',{exact:true}).waitFor();
  const response=page.waitForResponse(r=>r.url().includes('/classes/roster?')&&r.status()===200);
  releaseSlow();await(await response).finished();
  await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
  assert.equal(await page.getByText('Phản hồi lớp cũ',{exact:true}).count(),0);
  await page.getByText('Học viên lớp mới',{exact:true}).waitFor();
  checks.push({mockedReads:true,error:true,retryOneRead:true,empty:true,loading:true,staleResponseIgnored:true});
 }finally{releaseSlow();if(page)await logout(page);await context.close();}
}
async function checkDirtySelection(){
 const context=await browser.newContext({viewport:{width:1280,height:900}});let page;
 try{
  page=await login(context);
  const classes=await page.evaluate(async()=> (await fetch('/api/dbms12/classes').then(r=>r.json())).rows);
  // Only this browser's read projection is changed to make an editable draft visible. No write is sent.
  await context.route('**/api/dbms12/classes',route=>route.fulfill({json:{rows:classes.map(c=>({...c,status:'ONGOING',grade_status:'DRAFT'}))}}));
  await page.getByRole('button',{name:'Tải lại',exact:true}).click();
  const code=await choose(page,1),current=classes.find(c=>c.class_code===code);
  await page.getByRole('button',{name:'Bảng điểm lớp này',exact:true}).click();
  const roster=page.getByRole('region',{name:'Bảng điểm toàn lớp',exact:true});
  await roster.locator('tbody tr').first().getByRole('button',{name:'Chọn',exact:true}).click();
  await page.getByLabel('Nhận xét',{exact:true}).fill('Bản nháp kiểm tra chọn lớp');
  const other=classes.find(c=>c.class_id!==current.class_id);
  page.once('dialog',dialog=>dialog.dismiss());
  await page.getByLabel('Chọn lớp',{exact:false}).selectOption(String(other.class_id));
  assert.equal(await page.getByLabel('Chọn lớp',{exact:false}).inputValue(),String(current.class_id));
  assert.equal(await page.getByLabel('Nhận xét',{exact:true}).inputValue(),'Bản nháp kiểm tra chọn lớp');
  page.once('dialog',dialog=>dialog.accept());
  await page.getByLabel('Chọn lớp',{exact:false}).selectOption(String(other.class_id));
  assert.equal(await page.getByLabel('Chọn lớp',{exact:false}).inputValue(),String(other.class_id));
  assert.equal(await page.getByLabel('Nhận xét',{exact:true}).count(),0);
  checks.push({mockedReadProjection:true,dirtyDismissPreservesDraft:true,dirtyAcceptChangesClass:true,businessWrites:0});
 }finally{if(page)await logout(page);await context.close();}
}
(async()=>{
 browser=await chromium.launch({channel:'msedge',headless:true});
 try{
  for(const width of [375,768,1280]){
   const context=await browser.newContext({viewport:{width,height:900}});let page;
   try{
    page=await login(context);
    let rosterReads=0;page.on('request',r=>{if(r.method()==='GET'&&r.url().includes('/classes/roster?'))rosterReads++;});
    const classes=await page.evaluate(async()=> (await fetch('/api/dbms12/classes').then(r=>r.json())).rows);
    assert(classes.length>=2,'Need two existing Teacher-owned classes; never seed automatically.');
    const second=await choose(page,1),selected=classes.find(c=>c.class_code===second);assert(selected);
    await page.getByRole('region',{name:'Danh sách học viên',exact:true}).waitFor();
    await page.getByRole('button',{name:'Bảng điểm lớp này',exact:true}).click();
    await page.getByRole('heading',{name:'Bảng điểm',exact:true}).waitFor();
    await page.waitForFunction(id=>document.querySelector('select')?.value===String(id),selected.class_id);
    assert.equal(await page.getByLabel('Chọn lớp',{exact:false}).inputValue(),String(selected.class_id));
    await page.getByRole('region',{name:'Bảng điểm toàn lớp',exact:true}).waitFor();
    await page.getByLabel('Chọn lớp',{exact:false}).selectOption(String(selected.class_id));
    await page.getByRole('region',{name:'Bảng điểm toàn lớp',exact:true}).waitFor();
    await navigate(page,'Lớp phụ trách');
    await page.getByRole('heading',{name:'Chi tiết lớp '+second,exact:true}).waitFor();
    const first=await choose(page,0),firstClass=classes.find(c=>c.class_code===first);
    await page.getByRole('button',{name:'Điểm danh lớp này',exact:true}).click();
    await page.getByRole('heading',{name:'Điểm danh',exact:true}).waitFor();
    await page.waitForFunction(id=>document.querySelector('select')?.value===String(id),firstClass.class_id);
    assert.equal(await page.getByLabel('Chọn lớp',{exact:false}).inputValue(),String(firstClass.class_id));
    await navigate(page,'Bảng điểm');
    await page.waitForFunction(id=>document.querySelector('select')?.value===String(id),firstClass.class_id);
    await page.getByLabel('Chọn lớp',{exact:false}).selectOption(String(selected.class_id));
    await navigate(page,'Lớp phụ trách');
    await page.getByRole('heading',{name:'Chi tiết lớp '+second,exact:true}).waitFor();
    await page.getByRole('region',{name:'Danh sách học viên',exact:true}).waitFor();
    const beforeRefresh=rosterReads;
    const refreshed=page.waitForResponse(r=>r.url().includes('/classes/roster?')&&r.request().method()==='GET');
    await page.getByRole('button',{name:'Tải lại',exact:true}).click();await(await refreshed).finished();
    await page.getByRole('region',{name:'Danh sách học viên',exact:true}).waitFor();
    assert.equal(rosterReads,beforeRefresh+1,'Refresh must reload the selected roster once.');
    assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Page overflow '+width);
    await page.screenshot({path:path.join(out,'teacher-class-'+width+'.png'),fullPage:true});
    checks.push({width,selectNonFirst:true,roster:true,shortcutsCarryClass:true,selectionRetained:true,refreshRosterOnce:true,noOverflow:true});console.log('Teacher selection '+width+' PASS');
   }finally{if(page)await logout(page);await context.close();}
  }
  await checkReadStates();await checkDirtySelection();
  assert.equal(writes,0);fs.writeFileSync(path.join(out,'summary.json'),JSON.stringify({pass:true,checks,businessWrites:writes,trustedHttps:true,realWidths:[375,768,1280]},null,2));
  console.log('Teacher class selection PASS: 3 widths + read states + dirty draft; business writes='+writes);
 }finally{await browser.close();}
})().catch(e=>{console.error(e.message.split('Call log:')[0]);process.exitCode=1;});
