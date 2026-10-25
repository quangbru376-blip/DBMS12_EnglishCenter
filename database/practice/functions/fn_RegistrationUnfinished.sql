-- Bài chạy riêng: fn_RegistrationUnfinished. Nguồn định nghĩa ở OBJECT_INDEX.md; đây là câu gọi/quan sát.
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
DECLARE @Switched bit=0,@Tag varchar(32)='LAB-'+LEFT(CONVERT(varchar(36),NEWID()),8);

BEGIN TRY
 BEGIN TRANSACTION;

SELECT registration_id,status,dbo.fn_RegistrationUnfinished(registration_id) AS unfinished FROM dbo.Registration; IF dbo.fn_RegistrationUnfinished(-1) IS NOT NULL THROW 51992,N'ID không tồn tại phải NULL.',1;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 ROLLBACK TRANSACTION;
 SELECT N'fn_RegistrationUnfinished' AS case_name,N'PASS_ROLLBACK' AS result,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|fn_RegistrationUnfinished';
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 THROW;
END CATCH;

