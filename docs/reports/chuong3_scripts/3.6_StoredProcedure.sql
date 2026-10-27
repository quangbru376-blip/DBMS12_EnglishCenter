-- ============================================================================
-- CHƯƠNG 3. CÀI ĐẶT CƠ SỞ DỮ LIỆU
-- 3.6. STORED PROCEDURE (24 THỦ TỤC LƯU TRỮ CHÍNH CỦA 4 THÀNH VIÊN)
-- Hệ thống: DBMS12 EnglishCenter
-- Thiết kế: D15 tự quản Transaction (TRY/CATCH/XACT_ABORT), D14 Phân quyền Native
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- PHẦN I: THÀNH VIÊN 1 (TV1) - TÀI KHOẢN, XÁC THỰC, PHIÊN VÀ BẢO MẬT
-- ============================================================================

-- 1. usp_StudentSignup: Đăng ký tài khoản học viên trực tuyến
CREATE OR ALTER PROCEDURE dbo.usp_StudentSignup
    @Email varchar(255), @Name nvarchar(201), @Phone varchar(11),
    @BirthDate date, @Address nvarchar(256), @PasswordHash varchar(513)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        IF DATALENGTH(@Email)>254 OR DATALENGTH(@Name)>400 OR DATALENGTH(@Phone)>10 OR DATALENGTH(@Address)>510 OR DATALENGTH(@PasswordHash)>512
            THROW 51235, N'Input vượt độ dài cho phép.', 1;
        INSERT dbo.Account(role_code, email, full_name, phone, date_of_birth, address, password_hash)
        VALUES('Student', @Email, @Name, @Phone, @BirthDate, @Address, @PasswordHash);
        DECLARE @Id int = CONVERT(int, SCOPE_IDENTITY()), @Operation uniqueidentifier = NEWID();
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Id, 'DBMS12.STUDENT.SIGNUP', @Id, 'SUCCESS', N'Tạo tài khoản Student.');
        SELECT @Id AS account_id;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 2. usp_LoginRead: Đọc thông tin xác thực để kiểm tra mật khẩu nội bộ
CREATE OR ALTER PROCEDURE dbo.usp_LoginRead
    @Email varchar(254)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
        SELECT account_id, password_hash, security_version, status, temp_issued_at, login_throttled_until, row_version
        FROM dbo.Account WHERE email=@Email;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 3. usp_LoginRecord: Ghi nhận kết quả đăng nhập, quản lý brute-force và cấp phiên SID
CREATE OR ALTER PROCEDURE dbo.usp_LoginRecord
    @AccountId int, @ObservedHash varchar(512), @ObservedEpoch bigint,
    @Accepted bit, @Sid binary(32)=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Now datetime2(3)=SYSUTCDATETIME(), @Hash varchar(512), @Version bigint, @State varchar(16), @Temp datetime2(3),
                @Count int, @Window datetime2(3), @Throttle datetime2(3), @Success bit=0, @Result varchar(16)='FAILURE';
        SELECT @Hash=password_hash, @Version=security_version, @State=status, @Temp=temp_issued_at,
               @Count=failed_login_count, @Window=failure_window_started_at, @Throttle=login_throttled_until
        FROM dbo.Account WHERE account_id=@AccountId;
        IF @Hash IS NOT NULL
        BEGIN
            IF @Hash COLLATE Latin1_General_100_BIN2<>@ObservedHash COLLATE Latin1_General_100_BIN2 OR @Version<>@ObservedEpoch OR @ObservedHash IS NULL OR @ObservedEpoch IS NULL
                THROW 51231, N'Credential đã thay đổi; phải kiểm tra lại mật khẩu.', 1;
            IF (@Throttle IS NOT NULL AND @Now>=@Throttle) OR (@Throttle IS NULL AND @Window IS NOT NULL AND @Now>=DATEADD(minute,15,@Window))
            BEGIN
                SET @Count=0; SET @Window=NULL; SET @Throttle=NULL;
            END;
            IF @State<>'ACTIVE' OR (@Throttle IS NOT NULL AND @Now<@Throttle) OR (@Temp IS NOT NULL AND @Now>=DATEADD(hour,24,@Temp)) 
                SET @Result='DENIED';
            ELSE IF @Accepted=1
            BEGIN
                IF @Sid IS NULL THROW 51232, N'Thiếu SID mới.', 1;
                SET @Success=1; SET @Result='SUCCESS';
                SET @Count=0; SET @Window=NULL; SET @Throttle=NULL;
                INSERT dbo.AuthSession(sid, account_id, issued_at, last_activity_at) VALUES(@Sid, @AccountId, @Now, @Now);
            END
            ELSE
            BEGIN
                SET @Count=@Count+1; SET @Window=ISNULL(@Window, @Now);
                IF @Count>=5 SET @Throttle=DATEADD(minute, 15, @Now);
            END;
            UPDATE dbo.Account SET failed_login_count=@Count, failure_window_started_at=@Window, login_throttled_until=@Throttle WHERE account_id=@AccountId;
        END
        ELSE IF @Accepted=1 THROW 51231, N'Tài khoản không tồn tại.', 1;
        DECLARE @Operation uniqueidentifier=NEWID(), @Action varchar(80)='DBMS12.AUTH.LOGIN.FAILURE';
        IF @Success=1 SET @Action='DBMS12.AUTH.LOGIN.SUCCESS';
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, CASE WHEN @Success=1 THEN @AccountId ELSE NULL END, @Action, @AccountId, @Result, N'Kết quả xác thực; không lưu credential hoặc SID.');
        SELECT @Success AS authenticated, @Result AS result_code, @Version AS security_version;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 4. usp_PasswordChange: Đổi mật khẩu, tăng epoch security và thu hồi toàn bộ phiên cũ
