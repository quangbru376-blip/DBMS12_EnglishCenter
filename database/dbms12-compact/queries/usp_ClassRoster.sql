CREATE OR ALTER PROCEDURE dbo.usp_ClassRoster
 @Sid binary(32),
 @Epoch bigint,
 @ClassId int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF @SessionRole NOT IN ('Teacher','AcademicAffairs') THROW 51203,N'Không có quyền xem roster.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Class WHERE class_id=@ClassId AND (@SessionRole<>'Teacher' OR teacher_account_id=@Actor)) THROW 51203,N'Không phải lớp phụ trách.',1;
        SELECT r.class_assignment_id,r.registration_id,r.student_account_id,r.full_name,r.email,r.phone,r.report_id,
            CASE WHEN @SessionRole='Teacher' OR c.grade_status IN ('SUBMITTED','FINALIZED') THEN r.continuous_score ELSE NULL END AS continuous_score,
            CASE WHEN @SessionRole='Teacher' OR c.grade_status IN ('SUBMITTED','FINALIZED') THEN r.final_exam_score ELSE NULL END AS final_exam_score,
            CASE WHEN @SessionRole='Teacher' OR c.grade_status IN ('SUBMITTED','FINALIZED') THEN r.teacher_comment ELSE NULL END AS teacher_comment,
            CASE WHEN @SessionRole='Teacher' OR c.grade_status IN ('SUBMITTED','FINALIZED') THEN r.report_version ELSE NULL END AS report_version
        FROM dbo.v_ClassRoster r JOIN dbo.v_ClassState c ON c.class_id=r.class_id WHERE r.class_id=@ClassId ORDER BY r.class_assignment_id;
END;
GO
