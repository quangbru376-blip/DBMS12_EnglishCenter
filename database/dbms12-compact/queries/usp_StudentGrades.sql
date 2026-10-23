CREATE OR ALTER PROCEDURE dbo.usp_StudentGrades
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
IF @SessionRole<>'Student' THROW 51203,N'Chỉ Student xem kết quả của mình.',1;
        SELECT class_assignment_id,class_id,class_code,course_id,continuous_score,final_exam_score,final_score,passed,teacher_comment,finalized_at
        FROM dbo.v_FinalizedGrades WHERE student_account_id=@Actor ORDER BY finalized_at DESC,class_assignment_id;
END;
GO
