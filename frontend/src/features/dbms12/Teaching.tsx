import { useEffect, useState } from 'react';
import type { FormEvent, ReactNode } from 'react';
import { Button } from '../../components/ui/Button';
import type { Dbms12Client, Payload, Row } from './api';
import { label, range } from './api';
import { Form, SelectionDialog, Table } from './controls';
import { display } from './display';

export function Teaching({view,classes,client,busy,requestBusy,feedback,run,revision,selectedClassId,onClassChange}:{view:string;classes:Row[];client:Dbms12Client;busy:boolean;requestBusy:boolean;feedback:ReactNode;run:(path:string,args:Payload)=>Promise<boolean>;read:(path:string,args?:Payload)=>Promise<Row[]>;revision:number;selectedClassId:string;onClassChange:(id:string)=>void}) {
  const [schedule,setSchedule]=useState(''),[roster,setRoster]=useState<Row[]>([]),[rosterClassId,setRosterClassId]=useState(''),[schedules,setSchedules]=useState<Row[]>([]),[attendance,setAttendance]=useState<Row[]>([]),[report,setReport]=useState<Row>(),[notice,setNotice]=useState(''),[loading,setLoading]=useState(true),[attendanceLoading,setAttendanceLoading]=useState(true),[dirty,setDirty]=useState(false),[attendanceKey,setAttendanceKey]=useState('');
  const current=classes.find(c=>String(c.class_id)===selectedClassId)??classes[0];const classId=current?.class_id;
  const lesson=schedules.find(s=>String(s.schedule_id)===schedule)??schedules.find(s=>s.class_id===classId&&s.schedule_type==='LESSON');
  useEffect(()=>{
    let active=true;const timer=setTimeout(()=>{setLoading(true);setReport(undefined);setDirty(false);if(!classId){setLoading(false);return;}
      void Promise.all([client.read('classes/roster',{classId}),...(view==='attendance'?[client.read('schedules',range())]:[])]).then(([r,s])=>{if(active){setRoster(r);setRosterClassId(String(classId));setSchedules(s??[]);}}).catch(e=>{if(active)setNotice(e instanceof Error?e.message:'Không thể tải lớp.');}).finally(()=>{if(active)setLoading(false);});
    },0);return()=>{active=false;clearTimeout(timer);};
  },[client,classId,view,revision]);
  useEffect(()=>{
    let active=true;const timer=setTimeout(()=>{setAttendanceLoading(true);setDirty(false);if(view!=='attendance'||!lesson){setAttendance([]);return;}void client.read('attendance',{scheduleId:lesson.schedule_id}).then(r=>{if(active){setAttendance(r);setAttendanceKey(String(lesson.schedule_id)+'|'+revision);}}).catch(e=>{if(active)setNotice(e instanceof Error?e.message:'Không thể tải điểm danh.');}).finally(()=>{if(active)setAttendanceLoading(false);});},0);
    return()=>{active=false;clearTimeout(timer);};
  },[client,view,lesson,revision]);
  const choose=(id:string)=>{if(id===String(classId))return;if(document.querySelector('[data-dbms12-dirty="true"]')&&!window.confirm('Có dữ liệu chưa lưu. Bỏ thay đổi?'))return;onClassChange(id);setLoading(true);setRoster([]);setRosterClassId('');setSchedules([]);setAttendance([]);setAttendanceKey('');setSchedule('');setReport(undefined);setNotice('');};
  const manifest=roster.map(r=>({reportId:r.report_id,expectedVersion:r.report_version}));
  const ready=!!current&&!loading&&!busy&&rosterClassId===String(classId);
  const attendanceReady=ready&&!attendanceLoading&&attendanceKey===String(lesson?.schedule_id)+'|'+revision;
  const discard=()=>!document.querySelector('[data-dbms12-dirty="true"]')||window.confirm('Có dữ liệu chưa lưu. Bỏ thay đổi?');
  const reviewMessage=current?.grade_status==='FINALIZED'?'Bảng điểm đã công bố và không thể chỉnh sửa.':
    current?.grade_status==='SUBMITTED'?'Bảng điểm đang chờ duyệt. Bạn có thể trả lại để chỉnh sửa hoặc chốt và công bố toàn lớp.':
    current?.grade_status==='RETURNED'?'Bảng điểm đã được trả lại. Đang chờ giáo viên chỉnh sửa và gửi lại.':
    'Giáo viên chưa gửi bảng điểm. Giáo vụ chỉ có thể duyệt sau khi bảng điểm được gửi.';
  async function saveAttendance(event:FormEvent<HTMLFormElement>) {
    event.preventDefault();const form=new FormData(event.currentTarget);
    const items=attendance.flatMap(r=>{const present=form.get('present-'+r.class_assignment_id);return present==='1'||present==='0'?[{assignmentId:r.class_assignment_id,present:present==='1',expectedVersion:r.attendance_version}]:[];});
    if(!items.length){setNotice('Chưa chọn trạng thái điểm danh.');return;}
    if(await run('attendance/save',{scheduleId:lesson?.schedule_id,classVersion:current?.row_version,items}))setDirty(false);
  }
  return <div className="ec-stack"><label className="ec-field ec12-filter"><span className="ec-label">Chọn lớp</span><select className="ec-input" value={String(classId??'')} disabled={busy} onChange={e=>choose(e.target.value)}>{classes.map(c=><option key={String(c.class_id)} value={String(c.class_id)}>{label(c,['class_code','course_name'])+' · '+display('grade_status',c.grade_status)}</option>)}</select></label>
    {current&&<section className="ec-card ec-stack" aria-label="Thông tin lớp đang chọn">
      <h2>Thông tin lớp đang chọn</h2>
      <dl className="ec12-grid ec12-grid--two ec12-readonly">
        <div><dt className="ec-label">Mã lớp</dt><dd>{String(current.class_code)}</dd></div>
        <div><dt className="ec-label">Giáo viên phụ trách</dt><dd>{String(current.teacher_name)}</dd></div>
        <div><dt className="ec-label">Trạng thái lớp</dt><dd><span className={'ec-badge ec-badge--'+(current.status==='COMPLETED'?'success':current.status==='CANCELLED'?'danger':'info')}>{display('status',current.status)}</span></dd></div>
        <div><dt className="ec-label">Trạng thái bảng điểm</dt><dd><span className={'ec-badge ec-badge--'+(current.grade_status==='FINALIZED'?'success':current.grade_status==='RETURNED'?'warning':current.grade_status==='SUBMITTED'?'info':'neutral')}>{display('grade_status',current.grade_status)}</span></dd></div>
      </dl>
      {view==='grade-reviews'&&<p className="ec-feedback">{reviewMessage}</p>}
    </section>}
    {notice&&<p role="alert" className="ec-feedback ec-feedback--error">{notice}</p>}{loading&&<p role="status">Đang tải bảng lớp…</p>}
    {!current?<p>Chưa có lớp phù hợp.</p>:<>
      {view==='attendance'?<><label className="ec-field ec12-filter"><span className="ec-label">Buổi học</span><select className="ec-input" disabled={busy} value={String(lesson?.schedule_id??'')} onChange={e=>{if(discard()){setSchedule(e.target.value);setAttendanceKey('');}}}>{schedules.filter(s=>s.class_id===classId&&s.schedule_type==='LESSON').map(s=><option key={String(s.schedule_id)} value={String(s.schedule_id)}>{new Date(String(s.start_at)).toLocaleString('vi-VN',{timeZone:'Asia/Ho_Chi_Minh'})+' · '+s.room}</option>)}</select></label>
        {lesson&&<form key={attendanceKey} className="ec-card ec-stack" onSubmit={e=>void saveAttendance(e)} onChange={()=>setDirty(true)} data-dbms12-dirty={dirty?'true':undefined}><h2>Điểm danh học viên</h2><p>Để “Chưa nhập” nếu chưa có kết quả; không tự coi là vắng.</p><div className="ec-table-wrap ec12-list-viewport" role="region" aria-label="Điểm danh học viên" tabIndex={0}><table className="ec-table ec12-attendance"><thead><tr><th>Học viên</th><th>Trạng thái</th></tr></thead><tbody>{attendance.map(r=><tr key={String(r.class_assignment_id)}><td>{String(r.full_name)}</td><td><select className="ec-input" name={'present-'+r.class_assignment_id} aria-label={'Điểm danh '+r.full_name} disabled={!attendanceReady} defaultValue={r.present===null?'':r.present?'1':'0'}><option value="">Chưa nhập</option><option value="1">Có mặt</option><option value="0">Vắng</option></select></td></tr>)}</tbody></table></div><Button type="submit" disabled={!attendanceReady||current.status!=='ONGOING'}>Lưu điểm danh</Button></form>}</>:
        <><Table title="Bảng điểm toàn lớp" rows={rosterClassId===String(classId)?roster:[]} columns={['full_name','email','phone','continuous_score','final_exam_score','teacher_comment']} onSelect={view==='gradebook'?(r=>{if(discard())setReport(r);}):undefined} selected={report} busy={!ready}/>
          {view==='gradebook'&&report&&<SelectionDialog title={'Nhập điểm — '+report.full_name} busy={requestBusy} onClose={()=>setReport(undefined)}>{feedback}<Form key={String(report.report_id)+String(report.report_version)} title={'Nhập điểm: '+report.full_name} busy={!ready||!['ONGOING','COMPLETED'].includes(String(current.status))||!['DRAFT','RETURNED'].includes(String(current.grade_status))} fields={[{name:'continuous',label:'Điểm quá trình (0–100)',required:false,value:String(report.continuous_score??'')},{name:'final',label:'Điểm cuối khóa (0–100)',required:false,value:String(report.final_exam_score??'')},{name:'comment',label:'Nhận xét',required:false,max:1000,value:String(report.teacher_comment??'')}]} onSubmit={f=>run('grades/save',{reportId:report.report_id,reportVersion:report.report_version,classVersion:current.row_version,continuous:f.continuous||null,final:f.final||null,comment:f.comment||null})}/></SelectionDialog>}
          {view==='gradebook'&&['DRAFT','RETURNED'].includes(String(current.grade_status))&&<Button disabled={!ready||current.status!=='COMPLETED'} onClick={()=>{if(window.confirm('Gửi toàn bộ bảng điểm lớp cho giáo vụ?'))void run('grades/submit',{classId,classVersion:current.row_version,manifest});}}>Gửi bảng điểm toàn lớp</Button>}
          {view==='grade-reviews'&&current.grade_status==='SUBMITTED'&&<><Form title="Trả bảng điểm để chỉnh sửa" busy={!ready} fields={[{name:'reason',label:'Lý do trả lại',max:1000}]} submit="Trả bảng điểm" onSubmit={f=>run('grades/return',{classId,classVersion:current.row_version,manifest,reason:f.reason})}/><Button disabled={!ready} onClick={()=>{if(window.confirm('Chốt điểm toàn lớp? Sau khi công bố sẽ không thể sửa.'))void run('grades/finalize',{classId,classVersion:current.row_version,manifest});}}>Chốt và công bố toàn lớp</Button></>}
          {view!=='grade-reviews'&&<p>{current.grade_status==='FINALIZED'?'Bảng điểm đã công bố và không thể chỉnh sửa.':current.grade_status==='SUBMITTED'?'Bảng điểm đang chờ giáo vụ duyệt.':'Chỉ gửi khi lớp đã hoàn thành và toàn bộ học viên có đủ hai điểm.'}</p>}
        </>}
    </>}
  </div>;
}
