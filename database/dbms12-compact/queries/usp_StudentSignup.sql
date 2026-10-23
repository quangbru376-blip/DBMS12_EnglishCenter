CREATE OR ALTER PROCEDURE dbo.usp_StudentSignup
 @Email varchar(255),
 @Name nvarchar(201),
 @Phone varchar(11),
 @BirthDate date,
 @Address nvarchar(256),
 @PasswordHash varchar(513)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51200,N'Caller phải mở transaction.',1;
 DECLARE @SecurityLockRows bigint;
 SELECT @SecurityLockRows=COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX,HOLDLOCK);
IF DATALENGTH(@Email)>254 OR DATALENGTH(@Name)>400 OR DATALENGTH(@Phone)>10 OR DATALENGTH(@Address)>510 OR DATALENGTH(@PasswordHash)>512
            THROW 51235,N'Input vượt độ dài cho phép.',1;
        INSERT dbo.Account(role_code,email,full_name,phone,date_of_birth,address,password_hash)
        VALUES('Student',@Email,@Name,@Phone,@BirthDate,@Address,@PasswordHash);
        DECLARE @Id int=CONVERT(int,SCOPE_IDENTITY()),@Operation uniqueidentifier=NEWID();
        INSERT dbo.AuditLog(operation_id,actor_account_id,action_code,root_entity_id,result_code,change_details)
        VALUES(@Operation,@Id,'DBMS12.STUDENT.SIGNUP',@Id,'SUCCESS',N'Tạo tài khoản Student.');
SELECT @Id AS account_id;
END;
GO
