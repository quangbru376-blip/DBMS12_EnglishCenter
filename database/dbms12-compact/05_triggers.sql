-- DBMS12 / SQL Server / independent database only
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TRIGGER dbo.tr_Account_Guard ON dbo.Account AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.account_id=d.account_id))
        THROW 51101,N'Không xóa vật lý tài khoản.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.account_id=i.account_id
              WHERE i.email<>d.email OR i.role_code<>d.role_code OR i.created_at<>d.created_at)
        THROW 51102,N'Email, vai trò và ngày tạo là bất biến.',1;
    IF EXISTS(SELECT 1 FROM inserted WHERE date_of_birth>CONVERT(date,DATEADD(hour,7,SYSUTCDATETIME())))
        THROW 51103,N'Ngày sinh không hợp lệ.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.account_id=i.account_id
              WHERE (i.password_hash<>d.password_hash OR i.status<>d.status
                OR ISNULL(i.temp_issued_at,'19000101')<>ISNULL(d.temp_issued_at,'19000101'))
                AND (i.security_version<>d.security_version+1 OR EXISTS(SELECT 1 FROM dbo.AuthSession s WHERE s.account_id=i.account_id)))
        THROW 51104,N'Đổi credential/trạng thái phải tăng epoch và thu hồi mọi phiên.',1;
    IF EXISTS(SELECT 1 FROM deleted WHERE role_code='Admin' AND status='ACTIVE')
       AND NOT EXISTS(SELECT 1 FROM dbo.Account WHERE role_code='Admin' AND status='ACTIVE')
        THROW 51105,N'Phải giữ ít nhất một Admin hoạt động.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.account_id=i.account_id WHERE i.security_version<>d.security_version
        AND (i.security_version<>d.security_version+1 OR EXISTS(SELECT 1 FROM dbo.AuthSession s WHERE s.account_id=i.account_id)))
        THROW 51104,N'Mọi đổi epoch phải tăng đúng một và thu hồi mọi SID.',1;
END;
GO
CREATE TRIGGER dbo.tr_Course_Freeze ON dbo.Course AFTER UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.course_id=d.course_id))
        THROW 51106,N'Không xóa vật lý khóa học.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.course_id=i.course_id
              WHERE i.course_code<>d.course_code OR i.created_at<>d.created_at
                 OR ((i.expected_lesson_count<>d.expected_lesson_count OR i.process_weight<>d.process_weight)
                     AND EXISTS(SELECT 1 FROM dbo.Class c WHERE c.course_id=i.course_id)))
        THROW 51107,N'Mã khóa bất biến; cấu hình đã có lớp không được đổi.',1;
END;
GO
CREATE TRIGGER dbo.tr_Registration_State ON dbo.Registration AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.registration_id=d.registration_id))
        THROW 51108,N'Không xóa hồ sơ.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Account a ON a.account_id=i.student_account_id WHERE a.role_code<>'Student')
        THROW 51109,N'Hồ sơ phải thuộc Student.',1;
    IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.registration_id=i.registration_id
              WHERE d.registration_id IS NULL AND i.status<>'PENDING')
        THROW 51110,N'Hồ sơ mới phải PENDING.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.registration_id=i.registration_id
              WHERE i.student_account_id<>d.student_account_id OR i.course_id<>d.course_id OR i.created_at<>d.created_at
                 OR (i.status<>d.status AND NOT (
                     (d.status='PENDING' AND i.status IN ('CONFIRMED','CANCELLED'))
                     OR (d.status='CONFIRMED' AND i.status IN ('ADMITTED','REJECTED','CANCELLED'))
                     OR (d.status='ADMITTED' AND i.status='CANCELLED'))))
        THROW 51111,N'Chuyển trạng thái hồ sơ không hợp lệ.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Invoice v ON v.registration_id=i.registration_id
              WHERE i.status IN ('CANCELLED','REJECTED') AND v.paid_at IS NOT NULL)
        THROW 51112,N'Không hủy/từ chối hồ sơ đã thanh toán.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.StudentClassAssignment a ON a.registration_id=i.registration_id WHERE i.status<>'ADMITTED')
        THROW 51113,N'Hồ sơ đã xếp lớp phải giữ ADMITTED.',1;
    IF EXISTS(SELECT r.student_account_id,r.course_id FROM dbo.Registration r
              WHERE dbo.fn_RegistrationUnfinished(r.registration_id)=1
                AND EXISTS(SELECT 1 FROM inserted i WHERE i.student_account_id=r.student_account_id AND i.course_id=r.course_id)
              GROUP BY r.student_account_id,r.course_id HAVING COUNT(*)>1)
        THROW 51114,N'Đã có hồ sơ chưa kết thúc cho khóa học này.',1;
