-- DBMS12 / SQL Server / independent database only
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION dbo.fn_GradeTotal(@Continuous decimal(5,2), @Final decimal(5,2), @Weight decimal(5,2))
RETURNS decimal(5,2)
AS
BEGIN
    IF @Continuous IS NULL OR @Final IS NULL OR @Weight IS NULL RETURN NULL;
    RETURN CONVERT(decimal(5,2), ROUND((CONVERT(decimal(9,4),@Continuous)*@Weight
        + CONVERT(decimal(9,4),@Final)*(100-@Weight))/CONVERT(decimal(9,4),100),2));
END;
GO
CREATE FUNCTION dbo.fn_InvoiceDueDate(@IssuedAt datetime2(3))
RETURNS date
AS
BEGIN
    RETURN DATEADD(day,7,CONVERT(date,DATEADD(hour,7,@IssuedAt)));
END;
GO
CREATE FUNCTION dbo.fn_RegistrationUnfinished(@RegistrationId int)
RETURNS bit
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.Registration WHERE registration_id=@RegistrationId) RETURN NULL;
    IF EXISTS (SELECT 1 FROM dbo.Registration WHERE registration_id=@RegistrationId AND status IN ('CANCELLED','REJECTED')) RETURN 0;
    IF EXISTS (
        SELECT 1 FROM dbo.StudentClassAssignment a
        JOIN dbo.Class c ON c.class_id=a.class_id
        JOIN dbo.AuditLog e ON e.operation_id=c.current_grade_operation_id
        WHERE a.registration_id=@RegistrationId AND c.status='COMPLETED'
          AND e.action_code='DBMS12.ACADEMIC.GRADE.FINALIZE' AND e.result_code='SUCCESS') RETURN 0;
    RETURN 1;
END;
GO
CREATE FUNCTION dbo.fn_ClassProgress(@ClassId int)
RETURNS decimal(5,2)
AS
BEGIN
    DECLARE @Expected int, @Held int;
    SELECT @Expected=p.expected_lesson_count FROM dbo.Class c JOIN dbo.Course p ON p.course_id=c.course_id WHERE c.class_id=@ClassId;
    IF @Expected IS NULL RETURN NULL;
    SELECT @Held=COUNT(*) FROM dbo.Schedule WHERE class_id=@ClassId AND schedule_type='LESSON' AND held_at IS NOT NULL;
    RETURN CONVERT(decimal(5,2),100.0*@Held/@Expected);
END;
GO
CREATE FUNCTION dbo.fn_InvoiceDebtFlags(@InvoiceId int, @Now datetime2(3))
RETURNS varchar(16)
AS
BEGIN
    DECLARE @Issued datetime2(3), @Paid datetime2(3), @State varchar(16);
    SELECT @Issued=i.issued_at,@Paid=i.paid_at,@State=r.status
    FROM dbo.Invoice i JOIN dbo.Registration r ON r.registration_id=i.registration_id WHERE i.invoice_id=@InvoiceId;
    IF @Issued IS NULL RETURN NULL;
    IF @Paid IS NOT NULL OR @State='CANCELLED' RETURN 'SETTLED';
    IF CONVERT(date,DATEADD(hour,7,@Now))>dbo.fn_InvoiceDueDate(@Issued) RETURN 'OVERDUE';
    RETURN 'DUE';
END;
GO
CREATE FUNCTION dbo.fn_ActionRootKind(@Action varchar(80))
RETURNS varchar(16)
AS
BEGIN
    IF @Action IS NULL OR DATALENGTH(@Action)<>LEN(@Action) RETURN NULL;
    RETURN CASE
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.AUTH.LOGIN.SUCCESS','DBMS12.AUTH.LOGIN.FAILURE','DBMS12.AUTH.ACCESS.DENIED','DBMS12.AUTH.LOGOUT','DBMS12.AUTH.PASSWORD.CHANGE','DBMS12.AUTH.PROFILE.UPDATE','DBMS12.ADMIN.ACCOUNT.CREATE','DBMS12.ADMIN.ACCOUNT.STATUS','DBMS12.ADMIN.ACCOUNT.RESET','DBMS12.STUDENT.SIGNUP') THEN 'ACCOUNT'
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.ACADEMIC.COURSE.CREATE','DBMS12.ACADEMIC.COURSE.UPDATE') THEN 'COURSE'
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.STUDENT.REGISTRATION.CREATE','DBMS12.STUDENT.REGISTRATION.CONFIRM','DBMS12.STUDENT.REGISTRATION.CANCEL','DBMS12.ADMISSIONS.REGISTRATION.REJECT','DBMS12.ADMISSIONS.REGISTRATION.CANCEL','DBMS12.ADMISSIONS.REGISTRATION.APPROVE') THEN 'REGISTRATION'
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.ACADEMIC.CLASS.CREATE','DBMS12.ACADEMIC.CLASS.EDIT','DBMS12.ACADEMIC.CLASS.OPEN','DBMS12.ACADEMIC.CLASS.START','DBMS12.ACADEMIC.CLASS.COMPLETE','DBMS12.ACADEMIC.CLASS.CANCEL','DBMS12.ACADEMIC.PLACEMENT.CREATE','DBMS12.ACADEMIC.SCHEDULE.BATCH','DBMS12.TEACHER.GRADE.SUBMIT','DBMS12.ACADEMIC.GRADE.RETURN','DBMS12.ACADEMIC.GRADE.FINALIZE') THEN 'CLASS'
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.ACADEMIC.SCHEDULE.MOVE','DBMS12.ACADEMIC.SCHEDULE.HELD','DBMS12.TEACHER.ATTENDANCE.SAVE') THEN 'SCHEDULE'
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.TEACHER.GRADE.SAVE') THEN 'REPORT'
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.FINANCE.INVOICE.COLLECT','DBMS12.FINANCE.INVOICE.CORRECT') THEN 'INVOICE'
        WHEN @Action COLLATE Latin1_General_100_BIN2 IN ('DBMS12.OPERATOR.SEED','DBMS12.OPERATOR.BOOTSTRAP','DBMS12.MAINTENANCE.CLEANUP') THEN 'NONE'
        ELSE NULL END;
END;
GO
