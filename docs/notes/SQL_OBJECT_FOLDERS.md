# SQL_OBJECT_FOLDERS — 25/10/2026
1. Owner yêu cầu phân loại script để học; source thật ở database/dbms12-compact được chuyển theo nhóm.
2. tables/functions/views/triggers/types/stored-procedures/security/seeds/transactions/notes có README riêng.
3. SP gồm core11 + operations45 + infrastructure5; tổng61 giữ nguyên, không thêm object.
4. OBJECT_INDEX.md chỉ tên105object → file/dòng; không tạo bản sao định nghĩa SQL.
5. Sequence ở đầu schema trước DEFAULT; một số file chứa nhiều object để giữ bytes và thứ tự cài.
6. Transaction thực vẫn trong SP; transactions chứa3script học, không tự cài hoặc tự chạy.
7. 61/62file pin giữ nguyên bytes; Install.sql chỉ đổi include path; manifest/operation/installOrder chỉ đổi path.
8. Verify-SqlLayout PASS; Test-Project PASS; fresh fixtureDB30 provision/DBCC/native1477/5commit+5rollback/concurrency PASS.
9. MainPROJECT26 rebind có guard exact identity/61definitions/path-only proof; không DDL/DML, profile chỉ đổi manifest pin.
10. Main DBCC/ready200/7roles3widths/reuse PASS, runtime session44412/PID33452; own auth sessions only.
11. Giữ dữ liệu/quyền/keys/ACL/phiênowner; giữ fixture/evidence cũ, không reset/reseed/commit/push.
12. Sinh index lại bằng tools/Generate-SqlStudyIndex.cjs; không claim load/production/fullrubric/máy Windows thứhai.
