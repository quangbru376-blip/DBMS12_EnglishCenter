# API DBMS12

Origin local: https://localhost:8446; UI /dbms12; base API /api/dbms12. Chỉ các route cố định bên dưới, không nhận operation/SQL tùy ý.

## Xác thực

GET auth/csrf trả requestToken; GET auth/me trả projection account/session không có hash/SID/epoch. POST auth/login(email,password), auth/signup(email,password,name,phone,birthDate,address), auth/password(oldPassword,newPassword), auth/logout({}). Cookie Secure/HttpOnly/SameSiteStrict __Host-ec12p-auth; unsafe request phải đúng Origin và X-CSRF-TOKEN từ framework. Restricted session chỉ được csrf/me/password/logout. Signup không tự login.

## Contract chung

- GET trả {rows:[...]}; các danh sách paged trả thêm một row total. Course/registration/invoice/account/audit phân trang, page>=1 và pageSize<=100.
- POST nghiệp vụ có Idempotency-Key UUID khác rỗng. Actor/SID/epoch/hash/digest chỉ server đặt, không nhận từ body.
- Command trả {rows:[{operation_id,target_id,replayed}],temporaryPassword?}. Chỉ account create/reset mới trả password tạm và chỉ lần non-replay, không log/lưu vào public evidence.
- RV là base64 8bytes. Instant là UTC ISO; birthDate/dueDate là yyyy-MM-dd. Tiền/tổng cần độ chính xác số nguyên được trả string; UI format Việt Nam.
- GET operations?action=...&requestId=... chỉ đọc receipt của actor hiện tại trong24h. Không tìm thấy chưa đủ để kết luận rollback. Client không tự retry command.
- 400 validation/business,401 session,403 role/CSRF,409 conflict,413 quá lớn,429 login limit,503 service/commit chưa rõ kết quả. Request size tối đa262144bytes.

## Map route → SQL operation

Tham số public là camelCase từ manifest parameters sau khi bỏ Sid/Epoch/RequestId/Digest/PasswordHash. Tất cả operation gọi SP dưới context cố định từ manifest. Một số operation role=null kiểm nhiều vai trò trực tiếp trong SQL; xem source được ghi ở bảng, không hiểu null là public/anonymous.

|Method/path|Operation|Role trong manifest|Cách gọi|
|---|---|---|---|
|GET courses|usp_CourseList|SQL role/ownership guard|SP|
|POST courses/create|usp_CourseCreate|AcademicAffairs|SP|
|POST courses/update|usp_CourseUpdate|AcademicAffairs|SP|
|GET registrations|usp_RegistrationList|SQL role/ownership guard|SP|
|POST registrations/create|usp_RegistrationCreate|Student|SP|
|POST registrations/confirm|usp_RegistrationConfirm|Student|SP|
|POST registrations/cancel-own|usp_RegistrationCancelOwn|Student|SP|
|POST admissions/approve|usp_AdmissionApprove|Admissions|SP|
|POST admissions/reject|usp_AdmissionReject|Admissions|SP|
|POST admissions/cancel|usp_AdmissionCancel|Admissions|SP|
|GET invoices/detail|usp_InvoiceRead|SQL role/ownership guard|SP|
|GET invoices|usp_InvoiceSearch|SQL role/ownership guard|SP|
|POST invoices/collect|usp_InvoiceCollect|Accountant|SP|
|POST invoices/correct|usp_InvoiceCorrect|Accountant|SP|
|GET classes|usp_ClassList|SQL role/ownership guard|SP|
|GET classes/roster|usp_ClassRoster|SQL role/ownership guard|SP|
|POST classes/create|usp_ClassCreate|AcademicAffairs|SP|
|POST classes/edit|usp_ClassEdit|AcademicAffairs|SP|
|POST classes/open|usp_ClassOpen|AcademicAffairs|SP|
|POST classes/start|usp_ClassStart|AcademicAffairs|SP|
|POST classes/complete|usp_ClassComplete|AcademicAffairs|SP|
|POST classes/cancel|usp_ClassCancel|AcademicAffairs|SP|
|POST placements|usp_PlacementCreate|AcademicAffairs|SP|
|GET schedules|usp_ScheduleList|SQL role/ownership guard|SP|
|GET schedules/preview|usp_WeeklySchedulePreview|SQL role/ownership guard|SP|
|POST schedules/batch|usp_ScheduleBatch|AcademicAffairs|SP|
|POST schedules/move|usp_ScheduleMove|AcademicAffairs|SP|
|POST schedules/held|usp_ScheduleHeld|AcademicAffairs|SP|
|GET attendance|usp_AttendanceRead|SQL role/ownership guard|SP|
|POST attendance/save|usp_AttendanceSave|Teacher|SP|
|POST grades/save|usp_GradeSave|Teacher|SP|
|POST grades/submit|usp_GradeSubmit|Teacher|SP|
|POST grades/return|usp_GradeReturn|AcademicAffairs|SP|
|POST grades/finalize|usp_GradeFinalize|AcademicAffairs|SP|
|GET grades/own|usp_StudentGrades|SQL role/ownership guard|SP|
|GET teachers|usp_TeacherOptions|SQL role/ownership guard|SP|
|POST profile/update|usp_ProfileUpdate|SQL role/ownership guard|SP|
|GET home|usp_StudentHome|SQL role/ownership guard|SP|
|GET accounts|usp_AdminAccountList|SQL role/ownership guard|SP|
|POST accounts/create|usp_AccountCreateStaff|Admin|SP|
|POST accounts/status|usp_AccountSetStatus|Admin|SP|
|POST accounts/reset-password|usp_AccountResetPassword|Admin|SP|
|GET audit|usp_AuditList|SQL role/ownership guard|SP|
|GET reports/finance|usp_FinanceReport|SQL role/ownership guard|SP|
|GET reports/director|usp_DirectorReport|SQL role/ownership guard|SP|
|GET operations|usp_ReplayLookup|SQL role/ownership guard|SP|

