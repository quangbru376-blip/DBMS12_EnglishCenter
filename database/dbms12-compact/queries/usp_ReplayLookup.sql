CREATE OR ALTER PROCEDURE dbo.usp_ReplayLookup
 @Sid binary(32),
 @Epoch bigint,
 @Action varchar(80),
 @RequestId uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
SELECT r.operation_id,a.root_entity_id AS target_id,r.completed_at FROM dbo.ReplayOperation r JOIN dbo.AuditLog a ON a.operation_id=r.operation_id
        WHERE r.actor_account_id=@Actor AND r.action_code=@Action AND r.request_id=@RequestId AND r.completed_at>DATEADD(hour,-24,SYSUTCDATETIME());
END;
GO
