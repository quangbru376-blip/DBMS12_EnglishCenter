# 4.2. Quản lý bảo mật

## 4.2.1. Chính sách và nguyên tắc phân quyền

Hệ thống quản lý trung tâm tiếng Anh áp dụng nguyên tắc đặc quyền tối thiểu: mỗi nhóm người dùng chỉ được thực thi các thủ tục hoặc truy vấn các view phục vụ nhiệm vụ của mình. Người dùng nghiệp vụ không được thao tác trực tiếp SELECT, INSERT, UPDATE, DELETE trên các bảng dữ liệu.

Hệ thống đồng thời áp dụng nguyên tắc phân tách nhiệm vụ. Quản trị viên ứng dụng quản lý tài khoản nhân sự và theo dõi nhật ký; tuyển sinh xử lý hồ sơ nhập học; giáo vụ điều hành khóa học, lớp và lịch; giáo viên thực hiện điểm danh và nhập điểm; kế toán xử lý học phí; giám đốc xem báo cáo tổng hợp. Quản trị viên ứng dụng không có quyền thực hiện giao dịch học phí hoặc sửa điểm. Tài khoản triển khai SQL của chủ máy được quản lý riêng, không đồng nhất với vai trò Admin của ứng dụng.

## 4.2.2. Khởi tạo định danh và phân nhóm quyền

Backend sử dụng Windows Login của runtime non-admin đã được chuẩn bị trên máy. Login này được ánh xạ thành Database User Dbms12ProjectRuntime và tham gia nhóm kỹ thuật dbms12_runtime. Nhóm kỹ thuật chỉ được gọi các thủ tục xác thực/hạ tầng cần thiết và được chuyển sang bảy user nghiệp vụ đã định trước.

Trong database, hệ thống tạo bảy nhóm role_QuanTri, role_TuyenSinh, role_GiaoVu, role_GiaoVien, role_KeToan, role_GiamDoc và role_HocVien. Mỗi nhóm có một Database User tương ứng để làm ngữ cảnh thực thi. Các user này được tạo WITHOUT LOGIN và không có mật khẩu SQL riêng. Sau khi xác thực phiên, backend ánh xạ vai trò được SQL xác nhận sang user tương ứng bằng EXECUTE AS USER, thực hiện thao tác và REVERT khi kết thúc.

Cách triển khai hiện tại sử dụng một Windows Login của backend và bảy ngữ cảnh user/role trong database; không phải bảy tài khoản đăng nhập máy chủ độc lập. Nếu yêu cầu môn học bổ sung việc đăng nhập trực tiếp SQL cho từng nhân sự, cần chuẩn bị và ánh xạ các Windows Login riêng trước khi nghiệm thu yêu cầu đó.

## 4.2.3. Chi tiết phân quyền cho từng vai trò

| Nhóm quyền | Quyền được cấp | Giới hạn |
|---|---|---|
| role_QuanTri | Gọi SP tạo nhân sự, cập nhật trạng thái, cấp lại mật khẩu và đọc nhật ký an toàn | Không thu học phí, xếp lớp, nhập hoặc chốt điểm |
| role_TuyenSinh | Đọc danh mục và hồ sơ; duyệt, từ chối hoặc hủy hồ sơ theo điều kiện | Không quản trị tài khoản, thu tiền hoặc điều hành học vụ |
| role_GiaoVu | Quản lý khóa/lớp/lịch, xếp lớp, xác nhận buổi đã tổ chức, hoàn thành lớp và trả lại/chốt bảng điểm | Không quản trị tài khoản hoặc tự thực hiện thu học phí; điểm nháp không được công bố cho học viên |
| role_GiaoVien | Xem lớp phụ trách, danh sách học viên, lịch; điểm danh, nhập hai điểm và gửi bảng điểm | Không thao tác lớp của giáo viên khác, thu tiền, tạo tài khoản hoặc tự chốt bảng điểm |
| role_KeToan | Tra cứu hóa đơn, thu đủ học phí, điều chỉnh thông tin thanh toán có lý do, báo cáo và xuất CSV | Không sửa tài khoản, lịch học hoặc bảng điểm; không sửa trực tiếp số tiền hóa đơn |
| role_GiamDoc | Đọc báo cáo tổng hợp qua SP và view được cấp | Không được ghi nghiệp vụ hoặc xem thông tin xác thực |
| role_HocVien | Xem và cập nhật hồ sơ, đăng ký/xác nhận/hủy hồ sơ chờ; xem hóa đơn, lớp/lịch và kết quả đã công bố của mình | Không đọc/sửa dữ liệu của học viên khác hoặc thực hiện chức năng nhân sự |

Các quyền được cấp tập trung bằng GRANT EXECUTE trên từng SP, GRANT SELECT trên các view phù hợp và quyền sử dụng TVP cần thiết. DENY được áp dụng cho truy cập trực tiếp các bảng; không cấp quyền SELECT hoặc EXECUTE toàn bộ schema cho nhóm nghiệp vụ. Trường hợp thu hồi quyền được minh họa bằng GRANT rồi REVOKE trên user kiểm thử, sau đó kiểm tra lại quyền hiệu lực; toàn bộ minh họa được rollback.

Ngoài quyền đối tượng SQL, mỗi SP còn kiểm SID, security version, thời hạn phiên, vai trò SQL và quyền sở hữu dữ liệu. Actor được lấy từ phiên hợp lệ thay vì nhận tùy ý từ client. Vì vậy, một SP được cấp cho nhóm học viên vẫn phải giới hạn kết quả vào dữ liệu của học viên đang đăng nhập.

Các thao tác ghi nghiệp vụ đi cùng AuditLog và ReplayOperation trong một transaction. Nếu ghi nhật ký thất bại, giao dịch nghiệp vụ được rollback. Khi mất phản hồi, ứng dụng tra cứu kết quả qua mã yêu cầu, không tự gửi lại giao dịch. Mô hình hiện tại có 61 SP, gồm 56 SP operation và 5 SP hạ tầng; số bảng và thuộc tính vẫn là 12 và 99.
