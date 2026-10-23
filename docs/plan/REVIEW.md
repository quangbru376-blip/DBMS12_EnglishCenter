# Review project DBMS12 độc lập

22/10/2026 — **PASS cho phạm vi project local độc lập và project memory**. Chỉ dùng skill code-review của owner, không gọi skill khác hoặc subagent. Slice đã đọc: slices/STANDALONE_PROJECT.md. Yêu cầu: project nhỏ chạy hoàn chỉnh, source và memory đủ cho agent khác; owner đã chọn database mẫu riêng.

## Những gì được giao

Backend, frontend, SQL, helper crypto/time/error, blocklist và licensed assets nằm trong project. Không ProjectReference/Link/import source ra project cha. New root marker thay đường dẫn tuyệt đối project cũ; machine settings nằm trong config.example. Có NuGet/npm lock, một solution, launcher, test/pack scripts, README/API, AGENTS và chín file memory đọc theo thứ tự.

Runtime mới: https://localhost:8446/dbms12, catalog PROJECT26/GUID E94F523E-AC86-448C-8E5B-79BE6C31D97B. Prefix/profile/DB user/issuer/audience/JWT/CSRF/app name/cookie riêng; dùng lại Windows runtime identity/certificate đã chuẩn bị của máy theo cấu hình, không tạo identity/key/trust hoặc đổi ACL custody cũ. Private state chỉ ở .local và không đóng gói.

## Kiểm đã chạy trực tiếp

|Kiểm|Kết quả|
|---|---|
|Source closure / frozen SQL|61 SHA khớp bản chuẩn;56operation/11SP; source references nằm trong project|
|Backend|Locked restore/audit và build PASS,0warning/0error; Shared copies compile trong namespace riêng|
|Frontend|Types/lint/build và5clienttests PASS;chỉ UI model12, không các module24|
|SQL|OwnerInspect kiểm exact name/ID/GUID,12tables99cols11SP7FN9VW12TG;FK/CHECK/triggers enabled/trusted;DBCC PASS|
|HTTP|77steps mới PASS với7roles; quyền sở hữu, forgery, RV/replay, payment/placement, attendance/grades, restricted password/logout|
|11SP|Toàn bộ11SP đã gọi thành công qua HTTP/UI của chính project này; danh sách trong summary.json|
|Teacher UI|Actual attendance/save và grades/save trong lớp ongoing,3widths PASS|
|UI lifecycle|10writes course/class/schedule/open/register/confirm/approve/collect/place;Student ownclass read;finalized teaching readonly;weeklypreview/batch/move PASS|
|Unknown response|Edge CDP chặn sau HTTP200/COMMIT,manual ownlookup,exact1write/no resend PASS|
|Audit/CSRF|Temporary owned trigger gây lỗi audit:business row0/receipt0;finallydrop đúngtrigger;privatefields400/missingCSRF403|
|Late validation/CSV|TVP400/email400/oversized413/CSV200UTF8BOM/StudentCSV403 PASS|
|Browser smoke|Installed Edge/trustedHTTPS;7roles,allmenus1280 và resulting view375/768/1280=21cases;no pageerror/failedAPI/pageoverflow|
|Lifecycle|Controlled Enter stop exit0,restartready200;2newkeyfiles và5businesscounts giữ nguyên;CMD defaultbrowser/reuse đúngreceipt PASS|
|Source archive|ZIP thử208entries/0private;extract sạch,restore174npm packages riêng,backendbuild/types/lint/5tests/frontendbuild PASS|
|Preservation|32parent shipping source hashes giữ nguyên;61SQLfiles parent/new giống;không có thao tác ghi catalog APP25/demo24 hoặc Word/checkpoint/oldkeys|

Bằng chứng tại docs/evidence/: summary.json, build-tests.txt, browser-smoke.json, ui-teacher-writes.json, http-journey.json, ui-journey.json, ui-weekly-move.json, audit-rollback-http.json, final-http.json, lifecycle.json, archive-build.json. source-hashes.json/artifact-hashes.json ghi đúng bộ source/evidence hiện tại.

Không cộng5unit+77HTTP+21browser thành số test duy nhất. Các suite có phạm vi chồng nhau; không lấy219test từ project cha làm kết quả của project mới. Teacher submit/AAreturn/finalize kiểm quaHTTP, UI có attendance/grade writes và finalized read; không claim tất cả nút ở mọi kích thước.

## Checklist review

- Scope/structure: PASS, chỉ new project và root handoff metadata. Source/SQL/runtime và dữ liệu cũ được giữ.
- Business: PASS trong các luồng đã nêu; guard ởSQL, transaction/audit/replay chung; không thêmRole/Payment/Band/Program.
- Backend: adapter mỏng, parameter/DTO validation và globalhandler; explicit auth metadata. Các danh sách chính paged; roster/calendar/options scoped và chưa benchmark tập lớn. Không EF migration, dùng DDL để tránh bảngthứ13.
- Frontend: shared shell/components/local assets, loading/empty/error, dirty prompts, RV refresh/attendance binding; evidence giới hạn rõ từng chiều kiểm.
- Security: no credential/header in public evidence, no TLS bypass; SQL identifiers chỉ từ generated/fixed allowlist; source ZIP loại state/dependencies/keys/DB. `.gitattributes` giữ nguyên bytes SQL.
- Owner understanding: note14lines tại docs/notes/STANDALONE_PROJECT.md, memory giải thích đường đi và transaction; phần crypto/HTTP là hạ tầng, không yêu cầu học như11SP.
- Docs: AGENTS/README/API/plan/memory/currentstate/tasks và evidence khớp trạng thái.

## Finding đã sửa và điều chưa kiểm

P2 launcher preflight ban đầu dùng owner để Test-Path certificate trong folder chỉ runtime đọc được. Đã bỏ phép đọc đó; host vẫn kiểm cert dưới đúng runtime identity, không đổi ACL/Trust. Lần thử script có sai cwd đã được sửa trước tạo DB; không có catalog hỏng hoặc reset. Không có automatic approval rejection cần owner xử lý.

NuGet Pkcs9.0.21 giữ bản vá từ bản nguồn. Không tắt audit, không sửa dependency/binary project cha. Không claim installer máy khác: Windows/SQL/TLS/runtime account/source RX vẫn là prerequisite của máy và có Runbook. ZIP chỉ là source, không chuyển dữ liệu hiện hành.

Chưa nghiệm thu public Internet/LAN, backup/restore/RPO/RTO, tải lớn, WCAG đầy đủ, mọi screen-width permutation, toàn bộ rubric hoặc runtime trên máy khác. Tests có ghi sample và Class2 đã FINALIZED; không tự reseed sau test. Mọi thay đổi phạm vi/custody tiếp theo cần task riêng của owner. Không còn must-fix trong phạm vi hiện tại.
