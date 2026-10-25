# Học transaction trong DBMS12 — yêu cầu 3.4

## Số lượng và phạm vi đã chuyển

**61/61 stored procedure có cấu trúc transaction đầy đủ trong SQL:** 56 operation và 5 thủ tục hạ tầng. Đây là tổng số SP, không phải 61 nghiệp vụ ghi dữ liệu. Có cả thủ tục đọc, xác thực và helper. Không thêm SP, bảng hay quyền bảng.

Theo `manifest.operations`, 56 operation gồm **29 command, 19 read và 8 auth**. Nhóm 29 command là các lệnh nghiệp vụ có UUID/digest và replay receipt; nhóm auth có cả đọc credential và thay đổi phiên/tài khoản. Thêm 5 helper là đủ 61 SP đã chuyển.

Đọc theo thứ tự:

1. Mẫu transaction và ví dụ duyệt nhập học bên dưới.
2. [Script 5 nghiệp vụ](../../database/dbms12-compact/transactions/01_five_business_transactions.sql).
3. Hai cửa sổ [Session A](../../database/dbms12-compact/transactions/02_concurrency_session_a.sql), [Session B](../../database/dbms12-compact/transactions/03_concurrency_session_b.sql).
4. [Danh mục toàn bộ 61 SP và đường dẫn](SQL_TRANSACTIONS_INDEX.md), rồi đọc định nghĩa SP thực tế. Chúng là source được cài và ứng dụng gọi.

## Cấu trúc thực tế trong mỗi SP

