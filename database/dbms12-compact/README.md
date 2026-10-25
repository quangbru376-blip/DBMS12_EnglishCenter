# SQL DBMS12 — đọc theo từng loại object

Đây là **source SQL thật được cài và ứng dụng gọi**. Bắt đầu bằng [danh mục105 object](OBJECT_INDEX.md), rồi chọn thư mục tương ứng. Có12 bảng/99 cột,61 SP,7 function,9 view,12 trigger,3 table type và1 sequence.

|Thư mục|Nội dung|
|---|---|
|[tables](tables/README.md)|12 bảng, PK/FK/CHECK/index và sequence khởi tạo|
|[stored-procedures](stored-procedures/README.md)|core/:11 SP chính; operations/:45 SP còn lại; infrastructure/:5 helper|
|[functions](functions/README.md)|7 function|
|[views](views/README.md)|9 view|
|[triggers](triggers/README.md)|12 trigger|
|[types](types/README.md)|3 table type dùng cho TVP|
|[indexes](indexes/README.md)|17 chỉ mục tường minh, lý do và5 phép đo|
|[security](security/README.md)|SQL role/user và GRANT/DENY|
|[transactions](transactions/README.md)|5 ví dụ nghiệp vụ và tranh chấp hai phiên|
|[seeds](seeds/README.md)|Dữ liệu mẫu cho catalog mới|
|[notes](notes/README.md)|2 ghi chú tương thích, không tạo SP|

Transaction là phạm vi thực thi bên trong SP, không phải một SQL object riêng như function hoặc trigger. Cả61 SP có transaction đầy đủ theo D15; thư mục transactions giúp học cách gọi và kiểm chúng. InvoiceNumberSequence nằm đầu tables/01_schema.sql trước các bảng dùng nó. Một số file chứa nhiều object; index chỉ đúng dòng bắt đầu của từng object.

OwnerProvision đọc manifest.installOrder để cài catalog PROJECT **mới**. Install.sql không phải công cụ nâng database hiện có; sample chỉ được tạo ở catalog mới. Những script trong transactions không nằm trong installOrder và không tự chạy khi mở ứng dụng.

Sau khi sửa SQL, chủ động refresh hash bằng node tools/Refresh-SqlManifest.cjs, kiểm bằng node tools/Verify-Source.cjs, rồi đánh giá migration phù hợp. Sinh lại danh mục bằng node tools/Generate-SqlStudyIndex.cjs. Riêng lần chuyển thư mục D16 có node tools/Verify-SqlLayout.cjs chứng minh61file giữ nguyên bytes và Install chỉ đổi include path. Profile D15 cũ nâng đường dẫn bằng CLI --rebind-sql-layout có guard khi host đã đóng bình thường; không tự sửa pin để bỏ qua drift.

Hướng dẫn đầy đủ: [transaction](../../docs/study/SQL_TRANSACTIONS.md), [phân công4 thành viên](../../docs/study/DATABASE_OBJECTS_4_MEMBERS.md), [bảo mật SQL](../../docs/SQL_SECURITY.md).

Học theo đề3.1–3.5: [hướng dẫn](../../docs/study/SQL_LEARNING_START.md), [107bài chạy riêng](../practice/README.md), [indexes](indexes/README.md). CREATE định nghĩa và câu gọi là hai thao tác khác nhau; thư mục practice cung cấp câu gọi, dữ liệu trước và kết quả mong đợi.
