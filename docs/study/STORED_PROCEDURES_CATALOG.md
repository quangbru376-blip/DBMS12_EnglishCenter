# Danh sách 61 SP và nhiệm vụ — bản học rút gọn

Mỗi thành viên học sâu **6 SP chính**: tổng **24 chính + 37 hỗ trợ = 61 SP thực tế**. Nhóm hỗ trợ được thu gọn bằng mục có thể mở, không xóa khỏi dự án hay khai báo thiếu trong báo cáo. Khi cần trình bày luồng, biết SP hỗ trợ làm gì và mở source để tra cứu; không yêu cầu học từng dòng của cả 61 SP.

Xem [bảng phân công](DATABASE_OBJECTS_4_MEMBERS.md), [transaction](TRANSACTIONS_4_MEMBERS.md) và [JSON đầy đủ](STORED_PROCEDURES_CATALOG.json). “Chính/hỗ trợ” là mức ưu tiên học trong báo cáo, không phải đánh giá SP nào có thể xóa hoặc bỏ kiểm bảo mật. Chạy bài trên fixture theo [hướng dẫn](SQL_LEARNING_START.md); bài SP mặc định outer ROLLBACK.

|Thành viên|SP chính học sâu|SP hỗ trợ tra cứu|Tổng SP được giao|
|---|---:|---:|---:|
|TV1|6|12|18|
|TV2|6|9|15|
|TV3|6|8|14|
|TV4|6|8|14|
|Tổng|24|37|61|

Chọn nhóm chính để có tạo dữ liệu, tìm kiếm, thống kê, xác thực và các giao dịch cốt lõi; giữ cả 8 transaction trình bày trọng tâm. Những bước chuyển trạng thái hoặc đọc dữ liệu nằm ở phụ lục vẫn được nhắc khi giải thích đầu vào của SP chính. Giáo viên vẫn có thể hỏi SP khác trong source; đây là kế hoạch học tập trung.

## TV1 — Tài khoản, xác thực, phiên đăng nhập và nhật ký

### 6 SP chính — học và báo cáo sâu

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_StudentSignup`|Tạo tài khoản học viên và ghi nhật ký đăng ký; hash mật khẩu do C# tạo.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_StudentSignup.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_StudentSignup.sql)|
|`usp_LoginRead`|Đọc credential/trạng thái nội bộ để C# kiểm mật khẩu; không trả hash ra trình duyệt.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_LoginRead.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_LoginRead.sql)|
|`usp_LoginRecord`|Ghi kết quả đăng nhập, đếm lần sai/throttle và tạo phiên khi thành công; kiểm credential chưa đổi.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_LoginRecord.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_LoginRecord.sql)|
|`usp_PasswordChange`|Đổi hash mật khẩu sau kiểm phiên/credential, tăng phiên bản bảo mật và thu hồi phiên cũ.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_PasswordChange.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_PasswordChange.sql)|
|`usp_AccountCreateStaff`|Admin tạo tài khoản nhân sự có mật khẩu tạm; ghi audit/receipt.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AccountCreateStaff.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AccountCreateStaff.sql)|
|`usp_AccountSetStatus`|Admin đổi trạng thái tài khoản, tăng phiên bản bảo mật và thu hồi phiên.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AccountSetStatus.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AccountSetStatus.sql)|

<details>
<summary>12 SP hỗ trợ — mở khi cần tra cứu</summary>

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_CurrentSession`|Xác minh phiên và trả thông tin tài khoản/vai trò hiện tại.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_CurrentSession.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_CurrentSession.sql)|
|`usp_SessionTouch`|Kiểm phiên hợp lệ rồi cập nhật thời điểm hoạt động của phiên.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_SessionTouch.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_SessionTouch.sql)|
|`usp_Logout`|Thu hồi phiên đăng nhập hiện tại và ghi nhật ký đăng xuất.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_Logout.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_Logout.sql)|
|`usp_ProfileUpdate`|Học viên cập nhật hồ sơ cá nhân theo rowversion; audit/receipt cùng giao dịch.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ProfileUpdate.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ProfileUpdate.sql)|
|`usp_AccountResetPassword`|Admin cấp lại mật khẩu tạm, tăng phiên bản bảo mật và thu hồi phiên.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AccountResetPassword.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AccountResetPassword.sql)|
|`usp_AdminAccountList`|Admin tra cứu/danh sách tài khoản theo bộ lọc và phân trang.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AdminAccountList.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AdminAccountList.sql)|
|`usp_AuditList`|Admin tra cứu nhật ký thao tác theo bộ lọc và phân trang.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AuditList.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AuditList.sql)|
|`usp_ReplayLookup`|Tra cứu receipt của chính người gọi để xác định kết quả lệnh sau mất phản hồi.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ReplayLookup.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ReplayLookup.sql)|
|`usp_OperatorBootstrap`|Operator tạo Admin đầu tiên khi catalog còn rỗng; không phải chức năng web Admin.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_OperatorBootstrap.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_OperatorBootstrap.sql)|
|`usp_MaintenanceCleanup`|Operator dọn receipt quá hạn, phiên hết hạn và bỏ IP trong audit quá thời hạn.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_MaintenanceCleanup.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_MaintenanceCleanup.sql)|
|`usp_SecuritySession`|Helper xác minh SID/epoch, thời hạn, trạng thái, vai trò và native SQL context; trả actor nội bộ.|[SQL](../../database/dbms12-compact/stored-procedures/infrastructure/session.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_SecuritySession.sql)|
|`usp_PasswordSnapshot`|Đọc snapshot hash/phiên bản của tài khoản thuộc phiên hợp lệ để adapter đổi mật khẩu.|[SQL](../../database/dbms12-compact/stored-procedures/infrastructure/password.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_PasswordSnapshot.sql)|

