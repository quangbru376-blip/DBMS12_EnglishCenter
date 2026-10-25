# stored-procedures

61 SP: `core/` chứa11 SP chính, `operations/` chứa45 SP còn lại, `infrastructure/` chứa5 helper. Transaction thật nằm trong từng SP theo D15.

[Bản đồ chung](../README.md) · [Tất cả object](../OBJECT_INDEX.md)

| Object | File định nghĩa | Chạy riêng |
|---|---|---|
| `usp_SecuritySession` | [stored-procedures/infrastructure/session.sql:1](infrastructure/session.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_SecuritySession.sql) |
| `usp_BeginRead` | [stored-procedures/infrastructure/begin-read.sql:1](infrastructure/begin-read.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_BeginRead.sql) |
| `usp_BeginWrite` | [stored-procedures/infrastructure/begin-write.sql:1](infrastructure/begin-write.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_BeginWrite.sql) |
| `usp_RecordFailure` | [stored-procedures/infrastructure/failure.sql:1](infrastructure/failure.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_RecordFailure.sql) |
| `usp_PasswordSnapshot` | [stored-procedures/infrastructure/password.sql:1](infrastructure/password.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_PasswordSnapshot.sql) |
| `usp_RegistrationCreate` | [stored-procedures/core/07_core_procedures.sql:2](core/07_core_procedures.sql#L2) | [Bài thực hành](../../practice/stored-procedures/usp_RegistrationCreate.sql) |
| `usp_AdmissionApprove` | [stored-procedures/core/07_core_procedures.sql:60](core/07_core_procedures.sql#L60) | [Bài thực hành](../../practice/stored-procedures/usp_AdmissionApprove.sql) |
| `usp_InvoiceCollect` | [stored-procedures/core/07_core_procedures.sql:119](core/07_core_procedures.sql#L119) | [Bài thực hành](../../practice/stored-procedures/usp_InvoiceCollect.sql) |
| `usp_PlacementCreate` | [stored-procedures/core/07_core_procedures.sql:183](core/07_core_procedures.sql#L183) | [Bài thực hành](../../practice/stored-procedures/usp_PlacementCreate.sql) |
| `usp_ScheduleBatch` | [stored-procedures/core/07_core_procedures.sql:246](core/07_core_procedures.sql#L246) | [Bài thực hành](../../practice/stored-procedures/usp_ScheduleBatch.sql) |
| `usp_ScheduleMove` | [stored-procedures/core/07_core_procedures.sql:307](core/07_core_procedures.sql#L307) | [Bài thực hành](../../practice/stored-procedures/usp_ScheduleMove.sql) |
| `usp_AttendanceSave` | [stored-procedures/core/07_core_procedures.sql:377](core/07_core_procedures.sql#L377) | [Bài thực hành](../../practice/stored-procedures/usp_AttendanceSave.sql) |
| `usp_GradeSave` | [stored-procedures/core/07_core_procedures.sql:449](core/07_core_procedures.sql#L449) | [Bài thực hành](../../practice/stored-procedures/usp_GradeSave.sql) |
| `usp_GradeSubmit` | [stored-procedures/core/07_core_procedures.sql:522](core/07_core_procedures.sql#L522) | [Bài thực hành](../../practice/stored-procedures/usp_GradeSubmit.sql) |
| `usp_GradeReturn` | [stored-procedures/core/07_core_procedures.sql:589](core/07_core_procedures.sql#L589) | [Bài thực hành](../../practice/stored-procedures/usp_GradeReturn.sql) |
| `usp_GradeFinalize` | [stored-procedures/core/07_core_procedures.sql:660](core/07_core_procedures.sql#L660) | [Bài thực hành](../../practice/stored-procedures/usp_GradeFinalize.sql) |
| `usp_CourseCreate` | [stored-procedures/operations/usp_CourseCreate.sql:1](operations/usp_CourseCreate.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_CourseCreate.sql) |
| `usp_CourseUpdate` | [stored-procedures/operations/usp_CourseUpdate.sql:1](operations/usp_CourseUpdate.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_CourseUpdate.sql) |
| `usp_RegistrationConfirm` | [stored-procedures/operations/usp_RegistrationConfirm.sql:1](operations/usp_RegistrationConfirm.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_RegistrationConfirm.sql) |
| `usp_RegistrationCancelOwn` | [stored-procedures/operations/usp_RegistrationCancelOwn.sql:1](operations/usp_RegistrationCancelOwn.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_RegistrationCancelOwn.sql) |
| `usp_AdmissionReject` | [stored-procedures/operations/usp_AdmissionReject.sql:1](operations/usp_AdmissionReject.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AdmissionReject.sql) |
| `usp_AdmissionCancel` | [stored-procedures/operations/usp_AdmissionCancel.sql:1](operations/usp_AdmissionCancel.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AdmissionCancel.sql) |
| `usp_InvoiceCorrect` | [stored-procedures/operations/usp_InvoiceCorrect.sql:1](operations/usp_InvoiceCorrect.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_InvoiceCorrect.sql) |
| `usp_ClassCreate` | [stored-procedures/operations/usp_ClassCreate.sql:1](operations/usp_ClassCreate.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassCreate.sql) |
| `usp_ClassEdit` | [stored-procedures/operations/usp_ClassEdit.sql:1](operations/usp_ClassEdit.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassEdit.sql) |
| `usp_ClassOpen` | [stored-procedures/operations/usp_ClassOpen.sql:1](operations/usp_ClassOpen.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassOpen.sql) |
| `usp_ClassStart` | [stored-procedures/operations/usp_ClassStart.sql:1](operations/usp_ClassStart.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassStart.sql) |
| `usp_ClassComplete` | [stored-procedures/operations/usp_ClassComplete.sql:1](operations/usp_ClassComplete.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassComplete.sql) |
| `usp_ClassCancel` | [stored-procedures/operations/usp_ClassCancel.sql:1](operations/usp_ClassCancel.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassCancel.sql) |
| `usp_ScheduleHeld` | [stored-procedures/operations/usp_ScheduleHeld.sql:1](operations/usp_ScheduleHeld.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ScheduleHeld.sql) |
| `usp_ProfileUpdate` | [stored-procedures/operations/usp_ProfileUpdate.sql:1](operations/usp_ProfileUpdate.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ProfileUpdate.sql) |
| `usp_AccountCreateStaff` | [stored-procedures/operations/usp_AccountCreateStaff.sql:1](operations/usp_AccountCreateStaff.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AccountCreateStaff.sql) |
| `usp_AccountSetStatus` | [stored-procedures/operations/usp_AccountSetStatus.sql:1](operations/usp_AccountSetStatus.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AccountSetStatus.sql) |
| `usp_AccountResetPassword` | [stored-procedures/operations/usp_AccountResetPassword.sql:1](operations/usp_AccountResetPassword.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AccountResetPassword.sql) |
| `usp_StudentSignup` | [stored-procedures/operations/usp_StudentSignup.sql:1](operations/usp_StudentSignup.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_StudentSignup.sql) |
| `usp_LoginRead` | [stored-procedures/operations/usp_LoginRead.sql:1](operations/usp_LoginRead.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_LoginRead.sql) |
| `usp_LoginRecord` | [stored-procedures/operations/usp_LoginRecord.sql:1](operations/usp_LoginRecord.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_LoginRecord.sql) |
| `usp_SessionTouch` | [stored-procedures/operations/usp_SessionTouch.sql:1](operations/usp_SessionTouch.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_SessionTouch.sql) |
| `usp_Logout` | [stored-procedures/operations/usp_Logout.sql:1](operations/usp_Logout.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_Logout.sql) |
| `usp_PasswordChange` | [stored-procedures/operations/usp_PasswordChange.sql:1](operations/usp_PasswordChange.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_PasswordChange.sql) |
| `usp_MaintenanceCleanup` | [stored-procedures/operations/usp_MaintenanceCleanup.sql:1](operations/usp_MaintenanceCleanup.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_MaintenanceCleanup.sql) |
| `usp_OperatorBootstrap` | [stored-procedures/operations/usp_OperatorBootstrap.sql:1](operations/usp_OperatorBootstrap.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_OperatorBootstrap.sql) |
| `usp_CurrentSession` | [stored-procedures/operations/usp_CurrentSession.sql:1](operations/usp_CurrentSession.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_CurrentSession.sql) |
| `usp_CourseList` | [stored-procedures/operations/usp_CourseList.sql:1](operations/usp_CourseList.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_CourseList.sql) |
| `usp_RegistrationList` | [stored-procedures/operations/usp_RegistrationList.sql:1](operations/usp_RegistrationList.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_RegistrationList.sql) |
| `usp_InvoiceRead` | [stored-procedures/operations/usp_InvoiceRead.sql:1](operations/usp_InvoiceRead.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_InvoiceRead.sql) |
| `usp_ClassList` | [stored-procedures/operations/usp_ClassList.sql:1](operations/usp_ClassList.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassList.sql) |
| `usp_ClassRoster` | [stored-procedures/operations/usp_ClassRoster.sql:1](operations/usp_ClassRoster.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ClassRoster.sql) |
| `usp_ScheduleList` | [stored-procedures/operations/usp_ScheduleList.sql:1](operations/usp_ScheduleList.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ScheduleList.sql) |
| `usp_StudentGrades` | [stored-procedures/operations/usp_StudentGrades.sql:1](operations/usp_StudentGrades.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_StudentGrades.sql) |
| `usp_ReplayLookup` | [stored-procedures/operations/usp_ReplayLookup.sql:1](operations/usp_ReplayLookup.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_ReplayLookup.sql) |
| `usp_AdminAccountList` | [stored-procedures/operations/usp_AdminAccountList.sql:1](operations/usp_AdminAccountList.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AdminAccountList.sql) |
| `usp_AuditList` | [stored-procedures/operations/usp_AuditList.sql:1](operations/usp_AuditList.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AuditList.sql) |
| `usp_FinanceReport` | [stored-procedures/operations/usp_FinanceReport.sql:1](operations/usp_FinanceReport.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_FinanceReport.sql) |
| `usp_DirectorReport` | [stored-procedures/operations/usp_DirectorReport.sql:1](operations/usp_DirectorReport.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_DirectorReport.sql) |
| `usp_InvoiceSearch` | [stored-procedures/operations/usp_InvoiceSearch.sql:1](operations/usp_InvoiceSearch.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_InvoiceSearch.sql) |
| `usp_AttendanceRead` | [stored-procedures/operations/usp_AttendanceRead.sql:1](operations/usp_AttendanceRead.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_AttendanceRead.sql) |
| `usp_TeacherOptions` | [stored-procedures/operations/usp_TeacherOptions.sql:1](operations/usp_TeacherOptions.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_TeacherOptions.sql) |
| `usp_WeeklySchedulePreview` | [stored-procedures/operations/usp_WeeklySchedulePreview.sql:1](operations/usp_WeeklySchedulePreview.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_WeeklySchedulePreview.sql) |
| `usp_FinanceExport` | [stored-procedures/operations/usp_FinanceExport.sql:1](operations/usp_FinanceExport.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_FinanceExport.sql) |
| `usp_StudentHome` | [stored-procedures/operations/usp_StudentHome.sql:1](operations/usp_StudentHome.sql#L1) | [Bài thực hành](../../practice/stored-procedures/usp_StudentHome.sql) |
