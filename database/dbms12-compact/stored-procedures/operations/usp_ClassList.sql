CREATE OR ALTER PROCEDURE dbo.usp_ClassList
 @Sid binary(32),
 @Epoch bigint,
 @ClassId int=NULL,
 @Status varchar(16)=NULL,
 @GradeStatus varchar(16)=NULL
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
IF @SessionRole NOT IN ('Student','Teacher','AcademicAffairs') THROW 51203,N'Không có quyền xem lớp.',1;
        SELECT c.class_id,c.class_code,c.course_id,c.teacher_account_id,c.capacity,c.status,c.grade_status,c.row_version,
            p.expected_lesson_count,p.lesson_count,p.exam_count,p.unheld_count,
            CASE WHEN @SessionRole<>'Student' THEN p.missing_attendance ELSE NULL END AS missing_attendance,p.progress_percent,
            course.course_code,course.course_name,teacher.full_name AS teacher_name,
            CASE WHEN @SessionRole IN ('Teacher','AcademicAffairs') THEN (SELECT TOP(1) e.reason FROM dbo.AuditLog e
                WHERE e.root_entity_id=c.class_id AND e.action_code='DBMS12.ACADEMIC.GRADE.RETURN' AND e.result_code='SUCCESS' ORDER BY e.audit_id DESC) ELSE NULL END AS last_return_reason,
            (SELECT COUNT(*) FROM dbo.StudentClassAssignment a WHERE a.class_id=c.class_id) AS assigned_count
        FROM dbo.v_ClassState c JOIN dbo.v_ClassProgress p ON p.class_id=c.class_id
        JOIN dbo.Course course ON course.course_id=c.course_id JOIN dbo.Account teacher ON teacher.account_id=c.teacher_account_id
        WHERE (@ClassId IS NULL OR c.class_id=@ClassId)
          AND (@Status IS NULL OR c.status=@Status) AND (@GradeStatus IS NULL OR c.grade_status=@GradeStatus)
          AND (@SessionRole<>'Teacher' OR c.teacher_account_id=@Actor)
          AND (@SessionRole<>'Student' OR EXISTS(SELECT 1 FROM dbo.StudentClassAssignment a JOIN dbo.Registration r ON r.registration_id=a.registration_id WHERE a.class_id=c.class_id AND r.student_account_id=@Actor))
        ORDER BY c.class_id;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
