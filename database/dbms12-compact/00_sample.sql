-- DBMS12 / SQL Server / independent database only
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Synthetic NEW database fixture, before trigger installation, not operational history.
-- Hash supplied in-memory by the verifier using ASP.NET Core PasswordHasher.
DECLARE @Hash varchar(512)=CONVERT(varchar(512),SESSION_CONTEXT(N'dbms12_sample_hash'));
IF @Hash IS NULL OR (SELECT COUNT(*) FROM dbo.Account)<>0 THROW 51300,N'Sample chỉ dành cho catalog mới rỗng và hash thật.',1;
INSERT dbo.Account(role_code,email,full_name,phone,date_of_birth,password_hash)
VALUES ('Admin','admin@dbms12.example',N'Quản trị mẫu',NULL,NULL,@Hash),
       ('Admissions','admissions@dbms12.example',N'Tuyển sinh mẫu',NULL,NULL,@Hash),
       ('AcademicAffairs','academic@dbms12.example',N'Giáo vụ mẫu',NULL,NULL,@Hash),
       ('Teacher','teacher@dbms12.example',N'Giáo viên mẫu',NULL,NULL,@Hash),
       ('Accountant','finance@dbms12.example',N'Kế toán mẫu',NULL,NULL,@Hash),
       ('Director','director@dbms12.example',N'Giám đốc mẫu',NULL,NULL,@Hash),
       ('Student','s1@dbms12.example',N'Học viên mẫu 1',NULL,'2000-01-01',@Hash),
       ('Student','s2@dbms12.example',N'Học viên mẫu 2',NULL,'2001-02-03',@Hash),
       ('Teacher','teacher2@dbms12.example',N'Giáo viên mẫu 2',NULL,NULL,@Hash),
       ('Student','s3@dbms12.example',N'Học viên mẫu 3',NULL,'2002-03-04',@Hash);
INSERT dbo.Course(course_code,course_name,tuition_fee,expected_lesson_count,process_weight)
VALUES('DB12-FUTURE',N'Khóa tương lai',2000000,2,40),('DB12-STUDY',N'Khóa đang học mẫu',1500000,1,40);
INSERT dbo.Class(class_code,course_id,teacher_account_id,capacity,status)
VALUES('DB12-OPEN',1,4,1,'PLANNED'),('DB12-ONGOING',2,4,15,'ONGOING');
INSERT dbo.Schedule(class_id,schedule_type,start_at,end_at,room)
VALUES(1,'LESSON',DATEADD(day,7,SYSUTCDATETIME()),DATEADD(hour,1,DATEADD(day,7,SYSUTCDATETIME())),N'A101'),
      (1,'LESSON',DATEADD(day,14,SYSUTCDATETIME()),DATEADD(hour,1,DATEADD(day,14,SYSUTCDATETIME())),N'A101'),
      (1,'FINAL_EXAM',DATEADD(day,21,SYSUTCDATETIME()),DATEADD(hour,1,DATEADD(day,21,SYSUTCDATETIME())),N'A101'),
      (2,'LESSON',DATEADD(day,-2,SYSUTCDATETIME()),DATEADD(hour,1,DATEADD(day,-2,SYSUTCDATETIME())),N'A102'),
      (2,'FINAL_EXAM',DATEADD(day,-1,SYSUTCDATETIME()),DATEADD(hour,1,DATEADD(day,-1,SYSUTCDATETIME())),N'A102');
INSERT dbo.Registration(student_account_id,course_id,status) VALUES(7,2,'ADMITTED'),(8,2,'ADMITTED');
INSERT dbo.Invoice(registration_id,amount,issued_at,paid_at,paid_by,payment_method)
VALUES(1,1500000,DATEADD(day,-10,SYSUTCDATETIME()),DATEADD(day,-9,SYSUTCDATETIME()),5,'CASH'),
      (2,1500000,DATEADD(day,-10,SYSUTCDATETIME()),DATEADD(day,-9,SYSUTCDATETIME()),5,'CASH');
INSERT dbo.StudentClassAssignment(registration_id,class_id,assigned_by) VALUES(1,2,3),(2,2,3);
INSERT dbo.GradeReport(class_assignment_id) VALUES(1),(2);
INSERT dbo.AuditLog(operation_id,action_code,result_code,change_details) VALUES(NEWID(),'DBMS12.OPERATOR.SEED','SUCCESS',N'Dữ liệu tổng hợp được tạo cho catalog mới; không phải lịch sử thao tác thực tế.');
