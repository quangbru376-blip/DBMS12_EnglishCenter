CREATE OR ALTER PROCEDURE dbo.usp_CourseList
 @Sid binary(32),
 @Epoch bigint,
 @Search nvarchar(200)=N'',
 @Page int=1,
 @PageSize int=20
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF @SessionRole NOT IN ('Student','Admissions','AcademicAffairs') THROW 51203,N'Không có quyền xem catalogue.',1;
        IF @Page<1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 51233,N'Phân trang không hợp lệ.',1;
        DECLARE @Pattern nvarchar(1000)=N'%'+REPLACE(REPLACE(REPLACE(@Search,N'[',N'[[]'),N'%',N'[%]'),N'_',N'[_]')+N'%';
        IF @SessionRole='AcademicAffairs'
            SELECT course_id,course_code,course_name,CONVERT(varchar(18),tuition_fee) AS tuition_fee,status,expected_lesson_count,process_weight,row_version
            FROM dbo.Course WHERE course_name COLLATE Latin1_General_100_CI_AS_SC LIKE @Pattern ORDER BY course_id OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
        ELSE
            SELECT course_id,course_code,course_name,CONVERT(varchar(18),tuition_fee) AS tuition_fee
            FROM dbo.Course WHERE status='ACTIVE' AND course_name COLLATE Latin1_General_100_CI_AS_SC LIKE @Pattern ORDER BY course_id OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
        SELECT COUNT_BIG(*) AS total FROM dbo.Course WHERE (@SessionRole='AcademicAffairs' OR status='ACTIVE') AND course_name COLLATE Latin1_General_100_CI_AS_SC LIKE @Pattern;
END;
GO
