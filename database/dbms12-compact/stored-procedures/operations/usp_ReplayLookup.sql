CREATE OR ALTER PROCEDURE dbo.usp_ReplayLookup
 @Sid binary(32),
 @Epoch bigint,
 @Action varchar(80),
 @RequestId uniqueidentifier
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
SELECT r.operation_id,a.root_entity_id AS target_id,r.completed_at FROM dbo.ReplayOperation r JOIN dbo.AuditLog a ON a.operation_id=r.operation_id
        WHERE r.actor_account_id=@Actor AND r.action_code=@Action AND r.request_id=@RequestId AND r.completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
