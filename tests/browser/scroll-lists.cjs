const {chromium}=require('../browser-support.cjs');
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=process.env.EC_DBMS12_TEST_ROOT||path.resolve(__dirname,'../..');
const out=process.env.EC_DBMS12_EVIDENCE_ROOT||path.join(root,'docs/evidence/scroll-lists');
fs.mkdirSync(out,{recursive:true});
const accounts=fs.readFileSync(path.join(root,'.local/operator/tai-khoan.md'),'utf8').split('\n').filter(x=>/^\| (Admin|Admissions|AcademicAffairs|Teacher|Accountant|Director|Student) \|/.test(x)).map(x=>{const a=x.split('|').map(s=>s.trim());return {role:a[1],email:a[2],password:a[3]};});
let writes=0;
const cases=[
 ['AcademicAffairs','Khóa học','Danh sách khóa học','courses','course_id'],
 ['AcademicAffairs','Xếp lớp','Hồ sơ đã duyệt','registrations','registration_id'],
 ['Admissions','Hồ sơ nhập học','Hồ sơ đăng ký','registrations','registration_id'],
 ['Student','Hóa đơn','Chọn hồ sơ để xem hóa đơn','registrations','registration_id'],
 ['Accountant','Hóa đơn','Tra cứu hóa đơn','invoices','invoice_id'],
 ['Admin','Tài khoản','Tài khoản','accounts','account_id'],
 ['Admin','Nhật ký','Nhật ký thao tác','audit','audit_id'],
];
function record(i,id){return {[id]:id==='audit_id'?String(i):i,course_id:id==='course_id'?i:1,course_code:'LIST-'+i,course_name:'Khóa danh sách '+i,tuition_fee:'1000000',expected_lesson_count:6,process_weight:'40',row_version:'test-version',full_name:'Bản ghi '+i,email:'list'+i+'@example.test',phone:'0901234567',status:id==='registration_id'?'ADMITTED':'ACTIVE',role_code:'Teacher',invoice_number:'INV-LIST-'+i,amount:'1000000',invoice_status:'UNPAID',due_date:'2026-11-01',paid_at:null,payment_method:null,payment_reference:null,created_at:'2026-10-22T00:00:00Z',decision_reason:null,action_code:'DBMS12.AUTH.LOGIN.SUCCESS',result_code:'SUCCESS',occurred_at:'2026-10-22T00:00:00Z',reason:null,change_details:'Bản ghi '+i};}
async function login(browser,role,width=1280){
 const ctx=await browser.newContext({viewport:{width,height:900}}),page=await ctx.newPage(),a=accounts.find(a=>a.role===role);
 page.on('request',r=>{if(r.method()==='POST'&&r.url().includes('/api/dbms12/')&&!r.url().includes('/auth/'))writes++;});
 await page.goto('https://localhost:8446/dbms12');await page.getByLabel('Email',{exact:true}).fill(a.email);await page.getByLabel('Mật khẩu',{exact:true}).fill(a.password);await page.getByRole('button',{name:'Đăng nhập',exact:true}).click();await page.getByRole('button',{name:'Menu tài khoản',exact:true}).waitFor();
 return {ctx,page};
}
async function logout(page,ctx){
 try{if(await page.getByRole('dialog').isVisible())await page.keyboard.press('Escape');await page.getByRole('button',{name:'Menu tài khoản',exact:true}).click();await page.getByRole('button',{name:'Đăng xuất',exact:true}).click();await page.getByRole('heading',{name:'Đăng nhập',exact:true}).waitFor();}finally{await ctx.close();}
}
async function count(region,n){await region.locator('tbody tr').nth(n-1).waitFor();assert.equal(await region.locator('tbody tr').count(),n);}
async function bottom(region){await region.evaluate(e=>{e.scrollTop=e.scrollHeight;});}
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true}),checks=[];try{
 for(const [role,menu,title,route,id] of cases){
  const {ctx,page}=await login(browser,role);const calls=[];let failSecond=route==='courses';
  try{
   await page.route('**/api/dbms12/'+route+'?*',async r=>{
    const u=new URL(r.request().url()),p=Number(u.searchParams.get('page')||1);calls.push(p);
    if(p===2&&failSecond){failSecond=false;return r.fulfill({status:503,json:{message:'Không thể tải thêm (kiểm thử).'}});}
    const rows=Array.from({length:45},(_,i)=>record(i+1,id)).slice((p-1)*20,p*20);
    if(route!=='audit')rows.push({total:45});return r.fulfill({json:{rows}});
   });
   // Refresh the initial menu as well, so all mocked pages belong to one generation.
   await page.locator('aside nav').getByRole('button',{name:menu,exact:true}).click();
   await page.getByRole('button',{name:'Tải lại',exact:true}).click();
   const region=page.getByRole('region',{name:title,exact:true});await count(region,20);calls.splice(0,calls.length,1);
   assert.equal(await page.getByRole('button',{name:'Trang trước',exact:true}).count(),0);assert.equal(await page.getByRole('button',{name:'Trang sau',exact:true}).count(),0);
   if(route!=='audit'&&!(role==='Student'))await region.locator('tbody tr').first().getByRole('button',{name:'Chọn',exact:true}).click();
   await bottom(region);
   if(route==='courses'){
    await page.getByRole('alert').filter({hasText:'Không thể tải thêm (kiểm thử).'}).waitFor();assert.equal(await region.locator('tbody tr').count(),20);
    await page.waitForTimeout(250);assert.equal(calls.filter(p=>p===2).length,1,'no automatic retry');
    await page.getByRole('button',{name:'Thử tải lại danh sách',exact:true}).click();
   }
   await count(region,40);if(route!=='audit'&&role!=='Student')assert.equal(await region.locator('tr[aria-selected=true]').count(),1,'selection retained after append');
   await bottom(region);await count(region,45);await page.getByText('Đã hiển thị hết danh sách.',{exact:true}).waitFor();
   assert.equal(calls.filter(p=>p===3).length,1);assert.equal(calls.filter(p=>p>3).length,0);assert.equal(new Set(await region.locator('tbody tr').allTextContents()).size,45);
   assert.equal(await region.locator('th').first().evaluate(e=>getComputedStyle(e).position),'sticky');
   await page.emulateMedia({media:'print'});await page.waitForTimeout(150);assert.equal(calls.filter(p=>p>3).length,0);await page.emulateMedia({media:'screen'});
   for(const width of [375,768,1280]){await page.setViewportSize({width,height:900});assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),title+' overflow');assert(await region.evaluate(e=>e.scrollHeight>e.clientHeight),'bounded scrolling');}
   await page.screenshot({path:path.join(out,role+'-'+route+'-45rows-mocked.png'),fullPage:true});
   checks.push({role,menu,route,rows:45,pages:[1,2,3],selectionRetained:role!=='Student'&&route!=='audit',noPaginationButtons:true,stickyHeading:true,widths:[375,768,1280],pass:true});console.log(role+' '+menu+' 45 rows PASS');
  }finally{await logout(page,ctx);}
 }
 // A slow old page must not append to a new filter; failed first page can retry.
 {
  const {ctx,page}=await login(browser,'Admissions');let release,started;const pending=new Promise(r=>{release=r;}),began=new Promise(r=>{started=r;});const calls=[];
  try{
   await page.route('**/api/dbms12/registrations?*',async r=>{
    const u=new URL(r.request().url()),p=Number(u.searchParams.get('page')),status=u.searchParams.get('status');calls.push({page:p,status});
    if(status==='REJECTED')return r.fulfill({json:{rows:[{...record(9000,'registration_id'),full_name:'Hồ sơ sau lọc',status:'REJECTED'},{total:1}]}});
    if(p===2){started();await pending;}
    return r.fulfill({json:{rows:[...Array.from({length:20},(_,i)=>record((p-1)*20+i+1,'registration_id')),{total:45}]}});
   });
   await page.getByRole('button',{name:'Tải lại',exact:true}).click();const region=page.getByRole('region',{name:'Hồ sơ đăng ký',exact:true});await count(region,20);await bottom(region);await began;
   await page.getByRole('status').filter({hasText:'Đang tải thêm…'}).waitFor();await page.getByLabel('Lọc trạng thái',{exact:false}).selectOption('REJECTED');
   await page.getByText('Hồ sơ sau lọc',{exact:true}).waitFor();release();await page.waitForTimeout(250);await count(region,1);assert.equal(await page.getByText('Bản ghi 21',{exact:true}).count(),0);
   assert(calls.some(c=>c.status==='REJECTED'&&c.page===1));checks.push({filterReset:true,latePageIgnored:true,loadingMore:true,pass:true});
  }finally{release();await logout(page,ctx);}
 }
 assert.equal(writes,0);fs.writeFileSync(path.join(out,'scroll-acceptance.json'),JSON.stringify({pass:true,trustedHttps:true,controlledReadProjections:true,businessPosts:writes,checks},null,2));
}finally{await browser.close();}})().catch(e=>{console.error(e.message.split('Call log:')[0]);process.exitCode=1;});
