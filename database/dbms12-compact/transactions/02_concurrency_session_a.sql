-- Mở hai cửa sổ SSMS trên CÙNG fixture riêng. Điền cùng InvoiceId/rowversion.
-- Lấy hai giá trị từ một Invoice chưa thu có Registration ADMITTED trong fixture.
-- Rowversion là phiên bản dữ liệu, không phải thời gian; giữ nguyên cho cả A và B.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @FixtureDatabase sysname=NULL,@FixtureGuid uniqueidentifier=NULL,
 @InvoiceId int=NULL,@ExpectedVersion binary(8)=NULL;
IF @FixtureDatabase IS NULL OR @FixtureGuid IS NULL OR @InvoiceId IS NULL OR @ExpectedVersion IS NULL
 THROW 51990,N'Điền danh tính fixture và hóa đơn/rowversion dùng chung.',1;
IF DB_NAME()<>@FixtureDatabase OR DB_NAME() NOT LIKE 'EnglishCenter[_]DBMS12[_]PROJECT[_]%'
 OR NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid=@FixtureGuid)
 THROW 51990,N'Sai danh tính fixture.',1;
IF USER_NAME()<>'dbo' OR @@TRANCOUNT<>0 THROW 51990,N'Cần owner và connection mới.',1;
DECLARE @Sid binary(32)=CRYPT_GEN_RANDOM(32),@Epoch bigint,@Request uniqueidentifier=NEWID(),
 @Digest binary(32),@Switched bit=0,@LockRows bigint;
SELECT @Epoch=security_version FROM dbo.Account WHERE account_id=5 AND role_code='Accountant' AND status='ACTIVE';
IF @Epoch IS NULL THROW 51990,N'Không có Accountant mẫu của fixture.',1;
SET @Digest=HASHBYTES('SHA2_256',CONCAT('Collect|',@InvoiceId,'|',CONVERT(varchar(18),@ExpectedVersion,1),'|CASH'));
INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at)
 VALUES(@Sid,5,SYSUTCDATETIME(),SYSUTCDATETIME());
BEGIN TRY
 BEGIN TRANSACTION;
 -- A giữ khóa Course 10 giây để B có thời gian chạy và chờ cùng khóa.
 SELECT @LockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 WAITFOR DELAY '00:00:10';
 EXECUTE AS USER='Dbms12Accountant'; SET @Switched=1;
 EXEC dbo.usp_InvoiceCollect @Sid,@Epoch,@Request,@Digest,@InvoiceId,@ExpectedVersion,'CASH',NULL;
 REVERT; SET @Switched=0;
 COMMIT TRANSACTION;
 DELETE dbo.AuthSession WHERE sid=@Sid AND account_id=5;
 PRINT 'COMMIT: thu tiền thành công.';
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 REVERT;
 DELETE dbo.AuthSession WHERE sid=@Sid AND account_id=5;
 -- 51214: người kia đã thu; tải lại hóa đơn, không tự gửi lại.
 THROW;
END CATCH;
-- Chỉ 1 paid_at/1 audit SUCCESS. Người thua không tạo SUCCESS/receipt.

