-- ============================================================================
-- CHƯƠNG 3. CÀI ĐẶT CƠ SỞ DỮ LIỆU
-- 3.5. INDEX (17 CHỈ MỤC TỐI ƯU HÓA TRUY VẤN VÀ BẢO VỆ TOÀN VẸN)
-- Hệ thống: DBMS12 EnglishCenter
-- Phân công: TV1 (5), TV2 (4), TV3 (4), TV4 (4)
-- ============================================================================

-- I. 2 CHỈ MỤC DUY NHẤT CÓ LỌC (FILTERED UNIQUE INDEXES)

-- 1. [TV3] UX_Class_CurrentGradeOperation: Mỗi giao dịch chốt bảng điểm chỉ được gán cho duy nhất 1 lớp học
CREATE UNIQUE INDEX [UX_Class_CurrentGradeOperation] 
    ON dbo.[Class] ([current_grade_operation_id]) 
    WHERE current_grade_operation_id IS NOT NULL;
GO

-- 2. [TV4] UX_Schedule_OneFinalExam: Đảm bảo mỗi lớp học chỉ có nhiều nhất 1 kỳ thi kết thúc khóa (FINAL_EXAM)
CREATE UNIQUE INDEX [UX_Schedule_OneFinalExam] 
    ON dbo.[Schedule] ([class_id]) 
    WHERE schedule_type='FINAL_EXAM';
GO

-- II. 15 CHỈ MỤC PHI CỤM (NON-CLUSTERED INDEXES VỚI INCLUDE COLUMNS)

-- NHÓM THÀNH VIÊN 1 (TV1): TÀI KHOẢN, PHIÊN, NHẬT KÝ VÀ REPLAY

-- 3. [TV1] IX_Account_RoleStatus: Tối ưu tra cứu/lọc danh sách tài khoản theo vai trò và trạng thái
CREATE INDEX [IX_Account_RoleStatus] 
    ON dbo.[Account] ([role_code],[status],[account_id]);
GO

-- 4. [TV1] IX_AuthSession_Account: Tối ưu tra cứu và thu hồi các phiên đăng nhập của một tài khoản
CREATE INDEX [IX_AuthSession_Account] 
    ON dbo.[AuthSession] ([account_id]) 
    INCLUDE ([issued_at],[last_activity_at]);
GO

-- 5. [TV1] IX_Audit_RootAction: Tối ưu tra cứu nhật ký thao tác theo thực thể nghiệp vụ và loại hành động
CREATE INDEX [IX_Audit_RootAction] 
    ON dbo.[AuditLog] ([root_entity_id],[action_code],[audit_id]) 
    INCLUDE ([occurred_at],[result_code],[actor_account_id]);
GO

-- 6. [TV1] IX_Audit_Time: Lọc và sắp xếp nhật ký kiểm toán theo thời gian (Thực nghiệm: Reads 881 -> 16)
CREATE INDEX [IX_Audit_Time] 
    ON dbo.[AuditLog] ([occurred_at],[audit_id]) 
    INCLUDE ([actor_account_id],[action_code],[result_code]);
GO

-- 7. [TV1] IX_Replay_Completed: Hỗ trợ tìm kiếm và dọn dẹp các bản ghi replay operation quá hạn 24h
CREATE INDEX [IX_Replay_Completed] 
    ON dbo.[ReplayOperation] ([completed_at],[replay_id]);
GO

-- NHÓM THÀNH VIÊN 2 (TV2): ĐĂNG KÝ, TUYỂN SINH VÀ HÓA ĐƠN

-- 8. [TV2] IX_Registration_StudentCourse: Tra hồ sơ theo học viên và khóa (Thực nghiệm: Reads 385 -> 3)
CREATE INDEX [IX_Registration_StudentCourse] 
    ON dbo.[Registration] ([student_account_id],[course_id],[status]) 
    INCLUDE ([created_at]);
GO

-- 9. [TV2] IX_Registration_CourseStatus: Tối ưu danh sách tuyển sinh theo khóa học, trạng thái và ngày tạo
CREATE INDEX [IX_Registration_CourseStatus] 
    ON dbo.[Registration] ([course_id],[status],[created_at]) 
    INCLUDE ([student_account_id]);
GO

-- 10. [TV2] IX_Invoice_Issued: Báo cáo và lọc hóa đơn theo ngày phát hành (Thực nghiệm: Reads 497 -> 11)
CREATE INDEX [IX_Invoice_Issued] 
    ON dbo.[Invoice] ([issued_at],[invoice_id]) 
    INCLUDE ([amount],[registration_id],[paid_at]);
GO

-- 11. [TV2] IX_Invoice_Paid: Tối ưu báo cáo doanh thu theo ngày thu tiền (Chỉ lưu trữ hóa đơn đã thanh toán)
CREATE INDEX [IX_Invoice_Paid] 
    ON dbo.[Invoice] ([paid_at],[invoice_id]) 
    INCLUDE ([amount],[registration_id]) 
    WHERE paid_at IS NOT NULL;
GO

-- NHÓM THÀNH VIÊN 3 (TV3): KHÓA HỌC, LỚP HỌC VÀ XẾP LỚP

-- 12. [TV3] IX_Class_CourseStatus: Tối ưu tìm kiếm lớp học theo khóa học và trạng thái vận hành
CREATE INDEX [IX_Class_CourseStatus] 
    ON dbo.[Class] ([course_id],[status]) 
    INCLUDE ([capacity],[teacher_account_id]);
GO

-- 13. [TV3] IX_Class_TeacherStatus: Tra cứu lớp do giáo viên phụ trách theo trạng thái (Thực nghiệm: Reads 485 -> 3)
CREATE INDEX [IX_Class_TeacherStatus] 
    ON dbo.[Class] ([teacher_account_id],[status]) 
    INCLUDE ([course_id]);
GO

-- 14. [TV3] IX_Assignment_Class: Tối ưu đọc danh sách phân lớp/sĩ số học viên trong một lớp học
CREATE INDEX [IX_Assignment_Class] 
    ON dbo.[StudentClassAssignment] ([class_id],[class_assignment_id]) 
    INCLUDE ([registration_id]);
GO

-- NHÓM THÀNH VIÊN 4 (TV4): LỊCH HỌC VÀ ĐIỂM DANH

-- 15. [TV4] IX_Schedule_ClassStart: Truy vấn lịch học của lớp theo khoảng thời gian (Thực nghiệm: Reads 723 -> 3)
CREATE INDEX [IX_Schedule_ClassStart] 
    ON dbo.[Schedule] ([class_id],[start_at]) 
    INCLUDE ([end_at],[schedule_type],[room],[held_at]);
GO

-- 16. [TV4] IX_Schedule_RoomStart: Tìm lịch theo phòng và thời gian để phát hiện xung đột xếp phòng
CREATE INDEX [IX_Schedule_RoomStart] 
    ON dbo.[Schedule] ([room],[start_at]) 
    INCLUDE ([end_at],[class_id]);
GO

-- 17. [TV4] IX_Attendance_Assignment: Tối ưu tra cứu điểm danh của học viên qua các buổi học
CREATE INDEX [IX_Attendance_Assignment] 
    ON dbo.[Attendance] ([class_assignment_id],[schedule_id]) 
    INCLUDE ([present]);
GO
