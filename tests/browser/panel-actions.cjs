// Edge/trusted HTTPS; controlled writes stay in this browser, live mode blocks business POST.
const {chromium}=require('../browser-support.cjs'),fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=process.env.EC_DBMS12_TEST_ROOT||path.resolve(__dirname,'../..'),out=process.env.EC_DBMS12_EVIDENCE_ROOT||path.join(root,'docs/evidence/panel-actions');
const origin='https://localhost:8446',version='AAAAAAAAAAE=',checks=[];fs.mkdirSync(out,{recursive:true});
const course={course_id:1,course_code:'POPUP-COURSE',course_name:'Khóa kiểm tra popup',tuition_fee:'1000000',expected_lesson_count:6,process_weight:'40',status:'ACTIVE',row_version:version};
const cls={class_id:1,class_code:'POPUP-CLASS',course_id:1,course_name:course.course_name,teacher_account_id:2,teacher_name:'Giáo viên kiểm tra',capacity:15,assigned_count:0,status:'PLANNED',grade_status:'DRAFT',row_version:version};
const staff={account_id:2,full_name:'Nhân sự kiểm tra',email:'staff@example.test',role_code:'Teacher',status:'ACTIVE',phone:null,row_version:version};
const invoice={invoice_id:1,invoice_number:'POPUP-INVOICE',full_name:'Học viên kiểm tra',amount:'1000000',invoice_status:'UNPAID',row_version:version};
const schedule={schedule_id:1,class_id:1,class_code:cls.class_code,schedule_type:'LESSON',start_at:'2099-10-24T02:00:00Z',end_at:'2099-10-24T03:00:00Z',room:'P01',schedule_status:'PLANNED',row_version:version};
const cases={AcademicAffairs:[['Khóa học','Danh sách khóa học',true,true],['Lớp học','Danh sách lớp học',true,false],['Lịch học','Lịch học và thi cuối khóa',true,false]],Admin:[['Tài khoản','Tài khoản',true,true]],Student:[['Khóa học','Danh sách khóa học',false,true]],Admissions:[['Khóa học','Danh sách khóa học',false,true]],Accountant:[['Hóa đơn','Tra cứu hóa đơn',false,true]],Teacher:[['Lớp phụ trách','Danh sách lớp học',false,false]],Director:[['Báo cáo tổng hợp',null,false,false]]};
async function ready(p){await p.waitForFunction(()=>!!document.querySelector('.ec12-workspace')&&!document.querySelector('.ec12-workspace .ec-page-header button:disabled'));}
async function nav(p,name,width){if(width<768){await p.getByRole('button',{name:'Mở menu',exact:true}).click();await p.getByRole('dialog').getByRole('button',{name,exact:true}).click();}else await p.locator('aside nav').getByRole('button',{name,exact:true}).click();await p.getByRole('heading',{level:1,name,exact:true}).waitFor();await ready(p);}
function list(p,title){return p.locator('.ec12-table-panel').filter({has:p.getByRole('heading',{name:title,exact:true})}).first();}
async function open(p,title,action){await list(p,title).locator('.ec12-panel-actions').getByRole('button',{name:action,exact:true}).click();await p.locator('dialog.ec12-selection[open]').waitFor();return p.locator('dialog.ec12-selection[open]');}
async function close(p){await p.waitForFunction(()=>{const b=document.querySelector('dialog.ec12-selection[open] button[aria-label="Đóng hộp thoại"]');return b&&!b.disabled;});await p.keyboard.press('Escape');await p.locator('dialog.ec12-selection[open]').waitFor({state:'detached'});}
async function fit(p){assert(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'page overflow');if(await p.locator('dialog.ec12-selection[open]').count())assert(await p.locator('dialog.ec12-selection[open]').evaluate(e=>{const r=e.getBoundingClientRect();return r.left>=0&&r.right<=innerWidth+1&&r.top>=0&&r.bottom<=innerHeight+1&&e.scrollWidth<=e.clientWidth+1;}),'popup fits');}
async function header(p,title,create,search,width){
 assert.equal(await p.locator('main form').count(),0,'no inline create/search forms');
 if(!title)return;
 const panel=list(p,title),actions=panel.locator('.ec12-panel-actions');assert.equal(await actions.getByRole('button',{name:'Tạo',exact:true}).count(),create?1:0);assert.equal(await actions.getByRole('button',{name:'Tìm kiếm',exact:true}).count(),search?1:0);
 if(create||search){const positions=await panel.locator('.ec12-table-header').evaluate(e=>{const h=e.querySelector('h2').getBoundingClientRect(),a=e.querySelector('.ec12-panel-actions').getBoundingClientRect(),r=e.getBoundingClientRect();return {sameRow:Math.abs(h.top+h.height/2-a.top-a.height/2)<2,rightAligned:Math.abs(a.right-r.right)<2,within:a.bottom<=r.bottom+1};});assert(positions.rightAligned&&positions.within);if(width>=768)assert(positions.sameRow,'desktop header buttons beside title');}
}
async function previewAssets(p){
 if(process.env.EC_DBMS12_USE_SERVED)return;
 await p.route(origin+'/dbms12',r=>r.fulfill({path:path.join(root,'frontend/dist/index.html'),contentType:'text/html'}));
 await p.route(origin+'/assets/*',r=>{const name=path.basename(new URL(r.request().url()).pathname);return r.fulfill({path:path.join(root,'frontend/dist/assets',name),contentType:({'.js':'text/javascript','.css':'text/css','.woff':'font/woff','.woff2':'font/woff2'})[path.extname(name)]});});
}
async function courseForm(d){const f=d.getByRole('heading',{name:'Tạo khóa học',exact:true}).locator('..');for(const [name,value] of Object.entries({code:'POPUP-NEW',name:'Khóa mới',tuition:'1000000',lessons:'6',weight:'40'}))await f.locator('[name='+name+']').fill(value);return f;}
async function controlled(browser,role,width){
 const ctx=await browser.newContext({viewport:{width,height:900}}),p=await ctx.newPage(),errors=[];p.setDefaultTimeout(12000);p.on('pageerror',e=>errors.push(e.message));
 const state={mode:'success',commands:[],searches:{},lookupFound:false,gate:null};
 await previewAssets(p);
 await p.route('**/api/dbms12/**',async r=>{const req=r.request(),url=new URL(req.url()),name=url.pathname.replace('/api/dbms12/','');
  if(name==='auth/me')return r.fulfill({json:{rows:[{account_id:1,full_name:'Kiểm tra popup',email:'popup@example.test',role_code:role,session_scope:'NORMAL',row_version:version,absolute_deadline:new Date(Date.now()+7200000).toISOString(),normal_idle_deadline:new Date(Date.now()+1800000).toISOString()}]}});
  if(name==='auth/csrf')return r.fulfill({json:{requestToken:'controlled-popup-test'}});
  if(req.method()==='POST'){
   state.commands.push({route:name,body:req.postDataJSON()});if(state.gate)await state.gate;
   if(state.mode!=='success')return r.fulfill({status:state.mode==='unknown'?503:400,json:{message:'Không thể tạo (kiểm thử).'}});
   return r.fulfill({json:{rows:[{operation_id:'11111111-1111-4111-8111-111111111111',target_id:1,replayed:false}],...(name==='accounts/create'?{temporaryPassword:'Synthetic-only-popup-test-123'}:{})}});
  }
  if(['courses','invoices','accounts'].includes(name))state.searches[name]=url.searchParams.get('search');
  const reads={courses:[course,{total:1}],classes:[cls],teachers:[staff],accounts:[staff,{total:1}],invoices:[invoice,{total:1}],schedules:[schedule],'classes/roster':[],'reports/director':[],home:[],registrations:[{total:0}],operations:state.lookupFound?[{operation_id:'11111111-1111-4111-8111-111111111111'}]:[],'schedules/preview':[{schedule_type:'LESSON',start_at:schedule.start_at,end_at:schedule.end_at,room:'P01'}]};
  assert(Object.hasOwn(reads,name),'unexpected read '+name);return r.fulfill({json:{rows:reads[name]}});
 });
 try{
  await p.goto(origin+'/dbms12');await ready(p);
  for(const [menu,title,create,search] of cases[role]){
   await nav(p,menu,width);if(menu==='Lịch học')await list(p,title).getByRole('button',{name:'Tạo',exact:true}).waitFor();await header(p,title,create,search,width);await fit(p);
   if(create){
    const opener=list(p,title).getByRole('button',{name:'Tạo',exact:true}),d=await open(p,title,'Tạo');await fit(p);const field=d.locator('input[type=text]').first(),original=await field.inputValue();await field.fill('Bản nháp chưa lưu');
    p.once('dialog',d=>d.dismiss());await p.keyboard.press('Escape');assert.equal(await field.inputValue(),'Bản nháp chưa lưu');
    p.once('dialog',d=>d.accept());await p.keyboard.press('Escape');await d.waitFor({state:'detached'});assert(await opener.evaluate(e=>e===document.activeElement),'create focus return');
    const reopened=await open(p,title,'Tạo');assert.equal(await reopened.locator('input[type=text]').first().inputValue(),original,'discard clears draft');await close(p);
   }
   if(search){
    const opener=list(p,title).getByRole('button',{name:'Tìm kiếm',exact:true}),d=await open(p,title,'Tìm kiếm');await fit(p);await d.locator('input[name=search]').fill('Popup query');await d.getByRole('button',{name:'Tìm',exact:true}).click();await d.waitFor({state:'detached'});await ready(p);
    const route=menu==='Khóa học'?'courses':role==='Admin'?'accounts':'invoices';assert.equal(state.searches[route],'Popup query');
    await open(p,title,'Tìm kiếm');assert.equal(await d.locator('input[name=search]').inputValue(),'Popup query');await d.locator('input[name=search]').fill('');await d.getByRole('button',{name:'Tìm',exact:true}).click();await d.waitFor({state:'detached'});await ready(p);assert.equal(state.searches[route],null,'clear query');
    await opener.waitFor();
   }
   await p.screenshot({path:path.join(out,`${role}-${menu}-${width}.png`)});checks.push({role,menu,width,create,search,actionsOnList:true,noInlineForms:true,fit:true,dirtyFocus:true});
  }
  if(role==='AcademicAffairs'){
   await nav(p,'Khóa học',width);let d=await open(p,'Danh sách khóa học','Tạo'),f=await courseForm(d);state.mode='error';await f.getByRole('button',{name:'Lưu',exact:true}).click();await d.getByRole('alert').filter({hasText:'Không thể tạo (kiểm thử).'}).waitFor();assert.equal(await f.locator('[name=code]').inputValue(),'POPUP-NEW');
   let release;state.gate=new Promise(r=>{release=r;});state.mode='unknown';await f.getByRole('button',{name:'Lưu',exact:true}).click();await p.waitForFunction(()=>document.querySelector('dialog[open] button[aria-label="Đóng hộp thoại"]')?.disabled);await p.keyboard.press('Escape');await d.waitFor();release();state.gate=null;
   await d.getByText('Chưa xác định được kết quả. Không gửi lại thao tác; hãy kiểm tra kết quả bên dưới.',{exact:true}).waitFor();const sent=state.commands.length;await d.getByRole('button',{name:'Kiểm tra kết quả',exact:true}).click();await d.getByText('Chưa tìm thấy kết quả. Tiếp tục kiểm tra hoặc đăng xuất; không gửi lại tự động.',{exact:true}).waitFor();state.lookupFound=true;await d.getByRole('button',{name:'Kiểm tra kết quả',exact:true}).click();await d.waitFor({state:'detached'});await ready(p);assert.equal(state.commands.length,sent,'lookup never resends');
   state.mode='success';d=await open(p,'Danh sách khóa học','Tạo');f=await courseForm(d);await f.getByRole('button',{name:'Lưu',exact:true}).click();await d.waitFor({state:'detached'});await ready(p);assert.equal(state.commands.at(-1).route,'courses/create');assert.equal(state.commands.at(-1).body.code,'POPUP-NEW');await p.locator('p.ec-feedback--success').filter({hasText:'Đã lưu thành công.'}).waitFor();
   await list(p,'Danh sách khóa học').getByRole('button',{name:'Chọn',exact:true}).first().click();await p.getByRole('heading',{name:'Cập nhật khóa học',exact:true}).waitFor();await close(p);
   await nav(p,'Lịch học',width);d=await open(p,'Lịch học và thi cuối khóa','Tạo');let weekly=d.getByRole('heading',{name:'Tạo lịch học theo tuần',exact:true}).locator('..');await weekly.locator('select[name=classId]').selectOption('1');await weekly.locator('input[name=room]').fill('P01');await weekly.getByRole('button',{name:'Xem trước',exact:true}).click();await d.getByRole('heading',{name:'Lịch dự kiến — chưa lưu',exact:true}).waitFor();
   p.once('dialog',d=>d.dismiss());await p.keyboard.press('Escape');await d.waitFor();p.once('dialog',d=>d.accept());await p.keyboard.press('Escape');await d.waitFor({state:'detached'});d=await open(p,'Lịch học và thi cuối khóa','Tạo');assert.equal(await d.getByRole('heading',{name:'Lịch dự kiến — chưa lưu',exact:true}).count(),0,'discard preview');
   const single=d.getByRole('heading',{name:'Thêm một buổi học hoặc thi',exact:true}).locator('..');await single.locator('select[name=classId]').selectOption('1');await single.locator('select[name=scheduleType]').selectOption('LESSON');await single.locator('input[name=start]').fill('2099-10-24T09:00');await single.locator('input[name=end]').fill('2099-10-24T10:00');await single.locator('input[name=room]').fill('P01');await single.getByRole('button',{name:'Lưu',exact:true}).click();await d.waitFor({state:'detached'});assert.equal(state.commands.at(-1).route,'schedules/batch');assert.equal(state.commands.at(-1).body.classVersion,version);
   checks.push({role,width,createFailureKeepsDraft:true,busyCloseBlocked:true,unknownLookupNoResend:true,successCloses:true,selectedPopupPreserved:true,weeklyPreviewDirtyDiscard:true,singleSchedulePayloadPreserved:true});
  }
  if(role==='Admin'){
   const d=await open(p,'Tài khoản','Tạo'),f=d.getByRole('heading',{name:'Tạo tài khoản nhân sự',exact:true}).locator('..');await f.locator('select[name=role]').selectOption('Teacher');await f.locator('input[name=email]').fill('new.staff@example.test');await f.locator('input[name=name]').fill('Nhân sự mới');await f.getByRole('button',{name:'Lưu',exact:true}).click();await d.waitFor({state:'detached'});await p.getByRole('heading',{name:'Mật khẩu tạm — chỉ hiển thị lần này',exact:true}).waitFor();await p.getByRole('button',{name:'Đã ghi nhận',exact:true}).click();assert.equal(await p.locator('output').count(),0);checks.push({role,width,createStaffOneTimePassword:true});
  }
  assert.deepEqual(errors,[]);console.log(role+' '+width+' controlled PASS');
 }catch(e){await p.screenshot({path:path.join(out,role+'-'+width+'-failure.png')});throw e;}finally{await ctx.close();}
}
async function live(browser){
 const accounts=fs.readFileSync(path.join(root,'.local/operator/tai-khoan.md'),'utf8').split('\n').filter(x=>/^\| (Admin|Admissions|AcademicAffairs|Teacher|Accountant|Director|Student) \|/.test(x)).map(x=>x.split('|').map(s=>s.trim()));let businessPosts=0;
 for(const role of Object.keys(cases)){
  const a=accounts.find(a=>a[1]===role),ctx=await browser.newContext({viewport:{width:1280,height:900}}),p=await ctx.newPage(),errors=[];p.setDefaultTimeout(12000);p.on('pageerror',e=>errors.push(e.message));
  await p.route('**/api/dbms12/**',r=>{if(r.request().method()==='POST'&&!new URL(r.request().url()).pathname.includes('/auth/')){businessPosts++;return r.abort();}return r.continue();});
  try{
   await p.goto(origin+'/dbms12');await p.getByLabel('Email',{exact:true}).fill(a[2]);await p.getByLabel('Mật khẩu',{exact:true}).fill(a[3]);await p.getByRole('button',{name:'Đăng nhập',exact:true}).click();await ready(p);
   for(const width of [375,768,1280]){await p.setViewportSize({width,height:900});for(const [menu,title,create,search] of cases[role]){
    await nav(p,menu,width);await header(p,title,create,search,width);for(const action of [...(create?['Tạo']:[]),...(search?['Tìm kiếm']:[])]){await open(p,title,action);await fit(p);await p.screenshot({path:path.join(out,`live-${role}-${menu}-${action}-${width}.png`)});await close(p);}checks.push({role,menu,width,create,search,live:true,actionsOnList:true,popupsFit:true});
   }}assert.deepEqual(errors,[]);console.log(role+' live / 3 widths PASS');
  }catch(e){await p.screenshot({path:path.join(out,'live-'+role+'-failure.png')});throw e;}
  finally{try{if(await p.locator('dialog.ec12-selection[open]').count())await close(p);await p.getByRole('button',{name:'Menu tài khoản',exact:true}).click();await p.getByRole('button',{name:'Đăng xuất',exact:true}).click();await p.getByRole('heading',{name:'Đăng nhập',exact:true}).waitFor();}finally{await ctx.close();}}
 }assert.equal(businessPosts,0);return businessPosts;
}
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true});try{
 const isLive=process.env.EC_DBMS12_LIVE_READS==='1';if(isLive)await live(browser);else for(const role of Object.keys(cases))for(const width of [375,768,1280])await controlled(browser,role,width);
 fs.writeFileSync(path.join(out,isLive?'live-acceptance.json':'controlled-acceptance.json'),JSON.stringify({pass:true,browser:'installed Edge',trustedHttps:true,controlledApi:!isLive,businessPostsToDatabase:0,checks},null,2));
}finally{await browser.close();}})().catch(e=>{console.error(e.message.split('Call log:')[0]);process.exitCode=1;});
