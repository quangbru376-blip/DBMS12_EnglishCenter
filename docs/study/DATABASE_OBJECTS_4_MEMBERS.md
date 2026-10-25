# Phân công học Database Object cho nhóm 4 người

Ngày lập: **24/10/2026**; bổ sung phân công transaction: **25/10/2026**. Nguồn: `database/dbms12-compact/manifest.json` và các định nghĩa SQL trong `installOrder`. Chưa có tên thành viên nên ký hiệu TV1–TV4.

Mỗi object có đúng **một người phụ trách giải thích và trình bày**. Người khác vẫn đọc các object liên quan khi lần theo nghiệp vụ. Đây là phân công học, không tạo bốn SQL role mới hoặc thay quyền của bảy vai trò ứng dụng.

## Cách tính và bảng chia

Phạm vi gồm **105 object chính**: 12 bảng + 61 SP + 7 function + 9 view + 12 trigger + 3 kiểu bảng TVP + 1 sequence. Chia gần đều nhất là **27–26–26–26**, chênh tối đa một object. Không nhầm 62 file SQL với số object; một file có thể định nghĩa nhiều object.

|Thành viên|Cụm nghiệp vụ|Bảng|SP|FN|View|Trigger|TVP|Sequence|Tổng|
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
|TV1|Tài khoản, xác thực, phiên và nhật ký|4|18|1|1|3|0|0|**27**|
|TV2|Đăng ký, tuyển sinh, học phí và báo cáo|2|15|3|3|2|0|1|**26**|
|TV3|Khóa học, lớp, xếp lớp và lập lịch|4|14|1|2|4|1|0|**26**|
|TV4|Tổ chức buổi học, điểm danh và bảng điểm|2|14|2|3|3|2|0|**26**|
|Tổng||12|61|7|9|12|3|1|**105**|

PK/FK/UNIQUE/CHECK/DEFAULT, index và rowversion học cùng bảng mà chúng bảo vệ, không đếm thêm để làm tăng số lượng. Role, user và GRANT/DENY/IMPERSONATE học cùng quyền của từng luồng; TV1 trình bày nền tảng, cả nhóm phải biết kiểm quyền trên nghiệp vụ mình. Danh sách này không tuyên bố bao trùm mọi loại object nội bộ trong `sys.objects`.

Số lượng gần bằng nhau không có nghĩa độ khó bằng nhau: SP gửi bảng điểm hoặc trigger kiểm trùng lịch cần phân tích nhiều hơn một view đơn giản. Mỗi thành viên chuẩn bị ít nhất một luồng có ghi dữ liệu, một trường hợp bị từ chối và một trường hợp liên quan người khác.

## Phân công transaction — yêu cầu 3.4

Phần transaction trước đây chỉ được nhắc trong SP/luồng, chưa được giao thành đầu việc riêng. Bảng dưới đây giao rõ cả 29 nghiệp vụ ghi và 2 bài trọng tâm cho mỗi người. Xem [danh sách đầy đủ, đầu ra và bài chạy](TRANSACTIONS_4_MEMBERS.md).

|Thành viên|Phần transaction của SP phụ trách|Command cần phân tích nguyên tử|Hai bài trình bày trọng tâm|
|---|---:|---:|---|
|TV1|18 SP, gồm 8 auth và 2 helper|4|Tạo nhân sự; khóa/mở trạng thái tài khoản và thu hồi phiên|
|TV2|15 SP, gồm 1 helper|8|Duyệt nhập học; thu học phí|
|TV3|14 SP|10|Xếp lớp; lưu cả lô lịch|
|TV4|14 SP, gồm 2 helper|7|Lưu điểm danh cả lớp; chốt toàn bộ bảng điểm|
|Tổng|61 scope theo owner SP|29|8 bài trọng tâm, 2/người|

Transaction là phạm vi công việc trong SP, không cộng thêm 29 object vào tổng 105 hoặc coi 61 SP là 61 giao dịch độc lập. Các helper có thể chia sẻ transaction của caller. Khối lượng transaction 4/8/10/7 bám đúng cụm nghiệp vụ; TV1 còn 8 module auth cần học về tạo/thu hồi phiên. Tổng object vẫn 27/26/26/26 và số bài trình bày trọng tâm chia đều 2/người.

