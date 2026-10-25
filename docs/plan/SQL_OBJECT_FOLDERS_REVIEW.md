# Review SQL_OBJECT_FOLDERS — 25/10/2026

Verdict: **PASS trong phạm vi được giao**. Áp dụng skill code-review, không delegation. [Scope](slices/SQL_OBJECT_FOLDERS.md), [bằng chứng](../evidence/sql-object-folders/summary.json), [bản đồ thư mục](../../database/dbms12-compact/README.md).

## Kết quả

Source SQL thật được chuyển vào tables, functions, views, triggers, types, stored-procedures/core/operations/infrastructure, security, seeds và notes. Ba script học chuyển từ database/examples vào transactions. Giữ62file pin/61SP/12bảng99cột/7FN9VW12TG/3TVP/1sequence. Không sao chép định nghĩa object; index105 trỏ file và dòng. Một số file chứa nhiều object; sequence cùng schema để giữ nguyên SQL và thứ tự phụ thuộc.

61file pin byte-identical theo ánh xạ62đường dẫn một-một; Install.sql chỉ thay đường dẫn :r. Verifier so toàn bộ manifest sau remap, kiểm thứ tự install, mọi operation/parameter/role/context và SHA file. Các ghi chú tương thích không phải SP được đặt ở notes. Transaction thực ở trong SP;3script học không nằm trong installOrder.

Backend chỉ đổi selector đường dẫn cho các migration đã có và thêm CLI `--rebind-sql-layout`. CLI chỉ nhận profile D15 pinF24, kiểm manifest cũ đúng hash, mapping/Installer/currentpackage đúng phép đổi path, exact PROJECT identity,61live definitions và metadata/rows12bảng. Chỉ đọc SQL trong transaction rồi promote profile pin; không chạy script/DDL/DML trên main. Không có endpoint/browser input mới. Receipt/profile trước/sau private, guarded prefix/name/ID/GUID/fileGUID và host phải dừng bình thường. Không thay dependency, UI, API nghiệp vụ, quyền bảng, crypto, khóa, ACL hoặc phiên owner.

## Kiểm đã chạy

|Lệnh/kiểm|Kết quả|
|---|---|
|`node tools/Verify-SqlLayout.cjs`|PASS62mapping;61byte-identical;Install chỉ đổi include;contract/order giữ nguyên|
|`node tools/Verify-Source.cjs`|PASS62pins/61transactionscopes/29replay/56ops/7roles|
|`node tools/Generate-SqlStudyIndex.cjs`|PASS105objects,6folder index và đường dẫn từng dòng|
|`node tools/Verify-StudyAssignment.cjs`|PASS105object đủ/unique,27/26/26/26|
|`tools/Test-Project.ps1`|PASS locked restore/audit, backend0warnings/errors, frontend types/lint/5tests/build|
|`tools/Invoke-SecurityRehearsal.ps1 -SkipBrowser`|PASS fresh fixtureDB30;schema/DBCC/62pins/native1477,5COMMIT+5forcedROLLBACK,replay,2collectors/1effect|
|Main `--rebind-sql-layout`|PASS exactPROJECT26/61live definitions;không DDL/DML,rows/metadata giữ nguyên;profile ngoài ManifestSha256 khớp|
|Main `--check-profile`|PASS12bảng99cột61SP7FN9VW12TG/DBCC|
|Main Edge `browser-smoke.cjs`|PASS7roles/375,768,1280;chỉ đọc nghiệp vụ,own auth writes|
|Main launcher `Start-Project.ps1 -NoBrowser`|PASS reuse đúng receipt/ready,không chạy provision/ACL|
|Liên kết tài liệu và source hashes|PASS; chi tiết số lượng trong summary|

Đã dừng host cũ session62144 bình thường exit0 trước build/rebind. Host mới session44412/PID33452 ready200, dùng identity/cert/key có sẵn, không provision hoặc đổi ACL. Fresh fixture giữ lại; không reset/drop hay đụng APP25/demo24. Historical evidence/hash/path giữ nguyên theo lần chạy cũ. Note13dòng; CURRENT_STATE/TASKS/plan và decisionD16 cập nhật.

Không còn finding phải sửa trong scope. Chưa kiểm load/production/backup-restore hoặc Windows máy thứhai. Không lặp toàn bộ HTTP mutation journey vì SQL nghiệp vụ và contract byte-identical; native/transaction trên catalog mới và main read-only đã kiểm. Danh mục thư mục không có nghĩa mỗi object một file; link chỉ rõ dòng định nghĩa. Không commit/push.