```sql
SET XACT_ABORT ON;
DECLARE @SqlOwnTransaction bit = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
BEGIN TRY
    IF @SqlOwnTransaction = 1 BEGIN TRANSACTION;
    -- Lấy khóa; xác thực phiên/native role/ownership; kiểm dữ liệu/rowversion.
    -- Thực hiện nghiệp vụ, ghi audit SUCCESS, replay receipt và activity.
    IF @SqlOwnTransaction = 1 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @SqlOwnTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

- `BEGIN TRANSACTION`: bắt đầu một đơn vị công việc; khóa cần thiết được giữ đến khi kết thúc.
- `COMMIT`: xác nhận tất cả thay đổi của giao dịch. SP đọc cũng đóng giao dịch để trả khóa.
- `ROLLBACK`: hủy các thay đổi trong giao dịch khi có lỗi. `XACT_STATE()` bằng 1 là còn commit được, -1 là chỉ rollback được, 0 là không có giao dịch.
- `TRY/CATCH` và `THROW`: bắt lỗi SQL phù hợp, rollback rồi chuyển lỗi lên caller. `XACT_ABORT ON` hỗ trợ hủy giao dịch khi gặp lỗi thực thi; không thay thế CATCH/cleanup.
- `@SqlOwnTransaction`: SP chỉ chốt giao dịch do chính nó mở. Khi được gọi trong một transaction hiện có ở depth 1, SP dùng chung transaction đó; caller phải COMMIT/ROLLBACK. Đây không phải transaction độc lập bên trong transaction khác; không dùng savepoint.
- SP operation vẫn kiểm độ sâu bằng 1. Không gọi thêm một `BEGIN TRAN` rồi mong tạo giao dịch con độc lập. Khi replay trả sớm, nhánh RETURN cũng COMMIT nếu SP là owner; có 29 nhánh như vậy đã kiểm tĩnh.

Khi web gọi bình thường, connection đi vào ở depth 0: **SQL tự BEGIN/COMMIT/ROLLBACK thật**. C# xác thực, ánh xạ role cố định, truyền tham số và REVERT. C# vẫn có ROLLBACK dọn dẹp nếu cancel/lỗi để không để sót giao dịch. Nó không mở/chốt transaction nghiệp vụ bình thường nữa. Phiên SQL có thể bị client cancel ngoài khả năng bắt của TRY/CATCH; connection không pooling và cleanup vẫn cần thiết.

## Năm nghiệp vụ để trình bày

|Nghiệp vụ / SP|Các thay đổi phải đi cùng nhau|Nếu audit SUCCESS lỗi|
|---|---|---|
|Tạo khóa — `usp_CourseCreate`|Course + audit + receipt + activity|Không còn khóa vừa tạo, không có receipt thành công|
|Đăng ký — `usp_RegistrationCreate`|Registration PENDING + audit + receipt + activity|Không còn hồ sơ vừa tạo|
|Duyệt — `usp_AdmissionApprove`|Registration CONFIRMED → ADMITTED + Invoice + audit + receipt|Hồ sơ vẫn CONFIRMED; không có hóa đơn mới|
|Thu học phí — `usp_InvoiceCollect`|Invoice.paid_at/paid_by/method + audit + receipt|Hóa đơn vẫn chưa thu|
|Xếp lớp — `usp_PlacementCreate`|Assignment + GradeReport DRAFT + audit + receipt|Không có phân lớp hoặc bảng điểm dở dang|

Ví dụ đọc `usp_AdmissionApprove` trong [stored-procedures/core/07_core_procedures.sql](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql):

1. BEGIN, lấy khóa Course và kiểm SID/epoch/Admissions đúng native user.
2. Kiểm UUID/digest; nếu thao tác đã hoàn tất thì trả receipt cũ, không tạo hóa đơn thứ hai.
3. UPDATE Registration với điều kiện CONFIRMED và đúng rowversion. Không trúng đúng một dòng thì THROW.
4. INSERT Invoice từ học phí hiện tại của khóa.
5. Kiểm phiên cuối, ghi audit SUCCESS và ReplayOperation, cập nhật activity.
6. COMMIT. Nếu bước 4 hoặc 5 thất bại, CATCH rollback cả bước 3; không có trạng thái ADMITTED mà thiếu hóa đơn vì lỗi giữa chừng.

Các kiểm điều kiện nghiệp vụ vẫn nằm trong SP; script học không viết lại DML để vượt quyền. Script ngoài minh họa caller BEGIN/COMMIT/ROLLBACK rõ ràng; SP được gọi bên trong nhận transaction đó. Source của 61 SP minh họa chiều ngược lại: ứng dụng không mở transaction thì SP tự quản.

## Chạy và quan sát ROLLBACK

Chỉ dùng catalog fixture riêng tạo bởi `tools/Invoke-SecurityRehearsal.ps1`, không dùng catalog chứa lớp/học viên đang làm việc. Script học mặc định để tên/GUID/ID là NULL và dừng; tự điền danh tính từ profile fixture của máy bạn. Không sao chép SID/password/profile của người khác vào script. Owner tạo các session thử trong RAM, dùng đúng native user rồi xóa riêng session đã tạo; không thay quyền hay phiên hiện có.

`01_five_business_transactions.sql` thực hiện 5 ví dụ COMMIT độc lập và chuẩn bị các điều kiện trước: học viên xác nhận, đủ lịch, lớp OPEN, đã thu đủ tiền. Các ví dụ trước đã COMMIT sẽ còn nguyên nếu ví dụ sau thất bại. Chạy lại sẽ tạo cohort khác, không phải thao tác hoàn tác hay reseed.

Để kiểm ROLLBACK có lỗi ở giữa thay vì chỉ sai input đầu vào:

```powershell
# Host hiện có phải được đóng bình thường trước. Tạo catalog fixture mới, giữ lại bằng chứng.
./tools/Invoke-SecurityRehearsal.ps1 -SkipBrowser
```

Công cụ chạy native security và `--verify-sql-transactions` trên fixture mới. Với từng nghiệp vụ, verifier tạm thêm trigger thử nghiệm trên AuditLog, THROW 51998 khi chèn đúng audit SUCCESS; luôn gỡ trigger trong finally. Kiểm dữ liệu nghiệp vụ và receipt đã rollback, sau đó chạy thành công với UUID mới. Trigger này chỉ thuộc kiểm fixture, không nằm trong 12 trigger sản phẩm. FAILURE audit riêng có thể được ghi sau rollback; đó không phải SUCCESS còn sót.

Không chạy lại verifier trên fixture đã có receipt hoàn thành. Không chạy fixture test để sửa workspace cũ. Các khoảng trống IDENTITY/SEQUENCE/rowversion sau rollback là bình thường; không khẳng định rollback trả lại số thứ tự hoặc trạng thái bộ đếm.

## Tranh chấp: hai người cùng thu một hóa đơn

Lấy một Invoice chưa thu thuộc Registration ADMITTED trong fixture. Owner đọc `invoice_id` và `sys.fn_varbintohexstr(row_version)`; điền **cùng hai giá trị** vào A và B, cùng tên/GUID fixture. Chạy A trước, rồi B trong 10 giây A đang chờ.

1. A lấy Course TABLOCKX/HOLDLOCK; B gọi SP phải chờ khóa.
2. A thu hóa đơn, ghi audit/receipt rồi COMMIT, trả khóa.
3. B tiếp tục nhưng điều kiện rowversion cũ và paid_at IS NULL không còn đúng. SQL THROW 51214; caller ROLLBACK.
4. Kết quả: một hóa đơn đã thu, đúng một audit SUCCESS; yêu cầu thua không tạo receipt thành công. Tải lại dữ liệu, không tự gửi lại yêu cầu thu.

Khóa thô hiện tại giúp tuần tự hóa ghi nghiệp vụ, giữ quy tắc dễ giải thích; chưa phải thiết kế đã benchmark cho tải lớn. Rowversion kiểm thay đổi giữa lúc người dùng đọc và gửi, còn khóa bảo vệ phần thực thi trong transaction. UUID/digest giải quyết gửi lại cùng thao tác; nó không thay thế hai cơ chế này.

Nếu mất ACK sau COMMIT, client giữ trạng thái chưa rõ và tra receipt theo actor/action/UUID. Không tìm thấy receipt chưa đủ chứng minh rollback. Không ghi FAILURE giả chỉ vì timeout, mất kết nối hoặc cancel sau khi write đã được dispatch.

## Kết quả và nguồn

Kết quả lần chạy hiện tại nằm ở [review](../plan/SQL_TRANSACTIONS_REVIEW.md) và [bằng chứng](../evidence/sql-transactions/summary.json). Có kiểm 5 COMMIT, 5 forced rollback, replay và hai yêu cầu thu đồng thời. Không suy ra đã đạt mọi mục của đề môn từ riêng mục 3.4 trong ảnh.

Tham khảo ngữ nghĩa SQL Server: [TRY/CATCH](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql?view=sql-server-ver17), [XACT_ABORT](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql?view=sql-server-ver17). Nguồn chuẩn cho nghiệp vụ là các SP trong project.
