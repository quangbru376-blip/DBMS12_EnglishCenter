-- ============================================================================
-- CHƯƠNG 3. CÀI ĐẶT CƠ SỞ DỮ LIỆU
-- 3.1. QUAN HỆ (DDL TẠO SEQUENCE, TYPE VÀ 12 BẢNG QUAN HỆ)
-- Hệ thống: DBMS12 EnglishCenter | Collation: Latin1_General_100_BIN2
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. SEQUENCE SINH SỐ HÓA ĐƠN TOÀN CỤC
CREATE SEQUENCE dbo.InvoiceNumberSequence AS bigint START WITH 1 INCREMENT BY 1 NO CYCLE;
GO

-- 2. USER-DEFINED TABLE TYPES (TVP) CHO THAO TÁC LÔ (BATCH OPERATIONS)
CREATE TYPE dbo.ScheduleBatch AS TABLE (
    item_no int NOT NULL PRIMARY KEY,
    schedule_type varchar(16) NOT NULL,
    start_at datetime2(3) NOT NULL,
    end_at datetime2(3) NOT NULL,
    room nvarchar(50) NOT NULL
);
GO

CREATE TYPE dbo.AttendanceBatch AS TABLE (
    class_assignment_id int NOT NULL PRIMARY KEY,
    present bit NOT NULL,
    expected_version binary(8) NULL
);
GO

CREATE TYPE dbo.GradeManifest AS TABLE (
    report_id int NOT NULL PRIMARY KEY,
    expected_version binary(8) NOT NULL
);
GO

-- 3. ĐỊNH NGHĨA 12 BẢNG DỮ LIỆU CHUẨN HÓA 3NF

-- Bảng 1: Account (Tài khoản người dùng 7 vai trò & Hồ sơ học viên)
CREATE TABLE dbo.[Account] (
    [account_id] int IDENTITY(1,1) NOT NULL,
    [role_code] varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [email] varchar(254) COLLATE Latin1_General_100_CI_AS_SC NOT NULL,
    [full_name] nvarchar(200) NOT NULL,
    [phone] varchar(10) NULL,
    [date_of_birth] date NULL,
    [address] nvarchar(255) NULL,
    [password_hash] varchar(512) NOT NULL,
    [status] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_Account_status] DEFAULT ('ACTIVE'),
    [created_at] datetime2(3) NOT NULL CONSTRAINT [DF_Account_created_at] DEFAULT (SYSUTCDATETIME()),
    [security_version] bigint NOT NULL CONSTRAINT [DF_Account_security_version] DEFAULT (1),
    [failed_login_count] int NOT NULL CONSTRAINT [DF_Account_failed_login_count] DEFAULT (0),
    [failure_window_started_at] datetime2(3) NULL,
    [login_throttled_until] datetime2(3) NULL,
    [temp_issued_at] datetime2(3) NULL,
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_Account] PRIMARY KEY ([account_id]),
    CONSTRAINT [UQ_Account_01] UNIQUE ([email]),
    CONSTRAINT [CK_Account_01] CHECK ((role_code IN ('Student','Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin') AND DATALENGTH(role_code)=LEN(role_code))),
    CONSTRAINT [CK_Account_02] CHECK ((status IN ('ACTIVE','LOCKED','DISABLED') AND DATALENGTH(status)=LEN(status))),
    CONSTRAINT [CK_Account_03] CHECK (LEN(email) BETWEEN 3 AND 254 AND DATALENGTH(email)=DATALENGTH(LTRIM(RTRIM(email)))),
    CONSTRAINT [CK_Account_04] CHECK (LEN(LTRIM(RTRIM(full_name))) > 0),
    CONSTRAINT [CK_Account_05] CHECK (phone IS NULL OR (DATALENGTH(phone)=10 AND LEFT(phone,1)='0' AND phone COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%')),
    CONSTRAINT [CK_Account_06] CHECK ((role_code='Student' AND date_of_birth IS NOT NULL) OR (role_code<>'Student' AND date_of_birth IS NULL AND address IS NULL)),
    CONSTRAINT [CK_Account_07] CHECK (security_version >= 1 AND failed_login_count >= 0),
    CONSTRAINT [CK_Account_08] CHECK ((failed_login_count=0 AND failure_window_started_at IS NULL AND login_throttled_until IS NULL) OR (failed_login_count>0 AND failure_window_started_at IS NOT NULL AND (login_throttled_until IS NULL OR login_throttled_until>=failure_window_started_at))),
    CONSTRAINT [CK_Account_09] CHECK (LEN(password_hash)>0)
);
GO

-- Bảng 2: AuthSession (Phiên đăng nhập người dùng)
CREATE TABLE dbo.[AuthSession] (
    [sid] binary(32) NOT NULL,
    [account_id] int NOT NULL,
    [issued_at] datetime2(3) NOT NULL CONSTRAINT [DF_AuthSession_issued_at] DEFAULT (SYSUTCDATETIME()),
    [last_activity_at] datetime2(3) NOT NULL,
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_AuthSession] PRIMARY KEY ([sid]),
    CONSTRAINT [CK_AuthSession_01] CHECK (last_activity_at>=issued_at)
);
GO

