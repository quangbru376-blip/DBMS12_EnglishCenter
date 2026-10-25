-- Bài chạy riêng: tr_Class_GradeDecision. Nguồn định nghĩa ở OBJECT_INDEX.md; đây là câu gọi/quan sát.
-- Mặc định ROLLBACK toàn bộ dữ liệu thử. IDENTITY/SEQUENCE/rowversion có thể có khoảng trống.
SET NOCOUNT ON;
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
DECLARE @Tag varchar(32)='LAB-'+LEFT(CONVERT(varchar(36),NEWID()),8),
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

BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at) SELECT sid,account_id,SYSUTCDATETIME(),SYSUTCDATETIME() FROM #Actors;

-- Owner phát DML để quan sát trigger. Business user bị DENY DML trực tiếp.
-- Chuẩn bị hợp lệ trên lớp tổng hợp ONGOING có giờ học/thi đã qua.
SET @Class=2;
INSERT dbo.Attendance(schedule_id,class_assignment_id,present)
SELECT s.schedule_id,a.class_assignment_id,1 FROM dbo.Schedule s JOIN dbo.StudentClassAssignment a ON a.class_id=s.class_id
WHERE s.class_id=2 AND s.schedule_type='LESSON' AND NOT EXISTS(SELECT 1 FROM dbo.Attendance t WHERE t.schedule_id=s.schedule_id AND t.class_assignment_id=a.class_assignment_id);
UPDATE dbo.Schedule SET held_at=SYSUTCDATETIME(),held_by=3 WHERE class_id=2 AND held_at IS NULL;
UPDATE dbo.Class SET status='COMPLETED' WHERE class_id=2;
UPDATE g SET continuous_score=70,final_exam_score=85 FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=2;
SELECT @ClassRV=row_version FROM dbo.Class WHERE class_id=2;
INSERT @Grades SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=2;
DECLARE @Operation uniqueidentifier=(SELECT TOP(1) operation_id FROM dbo.AuditLog WHERE action_code='DBMS12.OPERATOR.SEED'); UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=2;
 THROW 51991,N'Không xuất hiện lỗi mong đợi 51127.',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 IF @Error<>51127 THROW;
 SELECT N'tr_Class_GradeDecision' AS case_name,@Error AS expected_error,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|tr_Class_GradeDecision';
END CATCH;
DROP TABLE #Actors; DROP TABLE #Results;