END;
GO
CREATE TRIGGER dbo.tr_Class_Lifecycle ON dbo.Class AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.class_id=d.class_id))
        THROW 51115,N'Không xóa lớp.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Account a ON a.account_id=i.teacher_account_id WHERE a.role_code<>'Teacher')
        THROW 51116,N'Người phụ trách phải là Teacher.',1;
    IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.class_id=i.class_id WHERE d.class_id IS NULL AND (i.status<>'PLANNED' OR i.current_grade_operation_id IS NOT NULL))
        THROW 51117,N'Lớp mới phải PLANNED/DRAFT.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.class_id=i.class_id WHERE i.course_id<>d.course_id OR i.class_code<>d.class_code OR i.created_at<>d.created_at)
        THROW 51118,N'Không đổi khóa/mã/ngày tạo lớp.',1;
    IF EXISTS(SELECT 1 FROM inserted i WHERE i.capacity<(SELECT COUNT(*) FROM dbo.StudentClassAssignment a WHERE a.class_id=i.class_id))
        THROW 51119,N'Sức chứa nhỏ hơn sĩ số.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.class_id=i.class_id
              WHERE i.teacher_account_id<>d.teacher_account_id AND (
                d.status NOT IN ('PLANNED','OPEN')
                OR EXISTS(SELECT 1 FROM dbo.Schedule s WHERE s.class_id=i.class_id AND s.held_at IS NOT NULL)
                OR EXISTS(SELECT 1 FROM dbo.Attendance t JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=t.class_assignment_id WHERE a.class_id=i.class_id)
                OR EXISTS(SELECT 1 FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=i.class_id AND (g.continuous_score IS NOT NULL OR g.final_exam_score IS NOT NULL))))
        THROW 51121,N'Không đổi giáo viên khi đã dạy hoặc có dữ liệu.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.class_id=i.class_id
              WHERE i.status<>d.status AND NOT (
                (d.status='PLANNED' AND i.status IN ('OPEN','CANCELLED'))
                OR (d.status='OPEN' AND i.status IN ('ONGOING','CANCELLED'))
                OR (d.status='ONGOING' AND i.status='COMPLETED')))
        THROW 51122,N'Chuyển trạng thái lớp không hợp lệ.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.class_id=i.class_id
              WHERE i.status='OPEN' AND d.status<>'OPEN' AND (
                NOT EXISTS(SELECT 1 FROM dbo.Course p WHERE p.course_id=i.course_id AND p.status='ACTIVE')
                OR NOT EXISTS(SELECT 1 FROM dbo.Account t WHERE t.account_id=i.teacher_account_id AND t.status='ACTIVE')
                OR NOT EXISTS(SELECT 1 FROM dbo.Schedule s WHERE s.class_id=i.class_id AND s.schedule_type='LESSON' AND s.start_at>SYSUTCDATETIME())))
        THROW 51123,N'Mở lớp cần khóa/giáo viên hoạt động và buổi học tương lai.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.class_id=i.class_id JOIN dbo.v_ClassProgress p ON p.class_id=i.class_id
              WHERE i.status='ONGOING' AND d.status<>'ONGOING' AND (
                p.lesson_count<>p.expected_lesson_count OR p.exam_count<>1
                OR NOT EXISTS(SELECT 1 FROM dbo.StudentClassAssignment a WHERE a.class_id=i.class_id)
                OR SYSUTCDATETIME()<(SELECT MIN(s.start_at) FROM dbo.Schedule s WHERE s.class_id=i.class_id AND s.schedule_type='LESSON')))
        THROW 51124,N'Chưa đủ điều kiện bắt đầu lớp.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.class_id=i.class_id JOIN dbo.v_ClassProgress p ON p.class_id=i.class_id
              WHERE i.status='COMPLETED' AND d.status<>'COMPLETED' AND (p.lesson_count<>p.expected_lesson_count OR p.exam_count<>1 OR p.unheld_count<>0 OR p.missing_attendance<>0))
        THROW 51125,N'Chưa đủ HELD/điểm danh để hoàn thành.',1;
    IF EXISTS(SELECT 1 FROM inserted i WHERE i.status='CANCELLED' AND (
                EXISTS(SELECT 1 FROM dbo.StudentClassAssignment a WHERE a.class_id=i.class_id)
                OR EXISTS(SELECT 1 FROM dbo.Schedule s WHERE s.class_id=i.class_id AND s.held_at IS NOT NULL)))
        THROW 51126,N'Không hủy lớp đã xếp học viên/đã dạy.',1;

    IF EXISTS (
        SELECT 1 FROM dbo.Schedule s JOIN dbo.Class c ON c.class_id=s.class_id
        JOIN dbo.Schedule t ON s.schedule_id<t.schedule_id AND s.start_at<t.end_at AND t.start_at<s.end_at
        JOIN dbo.Class d ON d.class_id=t.class_id
        WHERE c.status<>'CANCELLED' AND d.status<>'CANCELLED'
          AND (s.class_id=t.class_id OR s.room=t.room OR c.teacher_account_id=d.teacher_account_id
            OR EXISTS (
                SELECT 1 FROM dbo.StudentClassAssignment a JOIN dbo.Registration r ON r.registration_id=a.registration_id
                JOIN dbo.StudentClassAssignment b ON b.class_id=t.class_id
                JOIN dbo.Registration q ON q.registration_id=b.registration_id
                WHERE a.class_id=s.class_id AND r.student_account_id=q.student_account_id)))
        THROW 51120,N'Lịch bị trùng lớp, phòng, giáo viên hoặc học viên.',1;

