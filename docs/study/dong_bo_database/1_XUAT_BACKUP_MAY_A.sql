-- ==============================================================================
-- BƯỚC 1: SCRIPT XUẤT BACKUP DATABASE TRÊN MÁY A (MÁY CHIA SẺ)
-- Mục đích: Tạo bản sao lưu toàn vẹn (Full Backup) của CSDL dự án hiện tại
-- để gửi cho các thành viên khác trong nhóm.
-- ==============================================================================

USE master;
GO

-- 1. Khai báo biến
DECLARE @DbName nvarchar(256);
DECLARE @BackupFile nvarchar(500);
DECLARE @SqlBackup nvarchar(max);

-- Lấy tên Database dự án đang chạy trên máy A
-- (Mặc định chọn Database có tiền tố EnglishCenter_DBMS12_PROJECT_)
SELECT TOP 1 @DbName = name 
FROM sys.databases 
WHERE name LIKE 'EnglishCenter_DBMS12_PROJECT_%' 
ORDER BY create_date DESC;

-- Nếu muốn chỉ định cứng tên DB, bỏ comment dòng sau:
-- SET @DbName = N'EnglishCenter_DBMS12_PROJECT_c4cef5a3a9b042b3bc4b0517f979d8d1';

IF @DbName IS NULL
BEGIN
    RAISERROR(N'Không tìm thấy CSDL bắt đầu bằng EnglishCenter_DBMS12_PROJECT_!', 16, 1);
    RETURN;
END;

PRINT N'--> Database được chọn để Backup: ' + @DbName;

-- 2. Đường dẫn lưu trữ file .bak (Lưu ý: Thư mục C:\SQL_Backups phải tồn tại)
-- Bạn có thể đổi đường dẫn theo ý muốn
SET @BackupFile = N'C:\SQL_Backups\DBMS12_Team_Shared.bak';

PRINT N'--> Bắt đầu quá trình sao lưu ra file: ' + @BackupFile;

-- 3. Thực hiện BACKUP DATABASE FULL
SET @SqlBackup = N'
BACKUP DATABASE ' + QUOTENAME(@DbName) + N'
TO DISK = N''' + @BackupFile + N'''
WITH FORMAT, 
     INIT, 
     NAME = N''DBMS12_Team_Shared_FullBackup'',
     COMPRESSION, 
     CHECKSUM, 
     STATS = 10;';

EXEC sp_executesql @SqlBackup;

PRINT N'==============================================================================';
PRINT N'--> SAO LƯU THÀNH CÔNG!';
PRINT N'--> Hãy gửi file: ' + @BackupFile + N' cho thành viên trong nhóm.';
PRINT N'==============================================================================';
GO
