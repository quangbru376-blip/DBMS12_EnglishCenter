# ERD Chen — phong cách giáo trình

Áp dụng phong cách ảnh mẫu owner gửi ngày22/10/2026. Đây là biểu diễn của đúng model12 hiện có, không đổi thiết kế database.

![ERD Chen cổ điển](ERD-Chen-classic.png)

[SVG](ERD-Chen-classic.svg) · [PDF13trang](ERD-Chen-classic.pdf) · [diagrams.net chỉnh sửa](ERD-Chen-classic.drawio)

## Phân tích phong cách mẫu

- Nền trắng, nét đen mảnh, không dùng màu phân nhóm hoặc đổ bóng.
- Thực thể là hình chữ nhật xám nhạt; quan hệ là hình thoi xám nhạt; tên viết hoa.
- Thuộc tính elip trắng, nối tỏa bằng các đoạn thẳng; khóa chính gạch chân liền.
- Nhãn1/N mô tả lực lượng tối đa; đường đôi thể hiện tham gia toàn phần, đường đơn là tùy chọn.
- Ảnh mẫu có khung đôi/thoi đôi/khóa gạch chân đứt cho thực thể yếu và quan hệ định danh. Model này mỗi bảng cóPK riêng, không có khóa bộ phận: không sao chép các ký hiệu đó sai ngữ nghĩa.

## Áp dụng vào project

Giữ12thực thể,99thuộc tính,19quan hệ. Không gắn dấu? trong elip để gần phong cách giáo trình; NULL và kiểu SQL có ở ERD-full-attributes.md. Không chuyển thuộc tính kỹ thuật hayFK thành thuộc tính của quan hệ chỉ để bắt chước dữ liệu hàng không.

Có15quan hệ với FK NOT NULL: phía con nối đôi đến hình thoi. Bốn FK nullable (R06,R11,R16,R17) giữ đường đơn. Phía cha đều tùy chọn vì FK không bắt mỗi bản ghi cha phải có con; ứng dụng có thể thêm invariant mạnh hơn trong giao dịch. Nhãn1/N không thể hiện min: kết hợp đường đơn/đôi mới thể hiện optional/mandatory.

Không suy thực thể yếu chỉ vì FK NOT NULL. MộtAuthSession phụ thuộcAccount để tồn tại vẫn cósid làmPK độc lập; dùng tham gia toàn phần và khung đơn.

## Quan hệ đối chiếu DDL

|Mã|Quan hệ|Cha|Con|Nguồn FK|Tỷ lệ tối đa|Phía con|
|---|---|---|---|---|---|---|
|R01|CÓ PHIÊN|Account|AuthSession|account_id → account_id|1:N|Bắt buộc, đường đôi|
|R02|ĐĂNG KÝ|Account|Registration|student_account_id → account_id|1:N|Bắt buộc, đường đôi|
|R03|THUỘC KHÓA|Course|Registration|course_id → course_id|1:N|Bắt buộc, đường đôi|
|R04|CÓ LỚP|Course|Class|course_id → course_id|1:N|Bắt buộc, đường đôi|
|R05|GIẢNG DẠY|Account|Class|teacher_account_id → account_id|1:N|Bắt buộc, đường đôi|
|R06|QUYẾT ĐỊNH ĐIỂM|AuditLog|Class|current_grade_operation_id → operation_id|1:1|Tùy chọn, đường đơn|
|R07|ĐƯỢC XẾP LỚP|Registration|StudentClassAssignment|registration_id → registration_id|1:1|Bắt buộc, đường đôi|
|R08|CÓ HỌC VIÊN|Class|StudentClassAssignment|class_id → class_id|1:N|Bắt buộc, đường đôi|
|R09|XẾP LỚP|Account|StudentClassAssignment|assigned_by → account_id|1:N|Bắt buộc, đường đôi|
|R10|CÓ LỊCH|Class|Schedule|class_id → class_id|1:N|Bắt buộc, đường đôi|
|R11|XÁC NHẬN BUỔI|Account|Schedule|held_by → account_id|1:N|Tùy chọn, đường đơn|
|R12|CÓ ĐIỂM DANH|Schedule|Attendance|schedule_id → schedule_id|1:N|Bắt buộc, đường đôi|
|R13|ĐƯỢC ĐIỂM DANH|StudentClassAssignment|Attendance|class_assignment_id → class_assignment_id|1:N|Bắt buộc, đường đôi|
|R14|CÓ BẢNG ĐIỂM|StudentClassAssignment|GradeReport|class_assignment_id → class_assignment_id|1:1|Bắt buộc, đường đôi|
|R15|CÓ HÓA ĐƠN|Registration|Invoice|registration_id → registration_id|1:1|Bắt buộc, đường đôi|
|R16|THU TIỀN|Account|Invoice|paid_by → account_id|1:N|Tùy chọn, đường đơn|
|R17|THỰC HIỆN|Account|AuditLog|actor_account_id → account_id|1:N|Tùy chọn, đường đơn|
|R18|GỬI LỆNH|Account|ReplayOperation|actor_account_id → account_id|1:N|Bắt buộc, đường đôi|
|R19|GHI NHẬN LỆNH|AuditLog|ReplayOperation|operation_id → operation_id|1:1|Bắt buộc, đường đôi|

Class.current_grade_operation_id tham chiếuAuditLog.operation_id(UK), có filteredUNIQUE. AuditLog.root_entity_id không phảiFK vật lý. KiểuSQL/nullability/UNIQUE ghép và các guard khác theoDDL, không thêm nét nối giả.