-- Bảng 3: Course (Danh mục khóa học đào tạo)
CREATE TABLE dbo.[Course] (
    [course_id] int IDENTITY(1,1) NOT NULL,
    [course_code] varchar(50) COLLATE Latin1_General_100_CI_AS_SC NOT NULL,
    [course_name] nvarchar(200) NOT NULL,
    [tuition_fee] decimal(18,0) NOT NULL,
    [status] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_Course_status] DEFAULT ('ACTIVE'),
    [expected_lesson_count] int NOT NULL,
    [process_weight] decimal(5,2) NOT NULL,
    [created_at] datetime2(3) NOT NULL CONSTRAINT [DF_Course_created_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_Course] PRIMARY KEY ([course_id]),
    CONSTRAINT [UQ_Course_01] UNIQUE ([course_code]),
    CONSTRAINT [CK_Course_01] CHECK (LEN(LTRIM(RTRIM(course_code)))>0 AND DATALENGTH(course_code)=DATALENGTH(LTRIM(RTRIM(course_code))) AND LEN(LTRIM(RTRIM(course_name)))>0),
    CONSTRAINT [CK_Course_02] CHECK (tuition_fee>0),
    CONSTRAINT [CK_Course_03] CHECK ((status IN ('ACTIVE','INACTIVE') AND DATALENGTH(status)=LEN(status))),
    CONSTRAINT [CK_Course_04] CHECK (expected_lesson_count>0),
    CONSTRAINT [CK_Course_05] CHECK (process_weight>0 AND process_weight<100)
);
GO

-- Bảng 4: Registration (Hồ sơ đăng ký học)
CREATE TABLE dbo.[Registration] (
    [registration_id] int IDENTITY(1,1) NOT NULL,
    [student_account_id] int NOT NULL,
    [course_id] int NOT NULL,
    [status] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_Registration_status] DEFAULT ('PENDING'),
    [created_at] datetime2(3) NOT NULL CONSTRAINT [DF_Registration_created_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_Registration] PRIMARY KEY ([registration_id]),
    CONSTRAINT [CK_Registration_01] CHECK ((status IN ('PENDING','CONFIRMED','ADMITTED','REJECTED','CANCELLED') AND DATALENGTH(status)=LEN(status)))
);
GO

-- Bảng 5: Class (Lớp học mở)
CREATE TABLE dbo.[Class] (
    [class_id] int IDENTITY(1,1) NOT NULL,
    [class_code] varchar(50) COLLATE Latin1_General_100_CI_AS_SC NOT NULL,
    [course_id] int NOT NULL,
    [teacher_account_id] int NOT NULL,
    [capacity] tinyint NOT NULL CONSTRAINT [DF_Class_capacity] DEFAULT (15),
    [status] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_Class_status] DEFAULT ('PLANNED'),
    [current_grade_operation_id] uniqueidentifier NULL,
    [created_at] datetime2(3) NOT NULL CONSTRAINT [DF_Class_created_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_Class] PRIMARY KEY ([class_id]),
    CONSTRAINT [UQ_Class_01] UNIQUE ([class_code]),
    CONSTRAINT [CK_Class_01] CHECK (LEN(LTRIM(RTRIM(class_code)))>0 AND DATALENGTH(class_code)=DATALENGTH(LTRIM(RTRIM(class_code)))),
    CONSTRAINT [CK_Class_02] CHECK (capacity BETWEEN 1 AND 15),
    CONSTRAINT [CK_Class_03] CHECK ((status IN ('PLANNED','OPEN','ONGOING','COMPLETED','CANCELLED') AND DATALENGTH(status)=LEN(status))),
    CONSTRAINT [CK_Class_04] CHECK (current_grade_operation_id IS NULL OR status='COMPLETED')
);
GO

