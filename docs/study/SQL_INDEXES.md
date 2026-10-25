# Index — lý do và minh chứng

Source có17 CREATE INDEX tường minh, gồm2filtered UNIQUE và15index thường, ngoài index tự tạo bởi PK/UQ. Chỉ mục được định nghĩa cuối [tables/01_schema.sql](../../database/dbms12-compact/tables/01_schema.sql).

## Phân công học index

Chia đủ 17 index: TV1 5, TV2 4, TV3 4, TV4 4. TV4 nhận Schedule theo nghiệp vụ buổi học và phối hợp TV3 phụ trách bảng. Mỗi tên có đúng một người trình bày; [bảng phân công tổng](DATABASE_OBJECTS_4_MEMBERS.md) giữ nguyên 105 core object và phân công index riêng.

|Index|Bảng|Người phụ trách|Mục đích|Key/INCLUDE/filter|
|---|---|---|---|---|
|[UX_Class_CurrentGradeOperation](../../database/dbms12-compact/tables/01_schema.sql#L241)|Class|TV3|Không để cùng một operation quyết định bảng điểm được gắn cho nhiều lớp; bỏ qua NULL.|`([current_grade_operation_id]) WHERE current_grade_operation_id IS NOT NULL`|
|[UX_Schedule_OneFinalExam](../../database/dbms12-compact/tables/01_schema.sql#L243)|Schedule|TV4|Bảo đảm mỗi lớp có nhiều nhất một lịch FINAL_EXAM; không tự bảo đảm lớp đã có kỳ thi.|`([class_id]) WHERE schedule_type='FINAL_EXAM'`|
|[IX_Account_RoleStatus](../../database/dbms12-compact/tables/01_schema.sql#L245)|Account|TV1|Hỗ trợ lọc tài khoản theo vai trò và trạng thái.|`([role_code],[status],[account_id])`|
|[IX_AuthSession_Account](../../database/dbms12-compact/tables/01_schema.sql#L247)|AuthSession|TV1|Hỗ trợ tìm/thu hồi các phiên của một tài khoản.|`([account_id]) INCLUDE ([issued_at],[last_activity_at])`|
|[IX_Registration_StudentCourse](../../database/dbms12-compact/tables/01_schema.sql#L249)|Registration|TV2|Hỗ trợ tra hồ sơ theo học viên, khóa và trạng thái.|`([student_account_id],[course_id],[status]) INCLUDE ([created_at])`|
|[IX_Registration_CourseStatus](../../database/dbms12-compact/tables/01_schema.sql#L251)|Registration|TV2|Hỗ trợ danh sách tuyển sinh theo khóa/trạng thái/thời điểm đăng ký.|`([course_id],[status],[created_at]) INCLUDE ([student_account_id])`|
|[IX_Class_CourseStatus](../../database/dbms12-compact/tables/01_schema.sql#L253)|Class|TV3|Hỗ trợ tìm lớp theo khóa và trạng thái, kèm sức chứa/giáo viên.|`([course_id],[status]) INCLUDE ([capacity],[teacher_account_id])`|
|[IX_Class_TeacherStatus](../../database/dbms12-compact/tables/01_schema.sql#L255)|Class|TV3|Hỗ trợ tìm lớp giáo viên phụ trách theo trạng thái.|`([teacher_account_id],[status]) INCLUDE ([course_id])`|
|[IX_Assignment_Class](../../database/dbms12-compact/tables/01_schema.sql#L257)|StudentClassAssignment|TV3|Hỗ trợ đọc danh sách phân lớp/học viên trong một lớp.|`([class_id],[class_assignment_id]) INCLUDE ([registration_id])`|
|[IX_Schedule_ClassStart](../../database/dbms12-compact/tables/01_schema.sql#L259)|Schedule|TV4|Hỗ trợ truy vấn lịch của lớp theo khoảng thời gian.|`([class_id],[start_at]) INCLUDE ([end_at],[schedule_type],[room],[held_at])`|
|[IX_Schedule_RoomStart](../../database/dbms12-compact/tables/01_schema.sql#L261)|Schedule|TV4|Hỗ trợ tìm lịch theo phòng/thời gian để kiểm tra xung đột; index không tự cấm trùng lịch.|`([room],[start_at]) INCLUDE ([end_at],[class_id])`|
|[IX_Attendance_Assignment](../../database/dbms12-compact/tables/01_schema.sql#L263)|Attendance|TV4|Hỗ trợ tra điểm danh của học viên đã xếp lớp qua các buổi.|`([class_assignment_id],[schedule_id]) INCLUDE ([present])`|
|[IX_Invoice_Issued](../../database/dbms12-compact/tables/01_schema.sql#L265)|Invoice|TV2|Hỗ trợ tra/báo cáo hóa đơn theo ngày phát hành.|`([issued_at],[invoice_id]) INCLUDE ([amount],[registration_id],[paid_at])`|
|[IX_Invoice_Paid](../../database/dbms12-compact/tables/01_schema.sql#L267)|Invoice|TV2|Hỗ trợ tra doanh thu theo ngày thu, chỉ giữ hóa đơn đã thanh toán trong index.|`([paid_at],[invoice_id]) INCLUDE ([amount],[registration_id]) WHERE paid_at IS NOT NULL`|
|[IX_Audit_RootAction](../../database/dbms12-compact/tables/01_schema.sql#L269)|AuditLog|TV1|Hỗ trợ tra nhật ký theo thực thể nghiệp vụ và loại hành động.|`([root_entity_id],[action_code],[audit_id]) INCLUDE ([occurred_at],[result_code],[actor_account_id])`|
|[IX_Audit_Time](../../database/dbms12-compact/tables/01_schema.sql#L271)|AuditLog|TV1|Hỗ trợ lọc/sắp nhật ký theo thời gian và audit_id.|`([occurred_at],[audit_id]) INCLUDE ([actor_account_id],[action_code],[result_code])`|
|[IX_Replay_Completed](../../database/dbms12-compact/tables/01_schema.sql#L273)|ReplayOperation|TV1|Hỗ trợ tìm receipt theo thời điểm hoàn thành để dọn bản ghi quá hạn.|`([completed_at],[replay_id])`|

## Năm chỉ mục dùng để bảo vệ

|Index|Người trình bày|Lý do|Bài chạy riêng|
|---|---|---|---|
|IX_Registration_StudentCourse|TV2|Tra hồ sơ theo học viên và khóa; status nằm sau equality keys, created_at được cover.|[Đo trước/sau](../../database/practice/indexes/IX_Registration_StudentCourse.sql)|
|IX_Class_TeacherStatus|TV3|Danh sách lớp giáo viên theo trạng thái; cover course_id, giảm lookup.|[Đo trước/sau](../../database/practice/indexes/IX_Class_TeacherStatus.sql)|
|IX_Schedule_ClassStart|TV4|Lịch một lớp theo khoảng thời gian; equality class_id rồi range start_at; cover giờ kết thúc/loại/phòng/HELD.|[Đo trước/sau](../../database/practice/indexes/IX_Schedule_ClassStart.sql)|
|IX_Invoice_Issued|TV2|Báo cáo hóa đơn theo khoảng phát hành; cover amount/registration/paid metadata.|[Đo trước/sau](../../database/practice/indexes/IX_Invoice_Issued.sql)|
|IX_Audit_Time|TV1|Lọc/sắp nhật ký theo thời gian và audit_id; cover actor/action/result.|[Đo trước/sau](../../database/practice/indexes/IX_Audit_Time.sql)|

Chạy `./tools/Invoke-SqlLearning.ps1 -Group indexes` hoặc F5 từng bài trong SSMS. Mỗi bài tạo temp replica100000dòng tổng hợp, cùng key/INCLUDE và predicate của chỉ mục được khảo sát. Truy vấn trước tạo nonclustered index và sau tạo index phải có cùng số dòng/checksum. Đọc logical reads từ STATISTICS IO; runner chỉ PASS khi reads sau thấp hơn trước. STATISTICS TIME cũng được ghi; trong SSMS bật Actual Execution Plan (Ctrl+M) để xem scan/seek/cover.

Đây là thí nghiệm có kiểm soát về cơ chế chỉ mục; không drop/disable index bảng thật, không xóa cache chung và không gọi đó là đo hiệu năng production của dữ liệu main. So logical reads giúp tránh chỉ dựa vào thời gian vài ms và ảnh hưởng cache. Index tăng chi phí ghi/bộ nhớ/lưu trữ; không suy ra mọi index đều cần chỉ vì đủ số lượng.

Kết quả đo thực tế của lần chạy hiện tại: [evidence](../evidence/sql-learning/index-performance.json). Không điền số liệu dự đoán vào bảng kết quả. [Microsoft — STATISTICS IO và logical reads](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statistics-io-transact-sql?view=sql-server-ver17).
