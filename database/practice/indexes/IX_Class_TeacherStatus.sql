-- Bài chạy riêng: IX_Class_TeacherStatus. Nguồn định nghĩa ở OBJECT_INDEX.md; đây là câu gọi/quan sát.
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

-- Đo có kiểm soát trên temp replica100000dòng, cùng key/include và predicate.
-- Không DROP/DISABLE index của bảng thật; đây không phải benchmark production.
CREATE TABLE #Lab(class_id int NOT NULL PRIMARY KEY,teacher_account_id int,status varchar(16),course_id int);
INSERT #Lab SELECT n,n%1000+1,CASE WHEN n%3=0 THEN 'OPEN' ELSE 'PLANNED' END,n%17+1 FROM(SELECT TOP(100000) CONVERT(int,ROW_NUMBER() OVER(ORDER BY(SELECT NULL))) AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b) t;
DECLARE @Teacher int=42,@Status varchar(16)='OPEN';
DECLARE @N0 bigint,@N1 bigint,@C0 int,@C1 int;
PRINT 'EC_INDEX_BASELINE|IX_Class_TeacherStatus';
SET STATISTICS IO ON; SET STATISTICS TIME ON;
SELECT @N0=COUNT_BIG(*),@C0=CHECKSUM_AGG(BINARY_CHECKSUM(class_id,course_id)) FROM #Lab WHERE teacher_account_id=@Teacher AND status=@Status;
SET STATISTICS IO OFF; SET STATISTICS TIME OFF;
CREATE INDEX [IX_Class_TeacherStatus] ON #Lab(teacher_account_id,status) INCLUDE(course_id);
PRINT 'EC_INDEX_WITH|IX_Class_TeacherStatus';
SET STATISTICS IO ON; SET STATISTICS TIME ON;
SELECT @N1=COUNT_BIG(*),@C1=CHECKSUM_AGG(BINARY_CHECKSUM(class_id,course_id)) FROM #Lab WHERE teacher_account_id=@Teacher AND status=@Status;
SET STATISTICS IO OFF; SET STATISTICS TIME OFF;
IF @N0<>@N1 OR ISNULL(@C0,0)<>ISNULL(@C1,0) THROW 51992,N'Hai truy vấn phải trả cùng dữ liệu.',1;
SELECT @N0 AS baseline_rows,@N1 AS indexed_rows,@C0 AS baseline_checksum,@C1 AS indexed_checksum;
PRINT 'EC_INDEX_END|IX_Class_TeacherStatus';
DROP TABLE #Lab;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 ROLLBACK TRANSACTION;
 SELECT N'IX_Class_TeacherStatus' AS case_name,N'PASS_ROLLBACK' AS result,@@TRANCOUNT AS transaction_depth;
 PRINT 'EC_LAB_PASS|IX_Class_TeacherStatus';
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
 THROW;
END CATCH;

