CREATE OR ALTER PROCEDURE dbo.usp_ScheduleList
 @Sid binary(32),
 @Epoch bigint,
 @From datetime2(3),
 @Until datetime2(3)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCK,HOLDLOCK);
 DECLARE @Actor int,@SessionRole varchar(24);
 EXEC dbo.usp_SecuritySession @Sid,@Epoch,NULL,0,1,@Actor OUTPUT,@SessionRole OUTPUT;
IF @SessionRole NOT IN ('Student','Teacher','AcademicAffairs') THROW 51203,N'Không có quyền xem lịch.',1;
        IF @From IS NULL OR @Until IS NULL OR @Until<=@From THROW 51234,N'Khoảng ngày không hợp lệ.',1;
        SELECT s.schedule_id,s.class_id,s.class_code,s.schedule_type,s.start_at,s.end_at,s.room,s.schedule_status,s.row_version
        FROM dbo.v_CurrentSchedule s WHERE s.start_at<@Until AND s.end_at>@From AND s.class_status<>'CANCELLED'
          AND (@SessionRole<>'Teacher' OR s.teacher_account_id=@Actor)
          AND (@SessionRole<>'Student' OR EXISTS(SELECT 1 FROM dbo.StudentClassAssignment a JOIN dbo.Registration r ON r.registration_id=a.registration_id WHERE a.class_id=s.class_id AND r.student_account_id=@Actor))
        ORDER BY s.start_at,s.schedule_id;
END;
GO