END;
GO
CREATE TRIGGER dbo.tr_Class_GradeDecision ON dbo.Class AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.class_id=i.class_id
              LEFT JOIN dbo.AuditLog n ON n.operation_id=i.current_grade_operation_id
              LEFT JOIN dbo.AuditLog o ON o.operation_id=d.current_grade_operation_id
              WHERE ISNULL(CONVERT(varchar(36),i.current_grade_operation_id),'')<>ISNULL(CONVERT(varchar(36),d.current_grade_operation_id),'') AND (
                n.operation_id IS NULL OR n.root_entity_id<>i.class_id OR n.result_code<>'SUCCESS' OR i.status<>'COMPLETED'
                OR n.action_code NOT IN ('DBMS12.TEACHER.GRADE.SUBMIT','DBMS12.ACADEMIC.GRADE.RETURN','DBMS12.ACADEMIC.GRADE.FINALIZE')
                OR (o.audit_id IS NOT NULL AND n.audit_id<=o.audit_id)
                OR NOT ((n.action_code='DBMS12.TEACHER.GRADE.SUBMIT' AND ISNULL(o.action_code,'DRAFT') IN ('DRAFT','DBMS12.ACADEMIC.GRADE.RETURN'))
                     OR (n.action_code IN ('DBMS12.ACADEMIC.GRADE.RETURN','DBMS12.ACADEMIC.GRADE.FINALIZE') AND ISNULL(o.action_code,'DRAFT')='DBMS12.TEACHER.GRADE.SUBMIT'))
                OR (n.action_code='DBMS12.TEACHER.GRADE.SUBMIT' AND n.actor_account_id<>i.teacher_account_id)
                OR (n.action_code IN ('DBMS12.ACADEMIC.GRADE.RETURN','DBMS12.ACADEMIC.GRADE.FINALIZE') AND NOT EXISTS(SELECT 1 FROM dbo.Account a WHERE a.account_id=n.actor_account_id AND a.role_code='AcademicAffairs'))
                OR EXISTS(SELECT 1 FROM dbo.StudentClassAssignment a LEFT JOIN dbo.GradeReport g ON g.class_assignment_id=a.class_assignment_id
                          WHERE a.class_id=i.class_id AND (g.report_id IS NULL OR g.continuous_score IS NULL OR g.final_exam_score IS NULL))))
        THROW 51127,N'Quyết định điểm toàn lớp không hợp lệ.',1;
