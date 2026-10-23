CREATE OR ALTER PROCEDURE dbo.usp_MaintenanceCleanup

AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 IF IS_ROLEMEMBER('db_owner')<>1 AND IS_ROLEMEMBER('dbms12_operator')<>1 THROW 51203,N'Operator only.',1;
DELETE dbo.ReplayOperation WHERE completed_at<=DATEADD(hour,-24,SYSUTCDATETIME());
        DELETE s FROM dbo.AuthSession s JOIN dbo.Account a ON a.account_id=s.account_id
        WHERE (a.temp_issued_at IS NULL AND (s.issued_at<=DATEADD(hour,-2,SYSUTCDATETIME()) OR s.last_activity_at<=DATEADD(minute,-30,SYSUTCDATETIME())))
           OR (a.temp_issued_at IS NOT NULL AND (s.issued_at<=DATEADD(minute,-10,SYSUTCDATETIME()) OR a.temp_issued_at<=DATEADD(hour,-24,SYSUTCDATETIME())));
        UPDATE dbo.AuditLog SET ip_address=NULL WHERE ip_address IS NOT NULL AND occurred_at<=DATEADD(day,-90,SYSUTCDATETIME());
END;
GO
