# Lược đồ quan hệ và lập luận3NF

Nguồn: tables/01_schema.sql hiện tại;12bảng/99cột/12PK/19FK. [ERD đủ99thuộc tính](../diagrams/ERD-full-attributes.md) · [ERD Chen](../diagrams/ERD-Chen-classic.md) · [Rubric](RUBRIC_SQL_SERVER.md).

PK = primary key; UQ = khóa duy nhất; FK được liệt kê riêng. row_version là metadata concurrency, không phải khóa nghiệp vụ.

## Account

```text
Account(account_id, role_code, email, full_name, phone, date_of_birth, address, password_hash, status, created_at, security_version, failed_login_count, failure_window_started_at, login_throttled_until, temp_issued_at, row_version)
PK: account_id
UQ: email
```

## AuthSession

```text
AuthSession(sid, account_id, issued_at, last_activity_at, row_version)
PK: sid
```

## Course

```text
Course(course_id, course_code, course_name, tuition_fee, status, expected_lesson_count, process_weight, created_at, row_version)
PK: course_id
UQ: course_code
```

## Registration

```text
Registration(registration_id, student_account_id, course_id, status, created_at, row_version)
PK: registration_id
```

## Class

```text
Class(class_id, class_code, course_id, teacher_account_id, capacity, status, current_grade_operation_id, created_at, row_version)
PK: class_id
UQ: class_code
```

## StudentClassAssignment

```text
StudentClassAssignment(class_assignment_id, registration_id, class_id, assigned_at, assigned_by)
PK: class_assignment_id
UQ: registration_id
```

## Schedule

```text
Schedule(schedule_id, class_id, schedule_type, start_at, end_at, room, held_at, held_by, row_version)
PK: schedule_id
```

## Attendance

```text
Attendance(attendance_id, schedule_id, class_assignment_id, present, recorded_at, row_version)
PK: attendance_id
UQ: schedule_id,class_assignment_id
```

## GradeReport

```text
GradeReport(report_id, class_assignment_id, continuous_score, final_exam_score, teacher_comment, updated_at, row_version)
PK: report_id
UQ: class_assignment_id
```

## Invoice

```text
Invoice(invoice_id, invoice_number, registration_id, amount, issued_at, paid_at, paid_by, payment_method, payment_reference, row_version)
PK: invoice_id
UQ: invoice_number
UQ: registration_id
```

## AuditLog

```text
AuditLog(audit_id, operation_id, actor_account_id, action_code, root_entity_id, result_code, occurred_at, reason, change_details, ip_address)
PK: audit_id
UQ: operation_id
```

## ReplayOperation

```text
ReplayOperation(replay_id, actor_account_id, action_code, request_id, input_digest, operation_id, completed_at)
PK: replay_id
UQ: actor_account_id,action_code,request_id
UQ: operation_id
```

## Khóa ngoại

- `AuthSession.account_id → Account.account_id` (FK_AuthSession_account_id).
- `Registration.student_account_id → Account.account_id` (FK_Registration_student_account_id).
- `Registration.course_id → Course.course_id` (FK_Registration_course_id).
- `Class.course_id → Course.course_id` (FK_Class_course_id).
- `Class.teacher_account_id → Account.account_id` (FK_Class_teacher_account_id).
- `Class.current_grade_operation_id → AuditLog.operation_id` (FK_Class_current_grade_operation_id).
- `StudentClassAssignment.registration_id → Registration.registration_id` (FK_StudentClassAssignment_registration_id).
- `StudentClassAssignment.class_id → Class.class_id` (FK_StudentClassAssignment_class_id).
- `StudentClassAssignment.assigned_by → Account.account_id` (FK_StudentClassAssignment_assigned_by).
- `Schedule.class_id → Class.class_id` (FK_Schedule_class_id).
- `Schedule.held_by → Account.account_id` (FK_Schedule_held_by).
- `Attendance.schedule_id → Schedule.schedule_id` (FK_Attendance_schedule_id).
- `Attendance.class_assignment_id → StudentClassAssignment.class_assignment_id` (FK_Attendance_class_assignment_id).
- `GradeReport.class_assignment_id → StudentClassAssignment.class_assignment_id` (FK_GradeReport_class_assignment_id).
- `Invoice.registration_id → Registration.registration_id` (FK_Invoice_registration_id).
- `Invoice.paid_by → Account.account_id` (FK_Invoice_paid_by).
- `AuditLog.actor_account_id → Account.account_id` (FK_AuditLog_actor_account_id).
- `ReplayOperation.actor_account_id → Account.account_id` (FK_ReplayOperation_actor_account_id).
- `ReplayOperation.operation_id → AuditLog.operation_id` (FK_ReplayOperation_operation_id).

