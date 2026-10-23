// Installed Edge / trusted HTTPS. Controlled API responses never reach business endpoints.
const {chromium}=require('../browser-support.cjs');
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=process.env.EC_DBMS12_TEST_ROOT||path.resolve(__dirname,'../..');
const out=process.env.EC_DBMS12_EVIDENCE_ROOT||path.join(root,'docs/evidence/create-first-dialogs');
const origin='https://localhost:8446',checks=[];
fs.mkdirSync(out,{recursive:true});
const version='AAAAAAAAAAE=';
const course={course_id:501,course_code:'UI-COURSE',course_name:'Khóa kiểm tra popup',tuition_fee:'2000000',status:'ACTIVE',expected_lesson_count:15,process_weight:'40',row_version:version};
const baseClass={class_id:601,class_code:'UI-CLASS',course_id:501,course_name:course.course_name,teacher_account_id:901,teacher_name:'Giáo viên kiểm tra',capacity:15,assigned_count:1,status:'PLANNED',grade_status:'DRAFT',row_version:version};
const registration={registration_id:701,course_id:501,course_code:course.course_code,course_name:course.course_name,full_name:'Học viên kiểm tra',status:'PENDING',created_at:new Date().toISOString(),row_version:version};
const invoice={invoice_id:801,registration_id:701,invoice_number:'UI-INVOICE',full_name:registration.full_name,amount:'2000000',invoice_status:'UNPAID',due_date:'2026-12-01',paid_at:null,payment_method:null,payment_reference:null,row_version:version};
const roster={class_assignment_id:901,report_id:902,full_name:registration.full_name,email:'ui.student@example.test',phone:'0901234567',continuous_score:null,final_exam_score:null,teacher_comment:null,report_version:version};
const schedule={schedule_id:1001,class_id:601,class_code:baseClass.class_code,schedule_type:'LESSON',start_at:'2026-12-01T02:00:00Z',end_at:'2026-12-01T03:00:00Z',room:'UI-P01',schedule_status:'PLANNED',row_version:version};
const account={account_id:1101,full_name:'Nhân sự kiểm tra',email:'ui.staff@example.test',role_code:'Teacher',status:'ACTIVE',phone:null,row_version:version};