CREATE OR ALTER PROCEDURE dbo.usp_PasswordChange
    @Sid binary(32), @Epoch bigint, @ObservedHash varchar(512), @NewHash varchar(513)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, NULL, 1, 0, @Actor OUTPUT, @SessionRole OUTPUT;
        IF DATALENGTH(@NewHash)>512 THROW 51235, N'Hash vượt độ dài cho phép.', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Account WHERE account_id=@Actor AND password_hash COLLATE Latin1_General_100_BIN2=@ObservedHash COLLATE Latin1_General_100_BIN2)
            THROW 51231, N'Credential đã thay đổi.', 1;
        DELETE dbo.AuthSession WHERE account_id=@Actor;
        UPDATE dbo.Account SET password_hash=@NewHash, temp_issued_at=NULL, security_version=security_version+1,
            failed_login_count=0, failure_window_started_at=NULL, login_throttled_until=NULL WHERE account_id=@Actor;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(NEWID(), @Actor, 'DBMS12.AUTH.PASSWORD.CHANGE', @Actor, 'SUCCESS', N'Đổi mật khẩu và thu hồi toàn bộ phiên.');
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 5. usp_AccountCreateStaff: Admin tạo tài khoản nhân sự với mật khẩu tạm (Idempotent)
CREATE OR ALTER PROCEDURE dbo.usp_AccountCreateStaff
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @Role varchar(25), @Email varchar(255), @Name nvarchar(201), @Phone varchar(11), @PasswordHash varchar(513)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Admin', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ADMIN.ACCOUNT.CREATE', @Operation uniqueidentifier=NEWID(), @RootId int,
                @CompletionReason nvarchar(1000), @CompletionDetails nvarchar(4000);
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF DATALENGTH(@Role)>24 OR DATALENGTH(@Email)>254 OR DATALENGTH(@Name)>400 OR DATALENGTH(@Phone)>10 OR DATALENGTH(@PasswordHash)>512
            THROW 51235, N'Input vượt độ dài cho phép.', 1;
        IF @Role NOT IN ('Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin') OR @Role IS NULL 
            THROW 51229, N'Vai trò nhân sự không hợp lệ.', 1;
        INSERT dbo.Account(role_code, email, full_name, phone, password_hash, temp_issued_at)
        VALUES(@Role, @Email, @Name, @Phone, @PasswordHash, SYSUTCDATETIME());
        SET @RootId = CONVERT(int, SCOPE_IDENTITY());
        SET @CompletionDetails = N'Thao tác nghiệp vụ.';
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', @CompletionDetails);
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 6. usp_AccountSetStatus: Admin cập nhật trạng thái tài khoản (ACTIVE/LOCKED/DISABLED) và thu hồi phiên
CREATE OR ALTER PROCEDURE dbo.usp_AccountSetStatus
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @AccountId int, @AccountVersion binary(8), @Status varchar(17)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Admin', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ADMIN.ACCOUNT.STATUS', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF DATALENGTH(@Status)>16 THROW 51235, N'Input @Status vượt độ dài cho phép.', 1;
        IF @AccountId=@Actor THROW 51230, N'Không tự khóa/sửa trạng thái tài khoản đang dùng.', 1;
        IF @Status IS NULL OR @Status NOT IN ('ACTIVE','LOCKED','DISABLED') THROW 51229, N'Trạng thái không hợp lệ.', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Account WHERE account_id=@AccountId AND row_version=@AccountVersion) THROW 51228, N'Tài khoản đã thay đổi.', 1;
        DECLARE @OldStatus varchar(16);
        SELECT @OldStatus=status FROM dbo.Account WHERE account_id=@AccountId;
        IF NOT ((@Status='LOCKED' AND @OldStatus='ACTIVE') OR (@Status='DISABLED' AND @OldStatus IN ('ACTIVE','LOCKED')) OR (@Status='ACTIVE' AND @OldStatus IN ('LOCKED','DISABLED')))
            THROW 51229, N'Chuyển trạng thái tài khoản không hợp lệ.', 1;
        DELETE dbo.AuthSession WHERE account_id=@AccountId;
        UPDATE dbo.Account SET status=@Status, security_version=security_version+1 WHERE account_id=@AccountId;
        SET @RootId=@AccountId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', CONCAT(N'Trạng thái: ',@OldStatus,N' -> ',@Status));
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- PHẦN II: THÀNH VIÊN 2 (TV2) - ĐĂNG KÝ, TUYỂN SINH, HỌC PHÍ VÀ BÁO CÁO
-- ============================================================================

