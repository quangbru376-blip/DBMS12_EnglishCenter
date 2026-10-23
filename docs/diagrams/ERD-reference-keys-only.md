# ERD — 12 bảng đích

Đường dưới đây biểu diễn đủ 19 FK vật lý, kể cả actor và con trỏ duyệt điểm. Audit root là tham chiếu có kiểu kiểm bằng SQL, không vẽ thành FK giả.

```mermaid
erDiagram
    Account ||--o{ AuthSession : "account_id"
    Account ||--o{ Registration : "student_account_id"
    Course ||--o{ Registration : "course_id"
    Course ||--o{ Class : "course_id"
    Account ||--o{ Class : "teacher_account_id"
    AuditLog |o--o| Class : "current_grade_operation_id"
    Registration ||--o| StudentClassAssignment : "registration_id"
    Class ||--o{ StudentClassAssignment : "class_id"
    Account ||--o{ StudentClassAssignment : "assigned_by"
    Class ||--o{ Schedule : "class_id"
    Account |o--o{ Schedule : "held_by"
    Schedule ||--o{ Attendance : "schedule_id"
    StudentClassAssignment ||--o{ Attendance : "class_assignment_id"
    StudentClassAssignment ||--o| GradeReport : "class_assignment_id"
    Registration ||--o| Invoice : "registration_id"
    Account |o--o{ Invoice : "paid_by"
    Account |o--o{ AuditLog : "actor_account_id"
    Account ||--o{ ReplayOperation : "actor_account_id"
    AuditLog ||--o| ReplayOperation : "operation_id"
    Account {
        int account_id PK
    }
    AuthSession {
        binary sid PK
        int account_id FK
    }
    Course {
        int course_id PK
    }
    Registration {
        int registration_id PK
        int student_account_id FK
        int course_id FK
    }
    Class {
        int class_id PK
        int course_id FK
        int teacher_account_id FK
        uniqueidentifier current_grade_operation_id FK
    }
    StudentClassAssignment {
        int class_assignment_id PK
        int registration_id FK
        int class_id FK
        int assigned_by FK
    }
    Schedule {
        int schedule_id PK
        int class_id FK
        int held_by FK
    }
    Attendance {
        int attendance_id PK
        int schedule_id FK
        int class_assignment_id FK
    }
    GradeReport {
        int report_id PK
        int class_assignment_id FK
    }
    Invoice {
        int invoice_id PK
        int registration_id FK
        int paid_by FK
    }
    AuditLog {
        bigint audit_id PK
        int actor_account_id FK
    }
    ReplayOperation {
        bigint replay_id PK
        int actor_account_id FK
        uniqueidentifier operation_id FK
    }
```

StudentClassAssignment và GradeReport là 1:0..1 ở mức FK/UQ; procedure phải tạo stub cùng transaction để nghiệp vụ đạt đúng 1:1 sau COMMIT. Các FK typed-role và cùng Class/Course cần guard SQL như CONTRACTS.md.
