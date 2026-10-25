-- DBMS12 / SQL Server / independent database only
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF DB_NAME() NOT LIKE N'EnglishCenter_DBMS12[_]%' OR EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0)
    THROW 51000,N'Chỉ cài vào database DBMS12 mới, rỗng; không dùng database demo hiện hành.',1;
IF CONVERT(varchar(128),DATABASEPROPERTYEX(DB_NAME(),'Collation'))<>'Latin1_General_100_BIN2'
    THROW 51000,N'Database DBMS12 phải dùng Latin1_General_100_BIN2.',1;
CREATE SEQUENCE dbo.InvoiceNumberSequence AS bigint START WITH 1 INCREMENT BY 1 NO CYCLE;

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

CREATE TABLE dbo.[AuthSession] (
    [sid] binary(32) NOT NULL,
    [account_id] int NOT NULL,
    [issued_at] datetime2(3) NOT NULL CONSTRAINT [DF_AuthSession_issued_at] DEFAULT (SYSUTCDATETIME()),
    [last_activity_at] datetime2(3) NOT NULL,
    [row_version] rowversion NOT NULL,
    CONSTRAINT [PK_AuthSession] PRIMARY KEY ([sid]),
    CONSTRAINT [CK_AuthSession_01] CHECK (last_activity_at>=issued_at)
);

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

CREATE TABLE dbo.[StudentClassAssignment] (
    [class_assignment_id] int IDENTITY(1,1) NOT NULL,
    [registration_id] int NOT NULL,
    [class_id] int NOT NULL,
    [assigned_at] datetime2(3) NOT NULL CONSTRAINT [DF_StudentClassAssignment_assigned_at] DEFAULT (SYSUTCDATETIME()),
    [assigned_by] int NOT NULL,
    CONSTRAINT [PK_StudentClassAssignment] PRIMARY KEY ([class_assignment_id]),
    CONSTRAINT [UQ_StudentClassAssignment_01] UNIQUE ([registration_id])
);

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

