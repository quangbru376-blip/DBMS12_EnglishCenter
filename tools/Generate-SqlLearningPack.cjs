const {fs,path,project,sql,manifest,guard,wrap,call,course,complete}=require('./sql-learning/common.cjs');
const {build}=require('./sql-learning/sp-cases.cjs');
const root=path.join(project,'database/practice'),cases=[];fs.mkdirSync(root,{recursive:true});
function add(group,name,body,options={}){const file=group+'/'+name+'.sql';fs.mkdirSync(path.dirname(path.join(root,file)),{recursive:true});fs.writeFileSync(path.join(root,file),wrap(name,body,options));cases.push({group,name,file,expectedError:options.error??0,mode:'ROLLBACK'});}
const functions={
 fn_GradeTotal:`SELECT dbo.fn_GradeTotal(70,85,40) AS actual,CAST(79 AS decimal(5,2)) AS expected; IF dbo.fn_GradeTotal(70,85,40)<>79 OR dbo.fn_GradeTotal(NULL,85,40) IS NOT NULL THROW 51992,N'Sai công thức/NULL.',1;`,
 fn_InvoiceDueDate:`SELECT dbo.fn_InvoiceDueDate('2026-01-01T18:00:00') AS actual,CONVERT(date,'2026-01-09') AS expected; IF dbo.fn_InvoiceDueDate('2026-01-01T18:00:00')<>'2026-01-09' THROW 51992,N'Phải đổi UTC sang VN rồi cộng7ngày.',1;`,
 fn_ValidScore:`SELECT input,dbo.fn_ValidScore(input) AS actual,expected FROM (VALUES(CAST(NULL AS varchar(40)),1),('70.50',1),('100',1),('100.01',0),(' 70',0),('1.234',0),('abc',0)) t(input,expected); IF EXISTS(SELECT 1 FROM (VALUES(CAST(NULL AS varchar(40)),1),('70.50',1),('100.01',0),(' 70',0),('1.234',0)) t(input,expected) WHERE dbo.fn_ValidScore(input)<>expected) THROW 51992,N'ValidScore sai.',1;`,
 fn_ActionRootKind:`SELECT action,dbo.fn_ActionRootKind(action) AS root_kind FROM (VALUES('DBMS12.FINANCE.INVOICE.COLLECT'),('DBMS12.TEACHER.GRADE.SAVE'),('UNKNOWN.ACTION')) t(action); IF dbo.fn_ActionRootKind('DBMS12.FINANCE.INVOICE.COLLECT')<>'INVOICE' OR dbo.fn_ActionRootKind('UNKNOWN.ACTION') IS NOT NULL THROW 51992,N'Action whitelist sai.',1;`,
 fn_RegistrationUnfinished:`SELECT registration_id,status,dbo.fn_RegistrationUnfinished(registration_id) AS unfinished FROM dbo.Registration; IF dbo.fn_RegistrationUnfinished(-1) IS NOT NULL THROW 51992,N'ID không tồn tại phải NULL.',1;`,
 fn_ClassProgress:`SELECT c.class_id,c.class_code,dbo.fn_ClassProgress(c.class_id) AS progress FROM dbo.Class c; IF dbo.fn_ClassProgress(-1) IS NOT NULL THROW 51992,N'ID không tồn tại phải NULL.',1;`,
 fn_InvoiceDebtFlags:`DECLARE @Now datetime2(3)=SYSUTCDATETIME(); SELECT invoice_id,paid_at,dbo.fn_InvoiceDebtFlags(invoice_id,@Now) AS debt_flag FROM dbo.Invoice; IF EXISTS(SELECT 1 FROM dbo.Invoice WHERE paid_at IS NOT NULL AND dbo.fn_InvoiceDebtFlags(invoice_id,@Now)<>'SETTLED') THROW 51992,N'Hóa đơn đã thu phải SETTLED.',1;`
};for(const [name,body]of Object.entries(functions))add('functions',name,body);
const source=manifest.installOrder.map(f=>fs.readFileSync(path.join(sql,f),'utf8')).join('\n');
for(const m of source.matchAll(/^CREATE VIEW dbo\.(\w+)/gm))add('views',m[1],`SELECT TOP(20) * FROM dbo.${m[1]};\n-- View có thể rỗng khi chưa có dữ liệu phù hợp; xem định nghĩa JOIN/WHERE tại source.`);
for(const name of Object.keys(manifest.operations)){const c=build(name);add('stored-procedures',name,c.body,{sp:true,error:c.error});}
add('stored-procedures','usp_BeginRead',`EXECUTE AS USER='Dbms12ProjectRuntime'; SET @Switched=1; EXEC dbo.usp_BeginRead; REVERT; SET @Switched=0; SELECT @@TRANCOUNT AS caller_depth;`,{sp:true});
add('stored-procedures','usp_BeginWrite',`EXECUTE AS USER='Dbms12ProjectRuntime'; SET @Switched=1; EXEC dbo.usp_BeginWrite; REVERT; SET @Switched=0; SELECT @@TRANCOUNT AS caller_depth;`,{sp:true});
add('stored-procedures','usp_SecuritySession',`SELECT @Sid=sid,@Epoch=epoch FROM #Actors WHERE account_id=7; DECLARE @Actor int,@Role varchar(24); EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Student',0,0,@Actor OUTPUT,@Role OUTPUT; SELECT @Actor AS verified_actor,@Role AS role_code; -- Helper private: owner chỉ gọi trực tiếp trong fixture; business user không có quyền EXECUTE riêng.`,{sp:true});
add('stored-procedures','usp_PasswordSnapshot',`SELECT @Sid=sid,@Epoch=epoch FROM #Actors WHERE account_id=7; CREATE TABLE #Snapshot(password_hash varchar(512)); EXECUTE AS USER='Dbms12ProjectRuntime'; SET @Switched=1; INSERT #Snapshot EXEC dbo.usp_PasswordSnapshot @Sid,@Epoch; REVERT; SET @Switched=0; SELECT COUNT(*) AS snapshot_rows FROM #Snapshot; DROP TABLE #Snapshot; -- Không xuất hash.`,{sp:true});
add('stored-procedures','usp_RecordFailure',`SELECT @Sid=sid,@Epoch=epoch FROM #Actors WHERE account_id=7; EXECUTE AS USER='Dbms12ProjectRuntime'; SET @Switched=1; EXEC dbo.usp_RecordFailure @Sid,@Epoch,'DBMS12.AUTH.ACCESS.DENIED',51203; REVERT; SET @Switched=0; SELECT TOP(1) action_code,result_code FROM dbo.AuditLog ORDER BY audit_id DESC;`,{sp:true});
const triggers={
 tr_Account_Guard:["UPDATE dbo.Account SET email='changed@lab.invalid' WHERE account_id=10;",51102],
 tr_Course_Freeze:["UPDATE dbo.Course SET course_code=@Tag WHERE course_id=1;",51107],
 tr_Registration_State:["UPDATE dbo.Registration SET status='PENDING' WHERE registration_id=1;",51111],
 tr_Class_Lifecycle:["UPDATE dbo.Class SET status='COMPLETED' WHERE class_id=1;",51122],
 tr_Class_GradeDecision:[complete()+"DECLARE @Operation uniqueidentifier=(SELECT TOP(1) operation_id FROM dbo.AuditLog WHERE action_code='DBMS12.OPERATOR.SEED'); UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=2;",51127],
 tr_Assignment_Eligibility:["UPDATE dbo.StudentClassAssignment SET assigned_by=3 WHERE class_assignment_id=1;",51128],
 tr_Schedule_Guard:["UPDATE dbo.Schedule SET class_id=1 WHERE class_id=2 AND schedule_type='LESSON';",51131],
 tr_Attendance_Guard:["DECLARE @Exam int=(SELECT schedule_id FROM dbo.Schedule WHERE class_id=2 AND schedule_type='FINAL_EXAM'); INSERT dbo.Attendance(schedule_id,class_assignment_id,present) VALUES(@Exam,1,1);",51137],
 tr_GradeReport_Guard:["DELETE dbo.GradeReport WHERE report_id=1;",51139],
 tr_Invoice_Integrity:["UPDATE dbo.Invoice SET amount=amount+1 WHERE invoice_id=1;",51146],
 tr_Audit_Integrity:["UPDATE dbo.AuditLog SET change_details=N'Không được sửa lịch sử' WHERE audit_id=(SELECT MIN(audit_id) FROM dbo.AuditLog);",51147],
 tr_Replay_Integrity:[course()+call('usp_RegistrationCreate',{'@CourseId':'@Course'})+"UPDATE dbo.ReplayOperation SET completed_at=completed_at WHERE request_id=@Request;",51152]
};for(const [name,[body,error]]of Object.entries(triggers))add('triggers',name,'-- Owner phát DML để quan sát trigger. Business user bị DENY DML trực tiếp.\n'+body,{sp:true,error});
const constraints={
 Course_Tuition_CHECK:["INSERT dbo.Course(course_code,course_name,tuition_fee,expected_lesson_count,process_weight) VALUES(@Tag,N'Khóa thử',0,1,40);",547],
 Course_Weight_CHECK:["INSERT dbo.Course(course_code,course_name,tuition_fee,expected_lesson_count,process_weight) VALUES(@Tag,N'Khóa thử',1000000,1,100);",547],
 Account_Phone_CHECK:["UPDATE dbo.Account SET phone='123' WHERE account_id=10;",547],
 Course_Code_UNIQUE:["INSERT dbo.Course(course_code,course_name,tuition_fee,expected_lesson_count,process_weight) SELECT course_code,N'Khóa trùng',1000000,1,40 FROM dbo.Course WHERE course_id=1;",2627],
 Course_Status_DEFAULT:["INSERT dbo.Course(course_code,course_name,tuition_fee,expected_lesson_count,process_weight) VALUES(@Tag,N'Khóa default',1000000,1,40); SELECT status,created_at FROM dbo.Course WHERE course_code=@Tag; IF NOT EXISTS(SELECT 1 FROM dbo.Course WHERE course_code=@Tag AND status='ACTIVE' AND created_at IS NOT NULL) THROW 51992,N'DEFAULT sai.',1;",0],
 Registration_Student_FK:["INSERT dbo.Registration(student_account_id,course_id) VALUES(2147483647,1);",547]
};for(const [name,[body,error]]of Object.entries(constraints))add('constraints',name,body,{error});
add('security','GRANT_REVOKE_DENY',`CREATE USER Ec12LearningProof WITHOUT LOGIN;
GRANT SELECT ON OBJECT::dbo.v_DirectorAggregate TO Ec12LearningProof;
EXECUTE AS USER='Ec12LearningProof'; SET @Switched=1;
IF HAS_PERMS_BY_NAME('dbo.v_DirectorAggregate','OBJECT','SELECT')<>1 THROW 51992,N'GRANT phải cho phép.',1;
SELECT COUNT(*) AS visible_aggregate_rows FROM dbo.v_DirectorAggregate;
REVERT; SET @Switched=0;
REVOKE SELECT ON OBJECT::dbo.v_DirectorAggregate FROM Ec12LearningProof;
EXECUTE AS USER='Ec12LearningProof'; SET @Switched=1;
IF HAS_PERMS_BY_NAME('dbo.v_DirectorAggregate','OBJECT','SELECT')<>0 THROW 51992,N'REVOKE không còn cấp quyền riêng.',1;
REVERT; SET @Switched=0;
CREATE ROLE Ec12LearningGrant; ALTER ROLE Ec12LearningGrant ADD MEMBER Ec12LearningProof;
GRANT SELECT ON OBJECT::dbo.v_DirectorAggregate TO Ec12LearningGrant;
DENY SELECT ON OBJECT::dbo.v_DirectorAggregate TO Ec12LearningProof;
EXECUTE AS USER='Ec12LearningProof'; SET @Switched=1;
IF HAS_PERMS_BY_NAME('dbo.v_DirectorAggregate','OBJECT','SELECT')<>0 THROW 51992,N'DENY user phải thắng GRANT role.',1;
REVERT; SET @Switched=0;
-- ROLLBACK sẽ gỡ user/role thử; không đổi7role thật.`);
add('security','Student_Direct_Table_Denied',`EXECUTE AS USER='Dbms12Student'; SET @Switched=1; SELECT COUNT(*) FROM dbo.Account;`,{error:229});
for(const name of ['usp_CourseCreate','usp_RegistrationCreate','usp_AdmissionApprove','usp_InvoiceCollect','usp_PlacementCreate']){
 const c=build(name),file='transactions/'+name+'.sql';
 let text=wrap(name,c.body,{sp:true});
 text=text.replace('DECLARE @LabGuid','DECLARE @CommitLab bit=0,@ForceFailure bit=0; -- Sửa1 để thử COMMIT hoặc lỗi sau nghiệp vụ.\nDECLARE @LabGuid');
 text=text.replace('BEGIN TRY\n BEGIN TRANSACTION;','DECLARE @SavedOperation uniqueidentifier;\nBEGIN TRY\n BEGIN TRANSACTION;');
 text=text.replace(' ROLLBACK TRANSACTION;\n SELECT',` IF @ForceFailure=1 THROW 51997,N'Cố ý lỗi sau nghiệp vụ để rollback cả audit/receipt.',1;
 IF @CommitLab=1 BEGIN DELETE a FROM dbo.AuthSession a JOIN #Actors s ON s.sid=a.sid AND s.account_id=a.account_id; COMMIT TRANSACTION; END
 ELSE ROLLBACK TRANSACTION;
 SELECT`);
 text=text.replace(' IF @ForceFailure=1 THROW',' SELECT TOP(1) @SavedOperation=operation_id FROM #Results;\n IF @ForceFailure=1 THROW');
 text=text.replace(' THROW;\nEND CATCH;',` IF @Error<>51997 THROW;
 IF EXISTS(SELECT 1 FROM dbo.Course WHERE course_code=@Tag) THROW 51992,N'Dữ liệu thử còn sót sau forced rollback.',1;
 IF EXISTS(SELECT 1 FROM dbo.ReplayOperation WHERE request_id=@Request) OR EXISTS(SELECT 1 FROM dbo.AuditLog WHERE operation_id=@SavedOperation) THROW 51992,N'Audit SUCCESS/receipt còn sót sau rollback.',1;
 SELECT N'FORCED_ROLLBACK' AS result,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|${name}';
END CATCH;`);
 text=text.replace("N'PASS_ROLLBACK' AS result","CASE WHEN @CommitLab=1 THEN N'PASS_COMMIT' ELSE N'PASS_ROLLBACK' END AS result");
 fs.mkdirSync(path.dirname(path.join(root,file)),{recursive:true});fs.writeFileSync(path.join(root,file),text);cases.push({group:'transactions',name,file,expectedError:0,mode:'ROLLBACK_DEFAULT_COMMIT_OPT_IN'});
}
require('./sql-learning/index-cases.cjs').generate({add,root,cases});
fs.writeFileSync(path.join(root,'catalog.json'),JSON.stringify({source:'../dbms12-compact/manifest.json',cases},null,2)+'\n');
console.log('Generated '+cases.length+' independent SQL exercises.');
