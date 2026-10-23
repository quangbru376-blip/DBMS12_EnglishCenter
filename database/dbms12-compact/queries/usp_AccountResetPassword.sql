CREATE OR ALTER PROCEDURE dbo.usp_AccountResetPassword
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @AccountId int,
 @AccountVersion binary(8),
 @PasswordHash varchar(513)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Admin',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ADMIN.ACCOUNT.RESET',@Operation uniqueidentifier=NEWID(),@RootId int,
 @CompletionReason nvarchar(1000),@CompletionDetails nvarchar(4000);
 IF @RequestId IS NULL OR @Digest IS NULL THROW 51204,N'Thiếu UUID/digest.',1;
 DECLARE @Previous uniqueidentifier,@PreviousDigest binary(32);
 SELECT @Previous=operation_id,@PreviousDigest=input_digest FROM dbo.ReplayOperation
 WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
 IF @Previous IS NOT NULL
 BEGIN
  IF @PreviousDigest<>@Digest THROW 51205,N'UUID đã dùng cho nội dung khác.',1;
  SELECT operation_id,root_entity_id AS target_id,CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
  RETURN;
 END;
IF DATALENGTH(@PasswordHash)>512 THROW 51235,N'Input @PasswordHash vượt độ dài cho phép.',1;

        IF @AccountId=@Actor THROW 51230,N'Không reset chính tài khoản đang dùng.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Account WHERE account_id=@AccountId AND row_version=@AccountVersion) THROW 51228,N'Tài khoản đã thay đổi.',1;
        DELETE dbo.AuthSession WHERE account_id=@AccountId;
        UPDATE dbo.Account SET password_hash=@PasswordHash,temp_issued_at=SYSUTCDATETIME(),security_version=security_version+1,
            failed_login_count=0,failure_window_started_at=NULL,login_throttled_until=NULL WHERE account_id=@AccountId;
        SET @RootId=@AccountId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Reset mật khẩu tạm và thu hồi mọi phiên; không lưu mật khẩu/hash trong audit/replay.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Admin',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF NOT EXISTS(SELECT 1 FROM dbo.AuditLog WHERE operation_id=@Operation)
 INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,reason,change_details)
 VALUES(@Operation,@Actor,@Action,@RootId,'SUCCESS',@CompletionReason,@CompletionDetails);
IF NOT EXISTS(SELECT 1 FROM dbo.AuditLog WHERE operation_id=@Operation AND actor_account_id=@Actor AND action_code=@Action AND root_entity_id=@RootId AND result_code='SUCCESS')
 THROW 51206,N'Audit không khớp thao tác.',1;
INSERT dbo.ReplayOperation(actor_account_id,action_code,request_id,input_digest,operation_id) VALUES(@Actor,@Action,@RequestId,@Digest,@Operation);
UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;

 SELECT @Operation AS operation_id,@RootId AS target_id,CONVERT(bit,0) AS replayed;
END;
GO
