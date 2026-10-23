CREATE OR ALTER PROCEDURE dbo.usp_ProfileUpdate
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @AccountVersion binary(8),
 @Name nvarchar(201),
 @Phone varchar(11),
 @BirthDate date=NULL,
 @Address nvarchar(256)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Student',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.AUTH.PROFILE.UPDATE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF DATALENGTH(@Name)>400 THROW 51235,N'Input @Name vượt độ dài cho phép.',1;
        IF DATALENGTH(@Phone)>10 THROW 51235,N'Input @Phone vượt độ dài cho phép.',1;
        IF DATALENGTH(@Address)>510 THROW 51235,N'Input @Address vượt độ dài cho phép.',1;

        UPDATE dbo.Account SET full_name=@Name,phone=@Phone,date_of_birth=@BirthDate,address=@Address
        WHERE account_id=@Actor AND row_version=@AccountVersion;
        IF @@ROWCOUNT<>1 THROW 51228,N'Hồ sơ cá nhân đã thay đổi.',1;
        SET @RootId=@Actor;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Cập nhật thông tin cá nhân theo quyền; không ghi dữ liệu riêng tư vào audit.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Student',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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