## Phụ thuộc hàm và3NF

Lập luận dựa trên các quy tắc nghiệp vụ hiện tại. Mỗi PK và mỗi UQ NOT NULL là một candidate key xác định toàn bộ thuộc tính còn lại của quan hệ. Với FD không tầm thường X→A,3NF yêu cầu X là superkey hoặc A là thuộc tính khóa. Không chỉ đếm bảng hoặc thêm cột ID rồi kết luận3NF.

|Quan hệ|FD chính / lý do tách|
|---|---|
|Account|account_id hoặc email → thông tin tài khoản. Không lưu thông tin khóa/lớp vào account.|
|AuthSession|sid → account_id,issued_at,last_activity_at,RV; role/name/password ở Account, không chép vào session.|
|Course|course_id hoặc course_code → name,fee,lesson_count,weight,status; không lưu tên giáo viên/lịch trong Course.|
|Registration|registration_id → student_account_id,course_id,status,created_at,RV. Tên/email/fee tra qua khóa ngoại.|
|Class|class_id hoặc class_code → course/teacher/capacity/state/current_decision; tên khóa/teacher và grade_status không lưu lặp.|
|StudentClassAssignment|class_assignment_id hoặc registration_id(UQ) → class,assigned_by,assigned_at; không chép student/course vì tra Registration.|
|Schedule|schedule_id → class,type,start,end,room,held metadata; teacher lấy từ Class. Filtered unique cho1FINAL_EXAM/class là ràng buộc có điều kiện.|
|Attendance|attendance_id hoặc(schedule_id,class_assignment_id) → present,recorded_at,RV; tên học viên/lớp không lưu lặp.|
|GradeReport|report_id hoặc class_assignment_id(UQ) → hai điểm,comment,RV; tổng điểm/pass/grade_status suy ra, không thêm thuộc tính phụ thuộc bắc cầu.|
|Invoice|invoice_id,invoice_number hoặc registration_id(UQ) → invoice facts. amount là snapshot tại phát hành, không phải bản sao của học phí hiện tại. due_date/debt/status suy ra.|
|AuditLog|audit_id hoặc operation_id(UQ) → sự kiện/actor/action/root/result/time/reason/details. Root đa hình được trigger kiểm; không phải FK vật lý tới mọi bảng.|
|ReplayOperation|replay_id,operation_id(UQ) hoặc(actor,action,request_id) → digest và completion. operation_id là candidate key, nên actor/action gắn với nó không phải FD từ thuộc tính không khóa.|

Mỗi thuộc tính giữ một giá trị theo miền (1NF); các candidate key ghép không có phụ thuộc từng phần của thuộc tính không khóa (2NF); các FD nghiệp vụ đã nêu không đặt dữ liệu phụ thuộc bắc cầu không khóa vào cùng bảng (3NF). Nhật ký và snapshot có ý nghĩa tại một thời điểm; cần giải thích khác biệt đó khi bị hỏi vì sao tồn tại amount/actor/action ở nhiều quan hệ. Đây là lập luận theo tập FD được xác định, không phải một chương trình tự chứng minh mọi FD ngoài nghiệp vụ.

Tham khảo: [Microsoft — chuẩn hóa và dữ liệu phụ thuộc khóa](https://learn.microsoft.com/en-us/office/troubleshoot/access/database-normalization-description).