Mỗi người phải chỉ ra BEGIN/COMMIT/ROLLBACK, các thay đổi phải nguyên tử, trước/sau và lúc lỗi, audit/receipt, lock/RV/replay và owner/caller. Mọi bài SP trong practice mặc định outer ROLLBACK để lặp lại. Riêng 5 file trong practice/transactions có COMMIT/forced-error opt-in; TV2 phụ trách 3 file, TV3 phụ trách 2 file. TV1/TV4 dùng bài SP của mình để phân tích và minh họa giao dịch; không mô tả nhầm chúng đã có cùng cờ COMMIT của 5 file này.

Concurrency thu cùng hóa đơn: **TV2 chủ trì, TV1 chạy phiên còn lại và đối chiếu audit/receipt; TV3/TV4 phối hợp giải thích khóa và rowversion**. Không bỏ trống người trình bày mục 3.4.

## TV1 — Tài khoản, xác thực, phiên đăng nhập và nhật ký

**Mục tiêu:** giải thích một người được nhận diện thế nào, SQL xác định actor và vai trò ra sao, phiên hết hiệu lực lúc nào, thao tác được ghi lại và tra cứu sau mất phản hồi như thế nào.

|Nhóm|Object phụ trách|
|---|---|
|4 bảng|`Account`, `AuthSession`, `AuditLog`, `ReplayOperation`|
|12 SP tài khoản/phiên|`usp_StudentSignup`, `usp_LoginRead`, `usp_LoginRecord`, `usp_CurrentSession`, `usp_SessionTouch`, `usp_Logout`, `usp_PasswordChange`, `usp_ProfileUpdate`, `usp_AccountCreateStaff`, `usp_AccountSetStatus`, `usp_AccountResetPassword`, `usp_AdminAccountList`|
|4 SP vận hành/tra cứu|`usp_AuditList`, `usp_ReplayLookup`, `usp_OperatorBootstrap`, `usp_MaintenanceCleanup`|
|2 SP hạ tầng|`usp_SecuritySession`, `usp_PasswordSnapshot`|
|1 function|`fn_ActionRootKind`|
|1 view|`v_AuditSafe`|
|3 trigger|`tr_Account_Guard`, `tr_Audit_Integrity`, `tr_Replay_Integrity`|

**Luồng học:** Student signup → đăng nhập → kiểm phiên/role → thao tác nghiệp vụ → AuditLog/ReplayOperation → logout hoặc hết hạn. Luồng nhân sự: Admin tạo tài khoản → mật khẩu tạm → đổi mật khẩu → vào nghiệp vụ.

**Transaction được giao rõ:** `usp_ProfileUpdate`, `usp_AccountCreateStaff`, `usp_AccountSetStatus`, `usp_AccountResetPassword`.

**Hai bài trọng tâm:** [usp_AccountCreateStaff](../../database/practice/stored-procedures/usp_AccountCreateStaff.sql) và [usp_AccountSetStatus](../../database/practice/stored-procedures/usp_AccountSetStatus.sql). Chuẩn bị cách giải thích tính nguyên tử, lỗi giữa chừng, audit/receipt và trước/sau ROLLBACK; phần COMMIT nằm trong scope SQL của SP khi nó là owner.

**Phải giải thích được:**

1. Mật khẩu được hash ở C#; SQL lưu hash, phiên và trạng thái. Không chuyển việc hash sang SQL hoặc đưa hash/SID ra browser.
2. SQL user theo role và tài khoản người thật là hai lớp khác nhau. `usp_SecuritySession` kiểm phiên, epoch, trạng thái account, role ứng dụng và native SQL role; actor không do browser tự chọn.
3. Bảy role nghiệp vụ bị DENY bảng trực tiếp, được EXECUTE đúng SP; quyền EXECUTE vẫn cần kiểm ownership bên trong SP.
4. Bảng điểm có quyết định dựa trên AuditLog, còn ReplayOperation gắn actor/action/request/digest để nhận diện lệnh đã xử lý. Tra cứu kết quả không phải tự gửi lại lệnh.
5. Bootstrap và maintenance là nghiệp vụ operator, không phải chức năng web Admin thông thường. Không chạy cleanup để thử trên phiên đang dùng của owner.

