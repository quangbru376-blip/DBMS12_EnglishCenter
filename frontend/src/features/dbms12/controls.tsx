import { useEffect, useRef, useState } from 'react';
import type { FormEvent, ReactNode } from 'react';
import { Button } from '../../components/ui/Button';
import { Modal } from '../../components/ui/Modal';
import type { Row } from './api';
import { display } from './display';
import type { ScrollList } from './useScrollList';

export type Field = { name: string; label: string; type?: string; value?: string | number; required?: boolean; options?: {value:string | number;label:string}[]; max?: number; hint?: string };
export function Form({title,fields,onSubmit,busy,submit='Lưu',children,horizontal=false}:{title:string;fields:Field[];onSubmit:(values:Record<string,string>)=>Promise<void|boolean>;busy:boolean;submit?:string;children?:ReactNode;horizontal?:boolean}) {
  const [dirty,setDirty]=useState(false),[error,setError]=useState('');
  async function save(event:FormEvent<HTMLFormElement>) { event.preventDefault(); const form=event.currentTarget; setError(''); try { const result=await onSubmit(Object.fromEntries(new FormData(form).entries()) as Record<string,string>); if(result!==false)setDirty(false); } catch(e) {setError(e instanceof Error?e.message:'Không thể lưu thông tin.');} }
  return <section className={'ec-card'+(horizontal?' ec12-create-panel':'')}><h2>{title}</h2><form className="ec-stack" onSubmit={e=>void save(e)} onChange={()=>setDirty(true)} data-dbms12-dirty={dirty?'true':undefined}><fieldset disabled={busy} className="ec12-fields">
    {fields.map(f=><label className="ec-field" key={f.name}><span className="ec-label">{f.label}</span>{f.options?<select className="ec-input" name={f.name} defaultValue={f.value??''} required={f.required!==false}><option value="">Chọn…</option>{f.options.map(o=><option key={o.value} value={o.value}>{o.label}</option>)}</select>:<input className="ec-input" name={f.name} type={f.type??'text'} defaultValue={f.value??''} required={f.required!==false} maxLength={f.max??200} autoComplete={f.type==='password'?'off':undefined}/>} {f.hint&&<span className="ec-field-hint">{f.hint}</span>}</label>)}
    {error&&<p role="alert" className="ec-feedback ec-feedback--error">{error}</p>}{children}<Button type="submit" disabled={busy} pending={busy}>{submit}</Button></fieldset></form></section>;
}
const terms:Record<string,string>={
  course_code:'Mã khóa học',course_name:'Khóa học',tuition_fee:'Học phí',expected_lesson_count:'Số buổi dự kiến',process_weight:'Trọng số quá trình (%)',
  full_name:'Họ và tên',email:'Email',phone:'Điện thoại',status:'Trạng thái',created_at:'Ngày tạo',decision_reason:'Lý do',
  class_code:'Lớp',teacher_name:'Giáo viên',capacity:'Sức chứa',assigned_count:'Đã xếp',grade_status:'Bảng điểm',lesson_count:'Buổi học',exam_count:'Buổi thi',unheld_count:'Chưa tổ chức',missing_attendance:'Chưa điểm danh',progress_percent:'Tiến độ (%)',
  schedule_type:'Loại buổi',start_at:'Bắt đầu',end_at:'Kết thúc',room:'Phòng',schedule_status:'Tổ chức',present:'Điểm danh',recorded_at:'Lần cập nhật',
  continuous_score:'Điểm quá trình',final_exam_score:'Điểm cuối khóa',total_score:'Điểm tổng',grade_total:'Điểm tổng',final_score:'Điểm tổng',passed:'Kết quả',teacher_comment:'Nhận xét',finalized_at:'Ngày công bố',last_return_reason:'Lý do trả lại',
  invoice_number:'Số hóa đơn',amount:'Số tiền',issued_at:'Ngày phát hành',paid_at:'Ngày thanh toán',payment_method:'Phương thức',payment_reference:'Tham chiếu',invoice_status:'Hóa đơn',due_date:'Hạn thanh toán',debt_flag:'Công nợ',
  role_code:'Vai trò',action_code:'Thao tác',result_code:'Kết quả',occurred_at:'Thời điểm',reason:'Lý do',change_details:'Nội dung',next_action:'Bước tiếp theo',
  billed:'Đã phát hành',revenue:'Doanh thu',current_debt:'Công nợ hiện tại',registrations:'Hồ sơ',classes:'Số lớp',results:'Học viên',
};
export function RecordDetails({row,columns}:{row:Row;columns:string[]}) {
  return <dl className="ec12-grid ec12-grid--two ec12-readonly">{columns.map(key=><div key={key}><dt className="ec-label">{terms[key]??key}</dt><dd>{display(key,row[key])}</dd></div>)}</dl>;
}
export function SelectionDialog({title,children,busy,onClose}:{title:string;children:ReactNode;busy:boolean;onClose:()=>void}) {
  const body=useRef<HTMLDivElement>(null);
  const close=()=>{
    if(body.current?.querySelector('[data-dbms12-dirty="true"]')&&!window.confirm('Có dữ liệu chưa lưu. Đóng và bỏ thay đổi?'))return;
    onClose();
  };
  return <Modal open title={title} className="ec12-selection" closeDisabled={busy} onRequestClose={close}><div ref={body} className="ec-stack" aria-busy={busy}>{busy&&<p role="status">Đang xử lý…</p>}{children}</div></Modal>;
}
export function Table({title,rows,columns,onSelect,selected,busy=false,list,actions}:{title:string;rows:Row[];columns:string[];onSelect?:(r:Row)=>void;selected?:Row;busy?:boolean;list?:ScrollList;actions?:ReactNode}) {
  const visible=rows.filter(r=>columns.some(k=>k in r));
  const viewport=useRef<HTMLDivElement>(null),end=useRef<HTMLDivElement>(null);
  const more=list?.hasMore,loading=list?.loading,error=list?.error,loadMore=list?.loadMore;
  useEffect(()=>{
    if(!more||loading||error||busy||!viewport.current||!end.current)return;
    const observer=new IntersectionObserver(entries=>{if(!window.matchMedia('print').matches&&entries.some(e=>e.isIntersecting))loadMore?.();},{root:viewport.current,rootMargin:'0px 0px 80px 0px'});
    observer.observe(end.current);return()=>observer.disconnect();
  },[more,loading,error,busy,loadMore,visible.length]);
  return <section className="ec-card ec12-table-panel ec-stack">{actions?<div className="ec12-table-header"><h2>{title}</h2><div className="ec12-panel-actions">{actions}</div></div>:<h2>{title}</h2>}
    {visible.length===0&&!error?<p className="ec-feedback ec-feedback--empty">Chưa có dữ liệu phù hợp.</p>:<div ref={viewport} className="ec-table-wrap ec12-list-viewport" role="region" aria-label={title} tabIndex={0}>
      {visible.length>0&&<table className="ec-table"><thead><tr>{columns.map(c=><th key={c} scope="col">{terms[c]??c}</th>)}{onSelect&&<th scope="col">Thao tác</th>}</tr></thead><tbody>{visible.map((r,i)=><tr key={i} aria-selected={selected===r}>{columns.map(c=><td key={c}>{display(c,r[c]??null)}</td>)}{onSelect&&<td><Button variant={selected===r?'primary':'secondary'} disabled={busy} onClick={()=>onSelect(r)}>Chọn</Button></td>}</tr>)}</tbody></table>}
      {list&&<div ref={end} className="ec12-list-end">
        {error?<><p role="alert" className="ec-feedback ec-feedback--error">{error}</p><Button variant="secondary" disabled={busy} onClick={loadMore}>Thử tải lại danh sách</Button></>:
          loading?<p role="status">Đang tải thêm…</p>:more?<Button variant="secondary" disabled={busy} onClick={loadMore}>Tải thêm bản ghi</Button>:<p>Đã hiển thị hết danh sách.</p>}
      </div>}
    </div>}
    {list&&<p className="ec12-list-count" role="status">Đang hiển thị {visible.length}{list.total!==null?' / '+list.total:''} bản ghi{more?' · Cuộn xuống để xem thêm.':'.'}</p>}
  </section>;
}
