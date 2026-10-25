CREATE OR ALTER PROCEDURE dbo.usp_AttendanceRead
 @Sid binary(32),
 @Epoch bigint,
 @ScheduleId int
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
IF @SessionRole NOT IN ('Teacher','AcademicAffairs') THROW 51203,N'Không có quyền xem điểm danh.',1;
        DECLARE @ClassId int;
        SELECT @ClassId=s.class_id FROM dbo.Schedule s JOIN dbo.Class c ON c.class_id=s.class_id
        WHERE s.schedule_id=@ScheduleId AND s.schedule_type='LESSON' AND (@SessionRole<>'Teacher' OR c.teacher_account_id=@Actor);
        IF @ClassId IS NULL THROW 51203,N'Không phải buổi thuộc lớp phụ trách.',1;
        SELECT a.class_assignment_id,r.student_account_id,p.full_name,t.present,t.recorded_at,t.row_version AS attendance_version
        FROM dbo.StudentClassAssignment a JOIN dbo.Registration r ON r.registration_id=a.registration_id
        JOIN dbo.Account p ON p.account_id=r.student_account_id
        LEFT JOIN dbo.Attendance t ON t.class_assignment_id=a.class_assignment_id AND t.schedule_id=@ScheduleId
        WHERE a.class_id=@ClassId ORDER BY a.class_assignment_id;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