GET reports/finance.csv gọi usp_FinanceExport, chỉ Accountant, UTF-8 BOM/quote/formula-safe. Bootstrap/maintenance/session-touch không có public endpoint. GET /health/ready chỉ báo ready khi profile/native SQL guard đúng.

Nguồn tham số/types/defaults chính xác: database/dbms12-compact/manifest.json; JSON/TVP validation: RequestFields.cs. Không mở endpoint nhận Accepted/ObservedHash/ObservedEpoch cho login; LoginRecord chỉ là adapter nội bộ.

Hạ tầng Native Security V2: 56 operation SP + 5 SP hạ tầng, 7 SQL business roles/users. Theo D15, toàn bộ61SP có SQL-owned transaction; command tự xác định Actor, ghi audit/replay và COMMIT trước final server completion. C# gọi/REVERT và rollback cleanup khi lỗi/cancel; HTTP không đổi. Khi write đã dispatch mà cancel/mất ACK, giữ COMMAND_OUTCOME_UNKNOWN, tra receipt thủ công. Chi tiết docs/SQL_SECURITY.md và SQL_SECURITY_MATRIX.md. Lỗi EXECUTE bị SQL từ chối (229) được trả HTTP403.

## Hành vi chọn lớp của Giáo viên

Lớp phụ trách → Chọn hiển thị thông tin lớp và danh sách học viên qua GET classes/roster?classId=... hiện có. Hai nút Điểm danh/Bảng điểm chuyển sang màn tương ứng và giữ đúng classId trong RAM Workspace; Tải lại cập nhật roster. Không thêm endpoint, không mở quyền xem lớp khác hoặc ghi dữ liệu khi chọn.

22/10/2026 UI_PANELS: thêm khung/nền cho vùng nội dung, bảng, bộ lọc, biểu mẫu, phân trang và navigation của 7 vai trò. Đây là thay đổi trình bày dùng cùng contract/handler; không có endpoint hoặc DTO mới.

22/10/2026 SCROLL_LISTS thay thanh phân trang UI bằng vùng cuộn giữ cột. Courses/registrations/invoices/accounts/audit vẫn gọi GET với page/pageSize=20 hiện có; đến gần cuối tự lấy trang tiếp, append theo ID, tách metadata total. Bao gồm Xếp lớp và chọn hồ sơ xem hóa đơn. Lỗi tải thêm giữ dòng cũ và retry bằng thao tác riêng; thay search/filter/refresh hủy áp dụng phản hồi query cũ. Không đổi HTTP/SQL/DTO/quyền/command; dữ liệu đọc không là snapshot giữa các trang nếu người khác đang cập nhật. In chỉ dùng các dòng hiện đã tải, không tự đọc thêm.

22/10/2026 CLASS_STATUS: Teaching hiển thị mã lớp/teacher_name/status/grade_status từ GET classes đang có dưới bộ chọn lớp. Màn Duyệt bảng điểm giải thích theo trạng thái thay lời hướng dẫn gửi dành cho Teacher; quyền ẩn điểm nháp và điều kiện nút duyệt không đổi. Không thêm request/DTO/endpoint.

23/10/2026 CREATE_FIRST_DIALOGS: form tạo khóa/lớp/nhân sự đứng trước tìm kiếm và danh sách; tạo lịch trước bảng lịch. Các giao diện mở qua Chọn nằm trong popup dùng Modal hiện có, gồm chi tiết/form/thao tác/nhập điểm; lỗi và manual lookup hiện trong popup. Đóng có dirty guard, request đang xử lý chặn đóng; in hóa đơn đọc mới rồi chỉ in nội dung popup. Route/payload/RV/role/command/replay giữ nguyên, không thêm API.

23/10/2026 CREATE_SEARCH_ROW: khung Tạo và Tìm kiếm của Khóa học/Giáo vụ và Tài khoản/Admin dùng cùng hàng hai cột khi viewport>=1000px, cùng đỉnh; màn hình nhỏ xếp dọc. Trang có một khung dùng toàn chiều rộng. Không đổi request/query/DTO/command/quyền/popup.

23/10/2026 HORIZONTAL_CREATE thay CREATE_SEARCH_ROW theo yêu cầu mới: Tạo fullwidth trên Tìm kiếm; field tạo khóa/lớp/nhân sự/lịch xếp1/2/3cột ở mobile/>=768/>=1100px, nút lưu dòng riêng. Hai form tạo lịch fullwidth. Chỉ presentation; query/DTO/command/quyền/popup không đổi.

23/10/2026 FEEDBACK_COLORS: notice thành công xanh lá/status, gồm hủy/signup/password/lookup tìm thấy; lỗi đỏ/alert trên trang và popup. Unknown/receipt chưa tìm thấy vẫn giữ ngữ nghĩa không xác định và manual lookup, tô đỏ. Dùng kết quả xử lý để đặt loại, không đổi HTTP/API/retry/command.

23/10/2026 PANEL_ACTION_DIALOGS thay bố cục inline cũ: Tạo/Tìm kiếm mở popup từ nút ở trên phải header danh sách tương ứng; chỉ các thao tác đã có theo vai trò. Search giữ query và chỉ áp dụng khi submit; create thành công đóng/refreshtheocũ, lỗi giữdraft, unknown giữlookup. Popup lịch chứa2form+preview và dirtyguard khi bỏ lịch dự kiến. Không đổi endpoint/payload/DTO/filter/scroll/role/command/replay; popup Chọn và màu thông báo giữ nguyên.