END;
GO
CREATE TRIGGER dbo.tr_Assignment_Eligibility ON dbo.StudentClassAssignment AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted) THROW 51128,N'Không gỡ/chuyển/sửa lần xếp lớp.',1;
    IF EXISTS(SELECT 1 FROM inserted a JOIN dbo.Registration r ON r.registration_id=a.registration_id
              JOIN dbo.Class c ON c.class_id=a.class_id JOIN dbo.Account b ON b.account_id=a.assigned_by
              LEFT JOIN dbo.Invoice v ON v.registration_id=r.registration_id
              WHERE r.status<>'ADMITTED' OR c.status<>'OPEN' OR r.course_id<>c.course_id OR v.paid_at IS NULL
                 OR b.role_code<>'AcademicAffairs' OR NOT EXISTS(SELECT 1 FROM dbo.Account t WHERE t.account_id=c.teacher_account_id AND t.status='ACTIVE')
                 OR (SELECT COUNT(*) FROM dbo.StudentClassAssignment x WHERE x.class_id=a.class_id)>c.capacity)
        THROW 51129,N'Xếp lớp cần ADMITTED/PAID/OPEN/cùng khóa/còn chỗ.',1;

    IF EXISTS (
        SELECT 1 FROM dbo.Schedule s JOIN dbo.Class c ON c.class_id=s.class_id
        JOIN dbo.Schedule t ON s.schedule_id<t.schedule_id AND s.start_at<t.end_at AND t.start_at<s.end_at
        JOIN dbo.Class d ON d.class_id=t.class_id
        WHERE c.status<>'CANCELLED' AND d.status<>'CANCELLED'
          AND (s.class_id=t.class_id OR s.room=t.room OR c.teacher_account_id=d.teacher_account_id
            OR EXISTS (
                SELECT 1 FROM dbo.StudentClassAssignment a JOIN dbo.Registration r ON r.registration_id=a.registration_id
                JOIN dbo.StudentClassAssignment b ON b.class_id=t.class_id
                JOIN dbo.Registration q ON q.registration_id=b.registration_id
                WHERE a.class_id=s.class_id AND r.student_account_id=q.student_account_id)))
        THROW 51120,N'Lịch bị trùng lớp, phòng, giáo viên hoặc học viên.',1;

END;
GO
CREATE TRIGGER dbo.tr_Schedule_Guard ON dbo.Schedule AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.schedule_id=d.schedule_id))
        THROW 51130,N'Không xóa lịch.',1;
    IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.schedule_id=i.schedule_id
              JOIN dbo.Class c ON c.class_id=i.class_id
              WHERE (d.schedule_id IS NULL AND (c.status IN ('COMPLETED','CANCELLED') OR i.start_at<=SYSUTCDATETIME() OR i.held_at IS NOT NULL))
                OR (d.schedule_id IS NOT NULL AND (i.class_id<>d.class_id OR i.schedule_type<>d.schedule_type)))
        THROW 51131,N'Lịch mới phải tương lai/chưa HELD; không đổi lớp/loại buổi.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Course p ON p.course_id=(SELECT c.course_id FROM dbo.Class c WHERE c.class_id=i.class_id)
              WHERE (SELECT COUNT(*) FROM dbo.Schedule s WHERE s.class_id=i.class_id AND s.schedule_type='LESSON')>p.expected_lesson_count)
        THROW 51132,N'Vượt số buổi LESSON.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.schedule_id=i.schedule_id JOIN dbo.Class c ON c.class_id=i.class_id
              WHERE (i.start_at<>d.start_at OR i.end_at<>d.end_at OR i.room<>d.room) AND (
                c.status IN ('COMPLETED','CANCELLED') OR d.held_at IS NOT NULL OR i.start_at<=SYSUTCDATETIME()
                OR EXISTS(SELECT 1 FROM dbo.Attendance a WHERE a.schedule_id=i.schedule_id)
                OR (i.schedule_type='FINAL_EXAM' AND EXISTS(SELECT 1 FROM dbo.GradeReport g JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=g.class_assignment_id WHERE a.class_id=i.class_id AND g.final_exam_score IS NOT NULL))))
        THROW 51133,N'Buổi đã tổ chức/có dữ liệu không được dời.',1;
    IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.schedule_id=i.schedule_id JOIN dbo.Class c ON c.class_id=i.class_id
              WHERE i.held_at IS NOT NULL AND (d.held_at IS NULL) AND (c.status<>'ONGOING' OR i.end_at>SYSUTCDATETIME()
                OR NOT EXISTS(SELECT 1 FROM dbo.Account a WHERE a.account_id=i.held_by AND a.role_code='AcademicAffairs')))
        THROW 51134,N'HELD chỉ giáo vụ, sau giờ kết thúc, lớp ONGOING.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.schedule_id=i.schedule_id WHERE d.held_at IS NOT NULL AND (
                i.held_at IS NULL OR i.held_at<>d.held_at OR i.held_by<>d.held_by))
        THROW 51135,N'Không xóa/sửa xác nhận HELD.',1;

    IF EXISTS (
        SELECT 1 FROM dbo.Schedule s JOIN dbo.Class c ON c.class_id=s.class_id
        JOIN dbo.Schedule t ON s.schedule_id<t.schedule_id AND s.start_at<t.end_at AND t.start_at<s.end_at
        JOIN dbo.Class d ON d.class_id=t.class_id
        WHERE c.status<>'CANCELLED' AND d.status<>'CANCELLED'
          AND (s.class_id=t.class_id OR s.room=t.room OR c.teacher_account_id=d.teacher_account_id
            OR EXISTS (
                SELECT 1 FROM dbo.StudentClassAssignment a JOIN dbo.Registration r ON r.registration_id=a.registration_id
                JOIN dbo.StudentClassAssignment b ON b.class_id=t.class_id
                JOIN dbo.Registration q ON q.registration_id=b.registration_id
                WHERE a.class_id=s.class_id AND r.student_account_id=q.student_account_id)))
        THROW 51120,N'Lịch bị trùng lớp, phòng, giáo viên hoặc học viên.',1;

