function generate({add}){
 const specs=[
  {name:'IX_Registration_StudentCourse',columns:'registration_id int NOT NULL PRIMARY KEY,student_account_id int,course_id int,status varchar(16),created_at datetime2(3)',values:"n,n%1000+1,n%17+1,'PENDING',DATEADD(minute,n,CONVERT(datetime2(3),'2025-01-01'))",index:'(student_account_id,course_id,status) INCLUDE(created_at)',where:'student_account_id=@Student AND course_id=@Course',checksum:'registration_id,status,created_at',args:'DECLARE @Student int=42,@Course int=7;'},
  {name:'IX_Class_TeacherStatus',columns:'class_id int NOT NULL PRIMARY KEY,teacher_account_id int,status varchar(16),course_id int',values:"n,n%1000+1,CASE WHEN n%3=0 THEN 'OPEN' ELSE 'PLANNED' END,n%17+1",index:'(teacher_account_id,status) INCLUDE(course_id)',where:"teacher_account_id=@Teacher AND status=@Status",checksum:'class_id,course_id',args:"DECLARE @Teacher int=42,@Status varchar(16)='OPEN';"},
  {name:'IX_Schedule_ClassStart',columns:'schedule_id int NOT NULL PRIMARY KEY,class_id int,start_at datetime2(3),end_at datetime2(3),schedule_type varchar(16),room nvarchar(50),held_at datetime2(3)',values:"n,n%1000+1,DATEADD(minute,n,CONVERT(datetime2(3),'2025-01-01')),DATEADD(minute,n+60,CONVERT(datetime2(3),'2025-01-01')),'LESSON',N'A101',NULL",index:'(class_id,start_at) INCLUDE(end_at,schedule_type,room,held_at)',where:'class_id=@Class AND start_at>=@From AND start_at<@Until',checksum:'schedule_id,end_at,schedule_type,room,held_at',args:"DECLARE @Class int=42,@From datetime2(3)='2025-02-01',@Until datetime2(3)='2025-02-07';"},
  {name:'IX_Invoice_Issued',columns:'invoice_id int NOT NULL PRIMARY KEY,issued_at datetime2(3),amount decimal(18,0),registration_id int,paid_at datetime2(3)',values:"n,DATEADD(minute,n,CONVERT(datetime2(3),'2025-01-01')),1000000,n,NULL",index:'(issued_at,invoice_id) INCLUDE(amount,registration_id,paid_at)',where:'issued_at>=@From AND issued_at<@Until',checksum:'invoice_id,amount,registration_id,paid_at',args:"DECLARE @From datetime2(3)='2025-02-01',@Until datetime2(3)='2025-02-02';"},
  {name:'IX_Audit_Time',columns:'audit_id bigint NOT NULL PRIMARY KEY,occurred_at datetime2(3),actor_account_id int,action_code varchar(80),result_code varchar(16)',values:"n,DATEADD(minute,n,CONVERT(datetime2(3),'2025-01-01')),n%1000+1,'DBMS12.FINANCE.INVOICE.COLLECT','SUCCESS'",index:'(occurred_at,audit_id) INCLUDE(actor_account_id,action_code,result_code)',where:'occurred_at>=@From AND occurred_at<@Until',checksum:'audit_id,actor_account_id,action_code,result_code',args:"DECLARE @From datetime2(3)='2025-02-01',@Until datetime2(3)='2025-02-02';"}
 ];
 for(const s of specs)add('indexes',s.name,`-- Đo có kiểm soát trên temp replica100000dòng, cùng key/include và predicate.
-- Không DROP/DISABLE index của bảng thật; đây không phải benchmark production.
CREATE TABLE #Lab(${s.columns});
INSERT #Lab SELECT ${s.values} FROM(SELECT TOP(100000) CONVERT(int,ROW_NUMBER() OVER(ORDER BY(SELECT NULL))) AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b) t;
${s.args}
DECLARE @N0 bigint,@N1 bigint,@C0 int,@C1 int;
PRINT 'EC_INDEX_BASELINE|${s.name}';
SET STATISTICS IO ON; SET STATISTICS TIME ON;
SELECT @N0=COUNT_BIG(*),@C0=CHECKSUM_AGG(BINARY_CHECKSUM(${s.checksum})) FROM #Lab WHERE ${s.where};
SET STATISTICS IO OFF; SET STATISTICS TIME OFF;
CREATE INDEX [${s.name}] ON #Lab${s.index};
PRINT 'EC_INDEX_WITH|${s.name}';
SET STATISTICS IO ON; SET STATISTICS TIME ON;
SELECT @N1=COUNT_BIG(*),@C1=CHECKSUM_AGG(BINARY_CHECKSUM(${s.checksum})) FROM #Lab WHERE ${s.where};
SET STATISTICS IO OFF; SET STATISTICS TIME OFF;
IF @N0<>@N1 OR ISNULL(@C0,0)<>ISNULL(@C1,0) THROW 51992,N'Hai truy vấn phải trả cùng dữ liệu.',1;
SELECT @N0 AS baseline_rows,@N1 AS indexed_rows,@C0 AS baseline_checksum,@C1 AS indexed_checksum;
PRINT 'EC_INDEX_END|${s.name}';
DROP TABLE #Lab;`);
}
module.exports={generate};
