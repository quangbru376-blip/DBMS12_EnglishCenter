# Database DBMS12

Nguồn chuẩn: database/dbms12-compact/manifest.json, tables/01_schema.sql, stored-procedures/core/07_core_procedures.sql, security/08_permissions.sql. Chạy node tools/Verify-Source.cjs để kiểm 62 SHA256. Collation toàn DB là Latin1_General_100_BIN2; email/tên/mã được đặt collation riêng theo DDL. Có 12 PK, 19 FK, 34 CHECK, 11 UNIQUE, 20 DEFAULT, 17 CREATE INDEX tường minh và99cột; không có bảng EF history hoặc Role.

|Bảng|Nội dung và quan hệ|
|---|---|
|Account|Identity chung 7 vai trò, hồ sơ Student, hash/epoch/throttle/password tạm và RV|
|AuthSession|SID ngẫu nhiên 32 bytes → Account, giờ cấp/hoạt động và RV|
|Course|Mã/tên khóa, học phí decimal(18,0), số buổi, trọng số quá trình|
|Registration|StudentAccount → Course, trạng thái và RV|
|Class|Course + TeacherAccount + sĩ số/trạng thái; current_grade_operation_id → AuditLog|
|StudentClassAssignment|Registration duy nhất → Class, assigned_byAccount|
|Schedule|Class, LESSON/FINAL_EXAM, UTC start/end, phòng, held_byAccount; một FINAL_EXAM/lớp|
|Attendance|Schedule + Assignment, present tường minh và RV|
|GradeReport|Một Assignment, hai điểm decimal(5,2), nhận xét và RV; trạng thái suy ra qua audit của Class|
|Invoice|Một Registration, amount bất biến, paid metadata/Account và RV; status/debt tính từ dữ liệu gốc|
|AuditLog|Operation UUID duy nhất, actor nullable, action/root/result/reason/details/time; không lưu credential/SID|
|ReplayOperation|Actor+action+request UUID duy nhất, input digest, operation FK; chống gửi lệnh trùng|

## 61 stored procedures thực (Native Security V2)

56 operation SP + 5 hạ tầng (usp_BeginRead, usp_BeginWrite, usp_SecuritySession, usp_PasswordSnapshot, usp_RecordFailure). Các SP chính ban đầu vẫn có tên:

- `usp_RegistrationCreate`
- `usp_AdmissionApprove`
- `usp_InvoiceCollect`
- `usp_PlacementCreate`
- `usp_ScheduleBatch`
- `usp_ScheduleMove`
- `usp_AttendanceSave`
- `usp_GradeSave`
- `usp_GradeSubmit`
- `usp_GradeReturn`
- `usp_GradeFinalize`


45 operation còn lại đã chuyển thành CREATE OR ALTER PROCEDURE trong stored-procedures/operations/ theo hướng A. Manifest có 56 operation: 53 phục vụ HTTP/auth/CSV; bootstrap, maintenance và session-touch không mở public API. Có 7 function, 9 view, 12 trigger và ba TVP: ScheduleBatch, AttendanceBatch, GradeManifest. SP tự giữ guard, audit/replay command và transaction BEGIN/COMMIT/ROLLBACK theo D15; C# giữ call/role/cleanup. Danh sách/quyền: docs/SQL_SECURITY_MATRIX.md.

## Quyền và cài đặt

Bảy database role/user nghiệp vụ thật theo docs/SQL_SECURITY.md, không thêm bảng Role. User WITHOUT LOGIN được backend impersonate theo role từ phiên đã xác thực; SP kiểm lại native role/ownership. Bốn group kỹ thuật cũ còn tên nhưng không còn quyền trực tiếp bảng. Runtime Dbms12ProjectRuntime map tới Windows Login đã chuẩn bị; chỉ module auth/hạ tầng và IMPERSONATE đúng7user, không sysadmin/db_owner. Không có bảy server login riêng; không bật Mixed Mode.

OwnerProvision tạo PROJECT catalog mới và chạy installOrder, truyền hash mẫu thật trong RAM. Install.sql được giữ nguyên từ native verifier với COMPACT guard; nó không phải initializer của app này. Không chạy lại installer lên database đang dùng. Có ownership/creation receipt mà thiếu profile: giữ state để điều tra, không tự drop/reseed/tạo catalog khác.

## Khi owner giao thay đổi SQL

Ghi decision, sửa SQL và manifest SHA cùng nhau, đánh giá schema/dữ liệu đang chạy. Profile pin manifest nên sẽ từ chối drift. Dùng catalog thử mới hoặc migration được chấp thuận; không bỏ guard hay chỉ sửa profile để vượt kiểm tra. Đối chiếu name/ID/GUID, chạy lại kiểm phù hợp và ghi rõ giới hạn. .gitattributes giữ byte SQL nguyên vẹn qua Git newline settings.
