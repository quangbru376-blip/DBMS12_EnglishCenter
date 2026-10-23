CREATE OR ALTER PROCEDURE dbo.usp_RegistrationList
 @Sid binary(32),
 @Epoch bigint,
 @CourseId int=NULL,
 @Status varchar(16)=NULL,
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
IF @SessionRole NOT IN ('Student','Admissions','AcademicAffairs') THROW 51203,N'Không có quyền xem hồ sơ.',1;
        IF @Page<1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 51233,N'Phân trang không hợp lệ.',1;
        SELECT registration_id,student_account_id,course_id,status,created_at,row_version,full_name,email,phone,course_code,course_name,is_unfinished,
            (SELECT TOP(1) e.reason FROM dbo.AuditLog e WHERE e.root_entity_id=f.registration_id AND e.result_code='SUCCESS'
              AND e.action_code IN ('DBMS12.ADMISSIONS.REGISTRATION.REJECT','DBMS12.ADMISSIONS.REGISTRATION.CANCEL') ORDER BY e.audit_id DESC) AS decision_reason
        FROM dbo.v_RegistrationFacts f
        WHERE (@SessionRole<>'Student' OR student_account_id=@Actor) AND (@SessionRole<>'AcademicAffairs' OR status='ADMITTED')
          AND (@CourseId IS NULL OR course_id=@CourseId) AND (@Status IS NULL OR status=@Status)
        ORDER BY registration_id DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
        SELECT COUNT_BIG(*) AS total FROM dbo.Registration WHERE (@SessionRole<>'Student' OR student_account_id=@Actor)
          AND (@SessionRole<>'AcademicAffairs' OR status='ADMITTED') AND (@CourseId IS NULL OR course_id=@CourseId) AND (@Status IS NULL OR status=@Status);
END;
GO
