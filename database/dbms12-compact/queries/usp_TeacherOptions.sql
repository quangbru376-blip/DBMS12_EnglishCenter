CREATE OR ALTER PROCEDURE dbo.usp_TeacherOptions
 @Sid binary(32),
 @Epoch bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF @SessionRole<>'AcademicAffairs' THROW 51203,N'Chỉ giáo vụ chọn giáo viên.',1;
        SELECT account_id,full_name,email FROM dbo.Account WHERE role_code='Teacher' AND status='ACTIVE' ORDER BY full_name,account_id;
END;
GO
