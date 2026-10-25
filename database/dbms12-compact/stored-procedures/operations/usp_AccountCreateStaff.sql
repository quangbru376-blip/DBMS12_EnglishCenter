CREATE OR ALTER PROCEDURE dbo.usp_AccountCreateStaff
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @Role varchar(25),
 @Email varchar(255),
 @Name nvarchar(201),
 @Phone varchar(11),
 @PasswordHash varchar(513)
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Admin',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ADMIN.ACCOUNT.CREATE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF DATALENGTH(@Role)>24 THROW 51235,N'Input @Role vượt độ dài cho phép.',1;
        IF DATALENGTH(@Email)>254 THROW 51235,N'Input @Email vượt độ dài cho phép.',1;
        IF DATALENGTH(@Name)>400 THROW 51235,N'Input @Name vượt độ dài cho phép.',1;
        IF DATALENGTH(@Phone)>10 THROW 51235,N'Input @Phone vượt độ dài cho phép.',1;
        IF DATALENGTH(@PasswordHash)>512 THROW 51235,N'Input @PasswordHash vượt độ dài cho phép.',1;

        IF @Role NOT IN ('Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin') OR @Role IS NULL THROW 51229,N'Vai trò nhân sự không hợp lệ.',1;
        INSERT dbo.Account(role_code,email,full_name,phone,password_hash,temp_issued_at)
        VALUES(@Role,@Email,@Name,@Phone,@PasswordHash,SYSUTCDATETIME());
        SET @RootId=CONVERT(int,SCOPE_IDENTITY());
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Thao tác nghiệp vụ.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Admin',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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
