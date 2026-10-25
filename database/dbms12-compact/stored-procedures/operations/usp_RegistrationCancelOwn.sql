CREATE OR ALTER PROCEDURE dbo.usp_RegistrationCancelOwn
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @RegistrationId int,
 @ExpectedVersion binary(8)
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Student',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.STUDENT.REGISTRATION.CANCEL',@Operation uniqueidentifier=NEWID(),@RootId int,
 @CompletionReason nvarchar(1000),@CompletionDetails nvarchar(4000);
 IF @RequestId IS NULL OR @Digest IS NULL THROW 51204,N'Thiếu UUID/digest.',1;
 DECLARE @Previous uniqueidentifier,@PreviousDigest binary(32);
 SELECT @Previous=operation_id,@PreviousDigest=input_digest FROM dbo.ReplayOperation
 WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
 IF @Previous IS NOT NULL
 BEGIN
  IF @PreviousDigest<>@Digest THROW 51205,N'UUID đã dùng cho nội dung khác.',1;
  SELECT operation_id,root_entity_id AS target_id,CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
  RETURN;
 END;
UPDATE dbo.Registration SET status='CANCELLED' WHERE registration_id=@RegistrationId AND student_account_id=@Actor AND status='PENDING' AND row_version=@ExpectedVersion;
        IF @@ROWCOUNT<>1 THROW 51212,N'Chỉ được hủy hồ sơ PENDING của mình.',1;
        SET @RootId=@RegistrationId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Thao tác nghiệp vụ.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Student',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF NOT EXISTS(SELECT 1 FROM dbo.AuditLog WHERE operation_id=@Operation)
 INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,reason,change_details)
 VALUES(@Operation,@Actor,@Action,@RootId,'SUCCESS',@CompletionReason,@CompletionDetails);
IF NOT EXISTS(SELECT 1 FROM dbo.AuditLog WHERE operation_id=@Operation AND actor_account_id=@Actor AND action_code=@Action AND root_entity_id=@RootId AND result_code='SUCCESS')
 THROW 51206,N'Audit không khớp thao tác.',1;
INSERT dbo.ReplayOperation(actor_account_id,action_code,request_id,input_digest,operation_id) VALUES(@Actor,@Action,@RequestId,@Digest,@Operation);
UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;

 SELECT @Operation AS operation_id,@RootId AS target_id,CONVERT(bit,0) AS replayed;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
