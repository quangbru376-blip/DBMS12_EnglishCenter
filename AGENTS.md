# Agent instructions — DBMS12 EnglishCenter

Đây là project độc lập cho model DBMS12. Đọc đúng thứ tự, đường dẫn tính từ thư mục này:

1. memory/00_START_HERE.md
2. memory/01_CURRENT_STATE.md
3. memory/02_DOMAIN.md
4. memory/03_ARCHITECTURE.md
5. memory/04_DATABASE.md
6. memory/05_RUNBOOK.md
7. memory/06_SECURITY.md
8. memory/07_DECISIONS.md
9. memory/08_TASKS.md, sau đó task/slice liên quan trong docs/plan/.

Khi chỉ nhận gói source: đọc thêm REQUIREMENTS.md và docs/CONTEXT_MAP.md; nếu được giao cài môi trường, đọc docs/SETUP_WINDOWS.md trước mọi thao tác account/cert/SQL/ACL. Các tài liệu đó nằm trong gói, không cần project cha. Yêu cầu môn/rubric gốc không kèm; không tự suy đoán đã đạt toàn bộ rubric.

Nhóm clone GitHub: docs/TEAM_QUICKSTART.md có công cụ setup theo pha. Test-Environment chỉ đọc/preflight; Prepare-Machine chỉ dùng trên máy mới đúng identity,không chạy để sửa workspace đã provision. Export-TeamSource/Pack-Source bỏ private/build state và kiểm định dạng secret; vẫn duyệt staged trước push.

## Ranh giới

- Model 12 bảng/99 cột, 61 SP tổng (56 operation + 5 hạ tầng), 7 function, 9 view, 12 trigger. Owner đã chọn/triển khai hướng A (D14), thay giới hạn 11 SP cũ. queries/usp_*.sql hiện là CREATE OR ALTER PROCEDURE.
- Bảy SQL role/user nghiệp vụ, DENY bảng; runtime chỉ qua module xác thực/hạ tầng và IMPERSONATE allowlist. Không đổi sang quyền bảng hoặc EXECUTE AS OWNER để chữa lỗi. Đọc docs/SQL_SECURITY.md.
- Mọi SELECT/INSERT/UPDATE/DELETE là SQL có tham số. Không thêm EF/LINQ-to-database hoặc bảng EF history.
- C# giữ HTTP/DTO/crypto/JWT/CSRF/CSV và điều phối transaction. SQL giữ nghiệp vụ; audit/receipt cùng transaction.
- Route cố định; không nhận SQL/operation/Actor/SID/epoch/hash tùy ý từ browser. SQL kiểm 7 vai trò và quyền sở hữu, Student chỉ thấy dữ liệu của mình.
- Không thêm Band, Program, thi đầu vào, thi lại riêng, Payment hoặc Role table khi owner chưa yêu cầu đổi phạm vi.
- Port8446, prefix EnglishCenter_DBMS12_PROJECT_, cookie/key app riêng. Không đụng APP25, demo24 hoặc catalog khác; không tự reset/reseed/drop/restore/revoke phiên owner.
- Sample chỉ tạo ở catalog mới. Có receipt nhưng thiếu profile thì giữ state để điều tra, không tạo catalog khác để che lỗi.
- .local và config/machine.json là state cá nhân, không commit/ZIP/log credential, cookie, SID, password hash, DPAPI, backup hoặc private key. Không đổi ACL/key/certificate của môi trường cũ.
- Không thêm ProjectReference/Link/import source ra ngoài project. Dùng dependency lock; machine prerequisites nằm trong config và Runbook, không hardcode đường dẫn project cha.
- Source/SQL và bằng chứng hiện tại là chuẩn; memory giải thích và trỏ nguồn. Không lấy kết quả kiểm của project cũ làm kết quả mới.

## Quy trình

Đọc task, ghi scope và tiêu chí kiểm; sửa đúng phần được giao; chạy tools/Test-Project.ps1 và các kiểm SQL/HTTP/UI phù hợp. Lượt tách project này chỉ dùng skill code-review, không delegation; task mới theo chỉ định mới của owner.

Sau task cập nhật CURRENT_STATE, TASKS, decision khi đổi kiến trúc, API khi contract đổi, note giải thích <=15 dòng. Ghi lệnh đã chạy, PASS/FAIL/chưa kiểm. Không claim production/load/backup/full môn chỉ từ build. Không tự commit/push hoặc tạo task/agent khác.
