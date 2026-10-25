# Bảo mật và vận hành

- SQL runtime không sysadmin/db_owner. Máy hiện tại dùng lại Windows runtime identity đã chuẩn bị; đây không phải cách ly bằng một Windows account mới. Database user, port, JWT issuer/audience, cookie, DataProtection app name và key files đều riêng.
- HTTPS chỉ loopback8446, exact Host/Origin. Cookie __Host-ec12p-auth là Secure/HttpOnly/SameSiteStrict; __Host-ec12p-csrf thuộc framework antiforgery. JWT phải khớp SQL session, trạng thái Account, epoch, scope và deadline ở từng request.
- Phiên NORMAL tối đa 2h, idle 30 phút; phiên đổi mật khẩu tối đa 10 phút và không quá 24h từ lúc cấp password tạm. Read không tự gia hạn idle; business write thành công cập nhật activity. UI xóa RAM khi 401/logout/cleanup, không lưu credential vào storage.
- PasswordHasher V3 dùng PBKDF2 HMAC-SHA512/220000 iterations, offline blocklist; password mẫu ngẫu nhiên riêng. Client không đọc/đặt password hash. Email/role bất biến theo SQL.
- Command UUID/digest gắn actor/action/body; audit và receipt cùng transaction. Không tự retry, manual lookup chỉ đọc của actor hiện tại. COMMIT mất phản hồi được giữ trạng thái unknown.
- Route và SQL operation cố định, typed SqlParameter. Identifier chỉ ghép từ GUID/machine/user allowlist hoặc tên operation trong code, không từ HTTP. JSON/query/TVP/size có whitelist; lỗi không lộ SQL hay credential.
- .local/operator chỉ owner đọc, có ledger DPAPI và Markdown mật khẩu riêng. Runtime được Modify trong .local/runtime, RX config/web; không export key. .local và config/machine.json không có trong ZIP/Git.
- NuGet audit được bật; Pkcs9.0.21 được pin trong project mới. Không coi đây là bản sửa dependency/binary của project cha.
- CSV có quoting, BOM và bảo vệ formula prefix, chỉ Accountant. Chưa kiểm actual Excel trên mọi máy/độ lớn số.

Nếu test driver có lỗi, không paste headers/cookie/token/password. Sanitize call log; nếu lộ SID thử nghiệm, chỉ thu hồi đúng phiên test với identity/window guard, không revoke toàn bộ phiên owner. Không ignore TLS để cho test qua.

Không tự mở Internet/tunnel/LAN. Backup/restore, RPO/RTO, tải lớn, WCAG và cài đặt trên máy khác cần task/bằng chứng riêng.

Native Security V2 (D14): role_QuanTri/TuyenSinh/GiaoVu/GiaoVien/KeToan/GiamDoc/HocVien,7WITHOUT LOGIN users thực sự dùng. Mọi nhóm nghiệp vụ và runtime bị DENY bảng trực tiếp; column GRANT legacy được gỡ bằng migration. Module CALLER/ownership chaining, không EXECUTE AS OWNER. Runtime chỉ auth/hạ tầng và IMPERSONATE allowlist; backend vẫn là trust boundary. SQL session/native role/ownership kiểm ở SP; Actor không là input publicSP. D15: command tự audit/replay và SQL COMMIT/ROLLBACK;61SP có scope owner/caller. C# call/cancel/cleanup/REVERT. Explicit SqlCommand.Cancel + cleanup đã kiểm với lock thực; lỗi cleanup sau commit trả503/uncertain. Windows Login runtime là login thực; không bảy serverlogin/password riêng hoặc đổi authentication mode.
