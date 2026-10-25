# Ma trận quyền SQL — Native Security V2

Sinh từ manifest.json. Quyền trực tiếp bảng của bảy nhóm và runtime đều bị DENY. Các SP đọc vẫn kiểm SID/epoch và ownership; quyền EXECUTE không thay thế lọc từng dòng.

| SP | Nhóm | Vai trò ứng dụng được cấp |
|---|---|---|
| usp_CourseCreate | command | AcademicAffairs |
| usp_CourseUpdate | command | AcademicAffairs |
| usp_RegistrationCreate | command | Student |
| usp_RegistrationConfirm | command | Student |
| usp_RegistrationCancelOwn | command | Student |
| usp_AdmissionReject | command | Admissions |
| usp_AdmissionCancel | command | Admissions |
| usp_AdmissionApprove | command | Admissions |
| usp_InvoiceCollect | command | Accountant |
| usp_InvoiceCorrect | command | Accountant |
| usp_ClassCreate | command | AcademicAffairs |
| usp_ClassEdit | command | AcademicAffairs |
| usp_ClassOpen | command | AcademicAffairs |
| usp_ClassStart | command | AcademicAffairs |
| usp_ClassComplete | command | AcademicAffairs |
| usp_ClassCancel | command | AcademicAffairs |
| usp_PlacementCreate | command | AcademicAffairs |
| usp_ScheduleBatch | command | AcademicAffairs |
| usp_ScheduleMove | command | AcademicAffairs |
| usp_ScheduleHeld | command | AcademicAffairs |
| usp_AttendanceSave | command | Teacher |
| usp_GradeSave | command | Teacher |
| usp_GradeSubmit | command | Teacher |
| usp_GradeReturn | command | AcademicAffairs |
| usp_GradeFinalize | command | AcademicAffairs |
| usp_ProfileUpdate | command | Student |
| usp_AccountCreateStaff | command | Admin |
| usp_AccountSetStatus | command | Admin |
| usp_AccountResetPassword | command | Admin |
| usp_StudentSignup | auth | dbms12_runtime (xác thực nội bộ) |
| usp_LoginRead | auth | dbms12_runtime (xác thực nội bộ) |
| usp_LoginRecord | auth | dbms12_runtime (xác thực nội bộ) |
| usp_SessionTouch | auth | dbms12_runtime (xác thực nội bộ) |
| usp_Logout | auth | dbms12_runtime (xác thực nội bộ) |
| usp_PasswordChange | auth | dbms12_runtime (xác thực nội bộ) |
| usp_MaintenanceCleanup | auth | dbms12_operator (không phải Admin ứng dụng) |
| usp_OperatorBootstrap | auth | dbms12_operator (không phải Admin ứng dụng) |
| usp_CurrentSession | read | dbms12_runtime (xác thực nội bộ) |
| usp_CourseList | read | Student, Admissions, AcademicAffairs |
| usp_RegistrationList | read | Student, Admissions, AcademicAffairs |
| usp_InvoiceRead | read | Student, Admissions, AcademicAffairs, Accountant |
| usp_ClassList | read | Student, Teacher, AcademicAffairs |
| usp_ClassRoster | read | Teacher, AcademicAffairs |
| usp_ScheduleList | read | Student, Teacher, AcademicAffairs |
| usp_StudentGrades | read | Student |
| usp_ReplayLookup | read | Admin, Admissions, AcademicAffairs, Teacher, Accountant, Director, Student |
| usp_AdminAccountList | read | Admin |
| usp_AuditList | read | Admin |
| usp_FinanceReport | read | Accountant |
| usp_DirectorReport | read | Director |
| usp_InvoiceSearch | read | Accountant |
| usp_AttendanceRead | read | Teacher, AcademicAffairs |
| usp_TeacherOptions | read | AcademicAffairs |
| usp_WeeklySchedulePreview | read | AcademicAffairs |
| usp_FinanceExport | read | Accountant |
| usp_StudentHome | read | Student |

| SP hạ tầng | Quyền gọi trực tiếp |
|---|---|
| usp_BeginRead / usp_BeginWrite | runtime/operator; D15 tự mở/chốt nếu depth0, dùng transaction caller nếu depth1 |
| usp_SecuritySession | Không cấp trực tiếp; chỉ gọi bên trong SP cùng owner |
| usp_PasswordSnapshot | runtime; bắt buộc SID/epoch hợp lệ, chỉ hash account của phiên |
| usp_RecordFailure | runtime; ghi lỗi sau rollback |

View cấp trực tiếp: v_DirectorAggregate cho role_GiamDoc/dbms12_report_reader; v_AuditSafe cho role_QuanTri/dbms12_audit_reader. Các view còn lại chỉ được truy cập qua SP.

TVP: ScheduleBatch cho role_GiaoVu; AttendanceBatch cho role_GiaoVien; GradeManifest cho role_GiaoVien/role_GiaoVu. Không có GRANT EXECUTE/SELECT toàn schema.

Tổng: 56 operation SP + 5 SP hạ tầng = 61 SP.
