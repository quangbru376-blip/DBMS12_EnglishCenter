const fs=require('fs'),path=require('path');
const project=path.resolve(__dirname,'../..'),sql=path.join(project,'database/dbms12-compact');
const manifest=JSON.parse(fs.readFileSync(path.join(sql,'manifest.json'),'utf8'));
const roles={Admin:[1,'Dbms12Admin'],Admissions:[2,'Dbms12Admissions'],AcademicAffairs:[3,'Dbms12AcademicAffairs'],Teacher:[4,'Dbms12Teacher'],Accountant:[5,'Dbms12Accountant'],Director:[6,'Dbms12Director'],Student:[7,'Dbms12Student']};
const guard=`SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
DECLARE @LabGuid uniqueidentifier=TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'ec12_learning_guid'));
IF @LabGuid IS NULL OR DB_NAME() NOT LIKE 'EnglishCenter[_]DBMS12[_]PROJECT[_]%'
 OR NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid=@LabGuid)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'DBMS12_LearningFixture' AND TRY_CONVERT(uniqueidentifier,CONVERT(nvarchar(36),value))=@LabGuid)
 THROW 51990,N'Chạy SSMS_SESSION.sql của learning fixture trước; không dùng database chính.',1;
IF @@TRANCOUNT<>0 OR USER_NAME()<>'dbo' THROW 51990,N'Dùng connection owner mới, không có transaction đang mở.',1;
`;
const variables=`DECLARE @Tag varchar(32)='LAB-'+LEFT(CONVERT(varchar(36),NEWID()),8),
 @Course int,@Class int,@Reg int,@Invoice int,@Schedule int,@Report int,
 @RV binary(8),@ClassRV binary(8),@RegRV binary(8),@Sid binary(32),@Epoch bigint,
 @Request uniqueidentifier,@Digest binary(32),@Switched bit=0,@Start datetime2(3)=DATEADD(day,120,SYSUTCDATETIME()),
 @From datetime2(3)=DATEADD(day,-365,SYSUTCDATETIME()),@Until datetime2(3)=DATEADD(day,366,SYSUTCDATETIME()),
 @Hash varchar(512),@NewSid binary(32)=CRYPT_GEN_RANDOM(32),@Email varchar(255);
SET @Email=@Tag+'@lab.invalid';
SELECT @Start=DATEADD(day,7,ISNULL(MAX(s.end_at),DATEADD(day,90,SYSUTCDATETIME()))) FROM dbo.Schedule s JOIN dbo.Class c ON c.class_id=s.class_id WHERE c.teacher_account_id=9;
DECLARE @Schedules dbo.ScheduleBatch,@Attendance dbo.AttendanceBatch,@Grades dbo.GradeManifest;
CREATE TABLE #Actors(account_id int PRIMARY KEY,sid binary(32),epoch bigint);
INSERT #Actors SELECT account_id,CRYPT_GEN_RANDOM(32),security_version FROM dbo.Account WHERE account_id BETWEEN 1 AND 10;
CREATE TABLE #Results(operation_id uniqueidentifier,target_id int,replayed bit);
SELECT @Hash=password_hash FROM dbo.Account WHERE account_id=10;
`;
function wrap(name,body,{error=0,sp=false}={}){
 return `-- Bài chạy riêng: ${name}. Nguồn định nghĩa ở OBJECT_INDEX.md; đây là câu gọi/quan sát.
-- Mặc định ROLLBACK toàn bộ dữ liệu thử. IDENTITY/SEQUENCE/rowversion có thể có khoảng trống.
${guard}${sp?variables:`DECLARE @Switched bit=0,@Tag varchar(32)='LAB-'+LEFT(CONVERT(varchar(36),NEWID()),8);\n`}
BEGIN TRY
 BEGIN TRANSACTION;
${sp?` INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at) SELECT sid,account_id,SYSUTCDATETIME(),SYSUTCDATETIME() FROM #Actors;\n`:''}
${body}
${error?` THROW 51991,N'Không xuất hiện lỗi mong đợi ${error}.',1;`:` IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 ROLLBACK TRANSACTION;
 SELECT N'${name}' AS case_name,N'PASS_ROLLBACK' AS result,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|${name}';`}
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
${error?` IF @Error<>${error} THROW;
 SELECT N'${name}' AS case_name,@Error AS expected_error,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|${name}';`:` THROW;`}
