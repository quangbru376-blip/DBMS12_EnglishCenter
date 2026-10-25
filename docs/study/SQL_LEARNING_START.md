# Học và bảo vệ phần SQL Server

Bạn cần giải thích được **vì sao tồn tại → dữ liệu vào → câu gọi → kết quả → trường hợp bị từ chối → transaction/quyền liên quan** của từng object. Không học bằng cách chạy toàn bộ installer rồi chỉ đọc thông báo thành công.

## Ba điểm mở đầu

1. [Đề3.1–3.5 đã nhận](RUBRIC_SQL_SERVER.md) và [bảng đối chiếu](SQL_RUBRIC_MATRIX.md).
2. [Danh mục source105 object](../../database/dbms12-compact/OBJECT_INDEX.md): xem định nghĩa thật đang được cài.
3. [Danh mục bài chạy riêng](../../database/practice/README.md): chọn đúng file để thực thi và quan sát.

|Bạn đang học|Định nghĩa / cách gọi|Cần nói khi giáo viên hỏi|
|---|---|---|
|SP|CREATE OR ALTER PROCEDURE cài định nghĩa; EXEC dbo.usp_Name gọi SP|Vai trò, ownership, SID/epoch, RV, tham số và thay đổi dữ liệu|
|Scalar Function|CREATE FUNCTION cài định nghĩa; SELECT dbo.fn_Name(...) lấy giá trị|Kiểu trả về, công thức, NULL và giá trị biên|
|View|CREATE VIEW cài định nghĩa; SELECT ... FROM dbo.v_Name|JOIN, cột suy ra, lọc dữ liệu và vì sao có thể rỗng|
|Trigger|CREATE TRIGGER cài định nghĩa; phát INSERT/UPDATE/DELETE lên bảng được gắn|inserted/deleted, quy tắc, mã lỗi và dữ liệu đã bị chặn|
|Transaction|Chạy một khối BEGIN TRY/BEGIN TRAN/COMMIT/CATCH/ROLLBACK|Những thao tác phải nguyên tử, ai sở hữu transaction, lỗi giữa chừng và concurrency|
|Index|CREATE INDEX cài cấu trúc; chạy truy vấn phù hợp và đọc kế hoạch/STATISTICS IO|Key order, INCLUDE/filter, truy vấn được hỗ trợ, chi phí ghi và kết quả đo|

Ví dụ Function có thể chạy trực tiếp:

```sql
SELECT dbo.fn_GradeTotal(70,85,40) AS total; --79.00
SELECT dbo.fn_ValidScore('100.01') AS valid; --0
```

