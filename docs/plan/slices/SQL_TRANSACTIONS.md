# SQL_TRANSACTIONS — 25/10/2026

Owner cung cấp yêu cầu3.4: tối thiểu5nghiệp vụ BEGIN/COMMIT/ROLLBACK và minh chứng concurrency hoặc recovery; yêu cầu chuyển toàn bộ transaction thành cấu trúc đầy đủ trong scriptSQL để học. Đây là thay đổi được giao đối vớiD04,không phải yêu cầu giảm SP.

Giữ61SP/12bảng99cột/7FN9VW12TG/7native roles. Toàn bộ61SP có TRY/CATCH/BEGIN/COMMIT/ROLLBACK rõ ràng: tự mở/chốt khi vào chưa có transaction; nếu đã có thì dùng transaction của caller,không commit/rollback thay caller. Early replayRETURN phải qua COMMIT của owner. Các entrypoint ứng dụng đi vào ởdepth0,SQL tự quản thật;backend bỏBEGIN/COMMIT bình thường,chỉ cleanup rollback khi cancel/error và REVERT. Không ghi failure giả khi write đã dispatch nhưng mấtACK/cancel/transporterror.

Scope: SQLprocedure files+manifest62pins;executor;verifier native/migration/CLI;tests SQL/HTTP;docs examples/guide;AGENTS/requirements/API/security/memory/plan/notes. Không đổi nghiệp vụ/quyền/tables/FN/views/triggers/UI/dependency/keys;giữ studyWIP cósẵn. Khôngcommit/push.

Kiểm: static61templates/29replaybranches;projectchecks;fixture riêng tất cả61module/7role/contextcancel;ít nhất5business success+forcedauditrollback,concurrency2writers/oneeffect;existingHTTP/UIjourney/lostACK. Main guardedrehearsalrollback rồimodulemigration61SPgiữ12tablehash/sequence/permissions/schema/keys vàphiênowner;khôngreset/reseed/drop/restore. MigrationchỉPROJECTprofile exactname/ID/GUID/fileGUID/oldmanifest/olddefinitions;host dừng bình thường trước migrate/restart.

Status: COMPLETE / scoped code-review PASS. Kết quả: docs/plan/SQL_TRANSACTIONS_REVIEW.md và docs/evidence/sql-transactions/summary.json. MainPROJECT26 đã ALTER61SP, dữ liệu/quyền/sequence giữ nguyên lúc chuyển đổi; runtime session62144 ready200. Hướng dẫn và3script học đã chạy trên fixture riêng.
