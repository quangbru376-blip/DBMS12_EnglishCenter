-- ============================================================================
-- CHƯƠNG 3. CÀI ĐẶT CƠ SỞ DỮ LIỆU
-- 3.4. VIEW (9 KHUNG NHÌN PHỤC VỤ TRUY VẤN VÀ BÁO CÁO TỔNG HỢP)
-- Hệ thống: DBMS12 EnglishCenter
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. View v_ClassState: Trạng thái lớp học kèm trạng thái bảng điểm suy diễn từ AuditLog (DRAFT/SUBMITTED/RETURNED/FINALIZED)
CREATE VIEW dbo.v_ClassState AS
SELECT c.class_id, c.class_code, c.course_id, c.teacher_account_id, c.capacity, c.status,
       c.current_grade_operation_id, c.created_at, c.row_version,
       CASE WHEN e.action_code='DBMS12.TEACHER.GRADE.SUBMIT' THEN 'SUBMITTED'
            WHEN e.action_code='DBMS12.ACADEMIC.GRADE.RETURN' THEN 'RETURNED'
            WHEN e.action_code='DBMS12.ACADEMIC.GRADE.FINALIZE' THEN 'FINALIZED'
            ELSE 'DRAFT' END AS grade_status,
       e.occurred_at AS grade_decided_at, e.actor_account_id AS grade_decided_by, e.reason AS grade_decision_reason
FROM dbo.Class c 
LEFT JOIN dbo.AuditLog e ON e.operation_id=c.current_grade_operation_id;
GO

-- 2. View v_RegistrationFacts: Hồ sơ đăng ký kết hợp thông tin học viên, khóa học và cờ hồ sơ chưa kết thúc
CREATE VIEW dbo.v_RegistrationFacts AS
SELECT r.registration_id, r.student_account_id, r.course_id, r.status, r.created_at, r.row_version,
       s.full_name, s.email, s.phone, p.course_code, p.course_name,
       dbo.fn_RegistrationUnfinished(r.registration_id) AS is_unfinished
FROM dbo.Registration r 
JOIN dbo.Account s ON s.account_id=r.student_account_id
JOIN dbo.Course p ON p.course_id=r.course_id;
GO

-- 3. View v_CurrentSchedule: Lịch học hiện tại của các lớp kèm thông tin giảng viên và trạng thái tổ chức (PLANNED/HELD)
CREATE VIEW dbo.v_CurrentSchedule AS
SELECT s.schedule_id, s.class_id, s.schedule_type, s.start_at, s.end_at, s.room, s.held_at, s.held_by, s.row_version,
       c.class_code, c.teacher_account_id, c.status AS class_status,
       CASE WHEN s.held_at IS NULL THEN 'PLANNED' ELSE 'HELD' END AS schedule_status
FROM dbo.Schedule s 
JOIN dbo.Class c ON c.class_id=s.class_id;
GO

-- 4. View v_ClassRoster: Danh sách học viên trong lớp kèm điểm số và thông tin liên hệ phục vụ Giáo viên/Giáo vụ
CREATE VIEW dbo.v_ClassRoster AS
SELECT a.class_assignment_id, a.registration_id, a.class_id, a.assigned_at,
       r.student_account_id, s.full_name, s.email, s.phone,
       g.report_id, g.continuous_score, g.final_exam_score, g.teacher_comment, g.row_version AS report_version
FROM dbo.StudentClassAssignment a 
JOIN dbo.Registration r ON r.registration_id=a.registration_id
JOIN dbo.Account s ON s.account_id=r.student_account_id
JOIN dbo.GradeReport g ON g.class_assignment_id=a.class_assignment_id;
GO

