CREATE OR ALTER PROCEDURE dbo.usp_PasswordSnapshot
 @Sid binary(32),@Epoch bigint
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 -- Tự mở giao dịch nếu chưa có; SP con dùng giao dịch của bên gọi.
 DECLARE @SqlOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
 BEGIN TRY
  IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
 DECLARE @SnapshotLockRows bigint;
 SELECT @SnapshotLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
IF @@TRANCOUNT<>1 THROW 51200,N'Độ sâu transaction không hợp lệ.',1;
 DECLARE @Actor int,@Role varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,1,0,@Actor OUTPUT,@Role OUTPUT;
 SELECT password_hash FROM dbo.Account WHERE account_id=@Actor AND status='ACTIVE';
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
