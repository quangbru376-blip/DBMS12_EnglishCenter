CREATE OR ALTER PROCEDURE dbo.usp_CourseCreate
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @Code varchar(51),
 @Name nvarchar(201),
 @Tuition varchar(41),
 @Lessons int,
 @Weight varchar(41)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ACADEMIC.COURSE.CREATE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF DATALENGTH(@Code)>50 THROW 51235,N'Input @Code vượt độ dài cho phép.',1;
        IF DATALENGTH(@Name)>400 THROW 51235,N'Input @Name vượt độ dài cho phép.',1;
        IF DATALENGTH(@Tuition)>40 THROW 51235,N'Input @Tuition vượt độ dài cho phép.',1;
        IF DATALENGTH(@Weight)>40 THROW 51235,N'Input @Weight vượt độ dài cho phép.',1;

        DECLARE @Amount decimal(18,0);
        IF @Tuition IS NULL OR LEN(@Tuition) NOT BETWEEN 1 AND 18 OR @Tuition COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%' OR DATALENGTH(@Tuition)<>LEN(@Tuition) THROW 51207,N'Tiền phải là số nguyên VND, tối đa18 chữ số.',1;
SET @Amount=CONVERT(decimal(18,0),@Tuition);
IF @Amount<=0 THROW 51207,N'Số tiền phải dương.',1;
        IF dbo.fn_ValidScore(@Weight)<>1 OR @Weight IS NULL
            THROW 51208,N'Trọng số phải nằm giữa 0 và 100, tối đa 2 số thập phân.',1;
        IF CONVERT(decimal(5,2),@Weight) NOT BETWEEN 0.01 AND 99.99 THROW 51208,N'Trọng số phải nằm giữa 0 và 100.',1;
        INSERT dbo.Course(course_code,course_name,tuition_fee,expected_lesson_count,process_weight)
        VALUES(@Code,@Name,@Amount,@Lessons,CONVERT(decimal(5,2),@Weight));
        SET @RootId=CONVERT(int,SCOPE_IDENTITY());
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Thao tác nghiệp vụ.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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