ALTER TABLE dbo.[AuthSession] WITH CHECK ADD CONSTRAINT [FK_AuthSession_account_id] FOREIGN KEY ([account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Registration] WITH CHECK ADD CONSTRAINT [FK_Registration_student_account_id] FOREIGN KEY ([student_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Registration] WITH CHECK ADD CONSTRAINT [FK_Registration_course_id] FOREIGN KEY ([course_id]) REFERENCES dbo.[Course] ([course_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Class] WITH CHECK ADD CONSTRAINT [FK_Class_course_id] FOREIGN KEY ([course_id]) REFERENCES dbo.[Course] ([course_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Class] WITH CHECK ADD CONSTRAINT [FK_Class_teacher_account_id] FOREIGN KEY ([teacher_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Class] WITH CHECK ADD CONSTRAINT [FK_Class_current_grade_operation_id] FOREIGN KEY ([current_grade_operation_id]) REFERENCES dbo.[AuditLog] ([operation_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[StudentClassAssignment] WITH CHECK ADD CONSTRAINT [FK_StudentClassAssignment_registration_id] FOREIGN KEY ([registration_id]) REFERENCES dbo.[Registration] ([registration_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[StudentClassAssignment] WITH CHECK ADD CONSTRAINT [FK_StudentClassAssignment_class_id] FOREIGN KEY ([class_id]) REFERENCES dbo.[Class] ([class_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[StudentClassAssignment] WITH CHECK ADD CONSTRAINT [FK_StudentClassAssignment_assigned_by] FOREIGN KEY ([assigned_by]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Schedule] WITH CHECK ADD CONSTRAINT [FK_Schedule_class_id] FOREIGN KEY ([class_id]) REFERENCES dbo.[Class] ([class_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Schedule] WITH CHECK ADD CONSTRAINT [FK_Schedule_held_by] FOREIGN KEY ([held_by]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Attendance] WITH CHECK ADD CONSTRAINT [FK_Attendance_schedule_id] FOREIGN KEY ([schedule_id]) REFERENCES dbo.[Schedule] ([schedule_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Attendance] WITH CHECK ADD CONSTRAINT [FK_Attendance_class_assignment_id] FOREIGN KEY ([class_assignment_id]) REFERENCES dbo.[StudentClassAssignment] ([class_assignment_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[GradeReport] WITH CHECK ADD CONSTRAINT [FK_GradeReport_class_assignment_id] FOREIGN KEY ([class_assignment_id]) REFERENCES dbo.[StudentClassAssignment] ([class_assignment_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Invoice] WITH CHECK ADD CONSTRAINT [FK_Invoice_registration_id] FOREIGN KEY ([registration_id]) REFERENCES dbo.[Registration] ([registration_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[Invoice] WITH CHECK ADD CONSTRAINT [FK_Invoice_paid_by] FOREIGN KEY ([paid_by]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[AuditLog] WITH CHECK ADD CONSTRAINT [FK_AuditLog_actor_account_id] FOREIGN KEY ([actor_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[ReplayOperation] WITH CHECK ADD CONSTRAINT [FK_ReplayOperation_actor_account_id] FOREIGN KEY ([actor_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.[ReplayOperation] WITH CHECK ADD CONSTRAINT [FK_ReplayOperation_operation_id] FOREIGN KEY ([operation_id]) REFERENCES dbo.[AuditLog] ([operation_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

CREATE UNIQUE INDEX [UX_Class_CurrentGradeOperation] ON dbo.[Class] ([current_grade_operation_id]) WHERE current_grade_operation_id IS NOT NULL;

CREATE UNIQUE INDEX [UX_Schedule_OneFinalExam] ON dbo.[Schedule] ([class_id]) WHERE schedule_type='FINAL_EXAM';

CREATE INDEX [IX_Account_RoleStatus] ON dbo.[Account] ([role_code],[status],[account_id]);

CREATE INDEX [IX_AuthSession_Account] ON dbo.[AuthSession] ([account_id]) INCLUDE ([issued_at],[last_activity_at]);

CREATE INDEX [IX_Registration_StudentCourse] ON dbo.[Registration] ([student_account_id],[course_id],[status]) INCLUDE ([created_at]);

CREATE INDEX [IX_Registration_CourseStatus] ON dbo.[Registration] ([course_id],[status],[created_at]) INCLUDE ([student_account_id]);

CREATE INDEX [IX_Class_CourseStatus] ON dbo.[Class] ([course_id],[status]) INCLUDE ([capacity],[teacher_account_id]);

CREATE INDEX [IX_Class_TeacherStatus] ON dbo.[Class] ([teacher_account_id],[status]) INCLUDE ([course_id]);

CREATE INDEX [IX_Assignment_Class] ON dbo.[StudentClassAssignment] ([class_id],[class_assignment_id]) INCLUDE ([registration_id]);

CREATE INDEX [IX_Schedule_ClassStart] ON dbo.[Schedule] ([class_id],[start_at]) INCLUDE ([end_at],[schedule_type],[room],[held_at]);

CREATE INDEX [IX_Schedule_RoomStart] ON dbo.[Schedule] ([room],[start_at]) INCLUDE ([end_at],[class_id]);

CREATE INDEX [IX_Attendance_Assignment] ON dbo.[Attendance] ([class_assignment_id],[schedule_id]) INCLUDE ([present]);

CREATE INDEX [IX_Invoice_Issued] ON dbo.[Invoice] ([issued_at],[invoice_id]) INCLUDE ([amount],[registration_id],[paid_at]);

CREATE INDEX [IX_Invoice_Paid] ON dbo.[Invoice] ([paid_at],[invoice_id]) INCLUDE ([amount],[registration_id]) WHERE paid_at IS NOT NULL;

CREATE INDEX [IX_Audit_RootAction] ON dbo.[AuditLog] ([root_entity_id],[action_code],[audit_id]) INCLUDE ([occurred_at],[result_code],[actor_account_id]);

CREATE INDEX [IX_Audit_Time] ON dbo.[AuditLog] ([occurred_at],[audit_id]) INCLUDE ([actor_account_id],[action_code],[result_code]);

CREATE INDEX [IX_Replay_Completed] ON dbo.[ReplayOperation] ([completed_at],[replay_id]);
