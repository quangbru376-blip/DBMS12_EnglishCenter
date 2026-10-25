# Yêu cầu SQL Server do owner cung cấp

Nguồn: nguyên văn nội dung mục 3 do owner gửi ngày 25/10/2026. Đây là phần yêu cầu CSDL đã nhận, không đại diện các phần khác của đề chưa được cung cấp.

## 3. YÊU CẦU VỀ CƠ SỞ DỮ LIỆU (SQL SERVER)

CSDL phải được thiết kế và cài đặt trên Microsoft SQL Server, đáp ứng tối thiểu các yêu cầu kỹ thuật sau:

### 3.1. Thiết kế dữ liệu

- Mô hình thực thể – kết hợp (ERD) và lược đồ quan hệ (Relational Schema) thể hiện rõ các thực thể, thuộc tính và mối kết hợp.
- Tối thiểu 8 bảng dữ liệu có quan hệ với nhau, đạt chuẩn hoá tối thiểu 3NF.
- Xác định đầy đủ khóa chính (Primary Key), khóa ngoại (Foreign Key) và các ràng buộc toàn vẹn dữ liệu.

### 3.2. Ràng buộc, Trigger, Khung nhìn, Chỉ mục

- Tối thiểu 5 ràng buộc CHECK/UNIQUE/DEFAULT có ý nghĩa nghiệp vụ thực tế.
- Tối thiểu 5 Trigger (ví dụ: kiểm tra dữ liệu trước khi ghi, tự động cập nhật số lượng tồn kho, ghi log thao tác...).
- Tối thiểu 5 View phục vụ truy vấn/báo cáo tổng hợp.
- Tối thiểu 5 Index (bao gồm ít nhất 1 chỉ mục không phải khóa chính) kèm giải thích lý do tạo chỉ mục và minh chứng cải thiện hiệu năng truy vấn.

### 3.3. Lập trình cơ sở dữ liệu

- Tối thiểu 5 Stored Procedure phục vụ các nghiệp vụ khác nhau (thêm/sửa/xóa/tìm kiếm/thống kê...).
- Tối thiểu 5 User-Defined Function (Scalar hoặc Table-Valued Function).
- Xử lý lỗi trong thủ tục bằng TRY...CATCH.

### 3.4. Quản lý giao dịch

- Tối thiểu 5 nghiệp vụ minh họa việc sử dụng TRANSACTION (BEGIN/COMMIT/ROLLBACK) đảm bảo tính toàn vẹn khi có nhiều thao tác liên quan (ví dụ: chuyển khoản, đặt hàng trừ kho...).
- Trình bày và minh chứng cách xử lý một tình huống tranh chấp truy cập đồng thời (concurrency) hoặc khôi phục sau sự cố.

### 3.5. Bảo mật và phân quyền

- Tạo tối thiểu 4 Role/Login khác nhau (ví dụ: Quản trị viên, Nhân viên, …) với quyền hạn khác nhau trên bảng/view/thủ tục.
- Minh họa lệnh GRANT/REVOKE/DENY và giải thích chính sách phân quyền của hệ thống.

Owner xác nhận thêm: giáo viên có thể yêu cầu chạy riêng **SP, Function, Trigger, View và Transaction** để kiểm tra mức độ hiểu. Bộ thực hành: [SQL_LEARNING_START.md](SQL_LEARNING_START.md).
