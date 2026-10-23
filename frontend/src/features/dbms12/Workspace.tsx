import { useEffect, useMemo, useState } from 'react';
import { Button } from '../../components/ui/Button';
import { Dbms12Client, label, number, range } from './api';
import type { Payload, Row } from './api';
import { Form, RecordDetails, SelectionDialog, Table } from './controls';
import { display } from './display';
import type { Field } from './controls';
import { Teaching } from './Teaching';
import { Schedules } from './Schedules';
import { TeacherClassDetails } from './TeacherClassDetails';
import { useScrollList } from './useScrollList';
import type { ListQuery } from './useScrollList';

const courseColumns=['course_code','course_name','tuition_fee','status','expected_lesson_count','process_weight'];
const registrationColumns=['full_name','course_code','course_name','status','created_at','decision_reason'];
const classColumns=['class_code','course_name','teacher_name','status','assigned_count','capacity','grade_status'];
const invoiceColumns=['invoice_number','full_name','amount','invoice_status','due_date','paid_at','payment_method','payment_reference'];
const roles=['Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin'];
type Data=Record<string,Row[]>;
export function Workspace({client,me,view,title,onRefreshSession,onBusyChange,onNavigate}:{client:Dbms12Client;me:Row;view:string;title:string;onRefreshSession:()=>Promise<unknown>;onBusyChange:(busy:boolean)=>void;onNavigate:(view:string)=>void}) {
  const role=String(me.role_code);
  const [data,setData]=useState<Data>({}),[loaded,setLoaded]=useState(''),[loading,setLoading]=useState(true),[busy,setBusy]=useState(false),[notice,setNotice]=useState({message:'',success:false}),[temporary,setTemporary]=useState<string|null>(null),[picked,setPicked]=useState<Row>(),[search,setSearch]=useState(''),[state,setState]=useState(''),[revision,setRevision]=useState(0);
  const selectionKey=[view,search,state,revision].join('|');
  const [teachingClassId,setTeachingClassId]=useState('');
  const [panel,setPanel]=useState<'create'|'search'|null>(null);
  const listQuery=useMemo<ListQuery|null>(()=>{
    if(view==='courses')return {path:'courses',params:{search},id:'course_id'};
    if(view==='registrations'||view==='invoices-own'||view==='placements')return {path:'registrations',params:{status:view==='placements'?'ADMITTED':state||undefined},id:'registration_id'};
    if(view==='invoices')return {path:'invoices',params:{search,state:state||undefined},id:'invoice_id'};
    if(view==='accounts')return {path:'accounts',params:{search,status:state||undefined},id:'account_id'};
    if(view==='audit')return {path:'audit',params:{},id:'audit_id'};
    return null;
  },[view,search,state]);
  const list=useScrollList(client,listQuery,selectionKey);

  useEffect(()=>{
    let active=true; const timer=setTimeout(()=>{
      setLoading(true);setPicked(undefined);setPanel(null);
      const jobs:[string,string,Payload][]=[];
      if(view==='home')jobs.push(['main','home',{}]);
      if(view==='classes'||view==='placements'||view==='attendance'||view==='gradebook'||view==='grade-reviews')jobs.push(['classes','classes',{}]);
      if(view==='classes'&&role==='AcademicAffairs')jobs.push(['courses','courses',{pageSize:100}],['teachers','teachers',{}]);
      if(view==='grades-own')jobs.push(['main','grades/own',{}]);
      if(view==='reports-finance')jobs.push(['main','reports/finance',range()]);
      if(view==='reports-director')jobs.push(['main','reports/director',range()]);
      void Promise.all(jobs.map(async([key,path,params])=>[key,await client.read(path,params)] as const)).then(results=>{if(active){setData(Object.fromEntries(results));setLoaded(selectionKey);}}).catch(e=>{if(active)setNotice({message:e instanceof Error?e.message:'Không thể tải dữ liệu.',success:false});}).finally(()=>{if(active)setLoading(false);});
    },0);
    return()=>{active=false;clearTimeout(timer);};
  },[client,view,role,search,state,selectionKey]);
  useEffect(()=>{onBusyChange(busy);return()=>onBusyChange(false);},[busy,onBusyChange]);
  const refresh=()=>setRevision(n=>n+1);
  const read=async(path:string,args:Payload={})=>{try{setBusy(true);return await client.read(path,args);}catch(e){setNotice({message:e instanceof Error?e.message:'Không thể tải dữ liệu.',success:false});return [];}finally{setBusy(false);}};
  const run=async(path:string,args:Payload):Promise<boolean>=>{
    setBusy(true);setNotice({message:'',success:false});setTemporary(null);
    try {const result=await client.command(path,args);setTemporary(result.temporaryPassword??null);setNotice({message:'Đã lưu thành công.',success:true});await onRefreshSession();setPanel(null);refresh();return true;}
    catch(e){setNotice({message:client.pending?'Chưa xác định được kết quả. Không gửi lại thao tác; hãy kiểm tra kết quả bên dưới.':e instanceof Error?e.message:'Không thể lưu dữ liệu.',success:false});return false;}
    finally{setBusy(false);}
  };
  const choose=(r:Row)=>{if(document.querySelector('[data-dbms12-dirty="true"]')&&!window.confirm('Có dữ liệu chưa lưu. Bỏ thay đổi để chọn dòng khác?'))return false;setPicked(r);setTemporary(null);return true;};
  const rows=listQuery?list.rows:data.main??[],classes=data.classes??[];
  const teacherClass=role==='Teacher'?classes.find(c=>String(c.class_id)===teachingClassId):undefined;
  const initialListLoading=!!listQuery&&(!list.ready||(list.loading&&list.rows.length===0));
  const disabled=busy||loading||initialListLoading||!!client.pending;
  const button=(text:string,path:string,body:Payload,danger=false)=><Button key={path} disabled={disabled} variant={danger?'danger':'secondary'} onClick={()=>{if(window.confirm(text+'?'))void run(path,body);}}>{text}</Button>;
  const options=(items:Row[],key:string,names:string[])=>items.filter(r=>r[key]!==undefined).map(r=>({value:String(r[key]),label:label(r,names)}));
  const feedback=<>
    {notice.message&&<p role={notice.success?'status':'alert'} className={'ec-feedback ec12-notice ec-feedback--'+(notice.success?'success':'error')}>{notice.message}</p>}
    {client.pending&&<section className="ec-feedback ec-feedback--error"><h2>Kiểm tra thao tác chưa rõ kết quả</h2><p>Không tự gửi lại yêu cầu. Việc kiểm tra chỉ đọc kết quả đã lưu.</p><Button disabled={busy} onClick={()=>void read('operations',{requestId:client.pending?.requestId,action:client.pending?.action}).then(rows=>{if(rows.length){client.pending=null;setNotice({message:'Thao tác đã được lưu.',success:true});refresh();}else setNotice({message:'Chưa tìm thấy kết quả. Tiếp tục kiểm tra hoặc đăng xuất; không gửi lại tự động.',success:false});})}>Kiểm tra kết quả</Button></section>}
    {temporary&&<section className="ec-feedback ec-feedback--success ec12-notice"><h2>Mật khẩu tạm — chỉ hiển thị lần này</h2><output>{temporary}</output><p>Gửi riêng cho nhân sự và yêu cầu đổi mật khẩu khi đăng nhập.</p><Button onClick={()=>setTemporary(null)}>Đã ghi nhận</Button></section>}
  </>;
  const contentReady=(loaded===selectionKey||loaded.startsWith(view+'|'))&&(!listQuery||list.ready&&!initialListLoading);
  const canCreate=(role==='AcademicAffairs'&&['courses','classes'].includes(view))||view==='accounts';
  const canSearch=['courses','invoices','accounts'].includes(view);
  const panelActions=canCreate||canSearch?<>
    {canCreate&&<Button disabled={disabled} onClick={()=>{setPicked(undefined);setPanel('create');}}>Tạo</Button>}
    {canSearch&&<Button variant="secondary" disabled={disabled} onClick={()=>{setPicked(undefined);setPanel('search');}}>Tìm kiếm</Button>}
  </>:undefined;
  function creation() {
    if(view==='courses'&&role==='AcademicAffairs')return <Form horizontal title="Tạo khóa học" busy={disabled} fields={courseFields()} onSubmit={f=>run('courses/create',{code:f.code,name:f.name,tuition:f.tuition,lessons:number(f.lessons),weight:f.weight})}/>;
    if(view==='classes'&&role==='AcademicAffairs')return <Form horizontal title="Tạo lớp học" busy={disabled} fields={[{name:'code',label:'Mã lớp'},{name:'courseId',label:'Khóa học',options:options(data.courses??[],'course_id',['course_code','course_name'])},{name:'teacherId',label:'Giáo viên',options:options(data.teachers??[],'account_id',['full_name','email'])},{name:'capacity',label:'Sĩ số tối đa',type:'number',value:15}]} onSubmit={f=>run('classes/create',{code:f.code,courseId:number(f.courseId),teacherId:number(f.teacherId),capacity:number(f.capacity)})}/>;
    if(view==='accounts')return <Form horizontal title="Tạo tài khoản nhân sự" busy={disabled} fields={[{name:'role',label:'Vai trò',options:roles.map(r=>({value:r,label:display('role_code',r)}))},{name:'email',label:'Email',type:'email',max:254},{name:'name',label:'Họ và tên'},{name:'phone',label:'Điện thoại',required:false,max:10}]} onSubmit={f=>run('accounts/create',{role:f.role,email:f.email,name:f.name,phone:f.phone||null})}/>;
    return null;
  }
  function selection() {
    if(!picked)return null;
    if(view==='courses')return <>
      <RecordDetails row={picked} columns={role==='AcademicAffairs'?courseColumns:courseColumns.slice(0,3)}/>
      {role==='Student'&&button('Đăng ký khóa học','registrations/create',{courseId:picked.course_id})}
      {role==='AcademicAffairs'&&<Form key={String(picked.course_id)+String(picked.row_version)} title="Cập nhật khóa học" busy={disabled} fields={[...courseFields(picked).filter(f=>f.name!=='code'),{name:'status',label:'Tuyển sinh',value:String(picked.status),options:[{value:'ACTIVE',label:'Đang tuyển'},{value:'INACTIVE',label:'Ngừng tuyển'}]}]} onSubmit={f=>run('courses/update',{courseId:picked.course_id,expectedVersion:picked.row_version,name:f.name,tuition:f.tuition,lessons:number(f.lessons),weight:f.weight,status:f.status})}/>}
    </>;
    if(view==='registrations')return <>
      <RecordDetails row={picked} columns={registrationColumns}/><div className="ec-actions">
        {role==='Student'&&picked.status==='PENDING'&&<>{button('Xác nhận nhập học','registrations/confirm',{registrationId:picked.registration_id,expectedVersion:picked.row_version})}{button('Hủy đăng ký','registrations/cancel-own',{registrationId:picked.registration_id,expectedVersion:picked.row_version},true)}</>}
        {role==='Admissions'&&picked.status==='CONFIRMED'&&button('Duyệt và phát hành hóa đơn','admissions/approve',{registrationId:picked.registration_id,expectedVersion:picked.row_version})}
      </div>{role==='Admissions'&&['CONFIRMED','ADMITTED'].includes(String(picked.status))&&<Form key={String(picked.registration_id)} title="Từ chối hoặc hủy hồ sơ" submit="Thực hiện" busy={disabled} fields={[{name:'decision',label:'Thao tác',options:[...(picked.status==='CONFIRMED'?[{value:'reject',label:'Từ chối hồ sơ'}]:[]),{value:'cancel',label:'Hủy hồ sơ chưa thanh toán'}]},{name:'reason',label:'Lý do',max:1000}]} onSubmit={f=>run('admissions/'+f.decision,{registrationId:picked.registration_id,expectedVersion:picked.row_version,reason:f.reason})}/>}</>;
    if(view==='classes')return <>
      {role==='Teacher'&&teacherClass?<TeacherClassDetails key={String(teacherClass.class_id)} classRow={teacherClass} client={client} busy={disabled} onOpen={onNavigate} revision={revision}/>:<RecordDetails row={picked} columns={classColumns}/>}
      {role==='AcademicAffairs'&&<><div className="ec-actions">{picked.status==='PLANNED'&&button('Mở nhận học viên','classes/open',{classId:picked.class_id,expectedVersion:picked.row_version})}{picked.status==='OPEN'&&button('Bắt đầu lớp học','classes/start',{classId:picked.class_id,expectedVersion:picked.row_version})}{picked.status==='ONGOING'&&button('Hoàn thành lớp học','classes/complete',{classId:picked.class_id,expectedVersion:picked.row_version})}</div>
        {['PLANNED','OPEN'].includes(String(picked.status))&&<><Form key={'edit'+picked.row_version} title="Giáo viên và sĩ số" busy={disabled} fields={[{name:'teacherId',label:'Giáo viên',value:String(picked.teacher_account_id),options:options(data.teachers??[],'account_id',['full_name','email'])},{name:'capacity',label:'Sĩ số tối đa',type:'number',value:String(picked.capacity)}]} onSubmit={f=>run('classes/edit',{classId:picked.class_id,expectedVersion:picked.row_version,teacherId:number(f.teacherId),capacity:number(f.capacity)})}/><Form title="Hủy lớp chưa bắt đầu" busy={disabled} fields={[{name:'reason',label:'Lý do hủy',max:1000}]} submit="Hủy lớp" onSubmit={f=>run('classes/cancel',{classId:picked.class_id,expectedVersion:picked.row_version,reason:f.reason})}/></>}
      </>}
    </>;
    if(view==='placements')return <><RecordDetails row={picked} columns={registrationColumns}/><Form key={String(picked.registration_id)} title={'Xếp lớp: '+label(picked,['full_name','course_name'])} busy={disabled} fields={[{name:'classId',label:'Lớp cùng khóa học',options:options(classes.filter(c=>c.status==='OPEN'&&c.course_id===picked.course_id),'class_id',['class_code','teacher_name'])}]} submit="Xếp lớp" onSubmit={f=>{const c=classes.find(c=>c.class_id===number(f.classId));return run('placements',{registrationId:picked.registration_id,registrationVersion:picked.row_version,classId:c?.class_id,classVersion:c?.row_version});}}/></>;
    if(view==='invoices-own')return <><Table title="Hóa đơn của bạn" rows={data.invoice??[]} columns={invoiceColumns.filter(c=>c!=='full_name')}/><Button disabled={disabled||!data.invoice?.length} onClick={()=>void read('invoices/detail',{registrationId:picked.registration_id}).then(invoice=>{setData(old=>({...old,invoice}));if(invoice.length)requestAnimationFrame(()=>requestAnimationFrame(()=>window.print()));})}>In hóa đơn</Button></>;
    if(view==='invoices')return <><RecordDetails row={picked} columns={invoiceColumns}/>{['PAID','UNPAID'].includes(String(picked.invoice_status))&&<Form key={String(picked.invoice_id)+String(picked.row_version)} title={picked.invoice_status==='UNPAID'?'Thu đủ học phí':'Sửa thông tin thanh toán'} busy={disabled} submit={picked.invoice_status==='UNPAID'?'Xác nhận đã thu đủ':'Lưu điều chỉnh'} fields={[{name:'method',label:'Phương thức',value:String(picked.payment_method??''),options:[{value:'CASH',label:'Tiền mặt'},{value:'BANK_TRANSFER',label:'Chuyển khoản'}]},{name:'reference',label:'Tham chiếu thanh toán',required:false,max:100,value:String(picked.payment_reference??'')},...(picked.invoice_status==='PAID'?[{name:'reason',label:'Lý do điều chỉnh',max:1000}]:[])]} onSubmit={f=>run(picked.invoice_status==='UNPAID'?'invoices/collect':'invoices/correct',{invoiceId:picked.invoice_id,expectedVersion:picked.row_version,method:f.method,reference:f.reference||null,...(picked.invoice_status==='PAID'?{reason:f.reason}:{})})}/>}</>;
    if(view==='accounts')return <><RecordDetails row={picked} columns={['full_name','email','role_code','status','phone']}/><Form key={String(picked.account_id)+String(picked.row_version)} title="Trạng thái tài khoản" busy={disabled} fields={[{name:'status',label:'Trạng thái',value:String(picked.status),options:[{value:'ACTIVE',label:'Đang hoạt động'},{value:'LOCKED',label:'Tạm khóa'},{value:'DISABLED',label:'Ngừng sử dụng'}]}]} onSubmit={f=>run('accounts/status',{accountId:picked.account_id,accountVersion:picked.row_version,status:f.status})}/>{button('Cấp lại mật khẩu tạm','accounts/reset-password',{accountId:picked.account_id,accountVersion:picked.row_version},true)}</>;
    return null;
  }
  function content() {
    if(view==='home')return <Table title="Hành trình học tập" rows={rows} columns={['course_code','course_name','status','invoice_status','class_code','grade_status','next_action']}/>;
    if(view==='courses')return <Table title="Danh sách khóa học" actions={panelActions} list={list} rows={rows} columns={role==='AcademicAffairs'?courseColumns:courseColumns.slice(0,3)} onSelect={role!=='Admissions'?choose:undefined} selected={picked} busy={disabled}/>;
    if(view==='registrations')return <Table title="Hồ sơ đăng ký" list={list} rows={rows} columns={registrationColumns} onSelect={choose} selected={picked} busy={disabled}/>;
    if(view==='classes')return <Table title="Danh sách lớp học" actions={panelActions} rows={classes} columns={classColumns} onSelect={r=>{if(choose(r)&&role==='Teacher')setTeachingClassId(String(r.class_id));}} selected={role==='Teacher'?teacherClass:picked} busy={disabled}/>;
    if(view==='placements')return <div className="ec-stack"><Table title="Hồ sơ đã duyệt" list={list} rows={rows} columns={registrationColumns} onSelect={choose} selected={picked} busy={disabled}/><p>Chỉ xếp hồ sơ đã thanh toán đủ học phí vào lớp còn chỗ và không trùng lịch.</p></div>;
    if(view==='schedules')return <Schedules client={client} role={role} busy={disabled} requestBusy={busy} feedback={feedback} run={run} read={read} revision={revision}/>;
    if(['attendance','gradebook','grade-reviews'].includes(view))return <Teaching key={view} view={view} classes={classes} client={client} busy={disabled} requestBusy={busy} feedback={feedback} run={run} read={read} revision={revision} selectedClassId={teachingClassId} onClassChange={setTeachingClassId}/>;
    if(view==='grades-own')return <Table title="Kết quả đã công bố" rows={rows} columns={['class_code','continuous_score','final_exam_score','final_score','passed','teacher_comment','finalized_at']}/>;
    if(view==='invoices-own')return <Table title="Chọn hồ sơ để xem hóa đơn" list={list} rows={rows} columns={['course_name','status','created_at']} onSelect={r=>{if(!choose(r))return;setData(old=>({...old,invoice:[]}));void read('invoices/detail',{registrationId:r.registration_id}).then(invoice=>setData(old=>({...old,invoice})));}} selected={picked} busy={disabled}/>;
    if(view==='invoices')return <Table title="Tra cứu hóa đơn" actions={panelActions} list={list} rows={rows} columns={invoiceColumns} onSelect={choose} selected={picked} busy={disabled}/>;
    if(view==='accounts')return <Table title="Tài khoản" actions={panelActions} list={list} rows={rows} columns={['full_name','email','role_code','status','phone']} onSelect={choose} selected={picked} busy={disabled}/>;
    if(view==='audit')return <Table title="Nhật ký thao tác" list={list} rows={rows} columns={['action_code','result_code','occurred_at','reason','change_details']}/>;
    if(view==='reports-finance'||view==='reports-director')return <div className="ec-stack"><div className="ec12-summary">{rows.flatMap((r,i)=>Object.entries(r).filter(([k])=>['billed','revenue','current_debt','classes','registrations','results'].includes(k)).map(([k,value])=><article key={i+k} className="ec-card"><p>{k==='billed'?'Đã phát hành':k==='revenue'?'Doanh thu':k==='current_debt'?'Công nợ hiện tại':display('status',r.status??r.passed??'')+' · '+(k==='classes'?'Lớp':k==='registrations'?'Hồ sơ':'Kết quả')}</p><strong>{display(k,value)}</strong></article>))}</div><p>Kỳ mặc định: từ đầu tháng trước đến cùng tháng năm sau. Công nợ là số dư chưa thanh toán hiện tại.</p>{view==='reports-finance'&&<a className="ec-button ec-button--secondary" href={'/api/dbms12/reports/finance.csv?'+new URLSearchParams(range())}>Xuất CSV</a>}</div>;
    if(view==='profile')return <Form key={String(me.row_version)} title="Thông tin cá nhân" busy={disabled} fields={[{name:'name',label:'Họ và tên',value:String(me.full_name)},{name:'phone',label:'Điện thoại',value:String(me.phone??''),max:10},{name:'birthDate',label:'Ngày sinh',type:'date',value:String(me.date_of_birth??'')},{name:'address',label:'Địa chỉ',required:false,max:255,value:String(me.address??'')}]} onSubmit={f=>run('profile/update',{accountVersion:me.row_version,name:f.name,phone:f.phone,birthDate:f.birthDate,address:f.address||null})}/>;
    return null;
  }
  const searchPanel=<Form title="Tìm kiếm" submit="Tìm" busy={disabled} fields={[{name:'search',label:view==='courses'?'Tên khóa học':'Họ tên hoặc email',required:false,value:search}]} onSubmit={async f=>{setSearch(f.search);setPanel(null);}}/>;
  return <div className="ec12-workspace ec-stack"><header className="ec-page-header"><h1>{title}</h1><Button variant="secondary" disabled={disabled} onClick={refresh}>Tải lại</Button></header>
    {feedback}
    {['registrations','invoices','accounts'].includes(view)&&<label className="ec-field ec12-filter"><span className="ec-label">Lọc trạng thái</span><select className="ec-input" value={state} disabled={disabled} onChange={e=>{setState(e.target.value);}}><option value="">Tất cả</option>{(view==='registrations'?['PENDING','CONFIRMED','ADMITTED','REJECTED','CANCELLED']:view==='invoices'?['UNPAID','PAID','CANCELLED']:['ACTIVE','LOCKED','DISABLED']).map(s=><option value={s} key={s}>{display('status',s)}</option>)}</select></label>}
    {(loading||initialListLoading)&&<p role="status">Đang tải dữ liệu…</p>}
    {contentReady?content():!loading&&!initialListLoading&&<p role="alert" className="ec-feedback ec-feedback--error">Không tải được dữ liệu. Hãy thử tải lại.</p>}
    {panel&&<SelectionDialog title={panel==='create'?'Tạo mới — '+title:'Tìm kiếm — '+title} busy={busy} onClose={()=>setPanel(null)}>{feedback}{panel==='create'?creation():searchPanel}</SelectionDialog>}
    {picked&&contentReady&&['courses','registrations','classes','placements','invoices-own','invoices','accounts'].includes(view)&&<SelectionDialog title={title+' — '+label(picked,['class_code','course_name','full_name','invoice_number'])} busy={busy} onClose={()=>setPicked(undefined)}>{feedback}{selection()}</SelectionDialog>}
  </div>;
}
function courseFields(row?:Row):Field[]{return [{name:'code',label:'Mã khóa học',max:50,value:String(row?.course_code??'')},{name:'name',label:'Tên khóa học',value:String(row?.course_name??'')},{name:'tuition',label:'Học phí (VND)',value:String(row?.tuition_fee??''),max:18},{name:'lessons',label:'Số buổi học',type:'number',value:String(row?.expected_lesson_count??'')},{name:'weight',label:'Trọng số điểm quá trình (%)',value:String(row?.process_weight??'40'),hint:'Điểm cuối khóa dùng trọng số còn lại.'}];}
