-- Bài chạy riêng: usp_SecuritySession. Nguồn định nghĩa ở OBJECT_INDEX.md; đây là câu gọi/quan sát.
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

SELECT @Sid=sid,@Epoch=epoch FROM #Actors WHERE account_id=7; DECLARE @Actor int,@Role varchar(24); EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Student',0,0,@Actor OUTPUT,@Role OUTPUT; SELECT @Actor AS verified_actor,@Role AS role_code; -- Helper private: owner chỉ gọi trực tiếp trong fixture; business user không có quyền EXECUTE riêng.
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 ROLLBACK TRANSACTION;
 SELECT N'usp_SecuritySession' AS case_name,N'PASS_ROLLBACK' AS result,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|usp_SecuritySession';
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 THROW;
END CATCH;
DROP TABLE #Actors; DROP TABLE #Results;
