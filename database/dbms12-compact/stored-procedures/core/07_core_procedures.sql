-- Eleven original domain procedures, now including session/audit/replay guards.
CREATE OR ALTER PROCEDURE dbo.usp_RegistrationCreate
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @CourseId int
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
 DECLARE @Action varchar(80)='DBMS12.STUDENT.REGISTRATION.CREATE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF NOT EXISTS(SELECT 1 FROM dbo.Course WHERE course_id=@CourseId AND status='ACTIVE') THROW 51210,N'Khóa không tuyển sinh.',1;
        IF EXISTS(SELECT 1 FROM dbo.Registration WHERE student_account_id=@Actor AND course_id=@CourseId AND dbo.fn_RegistrationUnfinished(registration_id)=1)
            THROW 51211,N'Đã có hồ sơ chưa kết thúc.',1;
        INSERT dbo.Registration(student_account_id,course_id) VALUES(@Actor,@CourseId);
        SET @RootId=CONVERT(int,SCOPE_IDENTITY());
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

CREATE OR ALTER PROCEDURE dbo.usp_AdmissionApprove
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Admissions',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ADMISSIONS.REGISTRATION.APPROVE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
UPDATE dbo.Registration SET status='ADMITTED' WHERE registration_id=@RegistrationId AND status='CONFIRMED' AND row_version=@ExpectedVersion;
        IF @@ROWCOUNT<>1 THROW 51212,N'Chỉ duyệt hồ sơ CONFIRMED đúng phiên bản.',1;
        INSERT dbo.Invoice(registration_id,amount)
        SELECT r.registration_id,p.tuition_fee FROM dbo.Registration r JOIN dbo.Course p ON p.course_id=r.course_id WHERE r.registration_id=@RegistrationId;
        SET @RootId=@RegistrationId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Duyệt nhập học và tạo một hóa đơn theo giá hiện hành.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Admissions',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_InvoiceCollect
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @InvoiceId int,
 @ExpectedVersion binary(8),
 @Method varchar(17),
 @Reference nvarchar(101)=NULL
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Accountant',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.FINANCE.INVOICE.COLLECT',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF DATALENGTH(@Method)>16 THROW 51235,N'Input @Method vượt độ dài cho phép.',1;
        IF DATALENGTH(@Reference)>200 THROW 51235,N'Input @Reference vượt độ dài cho phép.',1;

        UPDATE i SET paid_at=SYSUTCDATETIME(),paid_by=@Actor,payment_method=@Method,payment_reference=@Reference
        FROM dbo.Invoice i JOIN dbo.Registration r ON r.registration_id=i.registration_id
        WHERE i.invoice_id=@InvoiceId AND i.row_version=@ExpectedVersion AND i.paid_at IS NULL AND r.status='ADMITTED';
        IF @@ROWCOUNT<>1 THROW 51214,N'Hóa đơn không thể thu hoặc đã thay đổi.',1;
        SET @RootId=@InvoiceId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Đã thu đủ toàn bộ số tiền hóa đơn.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Accountant',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_PlacementCreate
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @RegistrationId int,
 @RegistrationVersion binary(8),
 @ClassId int,
 @ClassVersion binary(8)
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ACADEMIC.PLACEMENT.CREATE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF NOT EXISTS(SELECT 1 FROM dbo.Registration WHERE registration_id=@RegistrationId AND row_version=@RegistrationVersion) THROW 51212,N'Hồ sơ đã thay đổi.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Class WHERE class_id=@ClassId AND row_version=@ClassVersion) THROW 51218,N'Lớp đã thay đổi.',1;
        INSERT dbo.StudentClassAssignment(registration_id,class_id,assigned_by) VALUES(@RegistrationId,@ClassId,@Actor);
        DECLARE @AssignmentId int=CONVERT(int,SCOPE_IDENTITY());
        INSERT dbo.GradeReport(class_assignment_id) VALUES(@AssignmentId);
        UPDATE dbo.Class SET capacity=capacity WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Xếp một hồ sơ và tạo bảng điểm rỗng; thay phiên bản roster.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_ScheduleBatch
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @ClassId int,
 @ClassVersion binary(8),
 @Items dbo.ScheduleBatch READONLY
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ACADEMIC.SCHEDULE.BATCH',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF NOT EXISTS(SELECT 1 FROM dbo.Class WHERE class_id=@ClassId AND row_version=@ClassVersion AND status NOT IN ('COMPLETED','CANCELLED')) THROW 51218,N'Lớp không còn hợp lệ.',1;
        IF NOT EXISTS(SELECT 1 FROM @Items) THROW 51219,N'Danh sách lịch rỗng.',1;
        INSERT dbo.Schedule(class_id,schedule_type,start_at,end_at,room)
        SELECT @ClassId,schedule_type,start_at,end_at,room FROM @Items;
        UPDATE dbo.Class SET capacity=capacity WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Tạo toàn bộ lịch trong batch; không lưu một phần.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_ScheduleMove
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @ScheduleId int,
 @ExpectedVersion binary(8),
 @Start datetime2(3),
 @End datetime2(3),
 @Room nvarchar(51),
 @Reason nvarchar(1001)=NULL
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ACADEMIC.SCHEDULE.MOVE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF DATALENGTH(@Room)>100 THROW 51235,N'Input @Room vượt độ dài cho phép.',1;
        IF DATALENGTH(@Reason)>2000 THROW 51235,N'Input @Reason vượt độ dài cho phép.',1;

        DECLARE @OldStart datetime2(3),@OldEnd datetime2(3),@OldRoom nvarchar(50);
        SELECT @OldStart=start_at,@OldEnd=end_at,@OldRoom=room FROM dbo.Schedule WHERE schedule_id=@ScheduleId AND row_version=@ExpectedVersion;
        IF @OldStart IS NULL THROW 51220,N'Buổi không tồn tại hoặc đã thay đổi.',1;
        IF @OldStart<=SYSUTCDATETIME() AND (@Reason IS NULL OR LEN(LTRIM(RTRIM(@Reason)))=0) THROW 51213,N'Dời buổi bị lỡ giờ cần lý do.',1;
        DECLARE @MoveDetails nvarchar(4000)=CONCAT(N'UTC bắt đầu ',CONVERT(varchar(30),@OldStart,126),N' -> ',CONVERT(varchar(30),@Start,126),
            N'; kết thúc ',CONVERT(varchar(30),@OldEnd,126),N' -> ',CONVERT(varchar(30),@End,126),N'; phòng ',@OldRoom,N' -> ',@Room);
        UPDATE dbo.Schedule SET start_at=@Start,end_at=@End,room=@Room WHERE schedule_id=@ScheduleId AND row_version=@ExpectedVersion;
        IF @@ROWCOUNT<>1 THROW 51220,N'Buổi đã thay đổi.',1;
        SET @RootId=@ScheduleId;