**Bài thực hành trên fixture riêng:** đăng nhập đúng/sai; nhân sự chưa đổi mật khẩu tạm; phiên hết hạn/sai epoch; gọi chức năng ngoài role; tra cứu receipt của chính actor; chứng minh không đọc được receipt của người khác. Với mỗi ca, chỉ rõ lớp chặn là quyền SQL, SP hay trigger.

**Nguồn:** [schema](../../database/dbms12-compact/tables/01_schema.sql), [functions](../../database/dbms12-compact/functions/02_functions.sql), [views](../../database/dbms12-compact/views/03_views.sql), [triggers](../../database/dbms12-compact/triggers/05_triggers.sql), [SP tài khoản](../../database/dbms12-compact/stored-procedures/operations/), [security session](../../database/dbms12-compact/stored-procedures/infrastructure/session.sql), [password snapshot](../../database/dbms12-compact/stored-procedures/infrastructure/password.sql), [phân quyền](../SQL_SECURITY.md), [ma trận SP](../SQL_SECURITY_MATRIX.md).

## TV2 — Đăng ký, tuyển sinh, học phí và báo cáo

**Mục tiêu:** theo sát một hồ sơ từ đăng ký đến đủ điều kiện tài chính để xếp lớp; giải thích các nhánh kết thúc, hóa đơn, thu tiền và số liệu báo cáo.

|Nhóm|Object phụ trách|
|---|---|
|2 bảng|`Registration`, `Invoice`|
|7 SP hồ sơ|`usp_RegistrationCreate`, `usp_RegistrationConfirm`, `usp_RegistrationCancelOwn`, `usp_RegistrationList`, `usp_AdmissionApprove`, `usp_AdmissionReject`, `usp_AdmissionCancel`|
|4 SP hóa đơn|`usp_InvoiceCollect`, `usp_InvoiceCorrect`, `usp_InvoiceRead`, `usp_InvoiceSearch`|
|3 SP báo cáo|`usp_FinanceReport`, `usp_FinanceExport`, `usp_DirectorReport`|
|1 SP hạ tầng|`usp_RecordFailure`|
|3 function|`fn_RegistrationUnfinished`, `fn_InvoiceDueDate`, `fn_InvoiceDebtFlags`|
|3 view|`v_RegistrationFacts`, `v_InvoiceFacts`, `v_DirectorAggregate`|
|2 trigger|`tr_Registration_State`, `tr_Invoice_Integrity`|
|1 sequence|`InvoiceNumberSequence`|

**Luồng học:** Student tạo PENDING → Student CONFIRMED → Admissions ADMITTED đồng thời tạo Invoice → Accountant thu đủ → bàn giao hồ sơ đã trả tiền cho TV3 xếp lớp.

**Transaction được giao rõ:** `usp_RegistrationCreate`, `usp_RegistrationConfirm`, `usp_RegistrationCancelOwn`, `usp_AdmissionApprove`, `usp_AdmissionReject`, `usp_AdmissionCancel`, `usp_InvoiceCollect`, `usp_InvoiceCorrect`.

**Hai bài trọng tâm:** [usp_AdmissionApprove](../../database/practice/stored-procedures/usp_AdmissionApprove.sql) và [usp_InvoiceCollect](../../database/practice/stored-procedures/usp_InvoiceCollect.sql). Chuẩn bị cách giải thích tính nguyên tử, lỗi giữa chừng, audit/receipt và trước/sau ROLLBACK; phần COMMIT nằm trong scope SQL của SP khi nó là owner.

**Phải giải thích được:**

