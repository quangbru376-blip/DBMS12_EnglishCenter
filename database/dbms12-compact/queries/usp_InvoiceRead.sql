CREATE OR ALTER PROCEDURE dbo.usp_InvoiceRead
 @Sid binary(32),
 @Epoch bigint,
 @RegistrationId int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF @SessionRole NOT IN ('Student','Admissions','AcademicAffairs','Accountant') THROW 51203,N'Không có quyền xem hóa đơn.',1;
        IF @SessionRole IN ('Admissions','AcademicAffairs')
            SELECT invoice_id,registration_id,invoice_status FROM dbo.v_InvoiceFacts WHERE registration_id=@RegistrationId;
        ELSE IF @SessionRole='Student'
            SELECT invoice_id,CONVERT(varchar(20),invoice_number) AS invoice_number,registration_id,CONVERT(varchar(18),amount) AS amount,
                issued_at,paid_at,payment_method,payment_reference,invoice_status,due_date,debt_flag
            FROM dbo.v_InvoiceFacts WHERE registration_id=@RegistrationId AND student_account_id=@Actor;
        ELSE
            SELECT invoice_id,CONVERT(varchar(20),invoice_number) AS invoice_number,registration_id,CONVERT(varchar(18),amount) AS amount,
                issued_at,paid_at,paid_by,payment_method,payment_reference,invoice_status,due_date,debt_flag,row_version
            FROM dbo.v_InvoiceFacts WHERE registration_id=@RegistrationId;
END;
GO
