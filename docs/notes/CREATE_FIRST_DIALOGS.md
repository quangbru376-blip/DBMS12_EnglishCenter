# Form tạo và popup chọn dòng
1. Workspace đặt form tạo khóa/lớp/nhân sự trước tìm kiếm và danh sách.
2. Schedules đặt form tạo lịch tuần và thêm buổi trước bảng lịch.
3. Chọn dòng mở SelectionDialog, dùng Modal native sẵn có.
4. RecordDetails chỉ trình bày các trường đã nhận từ API.
5. Popup chứa lại form/thao tác cũ; endpoint, payload và quyền không đổi.
6. Đóng/ESC kiểm dữ liệu chưa lưu trong đúng popup; hủy đóng giữ bản nháp.
7. Đang gửi/đọc thì chặn đóng và báo đang xử lý; hoàn tất lưu thì refresh như cũ.
8. Lỗi và lookup mất ACK hiện trong popup; không tự gửi lại command.
9. Chi tiết lớp Teacher giữ đúng lớp khi chuyển sang điểm danh/bảng điểm.
10. In hóa đơn đọc mới trước khi in, CSS chỉ in nội dung popup hóa đơn.
11. Kiểm build/client và Edge thật + giả lập375/768/1280 PASS; không business write vào DB owner.
