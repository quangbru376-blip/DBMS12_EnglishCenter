# Nghiệp vụ đã chốt

Quản lý trung tâm theo chuỗi: khóa học → đăng ký và duyệt → học phí → xếp lớp → lịch và điểm danh → điểm và kết quả. Đây là phạm vi rút gọn phục vụ báo cáo CSDL.

|Vai trò|Quyền chính|
|---|---|
|Student|Tự tạo tài khoản, sửa hồ sơ của mình, xem khóa đang tuyển, đăng ký/xác nhận/hủy hồ sơ chờ; xem hóa đơn, lớp, lịch và kết quả đã công bố của mình|
|Admissions|Xem catalogue và hồ sơ; duyệt để phát hành hóa đơn, từ chối/hủy theo điều kiện; không quản trị học vụ|
|AcademicAffairs|Quản lý khóa, lớp, lịch, xếp lớp; xác nhận buổi đã tổ chức, hoàn thành lớp; trả lại/chốt bảng điểm toàn lớp|
|Teacher|Chỉ lớp mình phụ trách: roster, lịch, điểm danh, hai điểm và nhận xét; gửi toàn bộ bảng điểm|
|Accountant|Tra cứu hóa đơn, thu đủ, sửa thông tin thanh toán có lý do, báo cáo tài chính và CSV|
|Director|Báo cáo tổng hợp; không ghi nghiệp vụ hoặc xem credential|
|Admin|Tạo nhân sự, đổi trạng thái/cấp lại mật khẩu tạm, xem nhật ký; không tự nhận quyền nghiệp vụ của vai trò khác|

## Các quy tắc quan trọng

1. Bảy mã vai trò nằm trong CHECK của Account, không có bảng Role. Nhân sự nhận mật khẩu tạm một lần và phải đổi trước khi vào nghiệp vụ.
2. Course có một học phí, số buổi dự kiến và trọng số quá trình. Cấu hình đã có lớp được SQL bảo vệ. Có đúng hai điểm cố định.
3. Registration đi từ PENDING → CONFIRMED → ADMITTED; nhánh REJECTED/CANCELLED phụ thuộc người thao tác và trạng thái. Không tạo trùng hồ sơ chưa kết thúc cho cùng học viên/khóa.
4. Duyệt nhập học và tạo Invoice là một transaction. Một hóa đơn cho một registration; thu đủ một lần. Điều chỉnh phương thức/tham chiếu cần lý do; không sửa amount trực tiếp.
5. Class đi từ PLANNED → OPEN → ONGOING → COMPLETED. Hủy theo guard trước khi bắt đầu. Mở lớp cần đủ LESSON và một FINAL_EXAM tương lai.
6. Xếp lớp chỉ khi hồ sơ ADMITTED, đã thanh toán, lớp OPEN cùng khóa, còn chỗ và không trùng lịch. Một assignment cho một registration.
7. Lịch chỉ giữ phiên bản hiện tại. Có thể dời buổi tương lai chưa có dữ liệu khi SQL cho phép; lý do/lần sửa nằm trong Audit. Kiểm trùng lớp, giáo viên, phòng và học viên theo khoảng [start,end).
8. Điểm danh phải chọn tường minh, không coi chưa nhập là vắng. Giáo vụ xác nhận HELD sau giờ kết thúc và khi trạng thái lớp cho phép.
9. Chỉ sửa điểm khi lớp ONGOING/COMPLETED và bảng điểm DRAFT/RETURNED. Điểm cuối khóa chỉ nhập sau giờ thi. Gửi/chốt phải đủ toàn lớp, manifest và RV còn đúng, lớp COMPLETED. FINALIZED không sửa lại.
10. SQL tính tổng với trọng số cuối bằng 100-process_weight, làm tròn hai chữ số, đạt khi tổng>=50. Không lưu thêm total/pass. Student chỉ xem FINALIZED; giáo vụ không xem điểm nháp.
11. Ghi nghiệp vụ phải kiểm phiên và RV; audit/receipt cùng transaction. Mất phản hồi cần lookup riêng, không tự gửi lại. Không tìm thấy receipt chưa chứng minh rollback.

Không có thi đầu vào/booking/Band/Program, thi lại, Role table, thu nhiều đợt/Payment/refund, bulk import hoặc tự reset. Source SQL là chuẩn cho guard chi tiết.

Đăng ký lại khóa sau khi hồ sơ cũ đã kết thúc có thể được fn_RegistrationUnfinished cho phép; điều này khác một luồng thi lại/nhiều lần thi trên cùng assignment. Không tự thêm chức năng thi lại riêng.
