CREATE OR ALTER PROCEDURE dbo.usp_PasswordSnapshot
 @Sid binary(32),@Epoch bigint
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @Actor int,@Role varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,1,0,@Actor OUTPUT,@Role OUTPUT;
 SELECT password_hash FROM dbo.Account WHERE account_id=@Actor AND status='ACTIVE';
END;
GO
