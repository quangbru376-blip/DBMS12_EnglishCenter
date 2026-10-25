# Transaction — bài học và minh chứng

Đọc [hướng dẫn từng bước](../../../docs/study/SQL_TRANSACTIONS.md) trước, sau đó:

1. [01_five_business_transactions.sql](01_five_business_transactions.sql): tạo khóa → đăng ký → xác nhận → duyệt/tạo hóa đơn → thu đủ → chuẩn bị lớp/lịch → xếp lớp. Có5 khối transaction minh họa chính.
2. [02_concurrency_session_a.sql](02_concurrency_session_a.sql): A lấy khóa và chờ10 giây trước khi thu.
3. [03_concurrency_session_b.sql](03_concurrency_session_b.sql): B dùng cùng hóa đơn/rowversion, chờ A rồi bị từ chối phiên bản cũ.

Các script dùng database fixture riêng và mặc định dừng nếu chưa điền danh tính/tham số. Không nằm trong manifest.installOrder. Phần BEGIN/COMMIT/ROLLBACK thực của ứng dụng ở trong [61SP](../stored-procedures/README.md); không tách phần đó ra khỏi SP.

[Bản đồ thư mục SQL](../README.md) · [Index105 object](../OBJECT_INDEX.md).