async function ready(p){await p.waitForFunction(()=>!!document.querySelector('.ec12-workspace')&&!document.querySelector('.ec12-workspace .ec-page-header button:disabled'));}
async function navigate(p,name,width){
  if(width<768){await p.getByRole('button',{name:'Mở menu',exact:true}).click();await p.getByRole('dialog').getByRole('button',{name,exact:true}).click();}
  else await p.locator('aside nav').getByRole('button',{name,exact:true}).click();
  await p.getByRole('heading',{level:1,name,exact:true}).waitFor();await ready(p);
}
async function choose(p,title,index=0){
  const panel=p.locator('section').filter({has:p.getByRole('heading',{name:title,exact:true})}).filter({has:p.locator('table')}).last();
  const opener=panel.getByRole('button',{name:'Chọn',exact:true}).nth(index);
  await opener.click();await p.locator('dialog.ec12-selection[open]').waitFor();return opener;
}
async function fit(p){
  assert(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'page overflow');
  assert(await p.locator('dialog.ec12-selection[open]').evaluate(e=>{const r=e.getBoundingClientRect();return r.left>=0&&r.right<=innerWidth+1&&r.top>=0&&r.bottom<=innerHeight+1&&e.scrollWidth<=e.clientWidth+1;}),'dialog fits viewport');
}
async function close(p,opener){await p.waitForFunction(()=>{const b=document.querySelector('dialog.ec12-selection[open] button[aria-label="Đóng hộp thoại"]');return b&&!b.disabled;});await p.keyboard.press('Escape');await p.locator('dialog.ec12-selection[open]').waitFor({state:'detached'});if(opener)assert(await opener.evaluate(e=>e===document.activeElement),'focus returns to Chọn');}
async function firstForm(p,title){
  const headings=await p.locator('.ec12-workspace h2').allTextContents();assert.equal(headings[0],title,'creation precedes filters/list');
}
async function controlled(browser,role,width){
  const context=await browser.newContext({viewport:{width,height:900}}),p=await context.newPage(),errors=[],commands=[];
  const state={mode:'success',release:null,classRow:{...baseClass},registration:{...registration},invoice:{...invoice}};
  p.on('pageerror',e=>errors.push(e.message));p.setDefaultTimeout(12000);
  await p.route(origin+'/**',async route=>{
    const request=route.request(),url=new URL(request.url()),name=url.pathname.replace('/api/dbms12/','');
    if(url.pathname.startsWith('/api/dbms12/')){
      if(name==='auth/me')return route.fulfill({json:{rows:[{account_id:1201,full_name:'Người kiểm tra',email:'ui@example.test',role_code:role,session_scope:'NORMAL',row_version:version,absolute_deadline:new Date(Date.now()+7200000).toISOString(),normal_idle_deadline:new Date(Date.now()+1800000).toISOString()}]}});
      if(name==='auth/csrf')return route.fulfill({json:{requestToken:'controlled-ui-test'}});
      if(request.method()==='POST'){
        commands.push({route:name,body:request.postDataJSON()});
        if(state.release)await state.release;
        if(state.mode==='error')return route.fulfill({status:400,json:{message:'Lỗi điều kiện kiểm thử trong popup.'}});
        if(state.mode==='unknown')return route.fulfill({status:503,json:{message:'Kết quả chưa rõ.'}});
        return route.fulfill({json:{rows:[{operation_id:'11111111-1111-4111-8111-111111111111',target_id:601,replayed:false}],...(name==='accounts/reset-password'?{temporaryPassword:'Synthetic-only-do-not-use-123'}:{})}});
      }
      const reads={courses:[course,{total:1}],classes:[state.classRow,{...state.classRow,class_id:602,class_code:'UI-CLASS-OPEN',status:'OPEN'}],registrations:[state.registration,{total:1}],teachers:[{account_id:901,full_name:baseClass.teacher_name,email:'ui.teacher@example.test'}],schedules:[schedule],'classes/roster':[roster],attendance:[],'invoices/detail':[state.invoice],invoices:[state.invoice,{total:1}],accounts:[account,{total:1}],operations:state.mode==='lookup-found'?[{operation_id:'11111111-1111-4111-8111-111111111111'}]:[],home:[],'reports/finance':[],'reports/director':[],audit:[]};
      assert(Object.hasOwn(reads,name),'unexpected mock read '+name);return route.fulfill({json:{rows:reads[name]}});
    }
    // Preview the candidate bundle without publishing or restarting the owner's host.
    if(!process.env.EC_DBMS12_USE_SERVED&&url.pathname==='/dbms12')return route.fulfill({path:path.join(root,'frontend/dist/index.html'),contentType:'text/html'});
    if(!process.env.EC_DBMS12_USE_SERVED&&url.pathname.startsWith('/assets/')){
      const file=path.join(root,'frontend/dist/assets',path.basename(url.pathname));
      const types={'.js':'text/javascript','.css':'text/css','.woff':'font/woff','.woff2':'font/woff2'};
      return route.fulfill({path:file,contentType:types[path.extname(file)]||'application/octet-stream'});
    }
    return route.continue();
  });
  try{
    await p.goto(origin+'/dbms12');await ready(p);
    const dialog=p.locator('dialog.ec12-selection[open]');
    async function popup(menu,table,heading){
      await navigate(p,menu,width);const opener=await choose(p,table);if(heading)await dialog.getByRole('heading',{name:heading,exact:true}).waitFor();await fit(p);
      await p.screenshot({path:path.join(out,`${role}-${width}-${menu}.png`)});await close(p,opener);checks.push({role,width,menu,popup:true,fit:true,focusReturn:true});
    }
    if(role==='AcademicAffairs'){
      await firstForm(p,'Tạo khóa học');await popup('Khóa học','Danh sách khóa học','Cập nhật khóa học');
      await navigate(p,'Lớp học',width);await firstForm(p,'Tạo lớp học');await popup('Lớp học','Danh sách lớp học','Giáo viên và sĩ số');
      state.registration.status='ADMITTED';await popup('Xếp lớp','Hồ sơ đã duyệt','Xếp lớp: '+registration.full_name+' · '+registration.course_name);
      await navigate(p,'Lịch học',width);await firstForm(p,'Tạo lịch học theo tuần');await p.getByRole('heading',{name:'Thêm một buổi học hoặc thi',exact:true}).waitFor();await popup('Lịch học','Lịch học và thi cuối khóa','Dời buổi chưa tổ chức');
      // Keyboard trap and dirty confirmation preserve edits on cancel, discard on accept.
      await navigate(p,'Khóa học',width);const opener=await choose(p,'Danh sách khóa học');
      await dialog.getByLabel('Tên khóa học',{exact:true}).fill('Bản nháp chưa lưu');
      p.once('dialog',d=>d.dismiss());await p.keyboard.press('Escape');await dialog.waitFor();assert.equal(await dialog.getByLabel('Tên khóa học',{exact:true}).inputValue(),'Bản nháp chưa lưu');
      const buttons=dialog.locator('button:not(:disabled)');await buttons.last().focus();await p.keyboard.press('Tab');assert(await buttons.first().evaluate(e=>e===document.activeElement),'Tab wraps');
      await p.keyboard.press('Shift+Tab');assert(await buttons.last().evaluate(e=>e===document.activeElement),'Shift+Tab wraps');
      p.once('dialog',d=>d.accept());await dialog.getByRole('button',{name:'Đóng hộp thoại',exact:true}).click();await opener.waitFor();assert(await opener.evaluate(e=>e===document.activeElement));
      // Error, in-flight close guard, success close and unknown-result lookup: mock writes only.
      await navigate(p,'Lớp học',width);await choose(p,'Danh sách lớp học');state.mode='error';let release;
      state.release=new Promise(resolve=>{release=resolve;});p.once('dialog',d=>d.accept());await dialog.getByRole('button',{name:'Mở nhận học viên',exact:true}).click();
      await p.waitForFunction(()=>document.querySelector('dialog[open] button[aria-label="Đóng hộp thoại"]')?.disabled);await p.keyboard.press('Escape');await dialog.waitFor();release();state.release=null;
      await dialog.getByText('Lỗi điều kiện kiểm thử trong popup.',{exact:true}).waitFor();
      state.mode='unknown';p.once('dialog',d=>d.accept());await dialog.getByRole('button',{name:'Mở nhận học viên',exact:true}).click();await dialog.getByRole('heading',{name:'Kiểm tra thao tác chưa rõ kết quả',exact:true}).waitFor();
      const sent=commands.length;await dialog.getByRole('button',{name:'Kiểm tra kết quả',exact:true}).click();await dialog.getByText('Chưa tìm thấy kết quả. Tiếp tục kiểm tra hoặc đăng xuất; không gửi lại tự động.',{exact:true}).waitFor();assert.equal(commands.length,sent);
      state.mode='lookup-found';await dialog.getByRole('button',{name:'Kiểm tra kết quả',exact:true}).click();await dialog.waitFor({state:'detached'});await ready(p);assert.equal(commands.length,sent);
      state.mode='success';await choose(p,'Danh sách lớp học');p.once('dialog',d=>d.accept());await dialog.getByRole('button',{name:'Mở nhận học viên',exact:true}).click();await dialog.waitFor({state:'detached'});await ready(p);
      assert(commands.every(c=>c.route==='classes/open'&&c.body.classId===601&&c.body.expectedVersion===version));
      checks.push({role,width,dirtyCancelDiscard:true,keyboardTrap:true,busyCloseBlocked:true,errorInside:true,unknownLookupNoRetry:true,successCloses:true});
    }
    if(role==='Student'){
      await popup('Khóa học','Danh sách khóa học');await popup('Hồ sơ đăng ký','Hồ sơ đăng ký');await popup('Lớp của tôi','Danh sách lớp học');
      await navigate(p,'Hóa đơn',width);await choose(p,'Chọn hồ sơ để xem hóa đơn');await dialog.getByText('UI-INVOICE',{exact:true}).waitFor();await fit(p);
      await p.evaluate(()=>{window.__printCalls=0;window.print=()=>window.__printCalls++;});await dialog.getByRole('button',{name:'In hóa đơn',exact:true}).click();await p.waitForFunction(()=>window.__printCalls===1);
      await p.emulateMedia({media:'print'});assert(await p.locator('.ec12-workspace>.ec-page-header').evaluate(e=>getComputedStyle(e).display==='none'));assert(await dialog.evaluate(e=>getComputedStyle(e).display!=='none'&&getComputedStyle(e).overflow==='visible'));await p.pdf({path:path.join(out,'invoice-print-'+width+'.pdf'),format:'A4'});await p.emulateMedia({media:'screen'});await close(p);
      checks.push({role,width,invoicePopup:true,freshPrintRead:true,printOnlyDialog:true});
    }
    if(role==='Teacher'){
      state.classRow.status='ONGOING';await p.reload();await ready(p);await choose(p,'Danh sách lớp học');await dialog.getByRole('heading',{name:'Danh sách học viên',exact:true}).waitFor();await fit(p);
      await dialog.getByRole('button',{name:'Bảng điểm lớp này',exact:true}).click();await dialog.waitFor({state:'detached'});await ready(p);assert.equal(await p.getByLabel('Chọn lớp',{exact:false}).inputValue(),'601');
      await choose(p,'Bảng điểm toàn lớp');await dialog.getByRole('heading',{name:'Nhập điểm: '+roster.full_name,exact:true}).waitFor();await fit(p);await dialog.getByLabel('Điểm quá trình (0–100)',{exact:true}).fill('75');
      p.once('dialog',d=>d.dismiss());await p.keyboard.press('Escape');assert.equal(await dialog.getByLabel('Điểm quá trình (0–100)',{exact:true}).inputValue(),'75');
      state.mode='error';await dialog.getByRole('button',{name:'Lưu',exact:true}).click();await dialog.getByText('Lỗi điều kiện kiểm thử trong popup.',{exact:true}).waitFor();assert.equal(commands[0].route,'grades/save');assert.equal(commands[0].body.reportId,902);
      p.once('dialog',d=>d.accept());await p.keyboard.press('Escape');await dialog.waitFor({state:'detached'});
      checks.push({role,width,teacherDetailsPopup:true,shortcutClassPreserved:true,gradePopup:true,dirtyAndError:true});
    }
    if(role==='Admissions'){
      state.registration.status='CONFIRMED';await p.reload();await ready(p);await popup('Hồ sơ nhập học','Hồ sơ đăng ký','Từ chối hoặc hủy hồ sơ');
    }
    if(role==='Accountant'){
      await popup('Hóa đơn','Tra cứu hóa đơn','Thu đủ học phí');state.invoice.invoice_status='PAID';await p.getByRole('button',{name:'Tải lại',exact:true}).click();await ready(p);await popup('Hóa đơn','Tra cứu hóa đơn','Sửa thông tin thanh toán');
    }
    if(role==='Admin'){
      await firstForm(p,'Tạo tài khoản nhân sự');await popup('Tài khoản','Tài khoản','Trạng thái tài khoản');
      await choose(p,'Tài khoản');p.once('dialog',d=>d.accept());await dialog.getByRole('button',{name:'Cấp lại mật khẩu tạm',exact:true}).click();await dialog.waitFor({state:'detached'});await p.getByRole('heading',{name:'Mật khẩu tạm — chỉ hiển thị lần này',exact:true}).waitFor();await p.getByRole('button',{name:'Đã ghi nhận',exact:true}).click();assert.equal(await p.locator('output').count(),0);checks.push({role,width,temporaryPasswordPreserved:true});
    }
    assert.deepEqual(errors,[],role+' page errors');console.log(role+' '+width+' controlled PASS');
  }catch(e){await p.screenshot({path:path.join(out,role+'-'+width+'-failure.png')});throw e;}
  finally{await context.close();}
}
async function liveReads(browser){
  const accounts=fs.readFileSync(path.join(root,'.local/operator/tai-khoan.md'),'utf8').split('\n').filter(x=>/^\| (Admin|Admissions|AcademicAffairs|Teacher|Accountant|Director|Student) \|/.test(x)).map(x=>{const a=x.split('|').map(s=>s.trim());return {role:a[1],email:a[2],password:a[3]};});
  let businessPosts=0;const results=[];
  for(const role of ['Student','Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin']){
    const a=accounts.find(a=>a.role===role),context=await browser.newContext({viewport:{width:1280,height:900}}),p=await context.newPage(),errors=[];p.setDefaultTimeout(15000);
    p.on('pageerror',e=>errors.push(e.message));
    await p.route('**/api/dbms12/**',route=>{if(route.request().method()==='POST'&&!new URL(route.request().url()).pathname.includes('/auth/')){businessPosts++;return route.abort();}return route.continue();});
    try{
      await p.goto(origin+'/dbms12');await p.getByLabel('Email',{exact:true}).fill(a.email);await p.getByLabel('Mật khẩu',{exact:true}).fill(a.password);await p.getByRole('button',{name:'Đăng nhập',exact:true}).click();await ready(p);
      const menus=await p.locator('aside nav button').allTextContents();
      for(const width of [375,768,1280]){
        await p.setViewportSize({width,height:900});
        for(const raw of menus){
          const menu=raw.trim();await navigate(p,menu,width);await p.waitForFunction(()=>!Array.from(document.querySelectorAll('[role=status]')).some(e=>e.textContent.includes('Đang tải')));
          if(role==='AcademicAffairs'&&menu==='Lịch học')await p.waitForFunction(()=>!document.querySelector('.ec12-workspace fieldset:disabled'));
          const createTitle=role==='Admin'&&menu==='Tài khoản'?'Tạo tài khoản nhân sự':role==='AcademicAffairs'?{'Khóa học':'Tạo khóa học','Lớp học':'Tạo lớp học','Lịch học':'Tạo lịch học theo tuần'}[menu]:null;
          if(createTitle)await firstForm(p,createTitle);
          const opener=p.locator('main').getByRole('button',{name:'Chọn',exact:true}).first();let popup=false;
          if(await opener.count()){
            await opener.click();const dialog=p.locator('dialog.ec12-selection[open]');await dialog.waitFor();
            await p.waitForFunction(()=>!Array.from(document.querySelectorAll('dialog[open] [role=status]')).some(e=>e.textContent.includes('Đang tải')));
            await fit(p);await dialog.getByRole('button',{name:'Đóng hộp thoại',exact:true}).waitFor({state:'visible'});
            await p.screenshot({path:path.join(out,'live-'+role+'-'+width+'-'+menu+'.png')});
            await close(p,opener);popup=true;
          }
          assert(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),role+' '+menu+' overflow');results.push({role,width,menu,creationFirst:!!createTitle,popup,pass:true});
        }
      }
      assert.deepEqual(errors,[],role+' page errors');console.log(role+' live menus / 3 widths PASS');
    }catch(e){await p.screenshot({path:path.join(out,'live-'+role+'-failure.png')});throw e;}
    finally{
      try{const dialog=p.locator('dialog.ec12-selection[open]');if(await dialog.count())await p.keyboard.press('Escape');if(await p.getByRole('button',{name:'Menu tài khoản',exact:true}).isVisible()){await p.getByRole('button',{name:'Menu tài khoản',exact:true}).click();await p.getByRole('button',{name:'Đăng xuất',exact:true}).click();await p.getByRole('heading',{name:'Đăng nhập',exact:true}).waitFor();}}
      finally{await context.close();}
    }
  }
  assert.equal(businessPosts,0);fs.writeFileSync(path.join(out,'live-acceptance.json'),JSON.stringify({pass:true,browser:'installed Edge',trustedHttps:true,businessPosts,ownNormalAuthOnly:true,results},null,2));
}
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true});try{
  if(process.env.EC_DBMS12_LIVE_READS==='1')await liveReads(browser);
  else{
    for(const role of ['AcademicAffairs','Student','Teacher','Admissions','Accountant','Admin'])for(const width of [375,768,1280])await controlled(browser,role,width);
    fs.writeFileSync(path.join(out,'controlled-acceptance.json'),JSON.stringify({pass:true,browser:'installed Edge',trustedHttps:true,controlledApi:true,businessPostsToDatabase:0,checks},null,2));
  }
}finally{await browser.close();}})().catch(e=>{console.error(e.message.split('Call log:')[0]);process.exitCode=1;});
