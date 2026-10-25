CREATE OR ALTER PROCEDURE dbo.usp_AdminAccountList
 @Sid binary(32),
 @Epoch bigint,
 @Page int=1,
 @PageSize int=20,
 @Search nvarchar(200)=N'',
 @AccountRole varchar(24)=NULL,
 @Status varchar(16)=NULL
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
IF @SessionRole<>'Admin' THROW 51203,N'Chỉ Admin quản lý tài khoản.',1;
        IF @Page<1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 51233,N'Phân trang không hợp lệ.',1;
        SELECT account_id,role_code,email,full_name,phone,status,created_at,row_version FROM dbo.Account
        WHERE (@AccountRole IS NULL OR role_code=@AccountRole) AND (@Status IS NULL OR status=@Status)
          AND (full_name COLLATE Latin1_General_100_CI_AS_SC LIKE N'%'+@Search+N'%' OR email LIKE '%'+@Search+'%')
        ORDER BY account_id OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
        SELECT COUNT_BIG(*) AS total FROM dbo.Account WHERE (@AccountRole IS NULL OR role_code=@AccountRole) AND (@Status IS NULL OR status=@Status)
          AND (full_name COLLATE Latin1_General_100_CI_AS_SC LIKE N'%'+@Search+N'%' OR email LIKE '%'+@Search+'%');
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
