import type { Row } from './api';
const statuses:Record<string,string>={PENDING:'Chờ xác nhận',CONFIRMED:'Đã xác nhận',ADMITTED:'Đã duyệt',REJECTED:'Từ chối',CANCELLED:'Đã hủy',PLANNED:'Chuẩn bị',OPEN:'Đang nhận học viên',ONGOING:'Đang học',COMPLETED:'Hoàn thành',DRAFT:'Bản nháp',SUBMITTED:'Chờ giáo vụ duyệt',RETURNED:'Đã trả lại',FINALIZED:'Đã công bố',ACTIVE:'Đang hoạt động',INACTIVE:'Ngừng tuyển',LOCKED:'Tạm khóa',DISABLED:'Ngừng sử dụng',UNPAID:'Chưa thanh toán',PAID:'Đã thanh toán',DUE:'Trong hạn',OVERDUE:'Quá hạn',SETTLED:'Đã tất toán',LESSON:'Buổi học',FINAL_EXAM:'Thi cuối khóa',HELD:'Đã tổ chức',CASH:'Tiền mặt',BANK_TRANSFER:'Chuyển khoản',CONFIRM:'Xác nhận hồ sơ',WAIT_ADMISSION:'Chờ tuyển sinh duyệt',PAY:'Thanh toán học phí',WAIT_PLACEMENT:'Chờ xếp lớp',VIEW_RESULT:'Xem kết quả',VIEW_CLASS:'Xem lớp học',CLOSED:'Đã kết thúc',Student:'Học viên',Admissions:'Tuyển sinh',AcademicAffairs:'Giáo vụ',Teacher:'Giáo viên',Accountant:'Kế toán',Director:'Giám đốc',Admin:'Quản trị viên'};
export function display(key:string,v:Row[string]):string {
  if(v===null||v===undefined)return 'Chưa có';
  if(typeof v==='boolean')return key==='passed'?(v?'Đạt':'Chưa đạt'):v?'Có mặt':'Vắng';
  const s=String(v); if(statuses[s])return statuses[s];
  if(['tuition_fee','amount','billed','revenue','current_debt'].includes(key))return s.replace(/\B(?=(\d{3})+(?!\d))/g,'.')+' đ';
  if(/_at$/.test(key)&&!Number.isNaN(Date.parse(s)))return new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(s));
  return s;
}
