-- ==============================================================================
-- BƯỚC 2: SCRIPT NHẬP (RESTORE) DATABASE TRÊN MÁY B (MÁY NHẬN)
-- Mục đích: Phục hồi CSDL từ file .bak của Máy A đè vào CSDL của Máy B,
-- và TỰ ĐỘNG ÁNH XẠ LẠI QUYỀN TRUY CẬP cho Windows Runtime user của Máy B.
-- ==============================================================================

USE master;
GO

-- 1. Cấu hình thông tin
DECLARE @BackupFile nvarchar(500) = N'C:\SQL_Backups\DBMS12_Team_Shared.bak';

-- Tìm tên CSDL dự án trên máy B (nếu đã từng khởi động dự án)
DECLARE @TargetDbName nvarchar(256);
SELECT TOP 1 @TargetDbName = name 
FROM sys.databases 
WHERE name LIKE 'EnglishCenter_DBMS12_PROJECT_%' 
ORDER BY create_date DESC;

-- Nếu máy B chưa có CSDL hoặc muốn chỉ định tên cụ thể, hãy điền vào đây:
-- SET @TargetDbName = N'EnglishCenter_DBMS12_PROJECT_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

IF @TargetDbName IS NULL
BEGIN
    RAISERROR(N'Không tìm thấy CSDL đích! Hãy khởi động Chay-Project.cmd 1 lần trên máy B trước, hoặc điền tên CSDL mong muốn vào @TargetDbName.', 16, 1);
    RETURN;
END;

PRINT N'--> Database đích trên máy B sẽ được ghi đè: ' + @TargetDbName;
PRINT N'--> Nguồn file sao lưu: ' + @BackupFile;

-- 2. Ngắt các kết nối đang hoạt động tới Database đích trên máy B
PRINT N'--> Đang ngắt các kết nối active tới CSDL...';
DECLARE @SqlKill nvarchar(max) = N'ALTER DATABASE ' + QUOTENAME(@TargetDbName) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
EXEC sp_executesql @SqlKill;

-- 3. Phục hồi dữ liệu (RESTORE DATABASE WITH REPLACE)
PRINT N'--> Đang tiến hành RESTORE DATABASE...';
DECLARE @SqlRestore nvarchar(max) = N'
RESTORE DATABASE ' + QUOTENAME(@TargetDbName) + N'
FROM DISK = N''' + @BackupFile + N'''
WITH REPLACE, 
     RECOVERY, 
     STATS = 10;';

EXEC sp_executesql @SqlRestore;

-- Đặt lại chế độ MULTI_USER
DECLARE @SqlMulti nvarchar(max) = N'ALTER DATABASE ' + QUOTENAME(@TargetDbName) + N' SET MULTI_USER;';
EXEC sp_executesql @SqlMulti;

PRINT N'--> Phục hồi cấu trúc và dữ liệu thành công!';

-- ==============================================================================
-- 4. BƯỚC SỐNG CÒN: ÁNH XẠ LẠI QUYỀN CHO WINDOWS RUNTIME LOGIN CỦA MÁY B
-- Vì file .bak mang user Windows của máy A, ta phải map lại cho máy B
-- để ứng dụng Web C# (Dbms12Runtime) khởi động không bị lỗi quyền truy cập.
-- ==============================================================================
PRINT N'--> Đang kiểm tra và ánh xạ lại tài khoản Runtime của Máy B...';

DECLARE @ComputerName nvarchar(128) = CAST(SERVERPROPERTY('MachineName') AS nvarchar(128));
DECLARE @RuntimeLogin nvarchar(256) = @ComputerName + N'\Dbms12Runtime';
PRINT N'--> Tên Windows Runtime Login của máy B: ' + @RuntimeLogin;

-- Kiểm tra xem Windows Login đã có trên SQL Server chưa
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @RuntimeLogin)
BEGIN
    PRINT N'--> Tạo mới Windows Login trên SQL Server: ' + @RuntimeLogin;
    DECLARE @SqlCreateLogin nvarchar(max) = N'CREATE LOGIN ' + QUOTENAME(@RuntimeLogin) + N' FROM WINDOWS;';
    EXEC sp_executesql @SqlCreateLogin;
END;

-- Ánh xạ Database User Dbms12ProjectRuntime sang Windows Login của máy B
DECLARE @SqlFixUser nvarchar(max) = N'
USE ' + QUOTENAME(@TargetDbName) + N';

-- Nếu user Dbms12ProjectRuntime đã tồn tại, ánh xạ lại sang Login máy B
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''Dbms12ProjectRuntime'')
BEGIN
    ALTER USER [Dbms12ProjectRuntime] WITH LOGIN = ' + QUOTENAME(@RuntimeLogin) + N';
    PRINT N''    [PASS] Da anh xa user Dbms12ProjectRuntime sang '' + ' + QUOTENAME(@RuntimeLogin, '''') + N';
END
ELSE
BEGIN
    CREATE USER [Dbms12ProjectRuntime] FOR LOGIN ' + QUOTENAME(@RuntimeLogin) + N';
    PRINT N''    [PASS] Da tao moi user Dbms12ProjectRuntime cho '' + ' + QUOTENAME(@RuntimeLogin, '''') + N';
END;

-- Đảm bảo user thuộc role dbms12_runtime
ALTER ROLE [dbms12_runtime] ADD MEMBER [Dbms12ProjectRuntime];
PRINT N''    [PASS] Da cap quyen dbms12_runtime cho Dbms12ProjectRuntime.'';
';

EXEC sp_executesql @SqlFixUser;

-- 5. Kiểm tra toàn vẹn CSDL
PRINT N'--> Kiểm tra tính toàn vẹn CSDL (DBCC CHECKDB)...';
DECLARE @SqlCheck nvarchar(max) = N'DBCC CHECKDB(' + QUOTENAME(@TargetDbName) + N') WITH NO_INFOMSGS;';
EXEC sp_executesql @SqlCheck;

PRINT N'==============================================================================';
PRINT N'--> HOÀN TẤT ĐỒNG BỘ CSDL SANG MÁY B THÀNH CÔNG!';
PRINT N'--> Máy B bây giờ có thể chạy Chay-Project.cmd bình thường và có toàn bộ dữ liệu của Máy A.';
PRINT N'==============================================================================';
GO
