# Phân công transaction cho 4 thành viên

Đây là phần bổ sung rõ cho [bảng 105 Database Object](DATABASE_OBJECTS_4_MEMBERS.md). Giao đủ 29 command SP theo người phụ trách SP hiện có, không chỉ 5 ví dụ. Phần transaction trong 61 SP đọc/auth/helper đi theo người đã nhận SP đó. Giữ nguyên tổng 27/26/26/26; không đếm transaction thêm lần nữa như một schema object.

## Hai bài trọng tâm cho mỗi người

|Người|Bài 1|Bài 2|Những thay đổi phải nguyên tử|
|---|---|---|---|
|TV1|[Tạo nhân sự](../../database/practice/stored-procedures/usp_AccountCreateStaff.sql)|[Đổi trạng thái tài khoản](../../database/practice/stored-procedures/usp_AccountSetStatus.sql)|Account/mật khẩu tạm; thu hồi session/tăng epoch khi đổi trạng thái; audit/receipt cùng nghiệp vụ|
|TV2|[Duyệt nhập học](../../database/practice/stored-procedures/usp_AdmissionApprove.sql)|[Thu học phí](../../database/practice/stored-procedures/usp_InvoiceCollect.sql)|CONFIRMED→ADMITTED và Invoice; Invoice.paid metadata; audit/receipt, không thu hai lần|
|TV3|[Xếp lớp](../../database/practice/stored-procedures/usp_PlacementCreate.sql)|[Lưu lô lịch](../../database/practice/stored-procedures/usp_ScheduleBatch.sql)|Assignment+GradeReport stub; audit/receipt; mọi dòng lịch hợp lệ hoặc không lưu dòng nào|
|TV4|[Lưu điểm danh](../../database/practice/stored-procedures/usp_AttendanceSave.sql)|[Chốt bảng điểm](../../database/practice/stored-procedures/usp_GradeFinalize.sql)|Cả lô Attendance; quyết định điểm/AuditLog/Class.current_grade_operation_id/receipt, manifest toàn lớp đúng RV|

Tám bài trên chia đều 2/người là phần trình bày trọng tâm và đều thuộc 6 SP chính/người trong [bản báo cáo rút gọn](STORED_PROCEDURES_CATALOG.md). Danh sách 29 nghiệp vụ tiếp theo là kiểm kê trách nhiệm tra cứu; các SP hỗ trợ chỉ cần nắm nhiệm vụ và phụ thuộc, không yêu cầu học từng dòng khi báo cáo.

## Danh sách toàn bộ 29 nghiệp vụ ghi

|Người|SP có transaction (tra cứu)|Ý nghĩa nghiệp vụ|
|---|---|---|
|TV1|`usp_ProfileUpdate`|Cập nhật profile với RV, audit/receipt cùng giao dịch|
|TV1|`usp_AccountCreateStaff`|Tạo nhân sự/mật khẩu tạm và audit/receipt|
|TV1|`usp_AccountSetStatus`|Đổi trạng thái, tăng epoch, thu hồi phiên, audit/receipt|
|TV1|`usp_AccountResetPassword`|Reset mật khẩu tạm, tăng epoch, thu hồi phiên, audit/receipt|
|TV2|`usp_RegistrationCreate`|Tạo PENDING, chống hồ sơ đang xử lý trùng, audit/receipt|
|TV2|`usp_RegistrationConfirm`|PENDING→CONFIRMED đúng RV và receipt|
|TV2|`usp_RegistrationCancelOwn`|Học viên hủy hồ sơ của mình và audit/receipt|
|TV2|`usp_AdmissionApprove`|ADMITTED và tạo Invoice cùng giao dịch|
|TV2|`usp_AdmissionReject`|Từ chối đúng trạng thái/lý do và audit/receipt|
|TV2|`usp_AdmissionCancel`|Hủy hồ sơ còn cho phép, không hủy đã thu tiền|
|TV2|`usp_InvoiceCollect`|Thu đủ một lần, kiểm RV và audit/receipt|
|TV2|`usp_InvoiceCorrect`|Sửa metadata thanh toán có lý do, không sửa amount|
|TV3|`usp_CourseCreate`|Tạo khóa, audit/receipt cùng transaction|
|TV3|`usp_CourseUpdate`|Đổi cấu hình hợp lệ đúng RV, audit/receipt|
|TV3|`usp_ClassCreate`|Tạo PLANNED với khóa/teacher hợp lệ và receipt|
|TV3|`usp_ClassEdit`|Sửa teacher/capacity đúng trạng thái, RV và xung đột|
|TV3|`usp_ClassOpen`|Mở nhận khi đủ guard và ghi sự kiện thành công|
|TV3|`usp_ClassStart`|OPEN→ONGOING khi đủ lịch/học viên/thời điểm|
|TV3|`usp_ClassComplete`|ONGOING→COMPLETED khi đủ HELD/điểm danh|
|TV3|`usp_ClassCancel`|Hủy lớp còn cho phép cùng lý do/audit/receipt|
|TV3|`usp_PlacementCreate`|Assignment+GradeReport+audit/receipt nguyên tử|
|TV3|`usp_ScheduleBatch`|Cả lô Schedule, không ghi một phần khi có dòng lỗi|
|TV4|`usp_ScheduleMove`|Dời lịch đúng RV/không xung đột, lý do và audit|
|TV4|`usp_ScheduleHeld`|Ghi xác nhận đã tổ chức đúng cửa sổ và audit/receipt|
|TV4|`usp_AttendanceSave`|Lưu cả lô điểm danh, không coi thiếu nhập là vắng|
|TV4|`usp_GradeSave`|Lưu hai điểm/comment đúng report/class RV và receipt|
|TV4|`usp_GradeSubmit`|Đủ manifest toàn lớp, ghi quyết định và đổi pointer trạng thái|
|TV4|`usp_GradeReturn`|SUBMITTED→RETURNED có lý do, quyết định/receipt nguyên tử|
|TV4|`usp_GradeFinalize`|SUBMITTED→FINALIZED toàn lớp, quyết định/receipt nguyên tử|