1. Hồ sơ được xác nhận bởi ai; Admissions có thể duyệt/từ chối/hủy ở trạng thái nào; REJECTED/CANCELLED khác hồ sơ đang xử lý thế nào. Lần theo trigger thay vì đoán từ tên nút.
2. Duyệt và tạo hóa đơn nằm trong cùng giao dịch: không được chỉ ADMITTED mà không có hóa đơn khi thao tác chưa thành công trọn vẹn.
3. Một hóa đơn/hồ sơ, thu đủ một lần; sửa metadata thanh toán có lý do không có nghĩa được thay amount. Phân biệt invoice_status, due_date và debt_flag được suy ra.
4. Sequence cấp số có thể có khoảng trống; không xem số hóa đơn liên tục là điều kiện chứng minh không mất giao dịch.
5. `fn_RegistrationUnfinished` tham chiếu việc hoàn thành/chốt kết quả ở cụm TV4; một hồ sơ ADMITTED chưa chắc đã là học xong.
6. Finance report và Director report có phạm vi khác nhau; Director không được xem tùy ý dữ liệu tài khoản hoặc sửa nghiệp vụ.

**SP hạ tầng được giao kèm:** `usp_RecordFailure` phục vụ toàn hệ thống, không riêng kế toán. TV2 minh họa bằng ca thu tiền sai: business transaction rollback trước; executor mới gọi thủ tục ghi FAILURE/DENIED bằng giao dịch riêng. Đối chiếu với cách TV1 bảo vệ AuditLog; không gọi log FAILURE giả cho một commit chưa rõ kết quả.

**Bài thực hành trên fixture riêng:** đăng ký trùng hồ sơ chưa kết thúc; duyệt PENDING bị chặn; duyệt CONFIRMED thành công và có đúng một hóa đơn; thu sai/thu lại bị từ chối; đối chiếu tổng báo cáo từ hóa đơn; phân biệt hồ sơ hủy và công nợ. Bàn giao invoice PAID/registration ADMITTED cho TV3.

**Nguồn:** [schema/sequence](../../database/dbms12-compact/tables/01_schema.sql), [FN](../../database/dbms12-compact/functions/02_functions.sql), [view](../../database/dbms12-compact/views/03_views.sql), [trigger](../../database/dbms12-compact/triggers/05_triggers.sql), [SP lõi đăng ký/duyệt/thu tiền](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql), [SP còn lại](../../database/dbms12-compact/stored-procedures/operations/), [failure log](../../database/dbms12-compact/stored-procedures/infrastructure/failure.sql), [executor giao dịch](../../backend/EnglishCenter.Dbms12/Data/CompactSqlExecutor.cs).

## TV3 — Khóa học, lớp, xếp lớp và lập lịch

**Mục tiêu:** chuẩn bị lớp có khóa, giáo viên, chỗ học và lịch hợp lệ; nhận hồ sơ đã trả tiền từ TV2; biết tại sao không mở/bắt đầu/hoàn thành được lớp.

|Nhóm|Object phụ trách|
|---|---|
|4 bảng|`Course`, `Class`, `StudentClassAssignment`, `Schedule`|
|3 SP khóa học|`usp_CourseCreate`, `usp_CourseUpdate`, `usp_CourseList`|
|7 SP lớp|`usp_ClassCreate`, `usp_ClassEdit`, `usp_ClassOpen`, `usp_ClassStart`, `usp_ClassComplete`, `usp_ClassCancel`, `usp_ClassList`|
|2 SP xếp lớp/giáo viên|`usp_PlacementCreate`, `usp_TeacherOptions`|
|2 SP lập lịch|`usp_ScheduleBatch`, `usp_WeeklySchedulePreview`|
|1 function|`fn_ClassProgress`|
|2 view|`v_CurrentSchedule`, `v_ClassProgress`|
|4 trigger|`tr_Course_Freeze`, `tr_Class_Lifecycle`, `tr_Assignment_Eligibility`, `tr_Schedule_Guard`|
|1 TVP|`ScheduleBatch`|

**Luồng học:** tạo Course → tạo Class PLANNED → lập lịch → OPEN → xếp học viên đã ADMITTED/PAID → đủ điều kiện ONGOING → nhận điểm danh/HELD từ TV4 → COMPLETED.

