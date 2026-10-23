-- DBMS12 / SQL Server / independent database only
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TYPE dbo.ScheduleBatch AS TABLE (
    item_no int NOT NULL PRIMARY KEY,
    schedule_type varchar(16) NOT NULL,
    start_at datetime2(3) NOT NULL,
    end_at datetime2(3) NOT NULL,
    room nvarchar(50) NOT NULL
);
GO
CREATE TYPE dbo.AttendanceBatch AS TABLE (
    class_assignment_id int NOT NULL PRIMARY KEY,
    present bit NOT NULL,
    expected_version binary(8) NULL
);
GO
CREATE TYPE dbo.GradeManifest AS TABLE (
    report_id int NOT NULL PRIMARY KEY,
    expected_version binary(8) NOT NULL
);
GO
