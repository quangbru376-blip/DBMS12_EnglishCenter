-- Bài học 3.4: chạy bằng owner trong SSMS/sqlcmd, CHỈ catalog fixture mới.
-- Điền danh tính từ profile của fixture do Invoke-SecurityRehearsal tạo.
-- Không dùng profile/catalog đang chứa dữ liệu của bạn. Mặc định script từ chối chạy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @FixtureDatabase sysname=NULL, @FixtureGuid uniqueidentifier=NULL;
IF @FixtureDatabase IS NULL OR @FixtureGuid IS NULL
 THROW 51990,N'Điền tên và GUID của catalog fixture riêng trước khi chạy.',1;
IF DB_NAME()<>@FixtureDatabase OR DB_NAME() NOT LIKE 'EnglishCenter[_]DBMS12[_]PROJECT[_]%'
 OR NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid=@FixtureGuid)
 THROW 51990,N'Sai danh tính fixture.',1;
IF USER_NAME()<>'dbo' OR @@TRANCOUNT<>0 THROW 51990,N'Cần owner, connection mới, không có transaction bên ngoài.',1;

-- Session thử nghiệm chỉ tồn tại trong bài học; không xuất SID/hash/password.
DECLARE @Sessions TABLE(account_id int PRIMARY KEY,sid binary(32),epoch bigint);
INSERT @Sessions SELECT account_id,CRYPT_GEN_RANDOM(32),security_version FROM dbo.Account
 WHERE (account_id=2 AND role_code='Admissions') OR (account_id=3 AND role_code='AcademicAffairs')
 OR (account_id=5 AND role_code='Accountant') OR (account_id=7 AND role_code='Student');
IF (SELECT COUNT(*) FROM @Sessions)<>4 THROW 51990,N'Cần đúng sample accounts của fixture mới.',1;
DECLARE @Sid binary(32),@Epoch bigint,@Request uniqueidentifier,@Digest binary(32),@Version binary(8),
 @Course int,@Registration int,@Invoice int,@Class int,@ClassVersion binary(8),
 @Code varchar(50)='STUDY-'+LEFT(CONVERT(varchar(36),NEWID()),8),@ClassCode varchar(50),@Switched bit=0;
