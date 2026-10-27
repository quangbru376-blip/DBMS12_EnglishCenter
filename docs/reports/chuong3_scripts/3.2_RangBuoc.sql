-- ============================================================================
-- CHƯƠNG 3. CÀI ĐẶT CƠ SỞ DỮ LIỆU
-- 3.2. RÀNG BUỘC (TOÀN BỘ CÁC RÀNG BUỘC TOÀN VẸN CỦA HỆ THỐNG)
-- Bao gồm: 19 FK, 11 UNIQUE, 2 Filtered UNIQUE, 34 CHECK, 20 DEFAULT
-- ============================================================================

-- I. 19 KHÓA NGOẠI (FOREIGN KEYS) - QUAN HỆ THAM CHIẾU GIỮA CÁC BẢNG

-- R01: AuthSession -> Account
ALTER TABLE dbo.[AuthSession] WITH CHECK ADD CONSTRAINT [FK_AuthSession_account_id] 
    FOREIGN KEY ([account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R02: Registration -> Account (Học viên)
ALTER TABLE dbo.[Registration] WITH CHECK ADD CONSTRAINT [FK_Registration_student_account_id] 
    FOREIGN KEY ([student_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R03: Registration -> Course (Khóa học)
ALTER TABLE dbo.[Registration] WITH CHECK ADD CONSTRAINT [FK_Registration_course_id] 
    FOREIGN KEY ([course_id]) REFERENCES dbo.[Course] ([course_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R04: Class -> Course
ALTER TABLE dbo.[Class] WITH CHECK ADD CONSTRAINT [FK_Class_course_id] 
    FOREIGN KEY ([course_id]) REFERENCES dbo.[Course] ([course_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R05: Class -> Account (Giáo viên phụ trách)
ALTER TABLE dbo.[Class] WITH CHECK ADD CONSTRAINT [FK_Class_teacher_account_id] 
    FOREIGN KEY ([teacher_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R06: Class -> AuditLog (Giao dịch chốt bảng điểm)
ALTER TABLE dbo.[Class] WITH CHECK ADD CONSTRAINT [FK_Class_current_grade_operation_id] 
    FOREIGN KEY ([current_grade_operation_id]) REFERENCES dbo.[AuditLog] ([operation_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R07: StudentClassAssignment -> Registration
ALTER TABLE dbo.[StudentClassAssignment] WITH CHECK ADD CONSTRAINT [FK_StudentClassAssignment_registration_id] 
    FOREIGN KEY ([registration_id]) REFERENCES dbo.[Registration] ([registration_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R08: StudentClassAssignment -> Class
ALTER TABLE dbo.[StudentClassAssignment] WITH CHECK ADD CONSTRAINT [FK_StudentClassAssignment_class_id] 
    FOREIGN KEY ([class_id]) REFERENCES dbo.[Class] ([class_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R09: StudentClassAssignment -> Account (Giáo vụ xếp lớp)
ALTER TABLE dbo.[StudentClassAssignment] WITH CHECK ADD CONSTRAINT [FK_StudentClassAssignment_assigned_by] 
    FOREIGN KEY ([assigned_by]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R10: Schedule -> Class
ALTER TABLE dbo.[Schedule] WITH CHECK ADD CONSTRAINT [FK_Schedule_class_id] 
    FOREIGN KEY ([class_id]) REFERENCES dbo.[Class] ([class_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R11: Schedule -> Account (Giáo vụ xác nhận buổi học)
ALTER TABLE dbo.[Schedule] WITH CHECK ADD CONSTRAINT [FK_Schedule_held_by] 
    FOREIGN KEY ([held_by]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R12: Attendance -> Schedule
ALTER TABLE dbo.[Attendance] WITH CHECK ADD CONSTRAINT [FK_Attendance_schedule_id] 
    FOREIGN KEY ([schedule_id]) REFERENCES dbo.[Schedule] ([schedule_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R13: Attendance -> StudentClassAssignment
ALTER TABLE dbo.[Attendance] WITH CHECK ADD CONSTRAINT [FK_Attendance_class_assignment_id] 
    FOREIGN KEY ([class_assignment_id]) REFERENCES dbo.[StudentClassAssignment] ([class_assignment_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R14: GradeReport -> StudentClassAssignment
ALTER TABLE dbo.[GradeReport] WITH CHECK ADD CONSTRAINT [FK_GradeReport_class_assignment_id] 
    FOREIGN KEY ([class_assignment_id]) REFERENCES dbo.[StudentClassAssignment] ([class_assignment_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R15: Invoice -> Registration
ALTER TABLE dbo.[Invoice] WITH CHECK ADD CONSTRAINT [FK_Invoice_registration_id] 
    FOREIGN KEY ([registration_id]) REFERENCES dbo.[Registration] ([registration_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R16: Invoice -> Account (Kế toán thu tiền)
ALTER TABLE dbo.[Invoice] WITH CHECK ADD CONSTRAINT [FK_Invoice_paid_by] 
    FOREIGN KEY ([paid_by]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R17: AuditLog -> Account (Người thực hiện hành động)
ALTER TABLE dbo.[AuditLog] WITH CHECK ADD CONSTRAINT [FK_AuditLog_actor_account_id] 
    FOREIGN KEY ([actor_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R18: ReplayOperation -> Account
ALTER TABLE dbo.[ReplayOperation] WITH CHECK ADD CONSTRAINT [FK_ReplayOperation_actor_account_id] 
    FOREIGN KEY ([actor_account_id]) REFERENCES dbo.[Account] ([account_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- R19: ReplayOperation -> AuditLog
ALTER TABLE dbo.[ReplayOperation] WITH CHECK ADD CONSTRAINT [FK_ReplayOperation_operation_id] 
    FOREIGN KEY ([operation_id]) REFERENCES dbo.[AuditLog] ([operation_id]) ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- II. RÀNG BUỘC DUY NHẤT & CHỈ MỤC CÓ LỌC (UNIQUE & FILTERED UNIQUE)

-- UQ_Account_01: Mỗi email chỉ đăng ký duy nhất 1 tài khoản
-- UQ_Course_01: Mã khóa học duy nhất
-- UQ_Class_01: Mã lớp học duy nhất
-- UQ_StudentClassAssignment_01: Mỗi hồ sơ đăng ký chỉ xếp vào duy nhất 1 lớp (1 -> 0..1)
-- UQ_Attendance_01: Mỗi học viên chỉ điểm danh 1 lần cho 1 buổi học
-- UQ_GradeReport_01: Mỗi phân công học viên chỉ sở hữu 1 bảng điểm
-- UQ_Invoice_01: Số hóa đơn duy nhất
-- UQ_Invoice_02: Mỗi hồ sơ chỉ có đúng 1 hóa đơn học phí
-- UQ_AuditLog_01: Mỗi thao tác kiểm toán có mã UUID operation_id duy nhất
-- UQ_ReplayOperation_01: Bộ ba (actor_account_id, action_code, request_id) chống lặp lệnh
-- UQ_ReplayOperation_02: Liên kết 1-1 với operation_id của AuditLog

-- Ràng buộc duy nhất có lọc nghiệp vụ (Filtered Unique Indexes):
CREATE UNIQUE INDEX [UX_Class_CurrentGradeOperation] ON dbo.[Class] ([current_grade_operation_id]) 
    WHERE current_grade_operation_id IS NOT NULL; -- Mỗi giao dịch chốt điểm chỉ gán cho tối đa 1 lớp

CREATE UNIQUE INDEX [UX_Schedule_OneFinalExam] ON dbo.[Schedule] ([class_id]) 
    WHERE schedule_type='FINAL_EXAM'; -- Mỗi lớp chỉ có nhiều nhất 1 kỳ thi kết thúc khóa
GO

-- III. TỔNG HỢP 34 RÀNG BUỘC KIỂM TRA (CHECK CONSTRAINTS)

-- 1. Bảng Account (9 CHECKs):
-- CK_Account_01: role_code IN ('Student','Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin') AND DATALENGTH(role_code)=LEN(role_code)
-- CK_Account_02: status IN ('ACTIVE','LOCKED','DISABLED') AND DATALENGTH(status)=LEN(status)
-- CK_Account_03: LEN(email) BETWEEN 3 AND 254 AND DATALENGTH(email)=DATALENGTH(LTRIM(RTRIM(email)))
-- CK_Account_04: LEN(LTRIM(RTRIM(full_name))) > 0
-- CK_Account_05: phone IS NULL OR (DATALENGTH(phone)=10 AND LEFT(phone,1)='0' AND phone COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%')
-- CK_Account_06: (role_code='Student' AND date_of_birth IS NOT NULL) OR (role_code<>'Student' AND date_of_birth IS NULL AND address IS NULL)
-- CK_Account_07: security_version >= 1 AND failed_login_count >= 0
-- CK_Account_08: State Machine bảo vệ đăng nhập và chống tấn công dò mật khẩu brute-force
-- CK_Account_09: LEN(password_hash) > 0

-- 2. Bảng AuthSession (1 CHECK):
-- CK_AuthSession_01: last_activity_at >= issued_at

-- 3. Bảng Course (5 CHECKs):
-- CK_Course_01: LEN(LTRIM(RTRIM(course_code)))>0 AND DATALENGTH(course_code)=DATALENGTH(LTRIM(RTRIM(course_code))) AND LEN(LTRIM(RTRIM(course_name)))>0
-- CK_Course_02: tuition_fee > 0
-- CK_Course_03: (status IN ('ACTIVE','INACTIVE') AND DATALENGTH(status)=LEN(status))
-- CK_Course_04: expected_lesson_count > 0
-- CK_Course_05: process_weight > 0 AND process_weight < 100

-- 4. Bảng Registration (1 CHECK):
-- CK_Registration_01: (status IN ('PENDING','CONFIRMED','ADMITTED','REJECTED','CANCELLED') AND DATALENGTH(status)=LEN(status))

-- 5. Bảng Class (4 CHECKs):
-- CK_Class_01: LEN(LTRIM(RTRIM(class_code)))>0 AND DATALENGTH(class_code)=DATALENGTH(LTRIM(RTRIM(class_code)))
-- CK_Class_02: capacity BETWEEN 1 AND 15
-- CK_Class_03: (status IN ('PLANNED','OPEN','ONGOING','COMPLETED','CANCELLED') AND DATALENGTH(status)=LEN(status))
-- CK_Class_04: current_grade_operation_id IS NULL OR status='COMPLETED'

-- 6. Bảng Schedule (4 CHECKs):
-- CK_Schedule_01: (schedule_type IN ('LESSON','FINAL_EXAM') AND DATALENGTH(schedule_type)=LEN(schedule_type))
-- CK_Schedule_02: end_at > start_at
-- CK_Schedule_03: LEN(LTRIM(RTRIM(room)))>0 AND DATALENGTH(room)=DATALENGTH(LTRIM(RTRIM(room)))
-- CK_Schedule_04: (held_at IS NULL AND held_by IS NULL) OR (held_at IS NOT NULL AND held_by IS NOT NULL AND held_at>=end_at)

-- 7. Bảng GradeReport (2 CHECKs):
-- CK_GradeReport_01: continuous_score IS NULL OR continuous_score BETWEEN 0 AND 100
-- CK_GradeReport_02: final_exam_score IS NULL OR final_exam_score BETWEEN 0 AND 100

-- 8. Bảng Invoice (2 CHECKs):
-- CK_Invoice_01: invoice_number > 0 AND amount > 0
-- CK_Invoice_02: State Machine thanh toán hóa đơn (chưa nộp = 4 trường NULL; đã nộp = đủ thông tin thu tiền, method hợp lệ)

-- 9. Bảng AuditLog (5 CHECKs):
-- CK_AuditLog_01: LEN(action_code)>7 AND action_code LIKE 'DBMS12.%'
-- CK_AuditLog_02: (result_code IN ('SUCCESS','DENIED','FAILURE') AND DATALENGTH(result_code)=LEN(result_code))
-- CK_AuditLog_03: root_entity_id IS NULL OR root_entity_id > 0
-- CK_AuditLog_04: reason IS NULL OR LEN(LTRIM(RTRIM(reason))) > 0
-- CK_AuditLog_05: ip_address IS NULL OR LEN(ip_address) > 0

-- 10. Bảng ReplayOperation (1 CHECK):
-- CK_ReplayOperation_01: LEN(action_code)>7 AND action_code LIKE 'DBMS12.%'
GO
