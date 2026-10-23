CREATE OR ALTER PROCEDURE dbo.usp_RecordFailure
 @Sid binary(32)=NULL,@Epoch bigint=NULL,@Action varchar(80),@Error int
AS
BEGIN
 SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Rows bigint; SELECT @Rows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 DECLARE @Actor int,@Now datetime2(3)=SYSUTCDATETIME();
 SELECT @Actor=a.account_id FROM dbo.AuthSession s JOIN dbo.Account a ON a.account_id=s.account_id
 WHERE s.sid=@Sid AND a.security_version=@Epoch AND a.status='ACTIVE'
 AND ((a.temp_issued_at IS NULL AND @Now<DATEADD(hour,2,s.issued_at) AND @Now<DATEADD(minute,30,s.last_activity_at))
 OR (a.temp_issued_at IS NOT NULL AND @Now<DATEADD(minute,10,s.issued_at) AND @Now<DATEADD(hour,24,a.temp_issued_at)));
 INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,result_code,change_details)
 VALUES(NEWID(),@Actor,@Action,CASE WHEN @Error IN(51201,51202,51203) THEN 'DENIED' ELSE 'FAILURE' END,CONCAT(N'Mã lỗi SQL ',@Error,N'; business transaction rolled back.'));
 COMMIT;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
