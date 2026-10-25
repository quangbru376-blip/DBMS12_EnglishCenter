CREATE OR ALTER PROCEDURE dbo.usp_InvoiceSearch
 @Sid binary(32),
 @Epoch bigint,
 @State varchar(16)=NULL,
 @Search nvarchar(200)=N'',
 @Page int=1,
 @PageSize int=20
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 -- Tự mở giao dịch nếu chưa có; SP con dùng giao dịch của bên gọi.
 DECLARE @SqlOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
 BEGIN TRY
  IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
IF @@TRANCOUNT<>1 THROW 51200,N'Độ sâu transaction không hợp lệ.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF @SessionRole<>'Accountant' THROW 51203,N'Chỉ Accountant tra cứu tài chính.',1;
        IF @Page<1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 51233,N'Phân trang không hợp lệ.',1;
        SELECT i.invoice_id,CONVERT(varchar(20),i.invoice_number) AS invoice_number,i.registration_id,
            a.full_name,a.email,CONVERT(varchar(18),i.amount) AS amount,i.issued_at,i.paid_at,i.paid_by,i.payment_method,i.payment_reference,
            i.invoice_status,i.debt_flag,i.due_date,i.row_version
        FROM dbo.v_InvoiceFacts i JOIN dbo.Account a ON a.account_id=i.student_account_id
        WHERE (@State IS NULL OR i.invoice_status=@State) AND (a.full_name COLLATE Latin1_General_100_CI_AS_SC LIKE N'%'+@Search+N'%' OR a.email LIKE '%'+@Search+'%')
        ORDER BY i.invoice_id DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
        SELECT COUNT_BIG(*) AS total FROM dbo.v_InvoiceFacts i JOIN dbo.Account a ON a.account_id=i.student_account_id
        WHERE (@State IS NULL OR i.invoice_status=@State) AND (a.full_name COLLATE Latin1_General_100_CI_AS_SC LIKE N'%'+@Search+N'%' OR a.email LIKE '%'+@Search+'%');
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