SET @CompletionReason=@Reason;
SET @CompletionDetails=@MoveDetails;
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_AttendanceSave
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @ScheduleId int,
 @ClassVersion binary(8),
 @Items dbo.AttendanceBatch READONLY
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Teacher',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.TEACHER.ATTENDANCE.SAVE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
DECLARE @ClassId int;
        SELECT @ClassId=s.class_id FROM dbo.Schedule s JOIN dbo.Class c ON c.class_id=s.class_id
        WHERE s.schedule_id=@ScheduleId AND c.teacher_account_id=@Actor AND c.row_version=@ClassVersion;
        IF @ClassId IS NULL THROW 51221,N'Không phải lớp phụ trách hoặc lớp đã thay đổi.',1;
        IF NOT EXISTS(SELECT 1 FROM @Items) THROW 51222,N'Danh sách điểm danh rỗng.',1;
        IF EXISTS(SELECT 1 FROM @Items i LEFT JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=i.class_assignment_id AND a.class_id=@ClassId WHERE a.class_assignment_id IS NULL)
            THROW 51222,N'Học viên không thuộc lớp.',1;
        IF EXISTS(SELECT 1 FROM @Items i LEFT JOIN dbo.Attendance a ON a.class_assignment_id=i.class_assignment_id AND a.schedule_id=@ScheduleId
                  WHERE (a.attendance_id IS NULL AND i.expected_version IS NOT NULL)
                     OR (a.attendance_id IS NOT NULL AND (i.expected_version IS NULL OR a.row_version<>i.expected_version)))
            THROW 51223,N'Điểm danh đã thay đổi.',1;
        UPDATE a SET present=i.present,recorded_at=SYSUTCDATETIME()
        FROM dbo.Attendance a JOIN @Items i ON i.class_assignment_id=a.class_assignment_id WHERE a.schedule_id=@ScheduleId;
        INSERT dbo.Attendance(schedule_id,class_assignment_id,present)
        SELECT @ScheduleId,i.class_assignment_id,i.present FROM @Items i
        WHERE NOT EXISTS(SELECT 1 FROM dbo.Attendance a WHERE a.schedule_id=@ScheduleId AND a.class_assignment_id=i.class_assignment_id);
        SET @RootId=@ScheduleId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Thao tác nghiệp vụ.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Teacher',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_GradeSave
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @ReportId int,
 @ReportVersion binary(8),
 @ClassVersion binary(8),
 @Continuous varchar(41),
 @Final varchar(41),
 @Comment nvarchar(1001)=NULL
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Teacher',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.TEACHER.GRADE.SAVE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF DATALENGTH(@Continuous)>40 THROW 51235,N'Input @Continuous vượt độ dài cho phép.',1;
        IF DATALENGTH(@Final)>40 THROW 51235,N'Input @Final vượt độ dài cho phép.',1;
        IF DATALENGTH(@Comment)>2000 THROW 51235,N'Input @Comment vượt độ dài cho phép.',1;

        IF dbo.fn_ValidScore(@Continuous)<>1 OR dbo.fn_ValidScore(@Final)<>1 THROW 51224,N'Điểm 0–100, tối đa 2 số thập phân.',1;
        DECLARE @OldContinuous decimal(5,2),@OldFinal decimal(5,2);
        SELECT @OldContinuous=continuous_score,@OldFinal=final_exam_score FROM dbo.GradeReport WHERE report_id=@ReportId;
        DECLARE @ScoreDetails nvarchar(4000)=CONCAT(N'Quá trình ',COALESCE(CONVERT(varchar(10),@OldContinuous),'NULL'),N' -> ',COALESCE(@Continuous,'NULL'),
            N'; cuối khóa ',COALESCE(CONVERT(varchar(10),@OldFinal),'NULL'),N' -> ',COALESCE(@Final,'NULL'));
        UPDATE g SET continuous_score=CONVERT(decimal(5,2),@Continuous),final_exam_score=CONVERT(decimal(5,2),@Final),teacher_comment=@Comment,updated_at=SYSUTCDATETIME()
        FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id
        JOIN dbo.Class c ON c.class_id=a.class_id
        WHERE g.report_id=@ReportId AND g.row_version=@ReportVersion AND c.row_version=@ClassVersion AND c.teacher_account_id=@Actor;
        IF @@ROWCOUNT<>1 THROW 51225,N'Không phải lớp phụ trách hoặc dữ liệu đã thay đổi.',1;
        SET @RootId=@ReportId;