-- Bảng 6: StudentClassAssignment (Phân công học viên vào lớp học)
CREATE TABLE dbo.[StudentClassAssignment] (
    [class_assignment_id] int IDENTITY(1,1) NOT NULL,
    [registration_id] int NOT NULL,
    [class_id] int NOT NULL,
    [assigned_at] datetime2(3) NOT NULL CONSTRAINT [DF_StudentClassAssignment_assigned_at] DEFAULT (SYSUTCDATETIME()),
    [assigned_by] int NOT NULL,
    CONSTRAINT [PK_StudentClassAssignment] PRIMARY KEY ([class_assignment_id]),
    CONSTRAINT [UQ_StudentClassAssignment_01] UNIQUE ([registration_id])
);
GO

-- Bảng 7: Schedule (Lịch học và lịch thi)
CREATE TABLE dbo.[Schedule] (
    [schedule_id] int IDENTITY(1,1) NOT NULL,
    [class_id] int NOT NULL,
    [schedule_type] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [start_at] datetime2(3) NOT NULL,
    [end_at] datetime2(3) NOT NULL,
    [room] nvarchar(50) COLLATE Latin1_General_100_CI_AS_SC NOT NULL,
    [held_at] datetime2(3) NULL,
    [held_by] int NULL,
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_Schedule] PRIMARY KEY ([schedule_id]),
    CONSTRAINT [CK_Schedule_01] CHECK ((schedule_type IN ('LESSON','FINAL_EXAM') AND DATALENGTH(schedule_type)=LEN(schedule_type))),
    CONSTRAINT [CK_Schedule_02] CHECK (end_at>start_at),
    CONSTRAINT [CK_Schedule_03] CHECK (LEN(LTRIM(RTRIM(room)))>0 AND DATALENGTH(room)=DATALENGTH(LTRIM(RTRIM(room)))),
    CONSTRAINT [CK_Schedule_04] CHECK ((held_at IS NULL AND held_by IS NULL) OR (held_at IS NOT NULL AND held_by IS NOT NULL AND held_at>=end_at))
);
GO

-- Bảng 8: Attendance (Điểm danh học viên theo buổi học)
CREATE TABLE dbo.[Attendance] (
    [attendance_id] int IDENTITY(1,1) NOT NULL,
    [schedule_id] int NOT NULL,
    [class_assignment_id] int NOT NULL,
    [present] bit NOT NULL,
    [recorded_at] datetime2(3) NOT NULL CONSTRAINT [DF_Attendance_recorded_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_Attendance] PRIMARY KEY ([attendance_id]),
    CONSTRAINT [UQ_Attendance_01] UNIQUE ([schedule_id],[class_assignment_id])
);
GO

-- Bảng 9: GradeReport (Bảng điểm và kết quả học tập)
CREATE TABLE dbo.[GradeReport] (
    [report_id] int IDENTITY(1,1) NOT NULL,
    [class_assignment_id] int NOT NULL,
    [continuous_score] decimal(5,2) NULL,
    [final_exam_score] decimal(5,2) NULL,
    [teacher_comment] nvarchar(1000) NULL,
    [updated_at] datetime2(3) NOT NULL CONSTRAINT [DF_GradeReport_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_GradeReport] PRIMARY KEY ([report_id]),
    CONSTRAINT [UQ_GradeReport_01] UNIQUE ([class_assignment_id]),
    CONSTRAINT [CK_GradeReport_01] CHECK (continuous_score IS NULL OR continuous_score BETWEEN 0 AND 100),
    CONSTRAINT [CK_GradeReport_02] CHECK (final_exam_score IS NULL OR final_exam_score BETWEEN 0 AND 100)
);
GO

