// Read-only business navigation; own normal authentication only.
const {chromium}=require('../browser-support.cjs');
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=process.env.EC_DBMS12_TEST_ROOT||path.resolve(__dirname,'../..');
const out=process.env.EC_DBMS12_EVIDENCE_ROOT||path.join(root,'docs/evidence/ui-panels');
fs.mkdirSync(out,{recursive:true});
const accounts=fs.readFileSync(path.join(root,'.local/operator/tai-khoan.md'),'utf8').split('\n').filter(x=>/^\| (Admin|Admissions|AcademicAffairs|Teacher|Accountant|Director|Student) \|/.test(x)).map(x=>{const a=x.split('|').map(s=>s.trim());return {role:a[1],email:a[2],password:a[3]};});
let writes=0;
async function navigate(page,name,width){
 if(width<768){await page.getByRole('button',{name:'Mở menu',exact:true}).click();await page.getByRole('dialog').getByRole('button',{name,exact:true}).click();}
 else await page.locator('aside nav').getByRole('button',{name,exact:true}).click();
 await page.getByRole('heading',{level:1,name,exact:true}).waitFor();
 await page.waitForFunction(()=>!!document.querySelector('.ec12-workspace')&&!document.querySelector('.ec12-workspace .ec-page-header button:disabled'));
 await page.waitForTimeout(220); // Existing 180ms button color transition.
 await page.waitForFunction(()=>!Array.from(document.querySelectorAll('main [role=status]')).some(e=>e.textContent.includes('Đang tải')));
}
async function logout(page){
 if(await page.getByRole('dialog').isVisible())await page.keyboard.press('Escape');
 await page.getByRole('button',{name:'Menu tài khoản',exact:true}).click();
 await page.getByRole('button',{name:'Đăng xuất',exact:true}).click();
 await page.getByRole('heading',{name:'Đăng nhập',exact:true}).waitFor();
}
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});const results=[];
 try{
  for(const role of ['Student','Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin']){
   const a=accounts.find(a=>a.role===role),errors=[],failed=[];
   const ctx=await browser.newContext({viewport:{width:1280,height:900}}),page=await ctx.newPage();
   try{
    page.on('pageerror',e=>errors.push(e.message));
    page.on('response',r=>{if(r.status()>=400&&r.url().includes('/api/dbms12/')&&!r.url().endsWith('/auth/me'))failed.push({path:new URL(r.url()).pathname,status:r.status()});});
    page.on('request',r=>{if(r.method()==='POST'&&r.url().includes('/api/dbms12/')&&!r.url().includes('/auth/'))writes++;});
    await page.goto('https://localhost:8446/dbms12');
    await page.getByLabel('Email',{exact:true}).fill(a.email);await page.getByLabel('Mật khẩu',{exact:true}).fill(a.password);
    await page.getByRole('button',{name:'Đăng nhập',exact:true}).click();await page.getByRole('button',{name:'Menu tài khoản',exact:true}).waitFor();
    const names=await page.locator('aside nav button').allTextContents();
    for(const width of [375,768,1280]){
     await page.setViewportSize({width,height:900});
     for(const raw of names){
      const name=raw.trim();await navigate(page,name,width);
      const frames=await page.locator('main').evaluate(main=>{
       const targets=[...main.querySelectorAll('.ec-page-header,.ec-card,.ec12-filter,.ec12-pagination')];
       return targets.map(e=>{const s=getComputedStyle(e);return {border:s.borderTopWidth,background:s.backgroundColor,padding:s.paddingTop};});
      });
      assert(frames.length>0,role+' '+name+' frames');
      assert(frames.every(f=>parseFloat(f.border)>=1&&f.background==='rgb(255, 255, 255)'&&parseFloat(f.padding)>=16),role+' '+name+' framed surfaces');
      assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),role+' '+name+' overflow '+width);
      if(width<768)await page.getByRole('button',{name:'Mở menu',exact:true}).click();
      const nav=page.locator(width<768?'dialog[open] nav':'aside nav');
      assert.equal(await nav.evaluate(e=>getComputedStyle(e).backgroundColor),'rgb(255, 255, 255)');
      const active=nav.locator('[aria-current=page]');assert.equal(await active.count(),1);
      assert.equal(await active.evaluate(e=>getComputedStyle(e).borderTopColor),'rgb(29, 78, 216)',role+' '+name+' '+width+' active border');
      await active.focus();await page.keyboard.press('Tab');await page.keyboard.press('Shift+Tab');
      assert(await active.evaluate(e=>e.matches(':focus-visible')),'visible keyboard focus');
      if(width<768)await page.keyboard.press('Escape');
      results.push({role,view:name,width,frames:frames.length,pass:true});
      if(name===names[0].trim()||role==='Teacher'&&name==='Bảng điểm')await page.screenshot({path:path.join(out,`${role}-${width}-${name===names[0].trim()?'main':'gradebook'}.png`),fullPage:true});
     }
    }
    if(role!=='Student'){
     await page.getByRole('button',{name:'Thu gọn thanh điều hướng',exact:true}).click();
     assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'compact overflow');
     const bounds=await page.locator('aside nav').evaluate(e=>({nav:e.getBoundingClientRect().right,aside:e.closest('aside').getBoundingClientRect().right}));
     assert(bounds.nav<=bounds.aside+1,'compact frame outside sidebar');
     assert(await page.locator('aside nav').evaluate(e=>Array.from(e.querySelectorAll('button')).every(b=>b.getBoundingClientRect().right<=e.getBoundingClientRect().right+1)),'compact buttons outside frame');
     await page.getByRole('button',{name:'Mở rộng thanh điều hướng',exact:true}).click();
    }
    // Error/empty/loading states use read projections only; no data writes.
    if(role==='Admissions'){
     await navigate(page,names[0].trim(),1280);
     let mode='empty',release;
     const gate=new Promise(resolve=>{release=resolve;});
     await page.route('**/api/dbms12/registrations?*',async route=>{
      if(mode==='error')return route.fulfill({status:503,json:{message:'Không thể tải hồ sơ (kiểm thử).'}});
      if(mode==='loading')await gate;
      return route.fulfill({json:{rows:[]}});
     });
     await page.getByRole('button',{name:'Tải lại',exact:true}).click();
     await page.getByText('Chưa có dữ liệu phù hợp.',{exact:true}).waitFor();
     assert.equal(await page.locator('.ec12-table-panel').count(),1);
     await page.screenshot({path:path.join(out,'Admissions-empty.png'),fullPage:true});
     mode='error';await page.getByRole('button',{name:'Tải lại',exact:true}).click();
     await page.getByText('Không thể tải hồ sơ (kiểm thử).',{exact:true}).waitFor();
     await page.screenshot({path:path.join(out,'Admissions-error.png'),fullPage:true});
     mode='loading';await page.getByRole('button',{name:'Tải lại',exact:true}).click();
     await page.getByRole('status').filter({hasText:'Đang tải dữ liệu…'}).waitFor();
     await page.screenshot({path:path.join(out,'Admissions-loading.png'),fullPage:true});release();
     await page.getByText('Chưa có dữ liệu phù hợp.',{exact:true}).waitFor();
     await page.unroute('**/api/dbms12/registrations?*');failed.splice(0,failed.length,...failed.filter(f=>f.status!==503));
    }
    await page.emulateMedia({media:'print'});
    try{
     assert(await page.locator('.ec12-workspace>.ec-page-header').evaluate(e=>getComputedStyle(e).display==='none'),'print header');
     assert(await page.locator('main .ec-card').evaluateAll(cards=>cards.every(e=>getComputedStyle(e).borderTopWidth==='0px')),'print cards');
    }finally{await page.emulateMedia({media:'screen'});}
    assert.deepEqual(errors,[],role+' page errors');assert.deepEqual(failed,[],role+' failed reads');
    console.log(role+' all menus / 3 widths PASS');
   }catch(e){console.error(role+': '+e.message.split('Call log:')[0]);await page.screenshot({path:path.join(out,role+'-failure.png'),fullPage:true});throw e;}
   finally{try{await logout(page);}finally{await ctx.close();}}
  }
  assert.equal(writes,0,'business writes');
  fs.writeFileSync(path.join(out,'acceptance.json'),JSON.stringify({pass:true,browser:'installed Edge',trustedHttps:true,businessPosts:writes,controlledReadStates:['empty','error','loading'],results},null,2));
 }finally{await browser.close();}
})().catch(e=>{console.error(e.message.split('Call log:')[0]);process.exitCode=1;});
