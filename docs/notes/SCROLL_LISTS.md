# Danh sách cuộn

- Giữ cột/bảng và nút Chọn; bỏ thanh Trang trước/Trang sau trên toàn Workspace.
- Table tạo region cuộn cao tối đa32rem (mobile28rem), tiêu đề cột sticky.
- useScrollList dùng GET hiện có, ban đầu20 bản ghi; cuộn gần cuối tải tiếp20.
- Các trang: khóa học, hồ sơ, xếp lớp, chọn hồ sơ xem hóa đơn, hóa đơn, tài khoản, nhật ký.
- Theo dõi trang kế tiếp trong closure của một query; chỉ một request tải thêm được chạy.
- Append theo ID, bỏ dòng metadata total và bản ghi trùng; không mất dòng đang chọn.
- Search/filter/refresh đổi generation, bỏ phản hồi cũ và tải lại từ đầu.
- Lỗi giữ các dòng cũ, cần bấm Thử tải lại; không tự retry lỗi.
- Nút Tải thêm hỗ trợ bàn phím, cuộn bằng chuột tự kích hoạt khi tới gần cuối.
- Lớp/lịch/roster/điểm/kết quả/điểm danh dùng cùng viewport, không thêm request khi cuộn.
- Khi in bỏ giới hạn chiều cao, không kích hoạt tải thêm; chỉ in các dòng đã tải.
- SQL/HTTP/permission/command/dữ liệu không đổi; evidence docs/evidence/scroll-lists/.
