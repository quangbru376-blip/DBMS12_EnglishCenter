CREATE OR ALTER PROCEDURE dbo.usp_WeeklySchedulePreview
 @Sid binary(32),
 @Epoch bigint,
 @ClassId int,
 @FromDate date,
 @UntilDate date,
 @Weekdays varchar(8),
 @StartTime time(0),
 @EndTime time(0),
 @Room nvarchar(51)
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
IF @SessionRole<>'AcademicAffairs' THROW 51203,N'Chỉ giáo vụ tạo lịch tuần.',1;
        IF @FromDate IS NULL OR @UntilDate IS NULL OR @UntilDate<@FromDate OR DATEDIFF(day,@FromDate,@UntilDate)>365
            OR @Weekdays IS NULL OR DATALENGTH(@Weekdays) NOT BETWEEN 1 AND 7 OR @Weekdays COLLATE Latin1_General_100_BIN2 LIKE '%[^1-7]%'
            OR @StartTime IS NULL OR @EndTime IS NULL OR @EndTime<=@StartTime OR DATEPART(second,@StartTime)<>0 OR DATEPART(second,@EndTime)<>0
            OR @Room IS NULL OR DATALENGTH(@Room)>100 OR LEN(LTRIM(RTRIM(@Room)))=0 THROW 51234,N'Mẫu lịch tuần không hợp lệ.',1;
        DECLARE @Remaining int;
        SELECT @Remaining=p.expected_lesson_count-(SELECT COUNT(*) FROM dbo.Schedule s WHERE s.class_id=c.class_id AND s.schedule_type='LESSON')
        FROM dbo.Class c JOIN dbo.Course p ON p.course_id=c.course_id WHERE c.class_id=@ClassId AND c.status NOT IN ('COMPLETED','CANCELLED');
        IF @Remaining IS NULL THROW 51218,N'Lớp không hợp lệ.',1;
        SELECT TOP(@Remaining) 'LESSON' AS schedule_type,
            DATEADD(hour,-7,DATEADD(minute,DATEDIFF(minute,CONVERT(time,'00:00'),@StartTime),CONVERT(datetime2(3),DATEADD(day,n.day_no,@FromDate)))) AS start_at,
            DATEADD(hour,-7,DATEADD(minute,DATEDIFF(minute,CONVERT(time,'00:00'),@EndTime),CONVERT(datetime2(3),DATEADD(day,n.day_no,@FromDate)))) AS end_at,@Room AS room
        FROM (
            SELECT a.n+10*b.n+100*c.n AS day_no
            FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) a(n)
            CROSS JOIN (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) b(n)
            CROSS JOIN (VALUES(0),(1),(2),(3)) c(n)
        ) n
        WHERE DATEADD(day,n.day_no,@FromDate)<=@UntilDate
          AND CHARINDEX(CONVERT(varchar(1),((DATEDIFF(day,CONVERT(date,'19000101'),DATEADD(day,n.day_no,@FromDate))%7+7)%7)+1),@Weekdays)>0
        ORDER BY n.day_no;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
