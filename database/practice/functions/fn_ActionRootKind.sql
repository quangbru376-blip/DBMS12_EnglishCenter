-- Bài chạy riêng: fn_ActionRootKind. Nguồn định nghĩa ở OBJECT_INDEX.md; đây là câu gọi/quan sát.
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

SELECT action,dbo.fn_ActionRootKind(action) AS root_kind FROM (VALUES('DBMS12.FINANCE.INVOICE.COLLECT'),('DBMS12.TEACHER.GRADE.SAVE'),('UNKNOWN.ACTION')) t(action); IF dbo.fn_ActionRootKind('DBMS12.FINANCE.INVOICE.COLLECT')<>'INVOICE' OR dbo.fn_ActionRootKind('UNKNOWN.ACTION') IS NOT NULL THROW 51992,N'Action whitelist sai.',1;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 ROLLBACK TRANSACTION;
 SELECT N'fn_ActionRootKind' AS case_name,N'PASS_ROLLBACK' AS result,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|fn_ActionRootKind';
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 THROW;
END CATCH;

