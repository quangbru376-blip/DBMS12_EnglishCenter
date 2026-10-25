# SQL_LEARNING_PACK — 25/10/2026

Owner cung cấp nguyên văn rubricSQL3.1–3.5 và xác nhận cần chạy riêng SP/Function/Trigger/View/Transaction. Tạo bộ thực hành SSMS/sqlcmd trên fixture riêng, từng object có câu gọi, tham số, trước/sau và kỳ vọng. Giữ nguyên source cài đặt/runtime, mọi schema/quyền/nghiệp vụ,62pins và profile/main. Không commit/push/delegation.

Scope: docs/study rubric/checklist/3NF/relational schema/index rationale; database/practice SQL cases/registry/README; tools generator/runner/preparer/verifier; source index/README dẫn bài học; memory/notes/review/evidence. Đủ7FN9VW12TG61SP (happy hoặc negative case ghi rõ); ít nhất5transaction và concurrency tái dùng script/verification thực;5constraint và5index có benchmark được ghi rõ môi trường/dữ liệu. Không dùng hash/SID/password literal hoặc xuất chúng; auth modules capture kết quả nhạy cảm trong temp table và chỉ chiếu cột an toàn. SQL role/ownership vẫn kiểm; không grant thêm quyền để gọi sai context.

Fixture chỉ dùng workspace .local/security-redesign/fixture-GUID, guard name/ID/GUID/fileGUID, đánh dấu learning fixture riêng. Mỗi case rollback outer transaction, trừ transaction examples vốn có commit được ghi rõ. Các case bootstrap/start có thể minh họa từ chối hợp lệ và phải ghi expected error, không giả success. Index benchmark trên temp replicas không thay index/schema chính;không gọi đó là production benchmark. Giữ main host và owner sessions; không reset/reseed.

Kiểm: tất cả case theo registry trên fixture, assert expected state/error/depth/context; source coverage số lượng;5index logical-read before/after;Test-Project;source62pins/main manifest/runtime unchanged;docs links/note<=15lines. Ghi rõ kiểm thật/chưa kiểm,không claim đạt mọi rubric chỉ từ object counts.

Status: COMPLETE / scoped code-review PASS. Review docs/plan/SQL_LEARNING_PACK_REVIEW.md; evidence docs/evidence/sql-learning/summary.json. Main source/runtime giữ nguyên.
