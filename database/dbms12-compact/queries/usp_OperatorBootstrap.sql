CREATE OR ALTER PROCEDURE dbo.usp_OperatorBootstrap
 @Email varchar(255),
 @Name nvarchar(201),
 @PasswordHash varchar(513)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
 IF IS_ROLEMEMBER('db_owner')<>1 AND IS_ROLEMEMBER('dbms12_operator')<>1 THROW 51203,N'Operator only.',1;
IF EXISTS(SELECT account_id FROM dbo.Account) THROW 51236,N'Bootstrap chỉ tạo Admin đầu tiên trong catalog mới rỗng.',1;
        IF DATALENGTH(@Email)>254 OR DATALENGTH(@Name)>400 OR DATALENGTH(@PasswordHash)>512 THROW 51235,N'Input vượt độ dài.',1;
        INSERT dbo.Account(role_code,email,full_name,password_hash,temp_issued_at) VALUES('Admin',@Email,@Name,@PasswordHash,SYSUTCDATETIME());
        DECLARE @Id int=CONVERT(int,SCOPE_IDENTITY());
        INSERT dbo.AuditLog(operation_id,action_code,result_code,change_details)
        VALUES(NEWID(),'DBMS12.OPERATOR.BOOTSTRAP','SUCCESS',CONCAT(N'SQL operator tạo Admin đầu tiên, account_id=',@Id,N'; không giả actor web.'));
SELECT @Id AS account_id;
END;
GO