</details>

## TV2 — Đăng ký, tuyển sinh, học phí và báo cáo

### 6 SP chính — học và báo cáo sâu

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_RegistrationCreate`|Học viên tạo hồ sơ PENDING; chống đăng ký trùng hồ sơ chưa kết thúc.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L2)|[Chạy riêng](../../database/practice/stored-procedures/usp_RegistrationCreate.sql)|
|`usp_AdmissionApprove`|Tuyển sinh duyệt CONFIRMED thành ADMITTED và tạo hóa đơn trong cùng transaction.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L60)|[Chạy riêng](../../database/practice/stored-procedures/usp_AdmissionApprove.sql)|
|`usp_AdmissionReject`|Tuyển sinh từ chối hồ sơ hợp lệ, lưu lý do và audit/receipt.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AdmissionReject.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AdmissionReject.sql)|
|`usp_InvoiceCollect`|Kế toán thu đủ học phí một lần, kiểm rowversion và ghi thanh toán/audit/receipt nguyên tử.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L119)|[Chạy riêng](../../database/practice/stored-procedures/usp_InvoiceCollect.sql)|
|`usp_InvoiceSearch`|Kế toán tìm hóa đơn theo bộ lọc và phân trang.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_InvoiceSearch.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_InvoiceSearch.sql)|
|`usp_FinanceReport`|Kế toán tổng hợp số tiền phát hành/doanh thu theo khoảng ngày và công nợ hiện tại toàn bộ hóa đơn.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_FinanceReport.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_FinanceReport.sql)|

<details>
<summary>9 SP hỗ trợ — mở khi cần tra cứu</summary>

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_RegistrationConfirm`|Học viên xác nhận hồ sơ PENDING thành CONFIRMED theo rowversion.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_RegistrationConfirm.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_RegistrationConfirm.sql)|
|`usp_RegistrationCancelOwn`|Học viên hủy hồ sơ chờ của mình khi trạng thái còn cho phép.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_RegistrationCancelOwn.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_RegistrationCancelOwn.sql)|
|`usp_RegistrationList`|Liệt kê hồ sơ theo bộ lọc/phân trang và phạm vi quyền của người gọi.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_RegistrationList.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_RegistrationList.sql)|
|`usp_AdmissionCancel`|Tuyển sinh hủy hồ sơ khi trạng thái/tình trạng thu tiền còn cho phép.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AdmissionCancel.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AdmissionCancel.sql)|
|`usp_InvoiceCorrect`|Kế toán sửa metadata thanh toán có lý do; không thay số tiền hóa đơn.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_InvoiceCorrect.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_InvoiceCorrect.sql)|
|`usp_InvoiceRead`|Đọc hóa đơn cụ thể trong phạm vi vai trò/quyền sở hữu.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_InvoiceRead.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_InvoiceRead.sql)|
|`usp_FinanceExport`|Trả dữ liệu xuất báo cáo tài chính; C# định dạng CSV và bảo vệ formula injection.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_FinanceExport.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_FinanceExport.sql)|
|`usp_DirectorReport`|Giám đốc xem số liệu tổng hợp phục vụ quản lý, không có quyền ghi nghiệp vụ.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_DirectorReport.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_DirectorReport.sql)|
|`usp_RecordFailure`|Ghi FAILURE/DENIED xác định được sau khi giao dịch nghiệp vụ đã rollback; không giả lỗi cho commit chưa rõ.|[SQL](../../database/dbms12-compact/stored-procedures/infrastructure/failure.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_RecordFailure.sql)|