SET @CompletionReason=NULL;
SET @CompletionDetails=@ScoreDetails;
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Teacher',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_GradeSubmit
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @ClassId int,
 @ClassVersion binary(8),
 @Manifest dbo.GradeManifest READONLY
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Teacher',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.TEACHER.GRADE.SUBMIT',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF NOT EXISTS(SELECT 1 FROM dbo.v_ClassState c WHERE c.class_id=@ClassId AND c.row_version=@ClassVersion AND c.status='COMPLETED' AND c.grade_status IN ('DRAFT','RETURNED')
            AND c.teacher_account_id=@Actor) THROW 51226,N'Lớp/bảng điểm sai trạng thái hoặc phiên bản.',1;
        IF NOT EXISTS(SELECT 1 FROM @Manifest) THROW 51227,N'Manifest không được rỗng.',1;
        IF EXISTS(SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId
                  EXCEPT SELECT report_id,expected_version FROM @Manifest)
           OR EXISTS(SELECT report_id,expected_version FROM @Manifest EXCEPT
                     SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId)
            THROW 51227,N'Manifest phải đủ và đúng toàn bộ lớp.',1;
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,reason,change_details)
        VALUES(@Operation,@Actor,@Action,@ClassId,'SUCCESS',NULL,N'Quyết định cho toàn bộ bảng điểm lớp.');
        UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