END;
GO
CREATE TRIGGER dbo.tr_Attendance_Guard ON dbo.Attendance AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.attendance_id=d.attendance_id))
        THROW 51136,N'Không xóa điểm danh.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Schedule s ON s.schedule_id=i.schedule_id
              JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=i.class_assignment_id
              JOIN dbo.Class c ON c.class_id=a.class_id
              WHERE s.class_id<>a.class_id OR s.schedule_type<>'LESSON' OR c.status<>'ONGOING' OR s.start_at>SYSUTCDATETIME())
        THROW 51137,N'Điểm danh sai lớp/loại buổi/cửa sổ.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.attendance_id=i.attendance_id WHERE i.schedule_id<>d.schedule_id OR i.class_assignment_id<>d.class_assignment_id)
        THROW 51138,N'Không đổi chủ thể điểm danh.',1;
END;
GO
CREATE TRIGGER dbo.tr_GradeReport_Guard ON dbo.GradeReport AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.report_id=d.report_id))
        THROW 51139,N'Không xóa bảng điểm.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.report_id=i.report_id WHERE i.class_assignment_id<>d.class_assignment_id)
        THROW 51140,N'Không đổi lượt học của bảng điểm.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=i.class_assignment_id
              JOIN dbo.v_ClassState c ON c.class_id=a.class_id LEFT JOIN deleted d ON d.report_id=i.report_id
              WHERE (d.report_id IS NOT NULL OR i.continuous_score IS NOT NULL OR i.final_exam_score IS NOT NULL OR i.teacher_comment IS NOT NULL)
                AND (c.status NOT IN ('ONGOING','COMPLETED') OR c.grade_status NOT IN ('DRAFT','RETURNED')))
        THROW 51141,N'Điểm chỉ sửa ở lớp đang học/hoàn thành, DRAFT/RETURNED.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.StudentClassAssignment a ON a.class_assignment_id=i.class_assignment_id
              WHERE i.final_exam_score IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Schedule s WHERE s.class_id=a.class_id AND s.schedule_type='FINAL_EXAM' AND s.end_at<=SYSUTCDATETIME()))
        THROW 51142,N'Chưa kết thúc buổi thi cuối khóa.',1;
END;
GO
CREATE TRIGGER dbo.tr_Invoice_Integrity ON dbo.Invoice AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.invoice_id=d.invoice_id))
        THROW 51143,N'Không xóa hóa đơn.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Registration r ON r.registration_id=i.registration_id
              WHERE r.status NOT IN ('ADMITTED','CANCELLED') OR (i.paid_at IS NOT NULL AND r.status='CANCELLED')
                OR (i.paid_by IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Account a WHERE a.account_id=i.paid_by AND a.role_code='Accountant')))
        THROW 51144,N'Hóa đơn/receipt không phù hợp hồ sơ hoặc người thu.',1;
    IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.invoice_id=i.invoice_id JOIN dbo.Registration r ON r.registration_id=i.registration_id
              JOIN dbo.Course p ON p.course_id=r.course_id WHERE d.invoice_id IS NULL AND (r.status<>'ADMITTED' OR i.amount<>p.tuition_fee OR i.paid_at IS NOT NULL))
        THROW 51145,N'Hóa đơn mới phải UNPAID và snapshot học phí hiện hành.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.invoice_id=i.invoice_id WHERE i.registration_id<>d.registration_id OR i.invoice_number<>d.invoice_number OR i.amount<>d.amount OR i.issued_at<>d.issued_at
              OR (d.paid_at IS NOT NULL AND (i.paid_at IS NULL OR i.paid_at<>d.paid_at OR i.paid_by<>d.paid_by)))
        THROW 51146,N'Không sửa số tiền/chủ thể/thời điểm/người thu đã ghi.',1;
