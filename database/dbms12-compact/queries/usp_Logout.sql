CREATE OR ALTER PROCEDURE dbo.usp_Logout
 @Sid binary(32),
 @Epoch bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,1,0,@Actor OUTPUT,@SessionRole OUTPUT;
DELETE dbo.AuthSession WHERE sid=@Sid;
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,change_details)
        VALUES(NEWID(),@Actor,'DBMS12.AUTH.LOGOUT',@Actor,'SUCCESS',N'Thu hồi phiên hiện tại.');
END;
GO