-- 5. View v_FinalizedGrades: Kết quả điểm chính thức toàn lớp sau khi đã được Giáo vụ duyệt chốt (FINALIZED)
CREATE VIEW dbo.v_FinalizedGrades AS
SELECT a.class_assignment_id, a.class_id, a.registration_id, r.student_account_id, c.course_id, c.class_code,
       g.report_id, g.continuous_score, g.final_exam_score, g.teacher_comment,
       dbo.fn_GradeTotal(g.continuous_score, g.final_exam_score, p.process_weight) AS final_score,
       CONVERT(bit, CASE WHEN dbo.fn_GradeTotal(g.continuous_score, g.final_exam_score, p.process_weight)>=50 THEN 1 ELSE 0 END) AS passed,
       c.grade_decided_at AS finalized_at
FROM dbo.StudentClassAssignment a 
JOIN dbo.Registration r ON r.registration_id=a.registration_id
JOIN dbo.v_ClassState c ON c.class_id=a.class_id
JOIN dbo.Course p ON p.course_id=c.course_id
JOIN dbo.GradeReport g ON g.class_assignment_id=a.class_assignment_id
WHERE c.grade_status='FINALIZED';
GO

-- 6. View v_InvoiceFacts: Chi tiết hóa đơn học phí, trạng thái thanh toán (PAID/UNPAID/CANCELLED) và cờ hạn nộp
CREATE VIEW dbo.v_InvoiceFacts AS
SELECT i.invoice_id, i.invoice_number, i.registration_id, r.student_account_id, r.course_id, i.amount, i.issued_at,
       i.paid_at, i.paid_by, i.payment_method, i.payment_reference, i.row_version,
       CASE WHEN i.paid_at IS NOT NULL THEN 'PAID' 
            WHEN r.status='CANCELLED' THEN 'CANCELLED' 
            ELSE 'UNPAID' END AS invoice_status,
       dbo.fn_InvoiceDueDate(i.issued_at) AS due_date,
       dbo.fn_InvoiceDebtFlags(i.invoice_id, SYSUTCDATETIME()) AS debt_flag
FROM dbo.Invoice i 
JOIN dbo.Registration r ON r.registration_id=i.registration_id;
GO

-- 7. View v_ClassProgress: Tiến độ lớp học (số buổi dự kiến, đã lên lịch, đã dạy, thiếu điểm danh, tỷ lệ % hoàn thành)
CREATE VIEW dbo.v_ClassProgress AS
SELECT c.class_id, p.expected_lesson_count,
       (SELECT COUNT(*) FROM dbo.Schedule s WHERE s.class_id=c.class_id AND s.schedule_type='LESSON') AS lesson_count,
       (SELECT COUNT(*) FROM dbo.Schedule s WHERE s.class_id=c.class_id AND s.schedule_type='FINAL_EXAM') AS exam_count,
       (SELECT COUNT(*) FROM dbo.Schedule s WHERE s.class_id=c.class_id AND s.held_at IS NULL) AS unheld_count,
       (SELECT COUNT(*) FROM dbo.Schedule s JOIN dbo.StudentClassAssignment a ON a.class_id=s.class_id
        WHERE s.class_id=c.class_id AND s.schedule_type='LESSON'
          AND NOT EXISTS(SELECT 1 FROM dbo.Attendance t WHERE t.schedule_id=s.schedule_id AND t.class_assignment_id=a.class_assignment_id)) AS missing_attendance,
       dbo.fn_ClassProgress(c.class_id) AS progress_percent
FROM dbo.Class c 
JOIN dbo.Course p ON p.course_id=c.course_id;
GO

-- 8. View v_DirectorAggregate: Báo cáo số lượng lớp học phân nhóm theo trạng thái phục vụ Giám đốc
CREATE VIEW dbo.v_DirectorAggregate AS 
SELECT status, COUNT_BIG(*) AS class_count 
FROM dbo.Class 
GROUP BY status;
GO

-- 9. View v_AuditSafe: Xem nhật ký an toàn, loại bỏ các chi tiết nhạy cảm (IP, chi tiết payload)
CREATE VIEW dbo.v_AuditSafe AS 
SELECT audit_id, operation_id, action_code, result_code, occurred_at 
FROM dbo.AuditLog;
GO
