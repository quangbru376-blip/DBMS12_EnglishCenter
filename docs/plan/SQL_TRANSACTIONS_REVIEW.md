# Review SQL_TRANSACTIONS — 25/10/2026

Verdict: **PASS trong phạm vi được giao**. Dùng checklist skill code-review; không delegation. [Scope](slices/SQL_TRANSACTIONS.md), [bằng chứng](../evidence/sql-transactions/summary.json), [học và script](../study/SQL_TRANSACTIONS.md).

## Kết quả thay đổi

- 61/61 SP thực tế có TRY/CATCH/XACT_ABORT/BEGIN/COMMIT/ROLLBACK. 56 operation gồm29command/19read/8auth, cộng5helper. Tên/chữ ký/quyền/route giữ nguyên, không tăng object. 29 replay RETURN đi qua COMMIT nếu SP là owner.
- Ownership rõ: chưa có transaction thì SQL mở/chốt; có depth1 thì caller quản kết thúc. Không dùng nested commit như transaction độc lập. SP operation tiếp tục yêu cầu depth1, coarse Course locks, SID/epoch/native role/ownership/RV và audit/receipt nguyên tử.
- Executor bỏ normal BEGIN/COMMIT; typed call, fixed impersonation, final completion/depth0 và REVERT giữ nguyên. Rollback cleanup còn trong C#. Cancel sau write dispatch trả503 unknown; timeout/transport/cancel không tạo audit FAILURE giả. Chỉ log lỗi SQL xác định trước commit; lookup không tự gửi lại.
- PasswordSnapshot lấy Course read lock trong SQL và từ chối ambient connection ngay trước cleanup try, để không rollback transaction của caller. Không đổi crypto/JWT/CSRF/CSV/UI/dependency.
- Migration guard exact profile/name/ID/GUID/fileGUID/oldmanifest và61olddefinitions. Chỉ ALTER module, giữ tất cả hàng12bảng, permissions/principals/memberships, nonprocedure definitions/trigger flags và invoice sequence. Có rollback.sql riêng đúng danh tính, rehearsal thực thi script rồi rollback. Profile promote sau commit; lỗi sau commit giữ receipts để điều tra.

## Kiểm đã chạy

|Kiểm|Kết quả|
|---|---|
|`node tools/Verify-Source.cjs`|PASS62pins/61scopes/29replay/56ops/7roles|
|`node tools/Verify-StudyAssignment.cjs`|PASS105objects; phân công27/26/26/26 giữ nguyên|
|`tools/Test-Project.ps1 -CheckDatabase`|PASS locked restore/audit, backend0warnings/errors, frontend types/lint/5tests/build, main schema/DBCC|
|Fixture `--verify-security`|PASS1477checks/7roles, success/denial/readcancel/writecancel/nextrequest cleanup|
|Fixture `--verify-sql-transactions`|PASS5businessCOMMIT+5forcedauditROLLBACK, receipt rollback, replay/depth0,2collectors/1effect|
|Script học `01_five_business_transactions.sql` qua sqlcmd|PASS5caller transactions, các điều kiện trước, final depth0|
|Script học sessionA/B qua2sqlcmd cùng Invoice/RV|PASS A giữ khóa10giây rồiCOMMIT, B chờ rồi51214; một lần thu|
|Fixture HTTP/UI|PASS HTTP77;7roles/375,768,1280;Teacher attendance/grade;UIjourney12 gồm lostACK onePOST/lookup;weekly preview/batch/move;auditrollback/privateparameters/CSRF;final5validation/CSV|
|Main `--rehearse-sql-transactions`|PASS chạy rollback.sql, definitions restored và transaction rollback|
|Main `--migrate-sql-transactions` / `--check-profile`|PASS PROJECT26;61SP/12bảng99cột/7FN9VW12TG, dữ liệu/quyền/sequence giữ nguyên lúc chuyển đổi; DBCC|
|Main runtime và business read-only Edge|PASS ready200;7roles/3widths; không businessPOST, chỉ own auth sessions; runtime session62144 giữ chạy|
|`git -c core.whitespace=cr-at-eol diff --check`|PASS; SQL giữ CRLF theo pin, không sửa bytes chỉ để bỏ cảnh báo Git|

Fresh fixture được tạo riêng, không dùng dữ liệu main để diễn tập. Fixture và các cohort kiểm đã giữ lại; không reset/drop. Nguồn và bằng chứng là của project này. Hash104file hiện tại được lưu cùng evidence;9SQLfile không định nghĩa SP giữ nguyên pin. Các trường profile ngoài ManifestSha256 khớp trước/sau. Không đổi ACL/account/cert/key của môi trường cũ hoặc revoke phiên owner. Host cũ đã không còn chạy khi bắt đầu chuyển đổi; host mới dùng identity có sẵn, không gọi provision/reseed.

## Các vấn đề phát hiện và đã sửa

1. Nhánh replay RETURN có thể bỏ COMMIT khi chuyển ownership: đã thêm chốt có điều kiện trước toàn bộ29RETURN và kiểm tĩnh; replay thực/depth0 PASS.
2. Cancel sau write dispatch có thể bị hiểu là lỗi chắc chắn: giữ unknown, kiểm thực tế SP đang chờ khóa qua DMV, không receipt/false FAILURE và context sạch PASS.
3. Guard baseline ban đầu bỏ comment đầu `usp_RegistrationCreate` trong source cũ nên rehearsal từ chối an toàn. Đã đối chiếu toàn bộ61definition thực với nguồn cũ pinF72; giữ comment và chỉ normalize header CREATE/ALTER cùng line endings. Không bỏ qua drift thân SP. Rehearsal và actual sau sửa PASS.
4. UI drivers cũ tìm form Tạo inline và pending heading trùng bên ngoài popup. Sửa riêng selector mở popup/giới hạn dialog, giữ assertions và nghiệp vụ; chạy lại cohort riêng PASS. Các lần lỗi và cohort trước được giữ private, không biến thành PASS hoặc reseed.

Không còn finding phải sửa trong scope. Giới hạn: không có load/production/backup-restore hoặc máy Windows thứhai; không suy ra đạt toàn bộ rubric. HTTP77 chạy trước guard entry-depth bổ sung cho PasswordSnapshot; final build/native/main read-only chạy sau, contract không đổi. Nghiệp vụ ghi chỉ diễn tập trên fixture; dữ liệu main byte-identical là cam kết tại transaction chuyển đổi, không bao gồm login/logout của các phiên kiểm sau đó. Không commit/push.
