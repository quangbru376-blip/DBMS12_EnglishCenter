# Danh mục105 Database Object

Sinh từ `manifest.installOrder` bằng `node tools/Generate-SqlStudyIndex.cjs`. Mỗi liên kết trỏ vào định nghĩa source thật; không có bản SQL sao chép để học. Một số file chứa nhiều object để giữ nguyên thứ tự/phụ thuộc cài đặt.

[Bắt đầu ở README](README.md) · [Học transaction](../../docs/study/SQL_TRANSACTIONS.md)

## Bảng — 12

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `Account` | [tables/01_schema.sql:11](tables/01_schema.sql#L11) | — |
| `AuthSession` | [tables/01_schema.sql:41](tables/01_schema.sql#L41) | — |
| `Course` | [tables/01_schema.sql:51](tables/01_schema.sql#L51) | — |
| `Registration` | [tables/01_schema.sql:70](tables/01_schema.sql#L70) | — |
| `Class` | [tables/01_schema.sql:81](tables/01_schema.sql#L81) | — |
| `StudentClassAssignment` | [tables/01_schema.sql:99](tables/01_schema.sql#L99) | — |
| `Schedule` | [tables/01_schema.sql:109](tables/01_schema.sql#L109) | — |
| `Attendance` | [tables/01_schema.sql:126](tables/01_schema.sql#L126) | — |
| `GradeReport` | [tables/01_schema.sql:137](tables/01_schema.sql#L137) | — |
| `Invoice` | [tables/01_schema.sql:151](tables/01_schema.sql#L151) | — |
| `AuditLog` | [tables/01_schema.sql:169](tables/01_schema.sql#L169) | — |
| `ReplayOperation` | [tables/01_schema.sql:189](tables/01_schema.sql#L189) | — |

## Sequence — 1

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `InvoiceNumberSequence` | [tables/01_schema.sql:9](tables/01_schema.sql#L9) | — |

## Stored procedure — 61

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `usp_SecuritySession` | [stored-procedures/infrastructure/session.sql:1](stored-procedures/infrastructure/session.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_SecuritySession.sql) |
| `usp_BeginRead` | [stored-procedures/infrastructure/begin-read.sql:1](stored-procedures/infrastructure/begin-read.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_BeginRead.sql) |
| `usp_BeginWrite` | [stored-procedures/infrastructure/begin-write.sql:1](stored-procedures/infrastructure/begin-write.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_BeginWrite.sql) |
| `usp_RecordFailure` | [stored-procedures/infrastructure/failure.sql:1](stored-procedures/infrastructure/failure.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_RecordFailure.sql) |
| `usp_PasswordSnapshot` | [stored-procedures/infrastructure/password.sql:1](stored-procedures/infrastructure/password.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_PasswordSnapshot.sql) |
| `usp_RegistrationCreate` | [stored-procedures/core/07_core_procedures.sql:2](stored-procedures/core/07_core_procedures.sql#L2) | [Bài thực hành](../practice/stored-procedures/usp_RegistrationCreate.sql) |
| `usp_AdmissionApprove` | [stored-procedures/core/07_core_procedures.sql:60](stored-procedures/core/07_core_procedures.sql#L60) | [Bài thực hành](../practice/stored-procedures/usp_AdmissionApprove.sql) |
| `usp_InvoiceCollect` | [stored-procedures/core/07_core_procedures.sql:119](stored-procedures/core/07_core_procedures.sql#L119) | [Bài thực hành](../practice/stored-procedures/usp_InvoiceCollect.sql) |
| `usp_PlacementCreate` | [stored-procedures/core/07_core_procedures.sql:183](stored-procedures/core/07_core_procedures.sql#L183) | [Bài thực hành](../practice/stored-procedures/usp_PlacementCreate.sql) |
| `usp_ScheduleBatch` | [stored-procedures/core/07_core_procedures.sql:246](stored-procedures/core/07_core_procedures.sql#L246) | [Bài thực hành](../practice/stored-procedures/usp_ScheduleBatch.sql) |
| `usp_ScheduleMove` | [stored-procedures/core/07_core_procedures.sql:307](stored-procedures/core/07_core_procedures.sql#L307) | [Bài thực hành](../practice/stored-procedures/usp_ScheduleMove.sql) |
| `usp_AttendanceSave` | [stored-procedures/core/07_core_procedures.sql:377](stored-procedures/core/07_core_procedures.sql#L377) | [Bài thực hành](../practice/stored-procedures/usp_AttendanceSave.sql) |
| `usp_GradeSave` | [stored-procedures/core/07_core_procedures.sql:449](stored-procedures/core/07_core_procedures.sql#L449) | [Bài thực hành](../practice/stored-procedures/usp_GradeSave.sql) |
| `usp_GradeSubmit` | [stored-procedures/core/07_core_procedures.sql:522](stored-procedures/core/07_core_procedures.sql#L522) | [Bài thực hành](../practice/stored-procedures/usp_GradeSubmit.sql) |
| `usp_GradeReturn` | [stored-procedures/core/07_core_procedures.sql:589](stored-procedures/core/07_core_procedures.sql#L589) | [Bài thực hành](../practice/stored-procedures/usp_GradeReturn.sql) |
| `usp_GradeFinalize` | [stored-procedures/core/07_core_procedures.sql:660](stored-procedures/core/07_core_procedures.sql#L660) | [Bài thực hành](../practice/stored-procedures/usp_GradeFinalize.sql) |
| `usp_CourseCreate` | [stored-procedures/operations/usp_CourseCreate.sql:1](stored-procedures/operations/usp_CourseCreate.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_CourseCreate.sql) |
| `usp_CourseUpdate` | [stored-procedures/operations/usp_CourseUpdate.sql:1](stored-procedures/operations/usp_CourseUpdate.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_CourseUpdate.sql) |
| `usp_RegistrationConfirm` | [stored-procedures/operations/usp_RegistrationConfirm.sql:1](stored-procedures/operations/usp_RegistrationConfirm.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_RegistrationConfirm.sql) |
| `usp_RegistrationCancelOwn` | [stored-procedures/operations/usp_RegistrationCancelOwn.sql:1](stored-procedures/operations/usp_RegistrationCancelOwn.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_RegistrationCancelOwn.sql) |
| `usp_AdmissionReject` | [stored-procedures/operations/usp_AdmissionReject.sql:1](stored-procedures/operations/usp_AdmissionReject.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AdmissionReject.sql) |
| `usp_AdmissionCancel` | [stored-procedures/operations/usp_AdmissionCancel.sql:1](stored-procedures/operations/usp_AdmissionCancel.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AdmissionCancel.sql) |
| `usp_InvoiceCorrect` | [stored-procedures/operations/usp_InvoiceCorrect.sql:1](stored-procedures/operations/usp_InvoiceCorrect.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_InvoiceCorrect.sql) |
| `usp_ClassCreate` | [stored-procedures/operations/usp_ClassCreate.sql:1](stored-procedures/operations/usp_ClassCreate.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassCreate.sql) |
| `usp_ClassEdit` | [stored-procedures/operations/usp_ClassEdit.sql:1](stored-procedures/operations/usp_ClassEdit.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassEdit.sql) |
| `usp_ClassOpen` | [stored-procedures/operations/usp_ClassOpen.sql:1](stored-procedures/operations/usp_ClassOpen.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassOpen.sql) |
| `usp_ClassStart` | [stored-procedures/operations/usp_ClassStart.sql:1](stored-procedures/operations/usp_ClassStart.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassStart.sql) |
| `usp_ClassComplete` | [stored-procedures/operations/usp_ClassComplete.sql:1](stored-procedures/operations/usp_ClassComplete.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassComplete.sql) |
| `usp_ClassCancel` | [stored-procedures/operations/usp_ClassCancel.sql:1](stored-procedures/operations/usp_ClassCancel.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassCancel.sql) |
| `usp_ScheduleHeld` | [stored-procedures/operations/usp_ScheduleHeld.sql:1](stored-procedures/operations/usp_ScheduleHeld.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ScheduleHeld.sql) |
| `usp_ProfileUpdate` | [stored-procedures/operations/usp_ProfileUpdate.sql:1](stored-procedures/operations/usp_ProfileUpdate.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ProfileUpdate.sql) |
| `usp_AccountCreateStaff` | [stored-procedures/operations/usp_AccountCreateStaff.sql:1](stored-procedures/operations/usp_AccountCreateStaff.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AccountCreateStaff.sql) |
| `usp_AccountSetStatus` | [stored-procedures/operations/usp_AccountSetStatus.sql:1](stored-procedures/operations/usp_AccountSetStatus.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AccountSetStatus.sql) |
| `usp_AccountResetPassword` | [stored-procedures/operations/usp_AccountResetPassword.sql:1](stored-procedures/operations/usp_AccountResetPassword.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AccountResetPassword.sql) |
| `usp_StudentSignup` | [stored-procedures/operations/usp_StudentSignup.sql:1](stored-procedures/operations/usp_StudentSignup.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_StudentSignup.sql) |
| `usp_LoginRead` | [stored-procedures/operations/usp_LoginRead.sql:1](stored-procedures/operations/usp_LoginRead.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_LoginRead.sql) |
| `usp_LoginRecord` | [stored-procedures/operations/usp_LoginRecord.sql:1](stored-procedures/operations/usp_LoginRecord.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_LoginRecord.sql) |
| `usp_SessionTouch` | [stored-procedures/operations/usp_SessionTouch.sql:1](stored-procedures/operations/usp_SessionTouch.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_SessionTouch.sql) |
| `usp_Logout` | [stored-procedures/operations/usp_Logout.sql:1](stored-procedures/operations/usp_Logout.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_Logout.sql) |
| `usp_PasswordChange` | [stored-procedures/operations/usp_PasswordChange.sql:1](stored-procedures/operations/usp_PasswordChange.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_PasswordChange.sql) |
| `usp_MaintenanceCleanup` | [stored-procedures/operations/usp_MaintenanceCleanup.sql:1](stored-procedures/operations/usp_MaintenanceCleanup.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_MaintenanceCleanup.sql) |
| `usp_OperatorBootstrap` | [stored-procedures/operations/usp_OperatorBootstrap.sql:1](stored-procedures/operations/usp_OperatorBootstrap.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_OperatorBootstrap.sql) |
| `usp_CurrentSession` | [stored-procedures/operations/usp_CurrentSession.sql:1](stored-procedures/operations/usp_CurrentSession.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_CurrentSession.sql) |
| `usp_CourseList` | [stored-procedures/operations/usp_CourseList.sql:1](stored-procedures/operations/usp_CourseList.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_CourseList.sql) |
| `usp_RegistrationList` | [stored-procedures/operations/usp_RegistrationList.sql:1](stored-procedures/operations/usp_RegistrationList.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_RegistrationList.sql) |
| `usp_InvoiceRead` | [stored-procedures/operations/usp_InvoiceRead.sql:1](stored-procedures/operations/usp_InvoiceRead.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_InvoiceRead.sql) |
| `usp_ClassList` | [stored-procedures/operations/usp_ClassList.sql:1](stored-procedures/operations/usp_ClassList.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassList.sql) |
| `usp_ClassRoster` | [stored-procedures/operations/usp_ClassRoster.sql:1](stored-procedures/operations/usp_ClassRoster.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ClassRoster.sql) |
| `usp_ScheduleList` | [stored-procedures/operations/usp_ScheduleList.sql:1](stored-procedures/operations/usp_ScheduleList.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ScheduleList.sql) |
| `usp_StudentGrades` | [stored-procedures/operations/usp_StudentGrades.sql:1](stored-procedures/operations/usp_StudentGrades.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_StudentGrades.sql) |
| `usp_ReplayLookup` | [stored-procedures/operations/usp_ReplayLookup.sql:1](stored-procedures/operations/usp_ReplayLookup.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_ReplayLookup.sql) |
| `usp_AdminAccountList` | [stored-procedures/operations/usp_AdminAccountList.sql:1](stored-procedures/operations/usp_AdminAccountList.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AdminAccountList.sql) |
| `usp_AuditList` | [stored-procedures/operations/usp_AuditList.sql:1](stored-procedures/operations/usp_AuditList.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AuditList.sql) |
| `usp_FinanceReport` | [stored-procedures/operations/usp_FinanceReport.sql:1](stored-procedures/operations/usp_FinanceReport.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_FinanceReport.sql) |
| `usp_DirectorReport` | [stored-procedures/operations/usp_DirectorReport.sql:1](stored-procedures/operations/usp_DirectorReport.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_DirectorReport.sql) |
| `usp_InvoiceSearch` | [stored-procedures/operations/usp_InvoiceSearch.sql:1](stored-procedures/operations/usp_InvoiceSearch.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_InvoiceSearch.sql) |
| `usp_AttendanceRead` | [stored-procedures/operations/usp_AttendanceRead.sql:1](stored-procedures/operations/usp_AttendanceRead.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_AttendanceRead.sql) |
| `usp_TeacherOptions` | [stored-procedures/operations/usp_TeacherOptions.sql:1](stored-procedures/operations/usp_TeacherOptions.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_TeacherOptions.sql) |
| `usp_WeeklySchedulePreview` | [stored-procedures/operations/usp_WeeklySchedulePreview.sql:1](stored-procedures/operations/usp_WeeklySchedulePreview.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_WeeklySchedulePreview.sql) |
| `usp_FinanceExport` | [stored-procedures/operations/usp_FinanceExport.sql:1](stored-procedures/operations/usp_FinanceExport.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_FinanceExport.sql) |
| `usp_StudentHome` | [stored-procedures/operations/usp_StudentHome.sql:1](stored-procedures/operations/usp_StudentHome.sql#L1) | [Bài thực hành](../practice/stored-procedures/usp_StudentHome.sql) |

## Function — 7

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `fn_GradeTotal` | [functions/02_functions.sql:5](functions/02_functions.sql#L5) | [Bài thực hành](../practice/functions/fn_GradeTotal.sql) |
| `fn_InvoiceDueDate` | [functions/02_functions.sql:14](functions/02_functions.sql#L14) | [Bài thực hành](../practice/functions/fn_InvoiceDueDate.sql) |
| `fn_RegistrationUnfinished` | [functions/02_functions.sql:21](functions/02_functions.sql#L21) | [Bài thực hành](../practice/functions/fn_RegistrationUnfinished.sql) |
| `fn_ClassProgress` | [functions/02_functions.sql:36](functions/02_functions.sql#L36) | [Bài thực hành](../practice/functions/fn_ClassProgress.sql) |
| `fn_InvoiceDebtFlags` | [functions/02_functions.sql:47](functions/02_functions.sql#L47) | [Bài thực hành](../practice/functions/fn_InvoiceDebtFlags.sql) |
| `fn_ActionRootKind` | [functions/02_functions.sql:60](functions/02_functions.sql#L60) | [Bài thực hành](../practice/functions/fn_ActionRootKind.sql) |
| `fn_ValidScore` | [functions/06_score_validation.sql:4](functions/06_score_validation.sql#L4) | [Bài thực hành](../practice/functions/fn_ValidScore.sql) |

## View — 9

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `v_ClassState` | [views/03_views.sql:5](views/03_views.sql#L5) | [Bài thực hành](../practice/views/v_ClassState.sql) |
| `v_RegistrationFacts` | [views/03_views.sql:15](views/03_views.sql#L15) | [Bài thực hành](../practice/views/v_RegistrationFacts.sql) |
| `v_CurrentSchedule` | [views/03_views.sql:22](views/03_views.sql#L22) | [Bài thực hành](../practice/views/v_CurrentSchedule.sql) |
| `v_ClassRoster` | [views/03_views.sql:28](views/03_views.sql#L28) | [Bài thực hành](../practice/views/v_ClassRoster.sql) |
| `v_FinalizedGrades` | [views/03_views.sql:36](views/03_views.sql#L36) | [Bài thực hành](../practice/views/v_FinalizedGrades.sql) |
| `v_InvoiceFacts` | [views/03_views.sql:48](views/03_views.sql#L48) | [Bài thực hành](../practice/views/v_InvoiceFacts.sql) |
| `v_ClassProgress` | [views/03_views.sql:56](views/03_views.sql#L56) | [Bài thực hành](../practice/views/v_ClassProgress.sql) |
| `v_DirectorAggregate` | [views/03_views.sql:68](views/03_views.sql#L68) | [Bài thực hành](../practice/views/v_DirectorAggregate.sql) |
| `v_AuditSafe` | [views/03_views.sql:70](views/03_views.sql#L70) | [Bài thực hành](../practice/views/v_AuditSafe.sql) |

## Trigger — 12

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `tr_Account_Guard` | [triggers/05_triggers.sql:5](triggers/05_triggers.sql#L5) | [Bài thực hành](../practice/triggers/tr_Account_Guard.sql) |
| `tr_Course_Freeze` | [triggers/05_triggers.sql:28](triggers/05_triggers.sql#L28) | [Bài thực hành](../practice/triggers/tr_Course_Freeze.sql) |
| `tr_Registration_State` | [triggers/05_triggers.sql:40](triggers/05_triggers.sql#L40) | [Bài thực hành](../practice/triggers/tr_Registration_State.sql) |
| `tr_Class_Lifecycle` | [triggers/05_triggers.sql:69](triggers/05_triggers.sql#L69) | [Bài thực hành](../practice/triggers/tr_Class_Lifecycle.sql) |
| `tr_Class_GradeDecision` | [triggers/05_triggers.sql:130](triggers/05_triggers.sql#L130) | [Bài thực hành](../practice/triggers/tr_Class_GradeDecision.sql) |
| `tr_Assignment_Eligibility` | [triggers/05_triggers.sql:149](triggers/05_triggers.sql#L149) | [Bài thực hành](../practice/triggers/tr_Assignment_Eligibility.sql) |
| `tr_Schedule_Guard` | [triggers/05_triggers.sql:176](triggers/05_triggers.sql#L176) | [Bài thực hành](../practice/triggers/tr_Schedule_Guard.sql) |
| `tr_Attendance_Guard` | [triggers/05_triggers.sql:218](triggers/05_triggers.sql#L218) | [Bài thực hành](../practice/triggers/tr_Attendance_Guard.sql) |
| `tr_GradeReport_Guard` | [triggers/05_triggers.sql:232](triggers/05_triggers.sql#L232) | [Bài thực hành](../practice/triggers/tr_GradeReport_Guard.sql) |
| `tr_Invoice_Integrity` | [triggers/05_triggers.sql:249](triggers/05_triggers.sql#L249) | [Bài thực hành](../practice/triggers/tr_Invoice_Integrity.sql) |
| `tr_Audit_Integrity` | [triggers/05_triggers.sql:266](triggers/05_triggers.sql#L266) | [Bài thực hành](../practice/triggers/tr_Audit_Integrity.sql) |
| `tr_Replay_Integrity` | [triggers/05_triggers.sql:294](triggers/05_triggers.sql#L294) | [Bài thực hành](../practice/triggers/tr_Replay_Integrity.sql) |

## Table type / TVP — 3

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `ScheduleBatch` | [types/04_types.sql:5](types/04_types.sql#L5) | — |
| `AttendanceBatch` | [types/04_types.sql:13](types/04_types.sql#L13) | — |
| `GradeManifest` | [types/04_types.sql:19](types/04_types.sql#L19) | — |
