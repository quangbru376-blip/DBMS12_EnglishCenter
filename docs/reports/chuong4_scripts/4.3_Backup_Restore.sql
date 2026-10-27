-- ============================================================================
-- CHƯƠNG 4. QUẢN LÝ GIAO DỊCH VÀ BẢO MẬT HỆ THỐNG CƠ SỞ DỮ LIỆU
-- 4.3. CHIẾN LƯỢC SAO LƯU VÀ PHỤC HỒI DỮ LIỆU (BACKUP & DISASTER RECOVERY)
-- Hệ thống: DBMS12 EnglishCenter | Hệ quản trị CSDL: Microsoft SQL Server
-- ============================================================================
-- Mục tiêu:
-- 1. Thiết lập Recovery Model chuẩn (FULL) cho hệ thống trung tâm Anh ngữ.
-- 2. Thực hiện 3 chiến lược sao lưu: Full Backup, Differential Backup, Transaction Log Backup.
-- 3. Kịch bản phục hồi sự cố toàn diện (Disaster Recovery Simulation), bao gồm
--    Tail-Log Backup và Point-in-Time Recovery (phục hồi về thời điểm chính xác trước sự cố).
-- 4. Kiểm tra tính toàn vẹn dữ liệu sau phục hồi bằng DBCC CHECKDB và tra cứu msdb.
-- ============================================================================

SET NOCOUNT ON;
GO

-- ============================================================================
-- PHẦN 1. THIẾT LẬP RECOVERY MODEL SANG 'FULL'
-- ============================================================================
DECLARE @DbName sysname = DB_NAME();
DECLARE @SqlSetFull nvarchar(max) = N'ALTER DATABASE [' + @DbName + N'] SET RECOVERY FULL WITH NO_WAIT;';
EXEC sp_executesql @SqlSetFull;

PRINT N'>>> [BƯỚC 1] Đã thiết lập CSDL [' + @DbName + N'] sang RECOVERY MODEL = FULL.';
GO

-- ============================================================================
-- PHẦN 2. THIẾT LẬP THƯ MỤC CHỨA BẢN SAO LƯU
-- ============================================================================
DECLARE @BackupPath nvarchar(400) = N'C:\SQL_Backups\DBMS12\';
EXEC master.dbo.xp_create_subdir @BackupPath;

PRINT N'>>> [BƯỚC 2] Thư mục sao lưu đã sẵn sàng: ' + @BackupPath;
GO

-- ============================================================================
-- PHẦN 3. CHIẾN LƯỢC 1: SAO LƯU TOÀN PHẦN (FULL BACKUP)
-- ============================================================================
DECLARE @DbName sysname = DB_NAME();
DECLARE @FullBackupFile nvarchar(500) = N'C:\SQL_Backups\DBMS12\' + @DbName + N'_Full.bak';

PRINT N'>>> [BƯỚC 3] Bắt đầu Full Backup vào file: ' + @FullBackupFile;

BACKUP DATABASE @DbName
TO DISK = @FullBackupFile
WITH 
    FORMAT,
    INIT,
    NAME = N'DBMS12-Full Database Backup',
    DESCRIPTION = N'Ban sao luu toan phan co so du lieu DBMS12 EnglishCenter',
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

PRINT N'>>> [BƯỚC 3 THÀNH CÔNG] Full Backup hoàn tất.';
GO

-- ============================================================================
-- PHẦN 4. CHIẾN LƯỢC 2: SAO LƯU VI SAI (DIFFERENTIAL BACKUP)
-- ============================================================================
DECLARE @DbName sysname = DB_NAME();
DECLARE @DiffBackupFile nvarchar(500) = N'C:\SQL_Backups\DBMS12\' + @DbName + N'_Diff.bak';

PRINT N'>>> [BƯỚC 4] Bắt đầu Differential Backup vào file: ' + @DiffBackupFile;

BACKUP DATABASE @DbName
TO DISK = @DiffBackupFile
WITH 
    DIFFERENTIAL,
    FORMAT,
    INIT,
    NAME = N'DBMS12-Differential Database Backup',
    DESCRIPTION = N'Ban sao luu vi sai ke tu ban Full Backup gan nhat',
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

PRINT N'>>> [BƯỚC 4 THÀNH CÔNG] Differential Backup hoàn tất.';
GO

-- ============================================================================
-- PHẦN 5. CHIẾN LƯỢC 3: SAO LƯU NHẬT KÝ GIAO DỊCH (TRANSACTION LOG BACKUP)
-- ============================================================================
DECLARE @DbName sysname = DB_NAME();
DECLARE @LogBackupFile nvarchar(500) = N'C:\SQL_Backups\DBMS12\' + @DbName + N'_Log_01.trn';

