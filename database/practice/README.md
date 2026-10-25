# Bài chạy riêng — SQL Server

[Hướng dẫn SSMS/CLI](../../docs/study/SQL_LEARNING_START.md) · [Rubric3.1–3.5](../../docs/study/RUBRIC_SQL_SERVER.md) · [Định nghĩa105 object](../dbms12-compact/OBJECT_INDEX.md)

Có107 bài. Mở SSMS_SESSION.sql do tools/Invoke-SqlLearning.ps1 -Prepare tạo, chạy một lần trên query window của **fixture**, sau đó chọn một file dưới đây để chạy toàn bộ bằng F5. Không cần SQLCMD Mode. Mặc định rollback; negative case PASS khi bị từ chối đúng lỗi.

|Nhóm|Số bài|
|---|---|
|[7 Function](#functions)|7|
|[9 View](#views)|9|
|[61 Stored Procedure](#stored-procedures)|61|
|[12 Trigger](#triggers)|12|
|[6 bài constraint](#constraints)|6|
|[Phân quyền](#security)|2|
|[5 nghiệp vụ transaction](#transactions)|5|
|[5 bài đo index](#indexes)|5|

<a id="functions"></a>

## 7 Function

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[fn_GradeTotal](functions/fn_GradeTotal.sql)|Chạy và rollback|[source](../dbms12-compact/functions/02_functions.sql#L5)|
|[fn_InvoiceDueDate](functions/fn_InvoiceDueDate.sql)|Chạy và rollback|[source](../dbms12-compact/functions/02_functions.sql#L14)|
|[fn_ValidScore](functions/fn_ValidScore.sql)|Chạy và rollback|[source](../dbms12-compact/functions/06_score_validation.sql#L4)|
|[fn_ActionRootKind](functions/fn_ActionRootKind.sql)|Chạy và rollback|[source](../dbms12-compact/functions/02_functions.sql#L60)|
|[fn_RegistrationUnfinished](functions/fn_RegistrationUnfinished.sql)|Chạy và rollback|[source](../dbms12-compact/functions/02_functions.sql#L21)|
|[fn_ClassProgress](functions/fn_ClassProgress.sql)|Chạy và rollback|[source](../dbms12-compact/functions/02_functions.sql#L36)|
|[fn_InvoiceDebtFlags](functions/fn_InvoiceDebtFlags.sql)|Chạy và rollback|[source](../dbms12-compact/functions/02_functions.sql#L47)|

<a id="views"></a>

## 9 View

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[v_ClassState](views/v_ClassState.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L5)|
|[v_RegistrationFacts](views/v_RegistrationFacts.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L15)|
|[v_CurrentSchedule](views/v_CurrentSchedule.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L22)|
|[v_ClassRoster](views/v_ClassRoster.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L28)|
|[v_FinalizedGrades](views/v_FinalizedGrades.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L36)|
|[v_InvoiceFacts](views/v_InvoiceFacts.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L48)|
|[v_ClassProgress](views/v_ClassProgress.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L56)|
|[v_DirectorAggregate](views/v_DirectorAggregate.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L68)|
|[v_AuditSafe](views/v_AuditSafe.sql)|Chạy và rollback|[source](../dbms12-compact/views/03_views.sql#L70)|

<a id="stored-procedures"></a>

## 61 Stored Procedure

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[usp_CourseCreate](stored-procedures/usp_CourseCreate.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_CourseCreate.sql#L1)|
|[usp_CourseUpdate](stored-procedures/usp_CourseUpdate.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_CourseUpdate.sql#L1)|
|[usp_RegistrationCreate](stored-procedures/usp_RegistrationCreate.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L2)|
|[usp_RegistrationConfirm](stored-procedures/usp_RegistrationConfirm.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_RegistrationConfirm.sql#L1)|
|[usp_RegistrationCancelOwn](stored-procedures/usp_RegistrationCancelOwn.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_RegistrationCancelOwn.sql#L1)|
|[usp_AdmissionReject](stored-procedures/usp_AdmissionReject.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AdmissionReject.sql#L1)|
|[usp_AdmissionCancel](stored-procedures/usp_AdmissionCancel.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AdmissionCancel.sql#L1)|
|[usp_AdmissionApprove](stored-procedures/usp_AdmissionApprove.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L60)|
|[usp_InvoiceCollect](stored-procedures/usp_InvoiceCollect.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L119)|
|[usp_InvoiceCorrect](stored-procedures/usp_InvoiceCorrect.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_InvoiceCorrect.sql#L1)|
|[usp_ClassCreate](stored-procedures/usp_ClassCreate.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassCreate.sql#L1)|
|[usp_ClassEdit](stored-procedures/usp_ClassEdit.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassEdit.sql#L1)|
|[usp_ClassOpen](stored-procedures/usp_ClassOpen.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassOpen.sql#L1)|
|[usp_ClassStart](stored-procedures/usp_ClassStart.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassStart.sql#L1)|
|[usp_ClassComplete](stored-procedures/usp_ClassComplete.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassComplete.sql#L1)|
|[usp_ClassCancel](stored-procedures/usp_ClassCancel.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassCancel.sql#L1)|
|[usp_PlacementCreate](stored-procedures/usp_PlacementCreate.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L183)|
|[usp_ScheduleBatch](stored-procedures/usp_ScheduleBatch.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L246)|
|[usp_ScheduleMove](stored-procedures/usp_ScheduleMove.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L307)|
|[usp_ScheduleHeld](stored-procedures/usp_ScheduleHeld.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ScheduleHeld.sql#L1)|
|[usp_AttendanceSave](stored-procedures/usp_AttendanceSave.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L377)|
|[usp_GradeSave](stored-procedures/usp_GradeSave.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L449)|
|[usp_GradeSubmit](stored-procedures/usp_GradeSubmit.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L522)|
|[usp_GradeReturn](stored-procedures/usp_GradeReturn.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L589)|
|[usp_GradeFinalize](stored-procedures/usp_GradeFinalize.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L660)|
|[usp_ProfileUpdate](stored-procedures/usp_ProfileUpdate.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ProfileUpdate.sql#L1)|
|[usp_AccountCreateStaff](stored-procedures/usp_AccountCreateStaff.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AccountCreateStaff.sql#L1)|
|[usp_AccountSetStatus](stored-procedures/usp_AccountSetStatus.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AccountSetStatus.sql#L1)|
|[usp_AccountResetPassword](stored-procedures/usp_AccountResetPassword.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AccountResetPassword.sql#L1)|
|[usp_StudentSignup](stored-procedures/usp_StudentSignup.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_StudentSignup.sql#L1)|
|[usp_LoginRead](stored-procedures/usp_LoginRead.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_LoginRead.sql#L1)|
|[usp_LoginRecord](stored-procedures/usp_LoginRecord.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_LoginRecord.sql#L1)|
|[usp_SessionTouch](stored-procedures/usp_SessionTouch.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_SessionTouch.sql#L1)|
|[usp_Logout](stored-procedures/usp_Logout.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_Logout.sql#L1)|
|[usp_PasswordChange](stored-procedures/usp_PasswordChange.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_PasswordChange.sql#L1)|
|[usp_MaintenanceCleanup](stored-procedures/usp_MaintenanceCleanup.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_MaintenanceCleanup.sql#L1)|
|[usp_OperatorBootstrap](stored-procedures/usp_OperatorBootstrap.sql)|Từ chối đúng lỗi 51236|[source](../dbms12-compact/stored-procedures/operations/usp_OperatorBootstrap.sql#L1)|
|[usp_CurrentSession](stored-procedures/usp_CurrentSession.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_CurrentSession.sql#L1)|
|[usp_CourseList](stored-procedures/usp_CourseList.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_CourseList.sql#L1)|
|[usp_RegistrationList](stored-procedures/usp_RegistrationList.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_RegistrationList.sql#L1)|
|[usp_InvoiceRead](stored-procedures/usp_InvoiceRead.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_InvoiceRead.sql#L1)|
|[usp_ClassList](stored-procedures/usp_ClassList.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassList.sql#L1)|
|[usp_ClassRoster](stored-procedures/usp_ClassRoster.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ClassRoster.sql#L1)|
|[usp_ScheduleList](stored-procedures/usp_ScheduleList.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ScheduleList.sql#L1)|
|[usp_StudentGrades](stored-procedures/usp_StudentGrades.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_StudentGrades.sql#L1)|
|[usp_ReplayLookup](stored-procedures/usp_ReplayLookup.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_ReplayLookup.sql#L1)|
|[usp_AdminAccountList](stored-procedures/usp_AdminAccountList.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AdminAccountList.sql#L1)|
|[usp_AuditList](stored-procedures/usp_AuditList.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AuditList.sql#L1)|
|[usp_FinanceReport](stored-procedures/usp_FinanceReport.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_FinanceReport.sql#L1)|
|[usp_DirectorReport](stored-procedures/usp_DirectorReport.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_DirectorReport.sql#L1)|
|[usp_InvoiceSearch](stored-procedures/usp_InvoiceSearch.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_InvoiceSearch.sql#L1)|
|[usp_AttendanceRead](stored-procedures/usp_AttendanceRead.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_AttendanceRead.sql#L1)|
|[usp_TeacherOptions](stored-procedures/usp_TeacherOptions.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_TeacherOptions.sql#L1)|
|[usp_WeeklySchedulePreview](stored-procedures/usp_WeeklySchedulePreview.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_WeeklySchedulePreview.sql#L1)|
|[usp_FinanceExport](stored-procedures/usp_FinanceExport.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_FinanceExport.sql#L1)|
|[usp_StudentHome](stored-procedures/usp_StudentHome.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/operations/usp_StudentHome.sql#L1)|
|[usp_BeginRead](stored-procedures/usp_BeginRead.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/infrastructure/begin-read.sql#L1)|
|[usp_BeginWrite](stored-procedures/usp_BeginWrite.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/infrastructure/begin-write.sql#L1)|
|[usp_SecuritySession](stored-procedures/usp_SecuritySession.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/infrastructure/session.sql#L1)|
|[usp_PasswordSnapshot](stored-procedures/usp_PasswordSnapshot.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/infrastructure/password.sql#L1)|
|[usp_RecordFailure](stored-procedures/usp_RecordFailure.sql)|Chạy và rollback|[source](../dbms12-compact/stored-procedures/infrastructure/failure.sql#L1)|

<a id="triggers"></a>

## 12 Trigger

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[tr_Account_Guard](triggers/tr_Account_Guard.sql)|Từ chối đúng lỗi 51102|[source](../dbms12-compact/triggers/05_triggers.sql#L5)|
|[tr_Course_Freeze](triggers/tr_Course_Freeze.sql)|Từ chối đúng lỗi 51107|[source](../dbms12-compact/triggers/05_triggers.sql#L28)|
|[tr_Registration_State](triggers/tr_Registration_State.sql)|Từ chối đúng lỗi 51111|[source](../dbms12-compact/triggers/05_triggers.sql#L40)|
|[tr_Class_Lifecycle](triggers/tr_Class_Lifecycle.sql)|Từ chối đúng lỗi 51122|[source](../dbms12-compact/triggers/05_triggers.sql#L69)|
|[tr_Class_GradeDecision](triggers/tr_Class_GradeDecision.sql)|Từ chối đúng lỗi 51127|[source](../dbms12-compact/triggers/05_triggers.sql#L130)|
|[tr_Assignment_Eligibility](triggers/tr_Assignment_Eligibility.sql)|Từ chối đúng lỗi 51128|[source](../dbms12-compact/triggers/05_triggers.sql#L149)|
|[tr_Schedule_Guard](triggers/tr_Schedule_Guard.sql)|Từ chối đúng lỗi 51131|[source](../dbms12-compact/triggers/05_triggers.sql#L176)|
|[tr_Attendance_Guard](triggers/tr_Attendance_Guard.sql)|Từ chối đúng lỗi 51137|[source](../dbms12-compact/triggers/05_triggers.sql#L218)|
|[tr_GradeReport_Guard](triggers/tr_GradeReport_Guard.sql)|Từ chối đúng lỗi 51139|[source](../dbms12-compact/triggers/05_triggers.sql#L232)|
|[tr_Invoice_Integrity](triggers/tr_Invoice_Integrity.sql)|Từ chối đúng lỗi 51146|[source](../dbms12-compact/triggers/05_triggers.sql#L249)|
|[tr_Audit_Integrity](triggers/tr_Audit_Integrity.sql)|Từ chối đúng lỗi 51147|[source](../dbms12-compact/triggers/05_triggers.sql#L266)|
|[tr_Replay_Integrity](triggers/tr_Replay_Integrity.sql)|Từ chối đúng lỗi 51152|[source](../dbms12-compact/triggers/05_triggers.sql#L294)|

<a id="constraints"></a>

## 6 bài constraint

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[Course_Tuition_CHECK](constraints/Course_Tuition_CHECK.sql)|Từ chối đúng lỗi 547|Xem chú thích trong bài|
|[Course_Weight_CHECK](constraints/Course_Weight_CHECK.sql)|Từ chối đúng lỗi 547|Xem chú thích trong bài|
|[Account_Phone_CHECK](constraints/Account_Phone_CHECK.sql)|Từ chối đúng lỗi 547|Xem chú thích trong bài|
|[Course_Code_UNIQUE](constraints/Course_Code_UNIQUE.sql)|Từ chối đúng lỗi 2627|Xem chú thích trong bài|
|[Course_Status_DEFAULT](constraints/Course_Status_DEFAULT.sql)|Chạy và rollback|Xem chú thích trong bài|
|[Registration_Student_FK](constraints/Registration_Student_FK.sql)|Từ chối đúng lỗi 547|Xem chú thích trong bài|

<a id="security"></a>

## Phân quyền

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[GRANT_REVOKE_DENY](security/GRANT_REVOKE_DENY.sql)|Chạy và rollback|Xem chú thích trong bài|
|[Student_Direct_Table_Denied](security/Student_Direct_Table_Denied.sql)|Từ chối đúng lỗi 229|Xem chú thích trong bài|

<a id="transactions"></a>

## 5 nghiệp vụ transaction

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[usp_CourseCreate](transactions/usp_CourseCreate.sql)|Rollback mặc định; commit/forced rollback có tùy chọn|[source](../dbms12-compact/stored-procedures/operations/usp_CourseCreate.sql#L1)|
|[usp_RegistrationCreate](transactions/usp_RegistrationCreate.sql)|Rollback mặc định; commit/forced rollback có tùy chọn|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L2)|
|[usp_AdmissionApprove](transactions/usp_AdmissionApprove.sql)|Rollback mặc định; commit/forced rollback có tùy chọn|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L60)|
|[usp_InvoiceCollect](transactions/usp_InvoiceCollect.sql)|Rollback mặc định; commit/forced rollback có tùy chọn|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L119)|
|[usp_PlacementCreate](transactions/usp_PlacementCreate.sql)|Rollback mặc định; commit/forced rollback có tùy chọn|[source](../dbms12-compact/stored-procedures/core/07_core_procedures.sql#L183)|

<a id="indexes"></a>

## 5 bài đo index

|Bài thực hành|Kỳ vọng|Định nghĩa thật|
|---|---|---|
|[IX_Registration_StudentCourse](indexes/IX_Registration_StudentCourse.sql)|Chạy và rollback|[Lý do và đo](../../docs/study/SQL_INDEXES.md)|
|[IX_Class_TeacherStatus](indexes/IX_Class_TeacherStatus.sql)|Chạy và rollback|[Lý do và đo](../../docs/study/SQL_INDEXES.md)|
|[IX_Schedule_ClassStart](indexes/IX_Schedule_ClassStart.sql)|Chạy và rollback|[Lý do và đo](../../docs/study/SQL_INDEXES.md)|
|[IX_Invoice_Issued](indexes/IX_Invoice_Issued.sql)|Chạy và rollback|[Lý do và đo](../../docs/study/SQL_INDEXES.md)|
|[IX_Audit_Time](indexes/IX_Audit_Time.sql)|Chạy và rollback|[Lý do và đo](../../docs/study/SQL_INDEXES.md)|

Các bài auth capture dữ liệu nhạy cảm vào temp table và chỉ hiển thị projection an toàn. Bootstrap minh họa từ chối khi đã có account; ClassStart chờ16giây đến giờ học thật. Không xóa account hoặc giả thời gian để ép chạy. Transaction trong nguồn ứng dụng vẫn thuộc61SP. Những bài này không nằm trong manifest.installOrder và không tự chạy khi khởi động web.
