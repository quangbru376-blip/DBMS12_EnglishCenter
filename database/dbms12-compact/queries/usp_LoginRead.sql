CREATE OR ALTER PROCEDURE dbo.usp_LoginRead
 @Email varchar(254)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
-- Internal authentication adapter only: never return this result to a browser.
    SELECT account_id,password_hash,security_version,status,temp_issued_at,login_throttled_until,row_version
    FROM dbo.Account WHERE email=@Email;
END;
GO
