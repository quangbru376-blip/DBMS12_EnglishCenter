# Đối chiếu yêu cầu SQL3.1–3.5

Nguồn yêu cầu: [nội dung owner đã gửi](RUBRIC_SQL_SERVER.md). Số lượng lấy từ source hiện tại, không lấy kết quả project cha. Bằng chứng lần chạy bộ học: [summary](../evidence/sql-learning/summary.json). Đây là tự đối chiếu phần3 đã nhận, không phải điểm chấm hoặc cam kết đạt các phần khác của môn.

|Mục|Tối thiểu|Hiện có / nơi xem|Thực hành và bằng chứng|
|---|---|---|---|
|3.1 ERD và lược đồ quan hệ|Thực thể, thuộc tính, quan hệ|[ERD99thuộc tính](../diagrams/ERD-full-attributes.md), [Chen](../diagrams/ERD-Chen-classic.md), [relational schema](SQL_SCHEMA_3NF.md)|Đối chiếu12quan hệ/99cột/19FK với DDL; sơ đồ thể hiện19mối liên kết vật lý|
|3.1 bảng và3NF|8bảng/3NF|12bảng có quan hệ; [FD/candidate keys/3NF](SQL_SCHEMA_3NF.md)|Giải thích theo từng quan hệ, đặc biệt Invoice snapshot và ReplayOperation candidate key; không kết luận3NF chỉ từ số bảng|
|3.1 khóa/toàn vẹn|PK/FK đầy đủ|12PK,19FK; schema WITH CHECK, các trigger còn bật|DBCC/schema evidence trước; source và các bài FK/constraint lần này|
|3.2 ràng buộc|5 CHECK/UNIQUE/DEFAULT có nghĩa|34CHECK,11UQ,20DEFAULT|[6bài riêng](../../database/practice/README.md#constraints): học phí, trọng số, điện thoại, mã khóa duy nhất, default trạng thái/thời gian, FKStudent|
|3.2 trigger|5|12trigger trong source|[12bài riêng](../../database/practice/README.md#triggers), mỗi bài DML vi phạm phải gặp đúng lỗi511xx rồi rollback|
|3.2 view|5|9view|[9bài riêng](../../database/practice/README.md#views); view kết quả có thể rỗng khi chưaFINALIZED|
|3.2 index|5, có nonPK; lý do và đo|17CREATE INDEX tường minh, ngoài index PK/UQ; [danh mục và lý do](SQL_INDEXES.md)|[5benchmark](../../database/practice/README.md#indexes)100000dòng/temp replica, cùng dữ liệu/checksum, logical reads trước/sau; không gọi là đo production|
|3.3 SP|5nghiệp vụ khác nhau|61SP=56operation+5helper;29command/19read/8auth|[61bài riêng](../../database/practice/README.md#stored-procedures), gọi dưới native user phù hợp. Có thêm/sửa/hủy/tìm kiếm/thống kê; hủy theo nghiệp vụ giữ lịch sử|
|3.3 Function|5|7scalar UDF|[7bài riêng](../../database/practice/README.md#functions), có bình thường/NULL/biên|
|3.3 TRY/CATCH|Xử lý lỗi thủ tục|61/61SP cóTRY/CATCH/THROW/XACT_ABORT|Verify-Source kiểm template; native/negative cases và forced rollback|
|3.4 transaction|5nghiệp vụ BEGIN/COMMIT/ROLLBACK|Cả61SP có owner/caller scope; chọn5nghiệp vụ để diễn|[5bài riêng](../../database/practice/README.md#transactions); default rollback, đã thử5COMMIT+5lỗi sau nghiệp vụ và kiểm audit/receipt không còn|
|3.4 concurrency hoặc recovery|Ít nhất1tình huống|Concurrency2người thu cùngInvoice/RV|[Hướng dẫn hai phiên](SQL_TRANSACTIONS.md), source sessionA/B và evidence sql-transactions/sql-object-folders;1commit/1conflict. Không nhận đã kiểm backup/recovery|
|3.5 Role/Login|4vai trò/định danh có quyền khác|7nativebusinessrole/user,4nhóm kỹ thuật, Windows runtimeLogin hiện có|[Policy](../SQL_SECURITY.md),[matrix](../SQL_SECURITY_MATRIX.md), native1477checks trước và bài quyền lần này. Usernghiệp vụ là WITHOUT LOGIN, không mô tả là7loginSQLđộc lập|
|3.5 GRANT/REVOKE/DENY|Có minh họa/chính sách|Module-only, DENY bảng, fixed impersonation/ownership|[2bài riêng](../../database/practice/README.md#security):GRANT→REVOKE→GRANTquaRole+DENYuser và Student bịDENY bảng; role/user thử được rollback|

## Chọn một bộ ví dụ gọn khi bảo vệ

Không cần đọc thuộc61SP trong một lượt trình bày. Nên nắm luồng đăng ký → xác nhận → duyệt/tạoInvoice → thu → xếp lớp và giải thích các module hạ tầng mà nó dùng. Với Function, có thể mở đủ7file vì câu gọi ngắn. Trigger nên đọc inserted/deleted và chỉ ra **vì sao** lệnh thử bị chặn. Với index, chỉ rõ truy vấn nào được hỗ trợ và cho xem số liệu/log/plan của chính bài đó.

OperatorBootstrap có ca từ chối mặc định51236 vì catalog đã có account. ClassStart chuẩn bị lớp OPEN đủ lịch/học viên, chờ16giây đến buổi đầu rồi gọi thành công. Bộ học không xóa dữ liệu/đổi đồng hồ để ép nhánh thành công. Điều kiện nhánh thành công được ghi trong hướng dẫn và source. Kết quả tự kiểm theo rubric cần được giáo viên đánh giá, nhất là cách trình bày3NF, ý nghĩa thí nghiệm index và cách hiểu Role/Login.
