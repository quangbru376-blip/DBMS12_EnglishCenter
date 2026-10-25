# Kiến trúc và đường đi code

```mermaid
flowchart LR
 UI[React: 7 vai trò] -->|HTTPS cùng origin| HTTP[Fixed API routes]
 HTTP --> AUTH[JWT cookie + CSRF + SQL session]
 HTTP --> REPO[Repository]
 REPO --> EXEC[CompactSqlExecutor]
 EXEC -->|Typed parameters / one transaction| SQL[61 SP: module-only/native roles]
 SQL --> GUARD[Constraints / triggers / functions / views]
 SQL --> AUDIT[Trong SP: kiểm phiên cuối + audit + receipt]
 AUDIT --> COMMIT[SQL COMMIT; C# REVERT và trả DTO]
```

## Backend: backend/EnglishCenter.Dbms12

|File|Trách nhiệm|
|---|---|
|Program.cs|Chỉ chạy các mode CLI được chỉ định; không tự chọn database mặc định|
|ProjectLayout.cs|Xác minh marker của project, đọc cấu hình máy; không hardcode đường dẫn project cha|
|AppProfile.cs|Guard prefix/ID/fileGUID/schema/native user, SQL TLS, certificate, khóa JWT riêng|
|OwnerProvision.cs|Owner tạo catalog mới, cài theo manifest, sinh tài khoản mẫu, tạo DB user/role và profile; receipt ngăn tự tạo lại sau lỗi|
|OwnerInspect.cs|CLI chỉ đọc metadata/DBCC đúng profile, không mở HTTP endpoint|
|Dbms12Host.cs|Loopback8446, middleware bảo mật, CSRF, static .local/web, endpoint metadata, redaction lỗi|
|Dbms12Identity.cs|Hash mật khẩu/JWT, đọc credential và ghi kết quả login có CAS; session, đổi mật khẩu và logout|
|Dbms12Routes.cs / RequestFields.cs|Map route cố định, whitelist JSON/query/TVP, UUID/digest từ server, DTO và CSV|
|Data/Dbms12Repository.cs|Mở connection riêng, kiểm profile, gọi executor; không DbContext|
|Data/CompactSqlExecutor.cs|Kiểm file SHA/type, xác thực role rồi EXECUTE AS user cố định; gọi SP tự quản transaction, kiểm depth0, cleanup ROLLBACK khi lỗi/cancel và REVERT|
|Shared/ và Resources/|Crypto/time/error helpers và blocklist đã copy vào project; không tham chiếu source EnglishCenter.Api bên ngoài|

## Giao dịch

D15 thay D04:61/61SP có TRY/CATCH/XACT_ABORT và BEGIN/COMMIT/ROLLBACK. Nếu vào depth0, SP tự mở/chốt; nếu vào depth1, SP dùng transaction của caller, không tự commit/rollback thay caller. Operation lấy Course shared/exclusive lock, yêu cầu depth1, tự xác định Actor từ SID/epoch và kiểm native role. Command kiểm replay/phiên cuối, ghi audit/receipt/activity cùng transaction. Nhánh replay RETURN cũng commit nếu SP là owner. Executor vào depth0, gọi SP, đọc hết server completion, kiểm depth0 và luôn REVERT; kết nối không pooling. C# rollback cleanup khi lỗi/cancel. Khóa thô giữ tính đúng, chưa benchmark tải lớn.

Request cancellation áp dụng khi đọc/chạy SQL. Cancel sau write dispatch trả kết quả chưa rõ; SQL có thể đã COMMIT trước attention. Không ghi audit FAILURE cho timeout/transport/cancel hoặc lỗi cleanup sau commit. Chỉ log lỗi SQL xác định xảy ra trước COMMIT, bằng giao dịch riêng sau rollback. UI tra receipt, không tự gửi lại. Xem docs/study/SQL_TRANSACTIONS.md.

## Frontend

App chỉ render Dbms12App. Shared shell, Button, Modal, Avatar và ảnh/font có license đều nằm trong frontend. api.ts giữ CSRF, AbortControllers và pending command trong RAM; Workspace.tsx tải projection theo menu; Teaching.tsx/Schedules.tsx xử lý roster/TVP/lịch. Không dùng localStorage cho credential.

Đường chạy hoàn chỉnh là launcher build frontend rồi host phục vụ static cùng origin. npm run dev chỉ là frontend preview nếu chưa cấu hình API proxy. Dependency khóa bằng packages.lock.json và package-lock.json; không tự thêm framework khi sửa nghiệp vụ.
