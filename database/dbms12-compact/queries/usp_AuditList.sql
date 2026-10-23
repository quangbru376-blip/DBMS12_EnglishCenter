CREATE OR ALTER PROCEDURE dbo.usp_AuditList
 @Sid binary(32),
 @Epoch bigint,
 @Action varchar(80)=NULL,
 @RootId int=NULL,
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
IF @SessionRole<>'Admin' THROW 51203,N'Chỉ Admin xem audit.',1;
        IF @Page<1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 51233,N'Phân trang không hợp lệ.',1;
        SELECT CONVERT(varchar(20),a.audit_id) AS audit_id,a.operation_id,a.actor_account_id,a.action_code,a.root_entity_id,a.result_code,a.occurred_at,a.reason,a.change_details,
            CASE WHEN a.occurred_at>DATEADD(day,-90,SYSUTCDATETIME()) THEN a.ip_address ELSE NULL END AS ip_address
        FROM dbo.AuditLog a WHERE (@Action IS NULL OR a.action_code=@Action) AND (@RootId IS NULL OR a.root_entity_id=@RootId)
        ORDER BY a.audit_id DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