**Transaction được giao rõ:** `usp_CourseCreate`, `usp_CourseUpdate`, `usp_ClassCreate`, `usp_ClassEdit`, `usp_ClassOpen`, `usp_ClassStart`, `usp_ClassComplete`, `usp_ClassCancel`, `usp_PlacementCreate`, `usp_ScheduleBatch`.

**Hai bài trọng tâm:** [usp_PlacementCreate](../../database/practice/stored-procedures/usp_PlacementCreate.sql) và [usp_ScheduleBatch](../../database/practice/stored-procedures/usp_ScheduleBatch.sql). Chuẩn bị cách giải thích tính nguyên tử, lỗi giữa chừng, audit/receipt và trước/sau ROLLBACK; phần COMMIT nằm trong scope SQL của SP khi nó là owner.

**Phải giải thích được:**

1. Course đóng băng những cấu hình nào khi đã có lớp; không coi chỉnh khóa đã sử dụng giống tạo khóa mới.
2. Điều kiện OPEN và ONGOING khác nhau. Theo trigger hiện tại, OPEN cần khóa/giáo viên hoạt động và có LESSON tương lai; bắt đầu ONGOING mới kiểm đủ số LESSON, đúng một FINAL_EXAM, có học viên và đã đến thời điểm buổi học đầu.
3. Xếp lớp cần ADMITTED, PAID, lớp OPEN cùng khóa, còn chỗ và không trùng lịch. Đổi classId không được dùng để vượt các điều kiện này.
4. Phát hiện trùng theo khoảng thời gian, xét lớp/phòng/giáo viên/học viên; hai khoảng nối đuôi không phải chồng lấn.
5. Preview lịch chưa ghi dữ liệu. TVP cho phép SP lưu cả lô; một dòng lỗi không được làm lưu dở một phần lịch.
6. Hoàn thành cần đủ LESSON/một EXAM, tất cả buổi đã HELD và không thiếu điểm danh. `fn_ClassProgress` chỉ tính LESSON đã HELD; đạt 100% không thay thế toàn bộ điều kiện hoàn thành.

**Bài thực hành trên fixture riêng:** mở lớp chưa có buổi tương lai; bắt đầu khi thiếu kỳ thi/chưa có học viên/chưa tới buổi đầu; xếp lớp chưa trả tiền; lịch trùng phòng/giáo viên/học viên; thiếu HELD hoặc thiếu điểm danh khi hoàn thành. Nhờ TV4 giải thích dữ liệu còn thiếu bằng `v_ClassProgress`.

**Nguồn:** [schema](../../database/dbms12-compact/tables/01_schema.sql), [FN](../../database/dbms12-compact/functions/02_functions.sql), [view](../../database/dbms12-compact/views/03_views.sql), [ScheduleBatch](../../database/dbms12-compact/types/04_types.sql), [trigger](../../database/dbms12-compact/triggers/05_triggers.sql), [placement/lịch lô](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql), [SP lớp/khóa/preview](../../database/dbms12-compact/stored-procedures/operations/).

## TV4 — Tổ chức buổi học, điểm danh, bảng điểm và kết quả

**Mục tiêu:** vận hành các buổi học đã được TV3 lập lịch, cập nhật điểm danh/điểm đúng giáo viên, phối hợp hoàn thành lớp và đi tới kết quả công bố cho học viên.

|Nhóm|Object phụ trách|
|---|---|
|2 bảng|`Attendance`, `GradeReport`|
|3 SP vận hành lịch|`usp_ScheduleList`, `usp_ScheduleMove`, `usp_ScheduleHeld`|
|3 SP điểm danh/roster|`usp_AttendanceRead`, `usp_AttendanceSave`, `usp_ClassRoster`|
|4 SP bảng điểm|`usp_GradeSave`, `usp_GradeSubmit`, `usp_GradeReturn`, `usp_GradeFinalize`|
|2 SP kết quả/học viên|`usp_StudentGrades`, `usp_StudentHome`|
|2 SP hạ tầng|`usp_BeginRead`, `usp_BeginWrite`|
|2 function|`fn_ValidScore`, `fn_GradeTotal`|
|3 view|`v_ClassState`, `v_ClassRoster`, `v_FinalizedGrades`|
|3 trigger|`tr_Attendance_Guard`, `tr_GradeReport_Guard`, `tr_Class_GradeDecision`|
|2 TVP|`AttendanceBatch`, `GradeManifest`|