SET @ClassCode=@Code+'-CLASS';
BEGIN TRY
 INSERT dbo.AuthSession(sid,account_id,issued_at,last_activity_at)
 SELECT sid,account_id,SYSUTCDATETIME(),SYSUTCDATETIME() FROM @Sessions;

 -- 1. TẠO KHÓA: Course + AuditLog SUCCESS + ReplayOperation + activity.
 SELECT @Sid=sid,@Epoch=epoch FROM @Sessions WHERE account_id=3;
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('CourseCreate|',@Code,'|1000000|1|40'));
 BEGIN TRY
  BEGIN TRANSACTION;
  EXECUTE AS USER='Dbms12AcademicAffairs'; SET @Switched=1;
  EXEC dbo.usp_CourseCreate @Sid,@Epoch,@Request,@Digest,@Code,N'Khóa học transaction','1000000',1,'40';
  REVERT; SET @Switched=0;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
  THROW;
 END CATCH;
 SELECT @Course=course_id FROM dbo.Course WHERE course_code=@Code;

 -- 2. ĐĂNG KÝ: Registration + audit + receipt cùng commit/rollback.
 SELECT @Sid=sid,@Epoch=epoch FROM @Sessions WHERE account_id=7;
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('RegistrationCreate|',@Course));
 BEGIN TRY
  BEGIN TRANSACTION;
  EXECUTE AS USER='Dbms12Student'; SET @Switched=1;
  EXEC dbo.usp_RegistrationCreate @Sid,@Epoch,@Request,@Digest,@Course;
  REVERT; SET @Switched=0;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
  THROW;
 END CATCH;
 SELECT @Registration=registration_id,@Version=row_version FROM dbo.Registration
 WHERE course_id=@Course AND student_account_id=7;
 -- Điều kiện trước duyệt: học viên tự xác nhận. SP tự mở transaction vì depth=0.
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('Confirm|',@Registration,'|',CONVERT(varchar(18),@Version,1)));
 EXECUTE AS USER='Dbms12Student'; SET @Switched=1;
 EXEC dbo.usp_RegistrationConfirm @Sid,@Epoch,@Request,@Digest,@Registration,@Version;
 REVERT; SET @Switched=0;

 -- 3. DUYỆT NHẬP HỌC: CONFIRMED -> ADMITTED và tạo đúng một Invoice.
 SELECT @Sid=sid,@Epoch=epoch FROM @Sessions WHERE account_id=2;
 SELECT @Version=row_version FROM dbo.Registration WHERE registration_id=@Registration;
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('Approve|',@Registration,'|',CONVERT(varchar(18),@Version,1)));
 BEGIN TRY
  BEGIN TRANSACTION;
  EXECUTE AS USER='Dbms12Admissions'; SET @Switched=1;
  EXEC dbo.usp_AdmissionApprove @Sid,@Epoch,@Request,@Digest,@Registration,@Version;
  REVERT; SET @Switched=0;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
  THROW;
 END CATCH;

 -- 4. THU HỌC PHÍ: cập nhật Invoice + audit + receipt, kiểm rowversion.
 SELECT @Sid=sid,@Epoch=epoch FROM @Sessions WHERE account_id=5;
 SELECT @Invoice=invoice_id,@Version=row_version FROM dbo.Invoice WHERE registration_id=@Registration;
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('Collect|',@Invoice,'|',CONVERT(varchar(18),@Version,1),'|CASH'));
 BEGIN TRY
  BEGIN TRANSACTION;
  EXECUTE AS USER='Dbms12Accountant'; SET @Switched=1;
  EXEC dbo.usp_InvoiceCollect @Sid,@Epoch,@Request,@Digest,@Invoice,@Version,'CASH',NULL;
  REVERT; SET @Switched=0;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
  THROW;
 END CATCH;

 -- Chuẩn bị lớp nhận học viên: tạo lớp + đủ 1 LESSON/1 FINAL_EXAM, rồi OPEN.
 SELECT @Sid=sid,@Epoch=epoch FROM @Sessions WHERE account_id=3;
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('ClassCreate|',@ClassCode,'|',@Course,'|9|1'));
 EXECUTE AS USER='Dbms12AcademicAffairs'; SET @Switched=1;
 EXEC dbo.usp_ClassCreate @Sid,@Epoch,@Request,@Digest,@ClassCode,@Course,9,1;
 REVERT; SET @Switched=0;
 SELECT @Class=class_id,@ClassVersion=row_version FROM dbo.Class WHERE class_code=@ClassCode;
 DECLARE @Items dbo.ScheduleBatch,@Start datetime2=DATEADD(day,90,SYSUTCDATETIME());
 INSERT @Items VALUES(1,'LESSON',@Start,DATEADD(hour,1,@Start),@Code),
 (2,'FINAL_EXAM',DATEADD(day,1,@Start),DATEADD(hour,25,@Start),@Code);
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('ScheduleBatch|',@Class,'|',CONVERT(varchar(33),@Start,126),'|',@Code));
 EXECUTE AS USER='Dbms12AcademicAffairs'; SET @Switched=1;
 EXEC dbo.usp_ScheduleBatch @Sid,@Epoch,@Request,@Digest,@Class,@ClassVersion,@Items;
 REVERT; SET @Switched=0;
 SELECT @ClassVersion=row_version FROM dbo.Class WHERE class_id=@Class;
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('ClassOpen|',@Class,'|',CONVERT(varchar(18),@ClassVersion,1)));
 EXECUTE AS USER='Dbms12AcademicAffairs'; SET @Switched=1;
 EXEC dbo.usp_ClassOpen @Sid,@Epoch,@Request,@Digest,@Class,@ClassVersion;
 REVERT; SET @Switched=0;

 -- 5. XẾP LỚP: Assignment + GradeReport DRAFT + audit + receipt cùng transaction.
 SELECT @Version=row_version FROM dbo.Registration WHERE registration_id=@Registration;
 SELECT @ClassVersion=row_version FROM dbo.Class WHERE class_id=@Class;
 SET @Request=NEWID(); SET @Digest=HASHBYTES('SHA2_256',CONCAT('Placement|',@Registration,'|',@Class,'|',CONVERT(varchar(18),@Version,1),'|',CONVERT(varchar(18),@ClassVersion,1)));
 BEGIN TRY
  BEGIN TRANSACTION;
  EXECUTE AS USER='Dbms12AcademicAffairs'; SET @Switched=1;
  EXEC dbo.usp_PlacementCreate @Sid,@Epoch,@Request,@Digest,@Registration,@Version,@Class,@ClassVersion;
  REVERT; SET @Switched=0;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  IF @Switched=1 BEGIN REVERT; SET @Switched=0; END;
  THROW;
 END CATCH;
 DELETE a FROM dbo.AuthSession a JOIN @Sessions s ON s.sid=a.sid AND s.account_id=a.account_id;
 SELECT @Code AS study_course_code,@Registration AS registration_id,@Class AS class_id,@@TRANCOUNT AS transaction_depth;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 IF @Switched=1 REVERT;
 DELETE a FROM dbo.AuthSession a JOIN @Sessions s ON s.sid=a.sid AND s.account_id=a.account_id;
 THROW;
END CATCH;
-- Mỗi ví dụ đã COMMIT độc lập: lỗi bước sau không hoàn tác các ví dụ trước.
-- ROLLBACK không đảm bảo lấp khoảng trống IDENTITY/SEQUENCE/rowversion.