END CATCH;
${sp?'DROP TABLE #Actors; DROP TABLE #Results;':''}
`;
}
function call(name,args={},options={}){
 const op=manifest.operations[name];if(!op)throw Error('Unknown module '+name);
 const role=options.role??op.sqlRoles[0],id=options.id??roles[role]?.[0];
 const user=op.context==='business'?roles[role][1]:op.context==='authentication'?'Dbms12ProjectRuntime':null;
 let s=`-- Gọi thật ${name} dưới ${user??'owner/operator'}; không truyền Actor từ browser.\n`;
 if(op.parameters.some(p=>p.name==='@Sid'))s+=`SELECT @Sid=sid,@Epoch=epoch FROM #Actors WHERE account_id=${id??7};\n`;
 if(op.kind==='command')s+=`SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('${name}|',@Tag,'|',CONVERT(varchar(36),@Request)));\n`;
 const standard={'@Sid':'@Sid','@Epoch':'@Epoch','@RequestId':'@Request','@Digest':'@Digest'};
 const list=op.parameters.map(p=>{
  if(args[p.name]!==undefined)return p.name+'='+args[p.name];
  if(standard[p.name])return p.name+'='+standard[p.name];
  if(p.default!==null)return null;
  throw Error('Missing argument '+name+' '+p.name);
 }).filter(Boolean).join(',');
 if(user)s+=`EXECUTE AS USER='${user}'; SET @Switched=1;\n`;
 s+=`${options.capture?'INSERT '+options.capture+' ':op.kind==='command'?'INSERT #Results ':''}EXEC dbo.${name} ${list};\n`;
 if(user)s+='REVERT; SET @Switched=0;\n';
 return s;
}
const course=()=>`INSERT dbo.Course(course_code,course_name,tuition_fee,expected_lesson_count,process_weight) VALUES(@Tag,N'Khóa thực hành',1000000,1,40); SET @Course=CONVERT(int,SCOPE_IDENTITY());\n`;
const registration=(state='PENDING',paid=false)=>course()+`INSERT dbo.Registration(student_account_id,course_id) VALUES(7,@Course); SET @Reg=CONVERT(int,SCOPE_IDENTITY());\n`+(state!=='PENDING'?`UPDATE dbo.Registration SET status='CONFIRMED' WHERE registration_id=@Reg;\n`:'')+(state==='ADMITTED'?`UPDATE dbo.Registration SET status='ADMITTED' WHERE registration_id=@Reg;
INSERT dbo.Invoice(registration_id,amount) VALUES(@Reg,1000000); SET @Invoice=CONVERT(int,SCOPE_IDENTITY());
${paid?`UPDATE dbo.Invoice SET paid_at=SYSUTCDATETIME(),paid_by=5,payment_method='CASH' WHERE invoice_id=@Invoice;\n`:''}`:'')+`SELECT @RegRV=row_version FROM dbo.Registration WHERE registration_id=@Reg;\n`;
const classroom=(open=false,reuse=false)=> (reuse?'':course())+`INSERT dbo.Class(class_code,course_id,teacher_account_id,capacity) VALUES(@Tag,@Course,9,15); SET @Class=CONVERT(int,SCOPE_IDENTITY());\n`+(open?`INSERT dbo.Schedule(class_id,schedule_type,start_at,end_at,room) VALUES(@Class,'LESSON',@Start,DATEADD(hour,1,@Start),@Tag),(@Class,'FINAL_EXAM',DATEADD(day,1,@Start),DATEADD(hour,25,@Start),@Tag);
UPDATE dbo.Class SET status='OPEN' WHERE class_id=@Class;\n`:'')+`SELECT @ClassRV=row_version FROM dbo.Class WHERE class_id=@Class;\n`;
const complete=()=>`-- Chuẩn bị hợp lệ trên lớp tổng hợp ONGOING có giờ học/thi đã qua.
SET @Class=2;
INSERT dbo.Attendance(schedule_id,class_assignment_id,present)
SELECT s.schedule_id,a.class_assignment_id,1 FROM dbo.Schedule s JOIN dbo.StudentClassAssignment a ON a.class_id=s.class_id
WHERE s.class_id=2 AND s.schedule_type='LESSON' AND NOT EXISTS(SELECT 1 FROM dbo.Attendance t WHERE t.schedule_id=s.schedule_id AND t.class_assignment_id=a.class_assignment_id);
UPDATE dbo.Schedule SET held_at=SYSUTCDATETIME(),held_by=3 WHERE class_id=2 AND held_at IS NULL;
UPDATE dbo.Class SET status='COMPLETED' WHERE class_id=2;
UPDATE g SET continuous_score=70,final_exam_score=85 FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=2;
SELECT @ClassRV=row_version FROM dbo.Class WHERE class_id=2;
INSERT @Grades SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=2;
`;
module.exports={fs,path,project,sql,manifest,roles,guard,wrap,call,course,registration,classroom,complete};