**Luồng học:** ONGOING → Teacher điểm danh → AcademicAffairs xác nhận HELD → TV3 hoàn thành lớp → Teacher gửi cả bảng điểm → AcademicAffairs trả lại hoặc chốt → Student xem kết quả FINALIZED.

**Transaction được giao rõ:** `usp_ScheduleMove`, `usp_ScheduleHeld`, `usp_AttendanceSave`, `usp_GradeSave`, `usp_GradeSubmit`, `usp_GradeReturn`, `usp_GradeFinalize`.

**Hai bài trọng tâm:** [usp_AttendanceSave](../../database/practice/stored-procedures/usp_AttendanceSave.sql) và [usp_GradeFinalize](../../database/practice/stored-procedures/usp_GradeFinalize.sql). Chuẩn bị cách giải thích tính nguyên tử, lỗi giữa chừng, audit/receipt và trước/sau ROLLBACK; phần COMMIT nằm trong scope SQL của SP khi nó là owner.

**Phải giải thích được:**

1. Đã hết giờ không tự thành HELD. Điểm danh ghi có mặt/vắng; HELD ghi buổi thực tế đã tổ chức. Hai dữ liệu phục vụ hai điều kiện khác nhau.
2. Teacher chỉ thao tác lớp phụ trách; Student chỉ xem của mình. Phải kiểm native role, ownership và trạng thái, không chỉ nút có hiện hay không.
3. NULL khác điểm0; chưa điểm danh khác vắng. Điểm cuối khóa chỉ nhập sau giờ thi; chỉ nhập/sửa khi lớp và bảng điểm còn cho phép.
4. Tổng điểm tính theo trọng số và làm tròn; điểm tổng dưới50 là không đạt, không phải lý do cấm chốt một bảng điểm đã đủ dữ liệu.
5. Grade state suy ra qua quyết định AuditLog của Class; `v_ClassState` không phải một cột grade_status lưu độc lập trong Class.
6. Gửi/chốt cho toàn lớp cần COMPLETED, đủ hai điểm của mọi học viên, manifest đủ và phiên bản đúng; thiếu một người cũng bị chặn. FINALIZED không sửa lại.
7. `usp_StudentHome` tổng hợp cả chuỗi tuyển sinh → học phí → xếp lớp → kết quả. TV4 trình bày màn hình kết thúc và nhờ TV2/TV3 đối chiếu các trạng thái đầu vào.

**SP hạ tầng được giao kèm:** `usp_BeginRead` và `usp_BeginWrite` dùng toàn hệ thống, không riêng điểm. Theo D15, hai SP tự BEGIN/COMMIT/ROLLBACK nếu vào chưa có giao dịch, hoặc lấy khóa dùng chung/độc quyền trên Course trong transaction của caller. Khóa của lời gọi độc lập được trả khi helper COMMIT; muốn giữ khóa cho nhiều thao tác phải có caller transaction. TV4 minh họa hai thao tác điểm danh/gửi bảng điểm đồng thời; cả nhóm đọc [SQL_TRANSACTIONS](SQL_TRANSACTIONS.md) và executor để hiểu ownership/cleanup/REVERT.

**Bài thực hành trên fixture riêng:** giáo viên khác lớp; chưa nhập điểm cuối kỳ khi kỳ thi chưa kết thúc; gửi khi lớp ONGOING; manifest thiếu/cũ; thiếu một cột điểm; gửi → trả lại có lý do → sửa → gửi lại → chốt; Student không thấy bản nháp nhưng thấy FINALIZED. Một ca mất ACK cần phối hợp TV1 lookup trước khi quyết định bước tiếp theo.

