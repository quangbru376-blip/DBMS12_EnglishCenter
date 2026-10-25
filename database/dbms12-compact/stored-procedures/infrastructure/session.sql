CREATE OR ALTER PROCEDURE dbo.usp_SecuritySession
 @Sid binary(32),@Epoch bigint,@RequiredRole varchar(24),@AllowRestricted bit,@Native bit,
 @Actor int OUTPUT,@Role varchar(24) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 -- Tự mở giao dịch nếu chưa có; SP con dùng giao dịch của bên gọi.
 DECLARE @SqlOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;
 BEGIN TRY
  IF @SqlOwnTransaction=1 BEGIN TRANSACTION;
SET @Actor=NULL; SET @Role=NULL;
DECLARE @Issued datetime2(3),@Activity datetime2(3),@Temp datetime2(3),@Now datetime2(3)=SYSUTCDATETIME();
SELECT @Actor=a.account_id,@Role=a.role_code,@Issued=s.issued_at,@Activity=s.last_activity_at,@Temp=a.temp_issued_at
FROM dbo.AuthSession s JOIN dbo.Account a ON a.account_id=s.account_id
WHERE s.sid=@Sid AND a.status='ACTIVE' AND a.security_version=@Epoch;
IF @Actor IS NULL THROW 51201,N'Phiên không hợp lệ.',1;
IF (@Temp IS NULL AND (@Now>=DATEADD(hour,2,@Issued) OR @Now>=DATEADD(minute,30,@Activity)))
 OR (@Temp IS NOT NULL AND (@Now>=DATEADD(minute,10,@Issued) OR @Now>=DATEADD(hour,24,@Temp))) THROW 51201,N'Phiên đã hết hạn.',1;
IF @Temp IS NOT NULL AND @AllowRestricted=0 THROW 51202,N'Phải đổi mật khẩu trước.',1;
IF @RequiredRole IS NOT NULL AND @Role COLLATE Latin1_General_100_BIN2<>@RequiredRole COLLATE Latin1_General_100_BIN2 THROW 51203,N'Không có quyền.',1;

IF @Native=1 AND ISNULL(CASE @Role
 WHEN 'Admin' THEN IS_ROLEMEMBER('role_QuanTri')
 WHEN 'Admissions' THEN IS_ROLEMEMBER('role_TuyenSinh')
 WHEN 'AcademicAffairs' THEN IS_ROLEMEMBER('role_GiaoVu')
 WHEN 'Teacher' THEN IS_ROLEMEMBER('role_GiaoVien')
 WHEN 'Accountant' THEN IS_ROLEMEMBER('role_KeToan')
 WHEN 'Director' THEN IS_ROLEMEMBER('role_GiamDoc')
 WHEN 'Student' THEN IS_ROLEMEMBER('role_HocVien')
 END,0)<>1 THROW 51203,N'Vai trò SQL không khớp phiên ứng dụng.',1;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