Phân bố command: **TV1 = 4, TV2 = 8, TV3 = 10, TV4 = 7**. Đây là 29 đầu việc học trong 29 SP, không khẳng định 29 transaction độc lập ở mọi thời điểm chạy. Helper có thể dùng chung transaction của caller.

## Auth và helper cũng phải có người giải thích

- TV1 nhận 8 module auth: signup, loginread/loginrecord, sessiontouch, logout, passwordchange, operatorbootstrap, maintenancecleanup. LoginRead là đọc; loginrecord/passwordchange/logout có phần thay đổi phiên/tài khoản cần giải thích. Không gọi 8 auth là 8 nghiệp vụ command có receipt như 29 lệnh trên.
- TV1 phụ trách `usp_SecuritySession`, `usp_PasswordSnapshot`; TV2 phụ trách `usp_RecordFailure`; TV4 phụ trách `usp_BeginRead`, `usp_BeginWrite`. Các module dùng chung vẫn có owner trình bày, không chỉ phục vụ cụm nghiệp vụ của người đó.
- Mọi thành viên phải phân biệt @@TRANCOUNT 0/1, SQL owner/caller, TRY/CATCH/XACT_ABORT và trách nhiệm COMMIT/ROLLBACK. SP read cũng phải đóng transaction/nhả khóa nếu tự mở.

## Phân công 5 file có COMMIT/forced-error hiện có

|File trong practice/transactions|Người trình bày|
|---|---|
|[usp_CourseCreate.sql](../../database/practice/transactions/usp_CourseCreate.sql)|TV3|
|[usp_RegistrationCreate.sql](../../database/practice/transactions/usp_RegistrationCreate.sql)|TV2|
|[usp_AdmissionApprove.sql](../../database/practice/transactions/usp_AdmissionApprove.sql)|TV2|
|[usp_InvoiceCollect.sql](../../database/practice/transactions/usp_InvoiceCollect.sql)|TV2|
|[usp_PlacementCreate.sql](../../database/practice/transactions/usp_PlacementCreate.sql)|TV3|

Năm file được chọn từ trước để diễn 5 COMMIT/5 forced ROLLBACK, chủ yếu thuộc tuyển sinh/xếp lớp nên không tự chia đều 4 người. Tám bài trọng tâm ở đầu bổ sung trách nhiệm rõ cho TV1/TV4. Bài SP mặc định có outer ROLLBACK; chỉ 5 file trong bảng này có cờ `@CommitLab/@ForceFailure`. Không tự đổi ROLLBACK thành COMMIT trong bài SP thông thường rồi để lại session thử. Đọc [cách chạy đúng](SQL_LEARNING_START.md) và [index 107 bài](../../database/practice/README.md).

## Concurrency — yêu cầu 3.4

**TV2 chủ trì**, vì nghiệp vụ là `usp_InvoiceCollect`. **TV1 chạy phiên còn lại**, đối chiếu audit/replay và kết quả chưa rõ. TV3/TV4 giải thích khóa/rowversion và liên hệ với lô lịch/điểm danh/bảng điểm của mình.

Chạy [Session A](../../database/dbms12-compact/transactions/02_concurrency_session_a.sql) và [Session B](../../database/dbms12-compact/transactions/03_concurrency_session_b.sql) trên cùng Invoice/RV trong fixture. Phải giải thích tại sao một yêu cầu chờ, sau đó chỉ một COMMIT và yêu cầu còn lại lỗi 51214; không hai lần thu hoặc hai SUCCESS. [Bằng chứng đã có](../evidence/sql-transactions/summary.json) là lần kiểm của dự án, không tự coi là bằng chứng thành viên đã diễn lại.

## Đầu ra mỗi người phải nộp khi học

1. Danh sách command để tra cứu của mình và đường dẫn định nghĩa/câu gọi qua [OBJECT_INDEX](../../database/dbms12-compact/OBJECT_INDEX.md).
2. Hai bài trọng tâm: đầu vào, điều kiện, bảng/dòng thay đổi, audit/receipt và phần nguyên tử.
3. Chỉ đúng BEGIN/COMMIT/ROLLBACK trong SP, ai là owner khi chạy web và khi chạy bài outer transaction.
4. Một lần chạy hợp lệ, một lỗi được giải thích, ảnh/kết quả trước/sau trênfixture; chỉ ghi PASS khi tự chạy.
5. Giải thích RV/lock/replay/unknown và không khẳng địnhsequence/identity liên tục sau rollback.

Phần này là bổ sung phân công/tài liệu. Không thay SQL hoặc tăng số object, cũng không khẳng định mọi bài trên đã có COMMIT/forced-error flag. Mỗi người học transaction cùng nghiệp vụ mình đã nhận; số 2 bài trọng tâm giúp chia đều phần trình bày.
