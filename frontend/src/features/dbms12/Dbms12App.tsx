import { useEffect, useState } from 'react';
import { BookOpen, CalendarDays, ClipboardList, GraduationCap, Home, Receipt, ShieldCheck, Users } from 'lucide-react';
import { WorkspaceShell } from '../../app/WorkspaceShell';
import { IdentityShell } from '../../app/IdentityShell';
import { AccountActions } from '../../app/AccountActions';
import { Button } from '../../components/ui/Button';
import type { AuthContext } from '../../lib/auth';
import { ApiFailure, Dbms12Client } from './api';
import type { Row } from './api';
import { Form } from './controls';
import { Workspace } from './Workspace';
import './dbms12.css';

const menus:Record<string,{key:string;label:string}[]>={
  Student:[{key:'home',label:'Tổng quan'},{key:'courses',label:'Khóa học'},{key:'registrations',label:'Hồ sơ đăng ký'},{key:'invoices-own',label:'Hóa đơn'},{key:'classes',label:'Lớp của tôi'},{key:'schedules',label:'Lịch học'},{key:'grades-own',label:'Kết quả học tập'},{key:'profile',label:'Hồ sơ cá nhân'}],
  Admissions:[{key:'registrations',label:'Hồ sơ nhập học'},{key:'courses',label:'Khóa học'}],
  AcademicAffairs:[{key:'courses',label:'Khóa học'},{key:'classes',label:'Lớp học'},{key:'placements',label:'Xếp lớp'},{key:'schedules',label:'Lịch học'},{key:'grade-reviews',label:'Duyệt bảng điểm'}],
  Teacher:[{key:'classes',label:'Lớp phụ trách'},{key:'schedules',label:'Lịch dạy'},{key:'attendance',label:'Điểm danh'},{key:'gradebook',label:'Bảng điểm'}],
  Accountant:[{key:'invoices',label:'Hóa đơn'},{key:'reports-finance',label:'Báo cáo tài chính'}],
  Director:[{key:'reports-director',label:'Báo cáo tổng hợp'}],Admin:[{key:'accounts',label:'Tài khoản'},{key:'audit',label:'Nhật ký'}],
};
function context(row:Row):AuthContext {
  const role=String(row.role_code);if(!menus[role])throw new Error('Vai trò không hợp lệ.');
  return {accountId:Number(row.account_id),fullName:String(row.full_name),email:String(row.email),role:role as AuthContext['role'],scope:row.session_scope==='PASSWORD_CHANGE'?'PASSWORD_CHANGE':'NORMAL',accountVersion:String(row.row_version),serverTime:new Date().toISOString(),absoluteExpiresAt:String(row.absolute_deadline),effectiveExpiresAt:String(row.normal_idle_deadline??row.absolute_deadline)};
}
export function Dbms12App() {
  const [client]=useState(()=>new Dbms12Client());
  const [me,setMe]=useState<Row|null>(null),[checking,setChecking]=useState(true),[notice,setNotice]=useState({message:'',success:false}),[busy,setBusy]=useState(false),[guest,setGuest]=useState<'login'|'signup'>('login'),[view,setView]=useState('');
  const refresh=async()=>{const row=(await client.read('auth/me'))[0];setMe(row??null);return row;};
  useEffect(()=>{
    let active=true;
    const unsubscribe=client.subscribeUnauthorized(()=>{if(active){client.clear();setMe(null);setView('');}});
    const timer=setTimeout(()=>{void (async()=>{try{const row=(await client.read('auth/me'))[0];if(active)setMe(row??null);}catch(e){if(active&&!(e instanceof ApiFailure&&e.status===401))setNotice({message:'Chưa kết nối được hệ thống. Hãy thử lại.',success:false});}finally{if(active)setChecking(false);}})();},0);
    return()=>{active=false;unsubscribe();clearTimeout(timer);client.clear();};
  },[client]);
  useEffect(()=>{
    if(!me)return;
    const end=Math.min(Date.parse(String(me.absolute_deadline)),me.session_scope==='NORMAL'?Date.parse(String(me.normal_idle_deadline)):Infinity);
    const timer=setTimeout(()=>{client.clear();setMe(null);setView('');setNotice({message:'Phiên đã hết hạn. Vui lòng đăng nhập lại.',success:false});},Math.max(0,end-Date.now()));
    return()=>clearTimeout(timer);
  },[me,client]);
  const run=async(action:()=>Promise<void>)=>{setBusy(true);setNotice({message:'',success:false});try{await action();return true;}catch(e){setNotice({message:e instanceof Error?e.message:'Không thể xử lý yêu cầu.',success:false});return false;}finally{setBusy(false);}};
  const navigate=(next:string)=>{if(document.querySelector('[data-dbms12-dirty="true"]')&&!window.confirm('Có thông tin chưa lưu. Rời trang và bỏ thay đổi?'))return;setView(next);setNotice({message:'',success:false});};
  if(checking)return <IdentityShell><p role="status">Đang xác minh phiên đăng nhập…</p></IdentityShell>;
  if(!me)return <IdentityShell><h1>{guest==='login'?'Đăng nhập':'Tạo tài khoản học viên'}</h1>{notice.message&&<p role={notice.success?'status':'alert'} className={'ec-feedback ec-feedback--'+(notice.success?'success':'error')}>{notice.message}</p>}
    <Form key={guest} title={guest==='login'?'Chào mừng bạn trở lại':'Thông tin học viên'} busy={busy} submit={guest==='login'?'Đăng nhập':'Đăng ký'} fields={[
      {name:'email',label:'Email',type:'email',max:254},{name:'password',label:'Mật khẩu',type:'password',max:128,hint:guest==='signup'?'Từ 15 đến 128 ký tự.':undefined},
      ...(guest==='signup'?[{name:'name',label:'Họ và tên'},{name:'phone',label:'Điện thoại',type:'tel',max:10},{name:'birthDate',label:'Ngày sinh',type:'date'},{name:'address',label:'Địa chỉ',required:false,max:255}]:[]),
    ]} onSubmit={values=>run(async()=>{await client.auth(guest,values);if(guest==='signup'){setGuest('login');setNotice({message:'Đăng ký thành công. Bạn có thể đăng nhập.',success:true});}else await refresh();})}/>
    <Button className="mt-4" variant="ghost" disabled={busy} onClick={()=>{setGuest(guest==='login'?'signup':'login');setNotice({message:'',success:false});}}>{guest==='login'?'Chưa có tài khoản? Đăng ký học viên':'Đã có tài khoản? Đăng nhập'}</Button>
  </IdentityShell>;
  const auth=context(me);const current=view||menus[auth.role][0].key;
  const password=<Form title="Đổi mật khẩu" busy={busy} submit="Đổi mật khẩu" fields={[{name:'oldPassword',label:'Mật khẩu hiện tại',type:'password',max:128},{name:'newPassword',label:'Mật khẩu mới',type:'password',max:128,hint:'Từ 15 đến 128 ký tự.'}]} onSubmit={values=>run(async()=>{await client.auth('password',values);client.clear();setMe(null);setView('');setNotice({message:'Đã đổi mật khẩu. Vui lòng đăng nhập lại.',success:true});})}/>;
  return <div className="ec12-app"><WorkspaceShell context={auth} navigation={auth.scope==='NORMAL'?menus[auth.role].map((m,i)=>({label:m.label,icon:[Home,BookOpen,Users,CalendarDays,GraduationCap,Receipt,ClipboardList,ShieldCheck][i%8],selected:current===m.key,disabled:busy||!!client.pending,onClick:()=>navigate(m.key)})):[]}>
    <AccountActions><Button variant="ghost" disabled={busy} onClick={()=>navigate('password')}>Đổi mật khẩu</Button><Button variant="ghost" disabled={busy} onClick={()=>void run(async()=>{await client.auth('logout',{});client.clear();setMe(null);setView('');})}>Đăng xuất</Button></AccountActions>
    {notice.message&&<p role={notice.success?'status':'alert'} className={'ec-feedback ec-feedback--'+(notice.success?'success':'error')}>{notice.message}</p>}
    {auth.scope==='PASSWORD_CHANGE'||current==='password'?password:<Workspace key={auth.accountId} client={client} me={me} view={current} title={menus[auth.role].find(m=>m.key===current)?.label??''} onRefreshSession={refresh} onBusyChange={setBusy} onNavigate={navigate}/>}
  </WorkspaceShell></div>;
}
