CREATE OR ALTER PROCEDURE dbo.usp_PasswordChange
 @Sid binary(32),
 @Epoch bigint,
 @ObservedHash varchar(512),
 @NewHash varchar(513)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 -- Tự mở giao dịch nếu chưa có; SP con dùng giao dịch của bên gọi.
 DECLARE @SqlOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
 BEGIN TRY
  IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
IF @@TRANCOUNT<>1 THROW 51200,N'Độ sâu transaction không hợp lệ.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,1,0,@Actor OUTPUT,@SessionRole OUTPUT;
IF DATALENGTH(@NewHash)>512 THROW 51235,N'Hash vượt độ dài cho phép.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Account WHERE account_id=@Actor AND password_hash COLLATE Latin1_General_100_BIN2=@ObservedHash COLLATE Latin1_General_100_BIN2)
            THROW 51231,N'Credential đã thay đổi.',1;
        DELETE dbo.AuthSession WHERE account_id=@Actor;
        UPDATE dbo.Account SET password_hash=@NewHash,temp_issued_at=NULL,security_version=security_version+1,
            failed_login_count=0,failure_window_started_at=NULL,login_throttled_until=NULL WHERE account_id=@Actor;
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,change_details)
        VALUES(NEWID(),@Actor,'DBMS12.AUTH.PASSWORD.CHANGE',@Actor,'SUCCESS',N'Đổi mật khẩu và thu hồi toàn bộ phiên.');
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
