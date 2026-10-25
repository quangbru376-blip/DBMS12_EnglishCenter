CREATE OR ALTER PROCEDURE dbo.usp_LoginRecord
 @AccountId int,
 @ObservedHash varchar(512),
 @ObservedEpoch bigint,
 @Accepted bit,
 @Sid binary(32)
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
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
DECLARE @Now datetime2(3)=SYSUTCDATETIME(),@Hash varchar(512),@Version bigint,@State varchar(16),@Temp datetime2(3),
                @Count int,@Window datetime2(3),@Throttle datetime2(3),@Success bit=0,@Result varchar(16)='FAILURE';
        SELECT @Hash=password_hash,@Version=security_version,@State=status,@Temp=temp_issued_at,
               @Count=failed_login_count,@Window=failure_window_started_at,@Throttle=login_throttled_until
        FROM dbo.Account WHERE account_id=@AccountId;
        IF @Hash IS NOT NULL
        BEGIN
            IF @Hash COLLATE Latin1_General_100_BIN2<>@ObservedHash COLLATE Latin1_General_100_BIN2 OR @Version<>@ObservedEpoch OR @ObservedHash IS NULL OR @ObservedEpoch IS NULL
                THROW 51231,N'Credential đã thay đổi; phải kiểm tra lại mật khẩu.',1;
            IF (@Throttle IS NOT NULL AND @Now>=@Throttle) OR (@Throttle IS NULL AND @Window IS NOT NULL AND @Now>=DATEADD(minute,15,@Window))
            BEGIN
                SET @Count=0; SET @Window=NULL; SET @Throttle=NULL;
            END;
            IF @State<>'ACTIVE' OR (@Throttle IS NOT NULL AND @Now<@Throttle) OR (@Temp IS NOT NULL AND @Now>=DATEADD(hour,24,@Temp)) SET @Result='DENIED';
            ELSE IF @Accepted=1
            BEGIN
                IF @Sid IS NULL THROW 51232,N'Thiếu SID mới.',1;
                SET @Success=1; SET @Result='SUCCESS';
                SET @Count=0; SET @Window=NULL; SET @Throttle=NULL;
                INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at) VALUES(@Sid,@AccountId,@Now,@Now);
            END
            ELSE
            BEGIN
                SET @Count=@Count+1; SET @Window=ISNULL(@Window,@Now);
                IF @Count>=5 SET @Throttle=DATEADD(minute,15,@Now);
            END;
            UPDATE dbo.Account SET failed_login_count=@Count,failure_window_started_at=@Window,login_throttled_until=@Throttle WHERE account_id=@AccountId;
        END
        ELSE IF @Accepted=1 THROW 51231,N'Tài khoản không tồn tại.',1;
        DECLARE @Operation uniqueidentifier=NEWID(),@Action varchar(80)='DBMS12.AUTH.LOGIN.FAILURE';
        IF @Success=1 SET @Action='DBMS12.AUTH.LOGIN.SUCCESS';
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,change_details)
        VALUES(@Operation,CASE WHEN @Success=1 THEN @AccountId ELSE NULL END,@Action,@AccountId,@Result,N'Kết quả xác thực; không lưu credential hoặc SID.');
SELECT @Success AS authenticated,@Result AS result_code,@Version AS security_version;
  IF @SqlOwnTransaction=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @SqlOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
