CREATE OR ALTER PROCEDURE dbo.usp_StudentHome
 @Sid binary(32),
 @Epoch bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF @SessionRole<>'Student' THROW 51203,N'Chỉ Student xem trang chủ của mình.',1;
        SELECT r.registration_id,r.course_id,p.course_code,p.course_name,r.status,a.class_id,c.class_code,
            i.invoice_id,i.invoice_status,c.grade_status,
            CASE WHEN r.status='PENDING' THEN 'CONFIRM'
                 WHEN r.status='CONFIRMED' THEN 'WAIT_ADMISSION'
                 WHEN r.status='ADMITTED' AND i.invoice_status='UNPAID' THEN 'PAY'
                 WHEN r.status='ADMITTED' AND a.class_assignment_id IS NULL THEN 'WAIT_PLACEMENT'
                 WHEN c.grade_status='FINALIZED' THEN 'VIEW_RESULT'
                 WHEN a.class_assignment_id IS NOT NULL THEN 'VIEW_CLASS'
                 ELSE 'CLOSED' END AS next_action
        FROM dbo.Registration r JOIN dbo.Course p ON p.course_id=r.course_id
        LEFT JOIN dbo.StudentClassAssignment a ON a.registration_id=r.registration_id
        LEFT JOIN dbo.v_ClassState c ON c.class_id=a.class_id
        LEFT JOIN dbo.v_InvoiceFacts i ON i.registration_id=r.registration_id
        WHERE r.student_account_id=@Actor ORDER BY r.registration_id DESC;
END;
GO