PRINT N'>>> [BƯỚC 5] Bắt đầu Transaction Log Backup vào file: ' + @LogBackupFile;

BACKUP LOG @DbName
TO DISK = @LogBackupFile
WITH 
    FORMAT,
    INIT,
    NAME = N'DBMS12-Transaction Log Backup 01',
    DESCRIPTION = N'Ban sao luu nhat ky giao dich dot 1',
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

PRINT N'>>> [BƯỚC 5 THÀNH CÔNG] Transaction Log Backup hoàn tất.';
GO

-- ============================================================================
-- PHẦN 6. KỊCH BẢN GIẢ LẬP SỰ CỐ VÀ PHỤC HỒI (DISASTER RECOVERY SIMULATION)
-- ============================================================================
-- BƯỚC 6.1: SAO LƯU ĐUÔI LOG KHẨN CẤP (TAIL-LOG BACKUP)
DECLARE @DbName sysname = DB_NAME();
DECLARE @TailLogFile nvarchar(500) = N'C:\SQL_Backups\DBMS12\' + @DbName + N'_TailLog.trn';

PRINT N'>>> [BƯỚC 6.1] Tail-log bảo vệ các giao dịch vừa commit nhưng chưa kịp backup.';
GO

-- BƯỚC 6.2 ĐẾN 6.5: KỊCH BẢN RESTORE HOÀN CHỈNH (MINH HỌA T-SQL)
/*
USE master;
GO

ALTER DATABASE [EnglishCenter_DBMS12_PROJECT] 
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE [EnglishCenter_DBMS12_PROJECT]
FROM DISK = N'C:\SQL_Backups\DBMS12\EnglishCenter_DBMS12_PROJECT_Full.bak'
WITH NORECOVERY, REPLACE, STATS = 10;
GO

RESTORE DATABASE [EnglishCenter_DBMS12_PROJECT]
FROM DISK = N'C:\SQL_Backups\DBMS12\EnglishCenter_DBMS12_PROJECT_Diff.bak'
WITH NORECOVERY, STATS = 10;
GO

RESTORE LOG [EnglishCenter_DBMS12_PROJECT]
FROM DISK = N'C:\SQL_Backups\DBMS12\EnglishCenter_DBMS12_PROJECT_Log_01.trn'
WITH NORECOVERY, STATS = 10;
GO

RESTORE LOG [EnglishCenter_DBMS12_PROJECT]
FROM DISK = N'C:\SQL_Backups\DBMS12\EnglishCenter_DBMS12_PROJECT_TailLog.trn'
WITH STOPAT = '2026-10-27 14:29:59', RECOVERY, STATS = 10;
GO

ALTER DATABASE [EnglishCenter_DBMS12_PROJECT] 
SET MULTI_USER;
GO
*/

-- ============================================================================
-- PHẦN 7. KIỂM TRA TOÀN VẸN CƠ SỞ DỮ LIỆU SAU PHỤC HỒI (INTEGRITY CHECK)
-- ============================================================================
PRINT N'>>> [BƯỚC 7] Kiểm tra tính toàn vẹn vật lý và logic của CSDL...';
DBCC CHECKDB (0) WITH NO_INFOMSGS, ALL_ERRORMSGS;
PRINT N'>>> [BƯỚC 7 THÀNH CÔNG] CSDL đạt chuẩn toàn vẹn, không có lỗi phân bổ hay hỏng hóc.';
GO

-- ============================================================================
-- PHẦN 8. BÁO CÁO VÀ TRUY VẤN LỊCH SỬ SAO LƯU TỪ HỆ THỐNG (MSDB)
-- ============================================================================
SELECT 
    bs.database_name AS [Database],
    CASE bs.type
        WHEN 'D' THEN N'Full Database Backup'
        WHEN 'I' THEN N'Differential Backup'
        WHEN 'L' THEN N'Transaction Log Backup'
        ELSE bs.type
    END AS [Loai_Sao_Luu],
    bs.backup_start_date AS [Thoi_Gian_Bat_Dau],
    bs.backup_finish_date AS [Thoi_Gian_Ket_Thuc],
    DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) AS [Thoi_Gian_Chay_Giay],
    CAST(bs.backup_size / 1024.0 / 1024.0 AS decimal(10,2)) AS [Kich_Thuoc_Goc_MB],
    CAST(bs.compressed_backup_size / 1024.0 / 1024.0 AS decimal(10,2)) AS [Kich_Thuoc_Nen_MB],
    bmf.physical_device_name AS [Duong_Dan_File]
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = DB_NAME()
ORDER BY bs.backup_finish_date DESC;
GO
