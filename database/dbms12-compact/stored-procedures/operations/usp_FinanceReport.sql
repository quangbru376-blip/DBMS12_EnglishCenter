CREATE OR ALTER PROCEDURE dbo.usp_FinanceReport
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
IF @SessionRole<>'Accountant' THROW 51203,N'Chỉ Accountant xem báo cáo tài chính chi tiết.',1;
        IF @From IS NULL OR @Until IS NULL OR @Until<=@From THROW 51234,N'Khoảng ngày không hợp lệ.',1;
        SELECT CONVERT(varchar(38),ISNULL(SUM(CONVERT(decimal(38,0),amount)),0)) AS billed FROM dbo.Invoice WHERE issued_at>=@From AND issued_at<@Until;
        SELECT CONVERT(varchar(38),ISNULL(SUM(CONVERT(decimal(38,0),amount)),0)) AS revenue FROM dbo.Invoice WHERE paid_at>=@From AND paid_at<@Until;
        SELECT CONVERT(varchar(38),ISNULL(SUM(CONVERT(decimal(38,0),amount)),0)) AS current_debt FROM dbo.v_InvoiceFacts WHERE invoice_status='UNPAID';
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