SET @CompletionReason=NULL;
SET @CompletionDetails=N'Thao tác nghiệp vụ.';
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'Teacher',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
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

CREATE OR ALTER PROCEDURE dbo.usp_GradeReturn
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @ClassId int,
 @ClassVersion binary(8),
 @Manifest dbo.GradeManifest READONLY,
 @Reason nvarchar(1001)
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ACADEMIC.GRADE.RETURN',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF DATALENGTH(@Reason)>2000 THROW 51235,N'Input @Reason vượt độ dài cho phép.',1;
        IF @Reason IS NULL OR LEN(LTRIM(RTRIM(@Reason)))=0 THROW 51213,N'Cần lý do trả điểm.',1;

        IF NOT EXISTS(SELECT 1 FROM dbo.v_ClassState c WHERE c.class_id=@ClassId AND c.row_version=@ClassVersion AND c.status='COMPLETED' AND c.grade_status='SUBMITTED'
            ) THROW 51226,N'Lớp/bảng điểm sai trạng thái hoặc phiên bản.',1;
        IF NOT EXISTS(SELECT 1 FROM @Manifest) THROW 51227,N'Manifest không được rỗng.',1;
        IF EXISTS(SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId
                  EXCEPT SELECT report_id,expected_version FROM @Manifest)
           OR EXISTS(SELECT report_id,expected_version FROM @Manifest EXCEPT
                     SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId)
            THROW 51227,N'Manifest phải đủ và đúng toàn bộ lớp.',1;
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,reason,change_details)
        VALUES(@Operation,@Actor,@Action,@ClassId,'SUCCESS',@Reason,N'Quyết định cho toàn bộ bảng điểm lớp.');
        UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
SET @CompletionReason=@Reason;
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
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GradeFinalize
 @Sid binary(32),
 @Epoch bigint,
 @RequestId uniqueidentifier,
 @Digest binary(32),
 @ClassId int,
 @ClassVersion binary(8),
 @Manifest dbo.GradeManifest READONLY
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
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,'AcademicAffairs',0,1,@Actor OUTPUT,@SessionRole OUTPUT;
 DECLARE @Action varchar(80)='DBMS12.ACADEMIC.GRADE.FINALIZE',@Operation uniqueidentifier=NEWID(),@RootId int,
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
IF NOT EXISTS(SELECT 1 FROM dbo.v_ClassState c WHERE c.class_id=@ClassId AND c.row_version=@ClassVersion AND c.status='COMPLETED' AND c.grade_status='SUBMITTED'
            ) THROW 51226,N'Lớp/bảng điểm sai trạng thái hoặc phiên bản.',1;
        IF NOT EXISTS(SELECT 1 FROM @Manifest) THROW 51227,N'Manifest không được rỗng.',1;
        IF EXISTS(SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId
                  EXCEPT SELECT report_id,expected_version FROM @Manifest)
           OR EXISTS(SELECT report_id,expected_version FROM @Manifest EXCEPT
                     SELECT g.report_id,g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId)
            THROW 51227,N'Manifest phải đủ và đúng toàn bộ lớp.',1;
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,reason,change_details)
        VALUES(@Operation,@Actor,@Action,@ClassId,'SUCCESS',NULL,N'Quyết định cho toàn bộ bảng điểm lớp.');
        UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
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
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