</details>

## TV3 — Khóa học, lớp, xếp lớp và lập lịch

### 6 SP chính — học và báo cáo sâu

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_CourseCreate`|Giáo vụ tạo khóa học với học phí, số buổi và trọng số; audit/receipt cùng giao dịch.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_CourseCreate.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_CourseCreate.sql)|
|`usp_ClassOpen`|Chuyển lớp PLANNED sang OPEN khi khóa/giáo viên hoạt động và có buổi LESSON tương lai.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassOpen.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassOpen.sql)|
|`usp_ClassStart`|Chuyển OPEN sang ONGOING khi đủ lịch, kỳ thi, học viên và đã đến buổi học đầu.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassStart.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassStart.sql)|
|`usp_ClassComplete`|Chuyển ONGOING sang COMPLETED khi đủ lịch, mọi buổi đã HELD và không thiếu điểm danh.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassComplete.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassComplete.sql)|
|`usp_PlacementCreate`|Xếp hồ sơ ADMITTED/đã trả tiền vào lớp OPEN, kiểm sức chứa/trùng lịch và tạo GradeReport cùng giao dịch.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L183)|[Chạy riêng](../../database/practice/stored-procedures/usp_PlacementCreate.sql)|
|`usp_ScheduleBatch`|Lưu cả lô lịch từ TVP; một dòng vi phạm làm thất bại cả giao dịch.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L246)|[Chạy riêng](../../database/practice/stored-procedures/usp_ScheduleBatch.sql)|

<details>
<summary>8 SP hỗ trợ — mở khi cần tra cứu</summary>

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_CourseUpdate`|Giáo vụ sửa cấu hình khóa học theo rowversion và giới hạn khi khóa đã được sử dụng.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_CourseUpdate.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_CourseUpdate.sql)|
|`usp_CourseList`|Liệt kê/tìm khóa học theo bộ lọc, phân trang và vai trò.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_CourseList.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_CourseList.sql)|
|`usp_ClassCreate`|Giáo vụ tạo lớp PLANNED thuộc khóa học, giáo viên và sức chứa hợp lệ.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassCreate.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassCreate.sql)|
|`usp_ClassEdit`|Giáo vụ sửa thông tin lớp theo trạng thái/rowversion và các ràng buộc liên quan.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassEdit.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassEdit.sql)|
|`usp_ClassCancel`|Giáo vụ hủy lớp khi vòng đời còn cho phép, lưu lý do và audit/receipt.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassCancel.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassCancel.sql)|
|`usp_ClassList`|Liệt kê lớp và trạng thái bảng điểm trong phạm vi Student/Teacher/AcademicAffairs.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassList.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassList.sql)|
|`usp_TeacherOptions`|Lấy danh sách giáo viên phù hợp cho thao tác quản lý lớp.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_TeacherOptions.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_TeacherOptions.sql)|
|`usp_WeeklySchedulePreview`|Tính bản xem trước lịch theo tuần; chưa lưu lịch vào database.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_WeeklySchedulePreview.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_WeeklySchedulePreview.sql)|

