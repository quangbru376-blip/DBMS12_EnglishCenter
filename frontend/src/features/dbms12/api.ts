export type Row = Record<string, string | number | boolean | null>;
export type Payload = Record<string, unknown>;
type ResponseData = { rows?: Row[]; requestToken?: string; temporaryPassword?: string | null; message?: string; code?: string };
export class ApiFailure extends Error {
  constructor(public status: number, public code: string, message: string) { super(message); }
}
export type PendingCommand = { route: string; requestId: string; action: string };
const actions: Record<string,string> = {
  'courses/create':'ACADEMIC.COURSE.CREATE','courses/update':'ACADEMIC.COURSE.UPDATE',
  'registrations/create':'STUDENT.REGISTRATION.CREATE','registrations/confirm':'STUDENT.REGISTRATION.CONFIRM','registrations/cancel-own':'STUDENT.REGISTRATION.CANCEL',
  'admissions/approve':'ADMISSIONS.REGISTRATION.APPROVE','admissions/reject':'ADMISSIONS.REGISTRATION.REJECT','admissions/cancel':'ADMISSIONS.REGISTRATION.CANCEL',
  'invoices/collect':'FINANCE.INVOICE.COLLECT','invoices/correct':'FINANCE.INVOICE.CORRECT',
  'classes/create':'ACADEMIC.CLASS.CREATE','classes/edit':'ACADEMIC.CLASS.EDIT','classes/open':'ACADEMIC.CLASS.OPEN','classes/start':'ACADEMIC.CLASS.START',
  'classes/complete':'ACADEMIC.CLASS.COMPLETE','classes/cancel':'ACADEMIC.CLASS.CANCEL','placements':'ACADEMIC.PLACEMENT.CREATE',
  'schedules/batch':'ACADEMIC.SCHEDULE.BATCH','schedules/move':'ACADEMIC.SCHEDULE.MOVE','schedules/held':'ACADEMIC.SCHEDULE.HELD',
  'attendance/save':'TEACHER.ATTENDANCE.SAVE','grades/save':'TEACHER.GRADE.SAVE','grades/submit':'TEACHER.GRADE.SUBMIT',
  'grades/return':'ACADEMIC.GRADE.RETURN','grades/finalize':'ACADEMIC.GRADE.FINALIZE','profile/update':'AUTH.PROFILE.UPDATE',
  'accounts/create':'ADMIN.ACCOUNT.CREATE','accounts/status':'ADMIN.ACCOUNT.STATUS','accounts/reset-password':'ADMIN.ACCOUNT.RESET',
};
export class Dbms12Client {
  private csrf: string | null = null;
  private controllers = new Set<AbortController>();
  pending: PendingCommand | null = null;
  private onUnauthorized: () => void = () => {};
  subscribeUnauthorized(handler: () => void) { this.onUnauthorized=handler; return () => { this.onUnauthorized=()=>{}; }; }
  clear() { this.csrf=null; this.pending=null; for(const c of this.controllers)c.abort(); this.controllers.clear(); }
  async request(route: string, body?: Payload, requestId?: string): Promise<ResponseData> {
    const controller = new AbortController(); this.controllers.add(controller);
    try {
      const headers: Record<string,string> = {};
      if(body!==undefined) {
        if(!this.csrf) this.csrf=(await this.request('auth/csrf')).requestToken ?? null;
        if(!this.csrf)throw new Error('Chưa xác minh được yêu cầu. Hãy tải lại trang.');
        headers['X-CSRF-TOKEN']=this.csrf; headers['Content-Type']='application/json';
      }
      if(requestId)headers['Idempotency-Key']=requestId;
      const r=await fetch('/api/dbms12/'+route,{method:body===undefined?'GET':'POST',body:body===undefined?undefined:JSON.stringify(body),headers,credentials:'same-origin',cache:'no-store',signal:controller.signal});
      const value: ResponseData=r.status===204?{}:await r.json() as ResponseData;
      if(!r.ok) {
        if(r.status===401) { this.csrf=null; this.onUnauthorized(); }
        throw new ApiFailure(r.status,value.code??'REQUEST_FAILED',value.message??'Không thể xử lý yêu cầu.');
      }
      return value;
    } finally { this.controllers.delete(controller); }
  }
  async read(route: string, params: Payload = {}) {
    const query=new URLSearchParams(); for(const [k,v] of Object.entries(params))if(v!==null&&v!==undefined&&v!=='')query.set(k,String(v));
    return (await this.request(route+(query.size?'?'+query.toString():''))).rows??[];
  }
  async auth(route: string, body: Payload) { const result=await this.request('auth/'+route,body); this.csrf=null; return result; }
  async command(route: string, body: Payload) {
    if(this.pending)throw new Error('Cần kiểm tra kết quả thao tác trước trước khi gửi lệnh mới.');
    const requestId=crypto.randomUUID();const command={route,requestId,action:'DBMS12.'+actions[route]};
    this.pending=command;
    try { const result=await this.request(route,body,requestId); this.pending=null; return result; }
    catch(e) { if(e instanceof ApiFailure&&e.status<500)this.pending=null; throw e; }
  }
  async lookup() {
    if(!this.pending)return [];
    const rows=await this.read('operations',{action:this.pending.action,requestId:this.pending.requestId});
    if(rows.length)this.pending=null;return rows;
  }
}
export function number(value: unknown) { const n=Number(value); if(!Number.isInteger(n)||n<1)throw new Error('Vui lòng chọn thông tin hợp lệ.'); return n; }
export function value(row: Row | undefined, key: string) { return row?.[key]??null; }
export function label(row: Row, keys: string[]) { return keys.map(k=>row[k]).filter(v=>v!==null&&v!==undefined).join(' · '); }
export function range() { const now=new Date(); return {from:new Date(now.getFullYear(),now.getMonth()-1,1).toISOString(),until:new Date(now.getFullYear()+1,now.getMonth(),1).toISOString()}; }
