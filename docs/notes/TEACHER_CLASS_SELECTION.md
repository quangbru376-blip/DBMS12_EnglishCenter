# Sửa chọn lớp của Giáo viên
1. Lỗi cũ: nút Chọn chỉ đổi dòng được chọn; phần chi tiết chỉ render cho Giáo vụ.
2. Giáo viên nay thấy thông tin lớp và danh sách học viên từ API classes/roster hiện có.
3. Thẻ chi tiết có loading, rỗng, lỗi, thử lại và bỏ phản hồi của lớp đã rời đi.
4. Nút Điểm danh/Bảng điểm mở đúng lớp được chọn, giữ lựa chọn trong RAM Workspace.
5. Dropdown đổi lớp vẫn hỏi bỏ bản nháp; chọn lại cùng lớp không xóa bảng đang tải.
6. Tải lại cập nhật cả danh sách học viên; không gửi lệnh ghi nghiệp vụ khi chọn lớp.
7. SP, quyền SQL, backend, dữ liệu và dependency giữ nguyên.
8. Kiểm và ảnh: docs/evidence/teacher-class-selection/; review TEACHER_CLASS_SELECTION_REVIEW.md.
9. Cuối lượt có SQL thêm dòng trống: giữ bản định dạng riêng, khôi phục byte chuẩn sau khi kiểm không đổi nội dung.
