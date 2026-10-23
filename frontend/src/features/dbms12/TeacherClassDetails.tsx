import { useEffect, useRef, useState } from 'react';
import { Button } from '../../components/ui/Button';
import type { Dbms12Client, Row } from './api';
import { Table } from './controls';
import { display } from './display';

export function TeacherClassDetails({classRow,client,busy,onOpen,revision}:{classRow:Row;client:Dbms12Client;busy:boolean;onOpen:(view:string)=>void;revision:number}) {
  const [roster,setRoster]=useState<Row[]>([]),[loading,setLoading]=useState(true),[error,setError]=useState(''),[attempt,setAttempt]=useState(0);
  const heading=useRef<HTMLHeadingElement>(null);
  const classId=classRow.class_id;
  useEffect(()=>{
    let active=true;
    const timer=setTimeout(()=>{
      setLoading(true);setError('');setRoster([]);
      heading.current?.focus({preventScroll:true});heading.current?.scrollIntoView({block:'nearest'});
      void client.read('classes/roster',{classId}).then(rows=>{if(active)setRoster(rows);})
        .catch(e=>{if(active)setError(e instanceof Error?e.message:'Không thể tải danh sách học viên.');})
        .finally(()=>{if(active)setLoading(false);});
    },0);
    return()=>{active=false;clearTimeout(timer);};
  },[client,classId,attempt,revision]);
  return <section className="ec-card ec-stack" aria-label={'Chi tiết lớp '+classRow.class_code}>
    <h2 ref={heading} tabIndex={-1}>Chi tiết lớp {String(classRow.class_code)}</h2>
    <div className="ec12-grid ec12-grid--two">
      <p><strong>Khóa học: </strong>{String(classRow.course_name)}</p>
      <p><strong>Trạng thái: </strong>{display('status',classRow.status)}</p>
      <p><strong>Sĩ số: </strong>{String(classRow.assigned_count)} / {String(classRow.capacity)}</p>
      <p><strong>Bảng điểm: </strong>{display('grade_status',classRow.grade_status)}</p>
    </div>
    <div className="ec-actions">
      <Button variant="secondary" disabled={busy} onClick={()=>onOpen('attendance')}>Điểm danh lớp này</Button>
      <Button variant="secondary" disabled={busy} onClick={()=>onOpen('gradebook')}>Bảng điểm lớp này</Button>
    </div>
    {loading?<p role="status">Đang tải danh sách học viên…</p>:error?<div className="ec-stack"><p role="alert" className="ec-feedback ec-feedback--error">{error}</p><Button variant="secondary" disabled={busy} onClick={()=>setAttempt(n=>n+1)}>Tải lại danh sách học viên</Button></div>:
      <Table title="Danh sách học viên" rows={roster} columns={['full_name','email','phone']}/>}
  </section>;
}
