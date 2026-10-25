CREATE OR ALTER PROCEDURE dbo.usp_CurrentSession
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
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,1,0,@Actor OUTPUT,@SessionRole OUTPUT;
SELECT a.account_id,a.role_code,a.email,a.full_name,a.phone,a.date_of_birth,a.address,a.row_version,
            CASE WHEN a.temp_issued_at IS NULL THEN 'NORMAL' ELSE 'PASSWORD_CHANGE' END AS session_scope,
            CASE WHEN a.temp_issued_at IS NULL THEN DATEADD(hour,2,s.issued_at)
                 WHEN DATEADD(minute,10,s.issued_at)<DATEADD(hour,24,a.temp_issued_at) THEN DATEADD(minute,10,s.issued_at)
                 ELSE DATEADD(hour,24,a.temp_issued_at) END AS absolute_deadline,
            DATEADD(minute,30,s.last_activity_at) AS normal_idle_deadline
        FROM dbo.Account a JOIN dbo.AuthSession s ON s.account_id=a.account_id WHERE s.sid=@Sid;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