**Nguồn:** [schema](../../database/dbms12-compact/tables/01_schema.sql), [FN](../../database/dbms12-compact/functions/02_functions.sql), [view](../../database/dbms12-compact/views/03_views.sql), [TVP](../../database/dbms12-compact/types/04_types.sql), [triggers](../../database/dbms12-compact/triggers/05_triggers.sql), [score validation](../../database/dbms12-compact/functions/06_score_validation.sql), [SP điểm/điểm danh](../../database/dbms12-compact/stored-procedures/core/07_core_procedures.sql), [SP lịch/roster/kết quả](../../database/dbms12-compact/stored-procedures/operations/), [begin read](../../database/dbms12-compact/stored-procedures/infrastructure/begin-read.sql), [begin write](../../database/dbms12-compact/stored-procedures/infrastructure/begin-write.sql).

## Cách học chung và phối hợp trình bày

1. **Cả nhóm đọc mô hình:** 12 bảng, quan hệ và chuỗi từ đăng ký đến kết quả; nắm bảy role thật và sự khác biệt role ứng dụng/SQL user/người dùng.
2. **Mỗi người đọc một luồng trọn vẹn:** đầu vào, actor, trạng thái trước/sau, SP, bảng, FN/view, trigger, constraints, audit/receipt và lỗi. Không học thuộc tên object mà không biết thao tác nào gọi nó.
3. **Mỗi người chuẩn bị cùng bộ đầu ra:** một sơ đồ luồng; một bảng điều kiện; một ca hợp lệ; hai ca từ chối; một câu hỏi giao thoa với người khác. Ghi dự kiến trước, chỉ ghi PASS khi đã chạy thật trên fixture được giao.
4. **Diễn tập chuỗi:** TV1 cung cấp phiên/tài khoản → TV2 nhập học và thu tiền → TV3 lập lớp/xếp lớp → TV4 điểm danh/điểm → TV3 hoàn thành → TV4 gửi/chốt → TV1 đối chiếu audit và TV2 đối chiếu báo cáo.

|Điểm bàn giao|Người phối hợp|Điều cần thống nhất|
|---|---|---|
|Duyệt hồ sơ → xếp lớp|TV2 → TV3|Registration ADMITTED + Invoice PAID, cùng khóa|
|Lập lịch → tổ chức|TV3 → TV4|Schedule_id, LESSON/FINAL_EXAM, giờ Việt Nam/UTC, phòng, rowversion|
|Đã học → hoàn thành|TV4 → TV3|Không thiếu điểm danh, mọi buổi gồm kỳ thi đều HELD|
|Hoàn thành → gửi điểm|TV3 → TV4|COMPLETED, đầy đủ điểm/manifest, bản nháp hoặc trả lại|
|Mọi thao tác → audit/receipt|TV1 ↔ cả nhóm|Actor/action/root/UUID/digest; rollback và unknown khác nhau|
|Nghiệp vụ bị từ chối → failure log|TV2 ↔ TV1/TV4|Rollback business trước, log failure riêng; không ghi thất bại giả sau commit chưa rõ|

Không sửa quyền SQL hoặc reset DB hiện tại để làm bài thực hành. Dùng môi trường/fixture được chủ máy giao; đây là danh sách bài học, không phải biên bản các ca đã thực hiện.

## Đối chiếu số lượng

Danh sách máy đọc được: [DATABASE_OBJECTS_4_MEMBERS.json](DATABASE_OBJECTS_4_MEMBERS.json). Chạy từ root:

```powershell
node tools/Verify-Source.cjs
node tools/Verify-StudyAssignment.cjs
```

Verifier đọc đúng installOrder, xác nhận đủ105object, không trùng/thiếu/tên giả, số lượng27/26/26/26; thêm kiểm29command transaction đủ/unique/đúng người phụ trách SP, 2primarydemos/người, 5file COMMIT và concurrency có người phụ trách. Đây là kiểm tài liệu; chưa phải kiểm các bài thực hành trên database.
