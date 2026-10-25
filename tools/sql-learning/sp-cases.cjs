const {manifest,call,course,registration,classroom,complete}=require('./common.cjs');
function build(name){
 const op=manifest.operations[name];let prep='',args={},error=0,after='',options={};
 const reason="N'Bài thực hành có rollback'";
 switch(name){
 case 'usp_CourseCreate':args={'@Code':'@Tag','@Name':"N'Khóa thực hành SP'",'@Tuition':"'1000000'",'@Lessons':'1','@Weight':"'40'"};after='SELECT course_code,course_name,tuition_fee FROM dbo.Course WHERE course_code=@Tag;';break;
 case 'usp_CourseUpdate':prep=course()+'SELECT @RV=row_version FROM dbo.Course WHERE course_id=@Course;';args={'@CourseId':'@Course','@ExpectedVersion':'@RV','@Name':"N'Đã sửa trong transaction'",'@Tuition':"'1200000'",'@Lessons':'1','@Weight':"'40'",'@Status':"'ACTIVE'"};after='SELECT course_name,tuition_fee FROM dbo.Course WHERE course_id=@Course;';break;
 case 'usp_RegistrationCreate':prep=course();args={'@CourseId':'@Course'};after='SELECT registration_id,status FROM dbo.Registration WHERE course_id=@Course;';break;
 case 'usp_RegistrationConfirm':case 'usp_RegistrationCancelOwn':case 'usp_AdmissionApprove':case 'usp_AdmissionReject':case 'usp_AdmissionCancel':
  prep=registration(['usp_AdmissionApprove','usp_AdmissionReject','usp_AdmissionCancel'].includes(name)?'CONFIRMED':'PENDING');args={'@RegistrationId':'@Reg','@ExpectedVersion':'@RegRV'};if(name.endsWith('Reject')||name==='usp_AdmissionCancel')args['@Reason']=reason;
  after='SELECT registration_id,status FROM dbo.Registration WHERE registration_id=@Reg; SELECT invoice_id,amount,paid_at FROM dbo.Invoice WHERE registration_id=@Reg;';break;
 case 'usp_InvoiceCollect':case 'usp_InvoiceCorrect':
  prep=registration('ADMITTED',name==='usp_InvoiceCorrect')+'SELECT @RV=row_version FROM dbo.Invoice WHERE invoice_id=@Invoice;';args={'@InvoiceId':'@Invoice','@ExpectedVersion':'@RV','@Method':"'CASH'",'@Reference':"N'LAB-REFERENCE'"};if(name==='usp_InvoiceCorrect')args['@Reason']=reason;
  after='SELECT invoice_id,paid_at,payment_method,payment_reference FROM dbo.Invoice WHERE invoice_id=@Invoice;';break;
 case 'usp_ClassCreate':prep=course();args={'@Code':'@Tag','@CourseId':'@Course','@TeacherId':'9','@Capacity':'15'};break;
 case 'usp_ClassEdit':case 'usp_ClassCancel':case 'usp_ClassOpen':
  prep=classroom(name==='usp_ClassOpen'); // OPEN->OPEN would fail; keep schedules but revert preparation to PLANNED below.
  if(name==='usp_ClassOpen')prep=classroom(false)+"INSERT dbo.Schedule(class_id,schedule_type,start_at,end_at,room) VALUES(@Class,'LESSON',@Start,DATEADD(hour,1,@Start),@Tag);\n";
  args={'@ClassId':'@Class','@ExpectedVersion':'@ClassRV'};if(name==='usp_ClassEdit')Object.assign(args,{'@TeacherId':'9','@Capacity':'10'});if(name==='usp_ClassCancel')args['@Reason']=reason;
  after='SELECT class_code,status,capacity FROM dbo.Class WHERE class_id=@Class;';break;
 case 'usp_ClassStart':
  prep=registration('ADMITTED',true)+"-- Lịch bắt đầu15giây nữa; đợi thời gian thật, không đổi đồng hồ/tắt guard.\nSET @Start=DATEADD(second,15,SYSUTCDATETIME());\n"+classroom(true,true)+"INSERT dbo.StudentClassAssignment(registration_id,class_id,assigned_by) VALUES(@Reg,@Class,3); INSERT dbo.GradeReport(class_assignment_id) VALUES(CONVERT(int,SCOPE_IDENTITY())); WAITFOR DELAY '00:00:16'; SELECT @ClassRV=row_version FROM dbo.Class WHERE class_id=@Class;";
  args={'@ClassId':'@Class','@ExpectedVersion':'@ClassRV'};after="SELECT class_code,status FROM dbo.Class WHERE class_id=@Class; IF NOT EXISTS(SELECT 1 FROM dbo.Class WHERE class_id=@Class AND status='ONGOING') THROW 51992,N'Lớp chưa ONGOING.',1;";break;
 case 'usp_ClassComplete':prep=complete().replace("UPDATE dbo.Class SET status='COMPLETED' WHERE class_id=2;",'');args={'@ClassId':'@Class','@ExpectedVersion':'@ClassRV'};after='SELECT class_code,status FROM dbo.Class WHERE class_id=@Class;';break;
 case 'usp_PlacementCreate':prep=registration('ADMITTED',true)+classroom(true,true);args={'@RegistrationId':'@Reg','@RegistrationVersion':'@RegRV','@ClassId':'@Class','@ClassVersion':'@ClassRV'};after='SELECT a.class_assignment_id,g.report_id FROM dbo.StudentClassAssignment a JOIN dbo.GradeReport g ON g.class_assignment_id=a.class_assignment_id WHERE a.registration_id=@Reg;';break;
 case 'usp_ScheduleBatch':prep=classroom(false)+"INSERT @Schedules VALUES(1,'LESSON',@Start,DATEADD(hour,1,@Start),@Tag);";args={'@ClassId':'@Class','@ClassVersion':'@ClassRV','@Items':'@Schedules'};after='SELECT schedule_type,start_at,end_at FROM dbo.Schedule WHERE class_id=@Class;';break;
 case 'usp_ScheduleMove':prep=classroom(true)+"SELECT @Schedule=schedule_id,@RV=row_version FROM dbo.Schedule WHERE class_id=@Class AND schedule_type='LESSON'; SET @Start=DATEADD(day,2,@Start); DECLARE @End datetime2(3)=DATEADD(hour,1,@Start);";args={'@ScheduleId':'@Schedule','@ExpectedVersion':'@RV','@Start':'@Start','@End':'@End','@Room':'@Tag','@Reason':reason};break;
 case 'usp_ScheduleHeld':prep="SELECT @Schedule=schedule_id,@RV=row_version FROM dbo.Schedule WHERE class_id=2 AND schedule_type='LESSON';";args={'@ScheduleId':'@Schedule','@ExpectedVersion':'@RV'};after='SELECT held_at,held_by FROM dbo.Schedule WHERE schedule_id=@Schedule;';break;
 case 'usp_AttendanceSave':prep="SET @Class=2; SELECT @ClassRV=row_version FROM dbo.Class WHERE class_id=2; SELECT @Schedule=schedule_id FROM dbo.Schedule WHERE class_id=2 AND schedule_type='LESSON'; INSERT @Attendance SELECT a.class_assignment_id,1,t.row_version FROM dbo.StudentClassAssignment a LEFT JOIN dbo.Attendance t ON t.class_assignment_id=a.class_assignment_id AND t.schedule_id=@Schedule WHERE a.class_id=2;";args={'@ScheduleId':'@Schedule','@ClassVersion':'@ClassRV','@Items':'@Attendance'};break;
 case 'usp_GradeSave':prep='SELECT TOP(1) @Report=g.report_id,@RV=g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=2 ORDER BY g.report_id; SELECT @ClassRV=row_version FROM dbo.Class WHERE class_id=2;';args={'@ReportId':'@Report','@ReportVersion':'@RV','@ClassVersion':'@ClassRV','@Continuous':"'70'",'@Final':"'85'",'@Comment':reason};after='SELECT report_id,continuous_score,final_exam_score FROM dbo.GradeReport WHERE report_id=@Report;';break;
 case 'usp_GradeSubmit':case 'usp_GradeReturn':case 'usp_GradeFinalize':
  prep=complete();if(name!=='usp_GradeSubmit')prep+=call('usp_GradeSubmit',{'@ClassId':'@Class','@ClassVersion':'@ClassRV','@Manifest':'@Grades'})+'SELECT @ClassRV=row_version FROM dbo.Class WHERE class_id=@Class;';
  args={'@ClassId':'@Class','@ClassVersion':'@ClassRV','@Manifest':'@Grades'};if(name==='usp_GradeReturn')args['@Reason']=reason;after='SELECT class_code,status,grade_status FROM dbo.v_ClassState WHERE class_id=@Class;';break;
 case 'usp_ProfileUpdate':prep='SELECT @RV=row_version FROM dbo.Account WHERE account_id=7;';args={'@AccountVersion':'@RV','@Name':"N'Học viên thực hành'",'@Phone':"'0901234567'",'@BirthDate':"'2000-01-01'",'@Address':"N'Địa chỉ mẫu'"};after='SELECT full_name,phone FROM dbo.Account WHERE account_id=7;';break;
 case 'usp_AccountCreateStaff':args={'@Role':"'Teacher'",'@Email':'@Email','@Name':"N'Giáo viên thực hành'",'@Phone':'NULL','@PasswordHash':'@Hash'};after='SELECT account_id,role_code,temp_issued_at FROM dbo.Account WHERE email=@Email;';break;
 case 'usp_AccountSetStatus':case 'usp_AccountResetPassword':prep='SELECT @RV=row_version FROM dbo.Account WHERE account_id=10;';args={'@AccountId':'10','@AccountVersion':'@RV'};if(name==='usp_AccountSetStatus')args['@Status']="'LOCKED'";else args['@PasswordHash']='@Hash';after='SELECT account_id,status,temp_issued_at FROM dbo.Account WHERE account_id=10;';break;
 case 'usp_StudentSignup':args={'@Email':'@Email','@Name':"N'Học viên thực hành'",'@Phone':'NULL','@BirthDate':"'2000-01-01'",'@Address':'NULL','@PasswordHash':'@Hash'};break;
 case 'usp_LoginRead':prep='CREATE TABLE #CredentialRead(account_id int,password_hash varchar(512),security_version bigint,status varchar(16),temp_issued_at datetime2(3),login_throttled_until datetime2(3),row_version binary(8));';args={'@Email':"'s3@dbms12.example'"};options.capture='#CredentialRead';after='SELECT account_id,status FROM #CredentialRead; DROP TABLE #CredentialRead;';break;
 case 'usp_LoginRecord':prep='CREATE TABLE #LoginResult(authenticated bit,result_code varchar(16),security_version bigint);';args={'@AccountId':'10','@ObservedHash':'@Hash','@ObservedEpoch':'@Epoch','@Accepted':'1','@Sid':'@NewSid'};options={id:10,capture:'#LoginResult'};after='SELECT authenticated,result_code FROM #LoginResult; DROP TABLE #LoginResult;';break;
 case 'usp_PasswordChange':options.id=10;args={'@ObservedHash':'@Hash','@NewHash':'@Hash'};after='SELECT account_id,CONVERT(bit,CASE WHEN temp_issued_at IS NULL THEN 1 ELSE 0 END) AS normal_password_scope FROM dbo.Account WHERE account_id=10;';break;
 case 'usp_Logout':case 'usp_SessionTouch':options.id=10;break;
 case 'usp_OperatorBootstrap':args={'@Email':'@Email','@Name':"N'Bootstrap lab'",'@PasswordHash':'@Hash'};error=51236;break;
 case 'usp_MaintenanceCleanup':break;
 case 'usp_CurrentSession':break;
 case 'usp_CourseList':case 'usp_RegistrationList':case 'usp_ClassList':case 'usp_AdminAccountList':case 'usp_AuditList':case 'usp_InvoiceSearch':case 'usp_TeacherOptions':case 'usp_StudentHome':case 'usp_StudentGrades':break;
 case 'usp_InvoiceRead':args={'@RegistrationId':'1'};break;
 case 'usp_ClassRoster':args={'@ClassId':'2'};break;
 case 'usp_ScheduleList':case 'usp_FinanceReport':case 'usp_DirectorReport':case 'usp_FinanceExport':args={'@From':'@From','@Until':'@Until'};break;
 case 'usp_AttendanceRead':prep="SELECT @Schedule=schedule_id FROM dbo.Schedule WHERE class_id=2 AND schedule_type='LESSON';";args={'@ScheduleId':'@Schedule'};break;
 case 'usp_WeeklySchedulePreview':prep=classroom(false)+'DECLARE @Day date=CONVERT(date,@Start);';args={'@ClassId':'@Class','@FromDate':'@Day','@UntilDate':'@Day','@Weekdays':"'1234567'",'@StartTime':"'09:00'",'@EndTime':"'10:00'",'@Room':'@Tag'};break;
 case 'usp_ReplayLookup':prep=course()+call('usp_RegistrationCreate',{'@CourseId':'@Course'});args={'@Action':"'DBMS12.STUDENT.REGISTRATION.CREATE'",'@RequestId':'@Request'};break;
 default:throw Error('No independent example '+name);
 }
 const snapshot=phase=>`SELECT N'${phase}' AS phase,(SELECT COUNT(*) FROM dbo.Course) AS courses,(SELECT COUNT(*) FROM dbo.Registration) AS registrations,(SELECT COUNT(*) FROM dbo.Invoice) AS invoices,(SELECT COUNT(*) FROM dbo.StudentClassAssignment) AS placements,(SELECT COUNT(*) FROM dbo.AuditLog) AS audits,(SELECT COUNT(*) FROM dbo.ReplayOperation) AS receipts,(SELECT COUNT(*) FROM dbo.AuthSession) AS sessions;\n`;
 return {body:prep+'\n-- TRƯỚC: dữ liệu chuẩn bị ở trên chỉ thuộc fixture và sẽ rollback.\n'+snapshot('TRUOC')+call(name,args,options)+'\n-- SAU: quan sát kết quả trước khi rollback.\n'+after+'\n'+snapshot('SAU')+(op.kind==='command'?'\nSELECT operation_id,target_id,replayed FROM #Results;':''),error};
}
module.exports={build};