-- 7. usp_RegistrationCreate: Học viên tạo hồ sơ đăng ký PENDING (chống trùng hồ sơ chưa xong)
CREATE OR ALTER PROCEDURE dbo.usp_RegistrationCreate
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32), @CourseId int
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Student', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.STUDENT.REGISTRATION.CREATE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF NOT EXISTS(SELECT 1 FROM dbo.Course WHERE course_id=@CourseId AND status='ACTIVE') THROW 51210, N'Khóa không tuyển sinh.', 1;
        IF EXISTS(SELECT 1 FROM dbo.Registration WHERE student_account_id=@Actor AND course_id=@CourseId AND dbo.fn_RegistrationUnfinished(registration_id)=1)
            THROW 51211, N'Đã có hồ sơ chưa kết thúc.', 1;
        INSERT dbo.Registration(student_account_id, course_id) VALUES(@Actor, @CourseId);
        SET @RootId = CONVERT(int, SCOPE_IDENTITY());
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 8. usp_AdmissionApprove: Tuyển sinh duyệt hồ sơ CONFIRMED -> ADMITTED và phát hành hóa đơn cùng Transaction
CREATE OR ALTER PROCEDURE dbo.usp_AdmissionApprove
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @RegistrationId int, @ExpectedVersion binary(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Admissions', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ADMISSIONS.REGISTRATION.APPROVE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        DECLARE @Tuition decimal(18,0);
        SELECT @Tuition = p.tuition_fee FROM dbo.Registration r JOIN dbo.Course p ON p.course_id=r.course_id
        WHERE r.registration_id=@RegistrationId AND r.status='CONFIRMED' AND r.row_version=@ExpectedVersion AND p.status='ACTIVE';
        IF @Tuition IS NULL THROW 51212, N'Hồ sơ không đủ điều kiện duyệt hoặc đã thay đổi.', 1;
        UPDATE dbo.Registration SET status='ADMITTED' WHERE registration_id=@RegistrationId;
        INSERT dbo.Invoice(registration_id, amount) VALUES(@RegistrationId, @Tuition);
        SET @RootId = @RegistrationId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Duyệt nhập học và phát hành hóa đơn học phí.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 9. usp_AdmissionReject: Tuyển sinh từ chối hồ sơ kèm lý do bắt buộc
CREATE OR ALTER PROCEDURE dbo.usp_AdmissionReject
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @RegistrationId int, @ExpectedVersion binary(8), @Reason nvarchar(1001)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Admissions', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ADMISSIONS.REGISTRATION.REJECT', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF DATALENGTH(@Reason)>2000 THROW 51235, N'Input @Reason vượt độ dài cho phép.', 1;
        IF @Reason IS NULL OR LEN(LTRIM(RTRIM(@Reason)))=0 THROW 51213, N'Cần lý do.', 1;
        UPDATE r SET status='REJECTED' FROM dbo.Registration r
        WHERE r.registration_id=@RegistrationId AND r.status='CONFIRMED' AND r.row_version=@ExpectedVersion
          AND NOT EXISTS(SELECT 1 FROM dbo.Invoice i WHERE i.registration_id=r.registration_id AND i.paid_at IS NOT NULL);
        IF @@ROWCOUNT<>1 THROW 51212, N'Hồ sơ không đủ điều kiện/đã thay đổi.', 1;
        SET @RootId=@RegistrationId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, reason, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', @Reason, N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 10. usp_InvoiceCollect: Kế toán thu đủ học phí một lần, cập nhật thanh toán và audit nguyên tử
CREATE OR ALTER PROCEDURE dbo.usp_InvoiceCollect
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @InvoiceId int, @InvoiceVersion binary(8), @Method varchar(17), @Reference nvarchar(101)=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Accountant', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.FINANCE.INVOICE.COLLECT', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF DATALENGTH(@Method)>16 OR DATALENGTH(@Reference)>200 THROW 51235, N'Input vượt độ dài cho phép.', 1;
        IF @Method NOT IN ('CASH','BANK_TRANSFER') OR @Method IS NULL THROW 51214, N'Phương thức không hợp lệ.', 1;
        UPDATE i SET paid_at=SYSUTCDATETIME(), paid_by=@Actor, payment_method=@Method, payment_reference=@Reference
        FROM dbo.Invoice i JOIN dbo.Registration r ON r.registration_id=i.registration_id
        WHERE i.invoice_id=@InvoiceId AND i.row_version=@InvoiceVersion AND i.paid_at IS NULL AND r.status='ADMITTED';
        IF @@ROWCOUNT<>1 THROW 51214, N'Hóa đơn không hợp lệ hoặc đã thanh toán.', 1;
        SET @RootId=@InvoiceId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', CONCAT(N'Thu đủ qua ', @Method));
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 11. usp_InvoiceSearch: Kế toán tìm kiếm hóa đơn theo bộ lọc trạng thái, từ khóa và phân trang
CREATE OR ALTER PROCEDURE dbo.usp_InvoiceSearch
    @Sid binary(32), @Epoch bigint, @State varchar(16)=NULL, @Search nvarchar(200)=N'', @Page int=1, @PageSize int=20
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, NULL, 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        IF @SessionRole<>'Accountant' THROW 51203, N'Chỉ Accountant tra cứu tài chính.', 1;
        IF @Page<1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 51233, N'Phân trang không hợp lệ.', 1;
        SELECT i.invoice_id, CONVERT(varchar(20),i.invoice_number) AS invoice_number, i.registration_id,
            a.full_name, a.email, CONVERT(varchar(18),i.amount) AS amount, i.issued_at, i.paid_at, i.paid_by, i.payment_method, i.payment_reference,
            i.invoice_status, i.debt_flag, i.due_date, i.row_version
        FROM dbo.v_InvoiceFacts i JOIN dbo.Account a ON a.account_id=i.student_account_id
        WHERE (@State IS NULL OR i.invoice_status=@State) AND (a.full_name COLLATE Latin1_General_100_CI_AS_SC LIKE N'%'+@Search+N'%' OR a.email LIKE '%'+@Search+'%')
        ORDER BY i.invoice_id DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
        SELECT COUNT_BIG(*) AS total FROM dbo.v_InvoiceFacts i JOIN dbo.Account a ON a.account_id=i.student_account_id
        WHERE (@State IS NULL OR i.invoice_status=@State) AND (a.full_name COLLATE Latin1_General_100_CI_AS_SC LIKE N'%'+@Search+N'%' OR a.email LIKE '%'+@Search+'%');
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 12. usp_FinanceReport: Báo cáo tài chính tổng hợp (tổng phát hành, doanh thu thu được và nợ tồn đọng)
CREATE OR ALTER PROCEDURE dbo.usp_FinanceReport
    @Sid binary(32), @Epoch bigint, @From datetime2(3), @Until datetime2(3)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, NULL, 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        IF @SessionRole<>'Accountant' THROW 51203, N'Chỉ Accountant xem báo cáo tài chính chi tiết.', 1;
        IF @From IS NULL OR @Until IS NULL OR @Until<=@From THROW 51234, N'Khoảng ngày không hợp lệ.', 1;
        SELECT CONVERT(varchar(38),ISNULL(SUM(CONVERT(decimal(38,0),amount)),0)) AS billed FROM dbo.Invoice WHERE issued_at>=@From AND issued_at<@Until;
        SELECT CONVERT(varchar(38),ISNULL(SUM(CONVERT(decimal(38,0),amount)),0)) AS revenue FROM dbo.Invoice WHERE paid_at>=@From AND paid_at<@Until;
        SELECT CONVERT(varchar(38),ISNULL(SUM(CONVERT(decimal(38,0),amount)),0)) AS current_debt FROM dbo.v_InvoiceFacts WHERE invoice_status='UNPAID';
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- PHẦN III: THÀNH VIÊN 3 (TV3) - KHÓA HỌC, LỚP HỌC, XẾP LỚP VÀ LẬP LỊCH
-- ============================================================================

-- 13. usp_CourseCreate: Giáo vụ tạo khóa học mới kèm học phí và trọng số
CREATE OR ALTER PROCEDURE dbo.usp_CourseCreate
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @Code varchar(51), @Name nvarchar(201), @Tuition varchar(41), @Lessons int, @Weight varchar(41)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.COURSE.CREATE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF DATALENGTH(@Code)>50 OR DATALENGTH(@Name)>400 OR DATALENGTH(@Tuition)>40 OR DATALENGTH(@Weight)>40
            THROW 51235, N'Input vượt độ dài cho phép.', 1;
        DECLARE @Amount decimal(18,0);
        IF @Tuition IS NULL OR LEN(@Tuition) NOT BETWEEN 1 AND 18 OR @Tuition COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%' OR DATALENGTH(@Tuition)<>LEN(@Tuition) 
            THROW 51207, N'Tiền phải là số nguyên VND, tối đa 18 chữ số.', 1;
        SET @Amount = CONVERT(decimal(18,0), @Tuition);
        IF @Amount<=0 THROW 51207, N'Số tiền phải dương.', 1;
        IF dbo.fn_ValidScore(@Weight)<>1 OR @Weight IS NULL THROW 51208, N'Trọng số phải nằm giữa 0 và 100, tối đa 2 số thập phân.', 1;
        IF CONVERT(decimal(5,2),@Weight) NOT BETWEEN 0.01 AND 99.99 THROW 51208, N'Trọng số phải nằm giữa 0 và 100.', 1;
        INSERT dbo.Course(course_code, course_name, tuition_fee, expected_lesson_count, process_weight)
        VALUES(@Code, @Name, @Amount, @Lessons, CONVERT(decimal(5,2), @Weight));
        SET @RootId = CONVERT(int, SCOPE_IDENTITY());
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 14. usp_ClassOpen: Chuyển lớp PLANNED sang OPEN khi khóa/giáo viên hoạt động và có LESSON tương lai
CREATE OR ALTER PROCEDURE dbo.usp_ClassOpen
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ClassId int, @ExpectedVersion binary(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.CLASS.OPEN', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        UPDATE dbo.Class SET status='OPEN' WHERE class_id=@ClassId AND row_version=@ExpectedVersion AND status='PLANNED';
        IF @@ROWCOUNT<>1 THROW 51218, N'Lớp sai trạng thái hoặc đã thay đổi.', 1;
        SET @RootId=@ClassId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 15. usp_ClassStart: Chuyển OPEN sang ONGOING khi đủ lịch, 1 kỳ thi, có học viên và đến giờ học đầu
CREATE OR ALTER PROCEDURE dbo.usp_ClassStart
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ClassId int, @ExpectedVersion binary(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.CLASS.START', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        UPDATE dbo.Class SET status='ONGOING' WHERE class_id=@ClassId AND row_version=@ExpectedVersion AND status='OPEN';
        IF @@ROWCOUNT<>1 THROW 51218, N'Lớp sai trạng thái hoặc đã thay đổi.', 1;
        SET @RootId=@ClassId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 16. usp_ClassComplete: Chuyển ONGOING sang COMPLETED khi mọi buổi học đã HELD và không thiếu điểm danh
CREATE OR ALTER PROCEDURE dbo.usp_ClassComplete
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ClassId int, @ExpectedVersion binary(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.CLASS.COMPLETE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        UPDATE dbo.Class SET status='COMPLETED' WHERE class_id=@ClassId AND row_version=@ExpectedVersion AND status='ONGOING';
        IF @@ROWCOUNT<>1 THROW 51218, N'Lớp sai trạng thái hoặc đã thay đổi.', 1;
        SET @RootId=@ClassId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 17. usp_PlacementCreate: Xếp hồ sơ ADMITTED/PAID vào lớp OPEN và khởi tạo GradeReport cùng Transaction
CREATE OR ALTER PROCEDURE dbo.usp_PlacementCreate
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @RegistrationId int, @RegistrationVersion binary(8), @ClassId int, @ClassVersion binary(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.PLACEMENT.CREATE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF NOT EXISTS(SELECT 1 FROM dbo.Registration WHERE registration_id=@RegistrationId AND row_version=@RegistrationVersion) THROW 51212, N'Hồ sơ đã thay đổi.', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Class WHERE class_id=@ClassId AND row_version=@ClassVersion) THROW 51218, N'Lớp đã thay đổi.', 1;
        INSERT dbo.StudentClassAssignment(registration_id, class_id, assigned_by) VALUES(@RegistrationId, @ClassId, @Actor);
        DECLARE @AssignmentId int = CONVERT(int, SCOPE_IDENTITY());
        INSERT dbo.GradeReport(class_assignment_id) VALUES(@AssignmentId);
        UPDATE dbo.Class SET capacity=capacity WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Xếp một hồ sơ và tạo bảng điểm rỗng.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 18. usp_ScheduleBatch: Tạo toàn bộ lô lịch học từ TVP (Table-Valued Parameter) nguyên tử
CREATE OR ALTER PROCEDURE dbo.usp_ScheduleBatch
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ClassId int, @ClassVersion binary(8), @Items dbo.ScheduleBatch READONLY
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.SCHEDULE.BATCH', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF NOT EXISTS(SELECT 1 FROM dbo.Class WHERE class_id=@ClassId AND row_version=@ClassVersion AND status NOT IN ('COMPLETED','CANCELLED')) 
            THROW 51218, N'Lớp không còn hợp lệ.', 1;
        IF NOT EXISTS(SELECT 1 FROM @Items) THROW 51219, N'Danh sách lịch rỗng.', 1;
        INSERT dbo.Schedule(class_id, schedule_type, start_at, end_at, room)
        SELECT @ClassId, schedule_type, start_at, end_at, room FROM @Items;
        UPDATE dbo.Class SET capacity=capacity WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Tạo toàn bộ lịch trong batch; không lưu một phần.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- PHẦN IV: THÀNH VIÊN 4 (TV4) - TỔ CHỨC BUỔI HỌC, ĐIỂM DANH VÀ BẢNG ĐIỂM
-- ============================================================================

-- 19. usp_ScheduleHeld: Giáo vụ xác nhận buổi học đã diễn ra thực tế sau giờ kết thúc
CREATE OR ALTER PROCEDURE dbo.usp_ScheduleHeld
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ScheduleId int, @ExpectedVersion binary(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.SCHEDULE.HELD', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        UPDATE dbo.Schedule SET held_at=SYSUTCDATETIME(), held_by=@Actor 
        WHERE schedule_id=@ScheduleId AND row_version=@ExpectedVersion AND held_at IS NULL;
        IF @@ROWCOUNT<>1 THROW 51220, N'Buổi đã được xác nhận hoặc thay đổi.', 1;
        SET @RootId=@ScheduleId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 20. usp_AttendanceSave: Giáo viên lưu điểm danh cả lô từ TVP với kiểm soát OCC row_version
CREATE OR ALTER PROCEDURE dbo.usp_AttendanceSave
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ScheduleId int, @ClassVersion binary(8), @Items dbo.AttendanceBatch READONLY
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Teacher', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.TEACHER.ATTENDANCE.SAVE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        DECLARE @ClassId int;
        SELECT @ClassId=s.class_id FROM dbo.Schedule s JOIN dbo.Class c ON c.class_id=s.class_id
        WHERE s.schedule_id=@ScheduleId AND c.teacher_account_id=@Actor AND c.row_version=@ClassVersion;
        IF @ClassId IS NULL THROW 51221, N'Không phải lớp phụ trách hoặc lớp đã thay đổi.', 1;
        IF NOT EXISTS(SELECT 1 FROM @Items) THROW 51222, N'Danh sách điểm danh rỗng.', 1;
        IF EXISTS(SELECT 1 FROM @Items i LEFT JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=i.class_assignment_id AND a.class_id=@ClassId WHERE a.class_assignment_id IS NULL)
            THROW 51222, N'Học viên không thuộc lớp.', 1;
        IF EXISTS(SELECT 1 FROM @Items i LEFT JOIN dbo.Attendance a ON a.class_assignment_id=i.class_assignment_id AND a.schedule_id=@ScheduleId
                  WHERE (a.attendance_id IS NULL AND i.expected_version IS NOT NULL)
                     OR (a.attendance_id IS NOT NULL AND (i.expected_version IS NULL OR a.row_version<>i.expected_version)))
            THROW 51223, N'Điểm danh đã thay đổi.', 1;
        UPDATE a SET present=i.present, recorded_at=SYSUTCDATETIME()
        FROM dbo.Attendance a JOIN @Items i ON i.class_assignment_id=a.class_assignment_id WHERE a.schedule_id=@ScheduleId;
        INSERT dbo.Attendance(schedule_id, class_assignment_id, present)
        SELECT @ScheduleId, i.class_assignment_id, i.present FROM @Items i
        WHERE NOT EXISTS(SELECT 1 FROM dbo.Attendance a WHERE a.schedule_id=@ScheduleId AND a.class_assignment_id=i.class_assignment_id);
        SET @RootId=@ScheduleId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', N'Thao tác nghiệp vụ.');
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 21. usp_GradeSave: Giáo viên lưu hai điểm (quá trình & cuối kỳ) và nhận xét theo row_version
CREATE OR ALTER PROCEDURE dbo.usp_GradeSave
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ReportId int, @ReportVersion binary(8), @ClassVersion binary(8),
    @Continuous varchar(41), @Final varchar(41), @Comment nvarchar(1001)=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Teacher', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.TEACHER.GRADE.SAVE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF DATALENGTH(@Continuous)>40 OR DATALENGTH(@Final)>40 OR DATALENGTH(@Comment)>2000 THROW 51235, N'Input vượt độ dài cho phép.', 1;
        IF dbo.fn_ValidScore(@Continuous)<>1 OR dbo.fn_ValidScore(@Final)<>1 THROW 51224, N'Điểm 0–100, tối đa 2 số thập phân.', 1;
        DECLARE @OldContinuous decimal(5,2), @OldFinal decimal(5,2);
        SELECT @OldContinuous=continuous_score, @OldFinal=final_exam_score FROM dbo.GradeReport WHERE report_id=@ReportId;
        DECLARE @ScoreDetails nvarchar(4000) = CONCAT(N'Quá trình ', COALESCE(CONVERT(varchar(10),@OldContinuous),'NULL'), N' -> ', COALESCE(@Continuous,'NULL'),
            N'; cuối khóa ', COALESCE(CONVERT(varchar(10),@OldFinal),'NULL'), N' -> ', COALESCE(@Final,'NULL'));
        UPDATE g SET continuous_score=CONVERT(decimal(5,2),@Continuous), final_exam_score=CONVERT(decimal(5,2),@Final), teacher_comment=@Comment, updated_at=SYSUTCDATETIME()
        FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id
        JOIN dbo.Class c ON c.class_id=a.class_id
        WHERE g.report_id=@ReportId AND g.row_version=@ReportVersion AND c.row_version=@ClassVersion AND c.teacher_account_id=@Actor;
        IF @@ROWCOUNT<>1 THROW 51225, N'Không phải lớp phụ trách hoặc dữ liệu đã thay đổi.', 1;
        SET @RootId=@ReportId;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @RootId, 'SUCCESS', @ScoreDetails);
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 22. usp_GradeSubmit: Giáo viên nộp toàn bộ bảng điểm lớp COMPLETED kèm GradeManifest xác thực
CREATE OR ALTER PROCEDURE dbo.usp_GradeSubmit
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ClassId int, @ClassVersion binary(8), @Manifest dbo.GradeManifest READONLY
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'Teacher', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.TEACHER.GRADE.SUBMIT', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF NOT EXISTS(SELECT 1 FROM dbo.v_ClassState c WHERE c.class_id=@ClassId AND c.row_version=@ClassVersion AND c.status='COMPLETED' AND c.grade_status IN ('DRAFT','RETURNED')
            AND c.teacher_account_id=@Actor) THROW 51226, N'Lớp/bảng điểm sai trạng thái hoặc phiên bản.', 1;
        IF NOT EXISTS(SELECT 1 FROM @Manifest) THROW 51227, N'Manifest không được rỗng.', 1;
        IF EXISTS(SELECT g.report_id, g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId
                  EXCEPT SELECT report_id, expected_version FROM @Manifest)
           OR EXISTS(SELECT report_id, expected_version FROM @Manifest EXCEPT
                     SELECT g.report_id, g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId)
            THROW 51227, N'Manifest phải đủ và đúng toàn bộ lớp.', 1;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, change_details)
        VALUES(@Operation, @Actor, @Action, @ClassId, 'SUCCESS', N'Quyết định cho toàn bộ bảng điểm lớp.');
        UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 23. usp_GradeReturn: Giáo vụ trả lại bảng điểm SUBMITTED kèm lý do để Giáo viên chỉnh sửa
CREATE OR ALTER PROCEDURE dbo.usp_GradeReturn
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ClassId int, @ClassVersion binary(8), @Manifest dbo.GradeManifest READONLY, @Reason nvarchar(1001)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.GRADE.RETURN', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF DATALENGTH(@Reason)>2000 THROW 51235, N'Input @Reason vượt độ dài cho phép.', 1;
        IF @Reason IS NULL OR LEN(LTRIM(RTRIM(@Reason)))=0 THROW 51213, N'Cần lý do trả điểm.', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.v_ClassState c WHERE c.class_id=@ClassId AND c.row_version=@ClassVersion AND c.status='COMPLETED' AND c.grade_status='SUBMITTED') 
            THROW 51226, N'Lớp/bảng điểm sai trạng thái hoặc phiên bản.', 1;
        IF NOT EXISTS(SELECT 1 FROM @Manifest) THROW 51227, N'Manifest không được rỗng.', 1;
        IF EXISTS(SELECT g.report_id, g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId
                  EXCEPT SELECT report_id, expected_version FROM @Manifest)
           OR EXISTS(SELECT report_id, expected_version FROM @Manifest EXCEPT
                     SELECT g.report_id, g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId)
            THROW 51227, N'Manifest phải đủ và đúng toàn bộ lớp.', 1;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, reason, change_details)
        VALUES(@Operation, @Actor, @Action, @ClassId, 'SUCCESS', @Reason, N'Quyết định cho toàn bộ bảng điểm lớp.');
        UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 24. usp_GradeFinalize: Giáo vụ duyệt chốt bảng điểm chính thức toàn lớp (FINALIZED)