END;
GO
CREATE TRIGGER dbo.tr_Audit_Integrity ON dbo.AuditLog AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT audit_id,operation_id,actor_account_id,action_code,root_entity_id,result_code,occurred_at,reason,change_details FROM deleted
              EXCEPT SELECT audit_id,operation_id,actor_account_id,action_code,root_entity_id,result_code,occurred_at,reason,change_details FROM inserted)
        THROW 51147,N'Audit bất biến; chỉ được dọn IP đúng hạn.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.audit_id=i.audit_id WHERE
              ISNULL(i.ip_address,'')<>ISNULL(d.ip_address,'') AND (i.ip_address IS NOT NULL OR d.occurred_at>DATEADD(day,-90,SYSUTCDATETIME())))
        THROW 51148,N'Chỉ dọn IP sau 90 ngày.',1;
    IF EXISTS(SELECT 1 FROM inserted WHERE dbo.fn_ActionRootKind(action_code) IS NULL)
        THROW 51149,N'Action không thuộc whitelist DBMS12.',1;
    IF EXISTS(SELECT 1 FROM inserted WHERE result_code='SUCCESS' AND dbo.fn_ActionRootKind(action_code)<>'NONE' AND actor_account_id IS NULL)
        THROW 51149,N'Audit thành công cần actor đã xác thực.',1;
    IF EXISTS(SELECT 1 FROM inserted WHERE result_code='SUCCESS' AND action_code IN (
              'DBMS12.ADMISSIONS.REGISTRATION.REJECT','DBMS12.ADMISSIONS.REGISTRATION.CANCEL','DBMS12.ACADEMIC.CLASS.CANCEL',
              'DBMS12.ACADEMIC.GRADE.RETURN','DBMS12.FINANCE.INVOICE.CORRECT') AND reason IS NULL)
        THROW 51150,N'Thao tác này cần lý do.',1;
    IF EXISTS(SELECT 1 FROM inserted i WHERE i.result_code='SUCCESS' AND (
        (dbo.fn_ActionRootKind(i.action_code)='ACCOUNT' AND NOT EXISTS(SELECT 1 FROM dbo.Account a WHERE a.account_id=i.root_entity_id))
        OR (dbo.fn_ActionRootKind(i.action_code)='COURSE' AND NOT EXISTS(SELECT 1 FROM dbo.Course a WHERE a.course_id=i.root_entity_id))
        OR (dbo.fn_ActionRootKind(i.action_code)='REGISTRATION' AND NOT EXISTS(SELECT 1 FROM dbo.Registration a WHERE a.registration_id=i.root_entity_id))
        OR (dbo.fn_ActionRootKind(i.action_code)='CLASS' AND NOT EXISTS(SELECT 1 FROM dbo.Class a WHERE a.class_id=i.root_entity_id))
        OR (dbo.fn_ActionRootKind(i.action_code)='SCHEDULE' AND NOT EXISTS(SELECT 1 FROM dbo.Schedule a WHERE a.schedule_id=i.root_entity_id))
        OR (dbo.fn_ActionRootKind(i.action_code)='REPORT' AND NOT EXISTS(SELECT 1 FROM dbo.GradeReport a WHERE a.report_id=i.root_entity_id))
        OR (dbo.fn_ActionRootKind(i.action_code)='INVOICE' AND NOT EXISTS(SELECT 1 FROM dbo.Invoice a WHERE a.invoice_id=i.root_entity_id))))
        THROW 51151,N'Audit root không đúng loại/tồn tại.',1;
END;
GO
CREATE TRIGGER dbo.tr_Replay_Integrity ON dbo.ReplayOperation AFTER INSERT,UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.replay_id=i.replay_id) THROW 51152,N'Completion không sửa.',1;
    IF EXISTS(SELECT 1 FROM deleted WHERE completed_at>DATEADD(hour,-24,SYSUTCDATETIME())) THROW 51153,N'Chưa hết cửa sổ replay.',1;
    IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.AuditLog a ON a.operation_id=i.operation_id
              WHERE a.actor_account_id IS NULL OR a.actor_account_id<>i.actor_account_id OR a.action_code<>i.action_code OR a.result_code<>'SUCCESS')
        THROW 51154,N'Replay phải khớp audit SUCCESS/actor/action.',1;
END;
GO