Trigger tự chạy khi có sự kiện DML phù hợp; bài trigger không dùng EXEC trigger. SP được gọi dưới native user đúng vai trò. Nếu gọi sai user hoặc thiếu dữ liệu trước thì bị từ chối là kết quả cần giải thích, không chữa bằng cấp quyền bảng/tắt trigger. [Microsoft: DML triggers](https://learn.microsoft.com/en-us/sql/relational-databases/triggers/dml-triggers?view=sql-server-ver17), [UDF](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/user-defined-functions?view=sql-server-ver17).

## Chạy từng bài bằng SSMS

1. Dùng catalog fixture riêng đã có profile trong .local/security-redesign/fixture-GUID. Dữ liệu và native module giống source, tách khỏi lớp/học viên đang thao tác trên web.
2. Owner chạy `./tools/Invoke-SqlLearning.ps1 -Prepare`. Công cụ chỉ nhận profile fixture đúng source/identity, đánh dấu learning fixture và tạo `.local/operator/sql-learning/SSMS_SESSION.sql`.
3. Kết nối SQL Server bằng owner trên SSMS, chọn đúng database fixture được in trong đầu SSMS_SESSION.sql. Chạy file đó một lần trên **cửa sổ query này**. Nó kiểm name/ID/GUID/fileGUID rồi đặt ngữ cảnh phòng học; không chứa SID/password/hash.
4. Mở một bài trong database/practice, copy vào cùng cửa sổ query và chạy toàn bộ bài bằng F5. Không cần SQLCMD Mode. Đọc phần chuẩn bị, TRƯỚC, câu gọi, SAU và result cuối. Không chỉ bôi đen một dòng khi chưa có biến/dữ liệu trước.
5. Kết quả mong đợi là PASS_ROLLBACK hoặc đúng expected_error. Mỗi bài dọn transaction và REVERT; dữ liệu chuẩn bị được rollback, có thể thực hành lại. IDENTITY/SEQUENCE/rowversion có thể có khoảng trống dù rollback.

Nếu mở connection/query window khác thì chạy SSMS_SESSION.sql ở cửa sổ đó. Các script cố ý từ chối trên main hoặc database chưa được đánh dấu; không bỏ guard để cho qua.

Bộ bài mở outer transaction để có thể rollback và chạy lại. Vì vậy SP nhận transaction của caller ở depth1; phần BEGIN/COMMIT có điều kiện trong SP không tự chốt thay caller. Khi web gọi bình thường ở depth0, chính SP mở/chốt giao dịch theo D15. Bài usp_RecordFailure cũng được rollback để không để lại log thử; ứng dụng thực gọi helper này sau khi giao dịch nghiệp vụ đã rollback.

Máy chưa có fixture: sau khi cấu hình môi trường theo Team Quickstart và đóng host bình thường, owner chạy `./tools/Invoke-SecurityRehearsal.ps1 -SkipBrowser` để tạo catalog thử mới. Không chạy để sửa một receipt/profile đã lỗi; giữ state đó để điều tra. Sau khi đã có fixture, việc thực hành bằng Invoke-SqlLearning không cần tắt host main.

## Chạy bằng công cụ

```powershell
./tools/Invoke-SqlLearning.ps1 -Prepare
./tools/Invoke-SqlLearning.ps1 -Case functions/fn_GradeTotal.sql
./tools/Invoke-SqlLearning.ps1 -Case stored-procedures/usp_AdmissionApprove.sql
./tools/Invoke-SqlLearning.ps1 -Group triggers
./tools/Invoke-SqlLearning.ps1 -Group indexes
./tools/Invoke-SqlLearning.ps1 -All
```

CLI lưu result/log vào private .local/operator/sql-learning, không in SID/hash/password. Trong SSMS bạn thấy các bảng kết quả của bài. Module xác thực như LoginRead/PasswordSnapshot trả dữ liệu nội bộ nhạy cảm; bài tập capture vào temp table và chỉ chiếu các cột an toàn. Hash dùng thử được đọc trong RAM từ account fixture, không minh họa băm mật khẩu bằng SQL. C# vẫn chịu trách nhiệm crypto/kiểm password.

## Thực hành COMMIT và ROLLBACK

Năm file trong practice/transactions tương ứng tạo khóa, đăng ký, duyệt nhập học, thu học phí, xếp lớp. Mặc định `@CommitLab=0`: xem kết quả rồi rollback. Sửa `@ForceFailure=1` để THROW sau nghiệp vụ, kiểm Course/audit/receipt không còn sau rollback. Sửa `@CommitLab=1` để giữ dữ liệu thật trên fixture; script chỉ xóa những session thử do nó tạo trước COMMIT. Các bài khác luôn rollback.

```powershell
./tools/Invoke-SqlLearning.ps1 -Group transactions -ForceRollback
./tools/Invoke-SqlLearning.ps1 -Group transactions -CommitTransactions
```

Đây là sửa cách caller chốt transaction trong **bài học**. Để đổi transaction của ứng dụng, sửa source SP và triển khai module được kiểm như [hướng dẫn transaction](SQL_TRANSACTIONS.md). Không có hot reload SQL khi chỉ lưu file hoặc bấm Tải lại web.

Concurrency hai cửa sổ: dùng [Session A](../../database/dbms12-compact/transactions/02_concurrency_session_a.sql) và [Session B](../../database/dbms12-compact/transactions/03_concurrency_session_b.sql) trên cùng hóa đơn thử/rowversion. A giữ khóa rồi commit; B bị chặn và từ chối phiên bản cũ. Bằng chứng hiện có ở docs/evidence/sql-transactions; không cần thay đồng hồ/tắt guard để diễn.

## Bắt đầu lớp và ca từ chối có chủ đích

`usp_ClassStart` chuẩn bị lớp OPEN, đủ lịch/học viên và buổi đầu15giây nữa; WAITFOR16giây để đến giờ thật rồi bắt đầu thành công. Không đổi đồng hồ hoặc tắt guard. `usp_OperatorBootstrap` cho lỗi51236 vì fixture đã có account; không xóa account để chạy lại bootstrap. 12bài trigger cố tình vi phạm và phải nhận đúng lỗi. Nhìn PASS ở đây nghĩa là **đã kiểm đúng hành vi dự kiến**, không có nghĩa lệnh DML vi phạm được chấp nhận.

## Khi muốn sửa để tự thử

Sửa tham số hoặc câu gọi trong bài rồi F5 sẽ thực thi phiên bản bài bạn vừa sửa. Các file được sinh bằng generator; sao chép bài đang thử vào nơi riêng trước khi sinh lại để không ghi đè thay đổi cá nhân. Công cụ chạy bài không tự gọi generator.

Nếu muốn sửa **định nghĩa** một SP/Function, lấy riêng block của object đó từ source, dùng CREATE OR ALTER PROCEDURE hoặc ALTER FUNCTION trên fixture rồi gọi lại để xem tác dụng. Với Function nằm chung file, chỉ chọn đúng block của Function cần sửa. GO phân tách batch ở SSMS; nó không phải COMMIT. Giữ source chuẩn và database chính nguyên trạng khi luyện sửa; bộ kiểm có thể báo khác kỳ vọng sau khi bạn cố ý đổi định nghĩa, đó là kết quả cần hiểu chứ không phải lý do bỏ assertion.

## Chuẩn bị câu trả lời khi bảo vệ

- 3.1: mở [lược đồ và3NF](SQL_SCHEMA_3NF.md), ERD và chỉ PK/FK/candidate key của một quan hệ cụ thể.
- 3.2: chạy một constraint sai, một trigger sai và một view; sau đó trình bày [index và phép đo](SQL_INDEXES.md).
- 3.3: chọn một SP ghi và một SP đọc; chạy một Function bình thường/NULL/biên. Giải thích TRY/CATCH/THROW.
- 3.4: cho xem trước/sau COMMIT, lỗi giữa chừng ROLLBACK và hai phiên cạnh tranh cùng Invoice.
- 3.5: mở policy/matrix; chạy GRANT/REVOKE/DENY rồi giải thích7WITHOUT LOGIN users khác Windows runtime login.

Đọc rubric để chọn ví dụ trọng tâm; [phân công4thành viên](DATABASE_OBJECTS_4_MEMBERS.md) vẫn là27/26/26/26 object. Mỗi người phải hiểu transaction và quyền của phần mình, không chỉ thuộc tên object.