CREATE OR ALTER PROCEDURE dbo.usp_GradeFinalize
    @Sid binary(32), @Epoch bigint, @RequestId uniqueidentifier, @Digest binary(32),
    @ClassId int, @ClassVersion binary(8), @Manifest dbo.GradeManifest READONLY
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
        IF @@TRANCOUNT<>1 THROW 51200, N'Độ sâu transaction không hợp lệ.', 1;
        DECLARE @SecurityLockRows bigint;
        SELECT @SecurityLockRows = COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
        DECLARE @Actor int, @SessionRole varchar(24);
        EXEC dbo.usp_SecuritySession @Sid, @Epoch, 'AcademicAffairs', 0, 1, @Actor OUTPUT, @SessionRole OUTPUT;
        DECLARE @Action varchar(80)='DBMS12.ACADEMIC.GRADE.FINALIZE', @Operation uniqueidentifier=NEWID(), @RootId int;
        IF @RequestId IS NULL OR @Digest IS NULL THROW 51204, N'Thiếu UUID/digest.', 1;
        DECLARE @Previous uniqueidentifier, @PreviousDigest binary(32);
        SELECT @Previous=operation_id, @PreviousDigest=input_digest FROM dbo.ReplayOperation
        WHERE actor_account_id=@Actor AND action_code=@Action AND request_id=@RequestId AND completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
        IF @Previous IS NOT NULL
        BEGIN
            IF @PreviousDigest<>@Digest THROW 51205, N'UUID đã dùng cho nội dung khác.', 1;
            SELECT operation_id, root_entity_id AS target_id, CONVERT(bit,1) AS replayed FROM dbo.AuditLog WHERE operation_id=@Previous;
            IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF NOT EXISTS(SELECT 1 FROM dbo.v_ClassState c WHERE c.class_id=@ClassId AND c.row_version=@ClassVersion AND c.status='COMPLETED' AND c.grade_status='SUBMITTED') 
            THROW 51226, N'Lớp/bảng điểm sai trạng thái hoặc phiên bản.', 1;
        IF NOT EXISTS(SELECT 1 FROM @Manifest) THROW 51227, N'Manifest không được rỗng.', 1;
        IF EXISTS(SELECT g.report_id, g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId
                  EXCEPT SELECT report_id, expected_version FROM @Manifest)
           OR EXISTS(SELECT report_id, expected_version FROM @Manifest EXCEPT
                     SELECT g.report_id, g.row_version FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=@ClassId)
            THROW 51227, N'Manifest phải đủ và đúng toàn bộ lớp.', 1;
        INSERT dbo.AuditLog(operation_id, actor_account_id, action_code, root_entity_id, result_code, reason, change_details)
        VALUES(@Operation, @Actor, @Action, @ClassId, 'SUCCESS', NULL, N'Quyết định cho toàn bộ bảng điểm lớp.');
        UPDATE dbo.Class SET current_grade_operation_id=@Operation WHERE class_id=@ClassId;
        SET @RootId=@ClassId;
        INSERT dbo.ReplayOperation(actor_account_id, action_code, request_id, input_digest, operation_id) 
        VALUES(@Actor, @Action, @RequestId, @Digest, @Operation);
        UPDATE dbo.AuthSession SET last_activity_at=SYSUTCDATETIME() WHERE sid=@Sid;
        SELECT @Operation AS operation_id, @RootId AS target_id, CONVERT(bit,0) AS replayed;
        IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
