CREATE OR ALTER PROCEDURE dbo.usp_DirectorReport
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
IF @SessionRole<>'Director' THROW 51203,N'Chỉ Director xem dashboard tổng hợp.',1;
        IF @From IS NULL OR @Until IS NULL OR @Until<=@From THROW 51234,N'Khoảng ngày không hợp lệ.',1;
        SELECT status,COUNT_BIG(*) AS registrations FROM dbo.Registration WHERE created_at>=@From AND created_at<@Until GROUP BY status;
        SELECT status,COUNT_BIG(*) AS classes FROM dbo.Class GROUP BY status;
        SELECT passed,COUNT_BIG(*) AS results FROM dbo.v_FinalizedGrades WHERE finalized_at>=@From AND finalized_at<@Until GROUP BY passed;
        SELECT CONVERT(varchar(38),ISNULL(SUM(CONVERT(decimal(38,0),amount)),0)) AS revenue FROM dbo.Invoice WHERE paid_at>=@From AND paid_at<@Until;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
