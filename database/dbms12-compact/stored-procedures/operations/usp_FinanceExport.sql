CREATE OR ALTER PROCEDURE dbo.usp_FinanceExport
 @Sid binary(32),
 @Epoch bigint,
 @From datetime2(3),
 @Until datetime2(3)
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
IF @SessionRole<>'Accountant' THROW 51203,N'Chỉ Accountant lấy dữ liệu CSV tài chính.',1;
        IF @From IS NULL OR @Until IS NULL OR @Until<=@From THROW 51234,N'Khoảng ngày không hợp lệ.',1;
        SELECT i.invoice_id,CONVERT(varchar(20),i.invoice_number) AS invoice_number,a.full_name,
            CONVERT(varchar(18),i.amount) AS amount,i.issued_at,i.paid_at,i.invoice_status,i.payment_method,i.payment_reference,
            CONVERT(bit,CASE WHEN i.issued_at>=@From AND i.issued_at<@Until THEN 1 ELSE 0 END) AS billed_in_period,
            CONVERT(bit,CASE WHEN i.paid_at>=@From AND i.paid_at<@Until THEN 1 ELSE 0 END) AS paid_in_period,
            CONVERT(bit,CASE WHEN i.invoice_status='UNPAID' THEN 1 ELSE 0 END) AS current_unpaid
        FROM dbo.v_InvoiceFacts i JOIN dbo.Account a ON a.account_id=i.student_account_id
        WHERE (i.issued_at>=@From AND i.issued_at<@Until) OR (i.paid_at>=@From AND i.paid_at<@Until) OR i.invoice_status='UNPAID'
        ORDER BY i.invoice_id;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
