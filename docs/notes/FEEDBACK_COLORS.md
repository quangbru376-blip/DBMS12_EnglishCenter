# Màu thông báo
Workspace và Dbms12App giữ notice.message và notice.success.
Nhánh lưu/lookup/signup/password thành công đặt success=true, kể cả hủy.
Nhánh lỗi/unknown/không tìm thấy receipt đặt success=false, giữ nội dung cũ.
Render dùng ec-feedback--success xanh lá hoặc ec-feedback--error đỏ sẵn có.
Thành công role=status; lỗi role=alert; cùng feedback dùng trong popup và trang.
Teaching/Schedules chỉ có notice lỗi nên thêm class error.
Không đoán kết quả bằng từ khóa hoặc loại nút; không đổi retry/lookup/API.
Test-Project và Edge3widths/cancel/auth/read/lookup/colors PASS,khôngDBwrite.