</details>

## TV4 — Tổ chức buổi học, điểm danh, bảng điểm và kết quả

### 6 SP chính — học và báo cáo sâu

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_ScheduleHeld`|Giáo vụ xác nhận buổi đã tổ chức sau giờ kết thúc khi trạng thái lớp cho phép.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ScheduleHeld.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ScheduleHeld.sql)|
|`usp_AttendanceSave`|Giáo viên lưu cả lô có mặt/vắng từ TVP, kiểm lớp phụ trách và phiên bản.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L377)|[Chạy riêng](../../database/practice/stored-procedures/usp_AttendanceSave.sql)|
|`usp_GradeSave`|Giáo viên lưu hai điểm và nhận xét theo trạng thái lớp/bảng điểm và rowversion.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L449)|[Chạy riêng](../../database/practice/stored-procedures/usp_GradeSave.sql)|
|`usp_GradeSubmit`|Giáo viên gửi toàn bộ bảng điểm lớp COMPLETED, yêu cầu đủ điểm và manifest đúng phiên bản.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L522)|[Chạy riêng](../../database/practice/stored-procedures/usp_GradeSubmit.sql)|
|`usp_GradeReturn`|Giáo vụ trả lại bảng điểm SUBMITTED kèm lý do để giáo viên sửa.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L589)|[Chạy riêng](../../database/practice/stored-procedures/usp_GradeReturn.sql)|
|`usp_GradeFinalize`|Giáo vụ chốt bảng điểm SUBMITTED toàn lớp bằng quyết định audit và cập nhật con trỏ trạng thái.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L660)|[Chạy riêng](../../database/practice/stored-procedures/usp_GradeFinalize.sql)|

<details>
<summary>8 SP hỗ trợ — mở khi cần tra cứu</summary>

|SP|Nhiệm vụ|Định nghĩa|Bài chạy|
|---|---|---|---|
|`usp_ScheduleList`|Đọc lịch trong khoảng thời gian và phạm vi quyền của người gọi.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ScheduleList.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ScheduleList.sql)|
|`usp_ScheduleMove`|Giáo vụ dời buổi học còn cho phép, kiểm trùng lịch/rowversion và lưu lý do.|[SQL](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql#L307)|[Chạy riêng](../../database/practice/stored-procedures/usp_ScheduleMove.sql)|
|`usp_AttendanceRead`|Đọc danh sách điểm danh để hiển thị/chỉnh sửa trong phạm vi lớp hợp lệ.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_AttendanceRead.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_AttendanceRead.sql)|
|`usp_ClassRoster`|Đọc danh sách học viên của lớp trong phạm vi giáo viên/giáo vụ.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_ClassRoster.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_ClassRoster.sql)|
|`usp_StudentGrades`|Học viên xem kết quả FINALIZED của chính mình.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_StudentGrades.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_StudentGrades.sql)|
|`usp_StudentHome`|Tổng hợp đăng ký, học phí, lớp và kết quả của chính học viên.|[SQL](../../database/dbms12-compact/stored-procedures/operations/usp_StudentHome.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_StudentHome.sql)|
|`usp_BeginRead`|Helper lấy khóa đọc trên Course; tự mở/chốt khi depth0 hoặc dùng transaction caller ở depth1.|[SQL](../../database/dbms12-compact/stored-procedures/infrastructure/begin-read.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_BeginRead.sql)|
|`usp_BeginWrite`|Helper lấy khóa ghi độc quyền trên Course; tự mở/chốt khi depth0 hoặc dùng transaction caller ở depth1.|[SQL](../../database/dbms12-compact/stored-procedures/infrastructure/begin-write.sql#L1)|[Chạy riêng](../../database/practice/stored-procedures/usp_BeginWrite.sql)|

</details>