-- Bảng 10: Invoice (Hóa đơn thu học phí)
CREATE TABLE dbo.[Invoice] (
    [invoice_id] int IDENTITY(1,1) NOT NULL,
    [invoice_number] bigint NOT NULL CONSTRAINT [DF_Invoice_invoice_number] DEFAULT (NEXT VALUE FOR dbo.InvoiceNumberSequence),
    [registration_id] int NOT NULL,
    [amount] decimal(18,0) NOT NULL,
    [issued_at] datetime2(3) NOT NULL CONSTRAINT [DF_Invoice_issued_at] DEFAULT (SYSUTCDATETIME()),
    [paid_at] datetime2(3) NULL,
    [paid_by] int NULL,
    [payment_method] varchar(16) COLLATE Latin1_General_100_BIN2 NULL,
    [payment_reference] nvarchar(100) NULL,
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_Invoice] PRIMARY KEY ([invoice_id]),
    CONSTRAINT [UQ_Invoice_01] UNIQUE ([invoice_number]),
    CONSTRAINT [UQ_Invoice_02] UNIQUE ([registration_id]),
    CONSTRAINT [CK_Invoice_01] CHECK (invoice_number>0 AND amount>0),
    CONSTRAINT [CK_Invoice_02] CHECK ((paid_at IS NULL AND paid_by IS NULL AND payment_method IS NULL AND payment_reference IS NULL) OR (paid_at IS NOT NULL AND paid_by IS NOT NULL AND payment_method IS NOT NULL AND (payment_method IN ('CASH','BANK_TRANSFER') AND DATALENGTH(payment_method)=LEN(payment_method)) AND paid_at>=issued_at AND (payment_reference IS NULL OR LEN(LTRIM(RTRIM(payment_reference)))>0)))
);
GO

-- Bảng 11: AuditLog (Nhật ký kiểm toán hệ thống)
CREATE TABLE dbo.[AuditLog] (
    [audit_id] bigint IDENTITY(1,1) NOT NULL,
    [operation_id] uniqueidentifier NOT NULL,
    [actor_account_id] int NULL,
    [action_code] varchar(80) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [root_entity_id] int NULL,
    [result_code] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [occurred_at] datetime2(3) NOT NULL CONSTRAINT [DF_AuditLog_occurred_at] DEFAULT (SYSUTCDATETIME()),
    [reason] nvarchar(1000) NULL,
    [change_details] nvarchar(4000) NOT NULL CONSTRAINT [DF_AuditLog_change_details] DEFAULT (N''),
    [ip_address] varchar(45) NULL,
    CONSTRAINT [PK_AuditLog] PRIMARY KEY ([audit_id]),
    CONSTRAINT [UQ_AuditLog_01] UNIQUE ([operation_id]),
    CONSTRAINT [CK_AuditLog_01] CHECK (LEN(action_code)>7 AND action_code LIKE 'DBMS12.%'),
    CONSTRAINT [CK_AuditLog_02] CHECK ((result_code IN ('SUCCESS','DENIED','FAILURE') AND DATALENGTH(result_code)=LEN(result_code))),
    CONSTRAINT [CK_AuditLog_03] CHECK (root_entity_id IS NULL OR root_entity_id>0),
    CONSTRAINT [CK_AuditLog_04] CHECK (reason IS NULL OR LEN(LTRIM(RTRIM(reason)))>0),
    CONSTRAINT [CK_AuditLog_05] CHECK (ip_address IS NULL OR LEN(ip_address)>0)
);
GO

-- Bảng 12: ReplayOperation (Bảo đảm Idempotency chống lặp lệnh)
CREATE TABLE dbo.[ReplayOperation] (
    [replay_id] bigint IDENTITY(1,1) NOT NULL,
    [actor_account_id] int NOT NULL,
    [action_code] varchar(80) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_id] uniqueidentifier NOT NULL,
    [input_digest] binary(32) NOT NULL,
    [operation_id] uniqueidentifier NOT NULL,
    [completed_at] datetime2(3) NOT NULL CONSTRAINT [DF_ReplayOperation_completed_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ReplayOperation] PRIMARY KEY ([replay_id]),
    CONSTRAINT [UQ_ReplayOperation_01] UNIQUE ([actor_account_id],[action_code],[request_id]),
    CONSTRAINT [UQ_ReplayOperation_02] UNIQUE ([operation_id]),
    CONSTRAINT [CK_ReplayOperation_01] CHECK (LEN(action_code)>7 AND action_code LIKE 'DBMS12.%')
);
GO
