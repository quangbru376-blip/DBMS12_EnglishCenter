CREATE OR ALTER PROCEDURE dbo.usp_Logout
 @Sid binary(32),
 @Epoch bigint
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
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,1,0,@Actor OUTPUT,@SessionRole OUTPUT;
DELETE dbo.AuthSession WHERE sid=@Sid;
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,change_details)
        VALUES(NEWID(),@Actor,'DBMS12.AUTH.LOGOUT',@Actor,'SUCCESS',N'Thu hồi phiên hiện tại.');
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
