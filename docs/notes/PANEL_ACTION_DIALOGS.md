# Tạo và tìm kiếm từ danh sách
Table nhận actions để đặt nút ở góc trên phải, cùng vùng tiêu đề.
Workspace chỉ hiện Tạo/Tìm kiếm tại các danh sách đã có thao tác tương ứng.
panel=create/search mở SelectionDialog dùng Modal native sẵn có.
Search submit giữ query cũ, áp dụng giá trị mới rồi đóng; mở lại hiện query đã áp dụng.
Create thành công đóng popup, refresh và giữ feedback/password tạm bên ngoài.
Create lỗi giữ form; pending giữ manual lookup và không tự gửi lại.
Schedules đặt2form và preview vào popup Tạo của bảng lịch.
Preview chưa lưu được đánh dấu dirty; xác nhận bỏ sẽ xóa preview.
Dirty/ESC/focus/busy và màu feedback giữ nguyên; popup Chọn không đổi.
Test-Project,Edge33controlledchecks+27livecases/27popups PASS,businessPOSTtoDB0.
