# Ngữ cảnh độc lập và bản đồ nguồn

Gói DBMS12 chứa source, SQL, assets/license, dependency lock, memory và bằng chứng đủ để tiếp tục **phạm vi DBMS12 đã chốt** mà không cần thư mục project cha. Memory là chỉ mục giải thích; phải mở source/contract được dẫn khi sửa một chức năng. Không hứa vài trang memory thay thế toàn bộ source hoặc lịch sử trao đổi của bản cũ.

## Vì sao có bản này

Owner làm báo cáo môn Hệ quản trị CSDL, ban đầu dự án trung tâm lớn hơn. Owner quyết định giảm còn đúng12 bảng và chấp nhận bỏ nghiệp vụ, sau đó giới hạn còn11SP chính, SQL vừa phải để giải thích và viết lại. Đó là lịch sử bản đầu. Ngày22/10 owner chọn hướng A và giao triển khai: 61SP (56 operation +5 hạ tầng),7database role/user thật, không quyền bảng; xem docs/SQL_SECURITY.md. C# giữ phần hạ tầng ứng dụng. Cuối cùng owner yêu cầu tách source nhỏ, chạy được và có memory cho agent; chọn sample database mới, không mang dữ liệu bản cũ.

Những quyết định này đã được thực hiện; không mặc định cần thiết kế lại model hoặc đưa EF trở lại. [Decision log](../memory/07_DECISIONS.md) ghi lựa chọn và hệ quả. Thuật ngữ “hoàn chỉnh” chỉ chuỗi nghiệp vụ trong phạm vi đã giảm và các kiểm đã ghi; không ngụ ý toàn bộ hệ thống quản lý trung tâm lớn hoặc mọi mục rubric.

## Đọc để làm việc gì

|Câu hỏi / công việc|Nguồn trong chính gói|
|---|---|
|Bắt đầu và quy tắc cho agent|[AGENTS](../AGENTS.md), chín file memory theo thứ tự|
|Yêu cầu chức năng/môi trường|[REQUIREMENTS](../REQUIREMENTS.md)|
|Clone GitHub/cài máy nhóm|[TEAM_QUICKSTART](TEAM_QUICKSTART.md),[SETUP_WINDOWS](SETUP_WINDOWS.md),[RUNBOOK](../memory/05_RUNBOOK.md);tools/Test-Environment.ps1,Initialize-MachineConfig.ps1,setup/Prepare-Machine.ps1|
|Vai trò, trạng thái, điều kiện trước/sau|[DOMAIN](../memory/02_DOMAIN.md), SQL manifest và file operation tương ứng|
|API/DTO/route → operation|[API](API.md), `Dbms12Routes.cs`, `RequestFields.cs`|
|12 bảng, cột, khóa và index|[DATABASE](../memory/04_DATABASE.md), `database/dbms12-compact/01_schema.sql`|
|FN/VW/trigger/SP/permissions|[SQL manifest](../database/dbms12-compact/manifest.json),installOrder và62file SHA;[SQL README](../database/dbms12-compact/README.md)|
|Transaction/audit/replay/mất phản hồi|[ARCHITECTURE](../memory/03_ARCHITECTURE.md), `Data/CompactSqlExecutor.cs`, `frontend/src/features/dbms12/api.ts`|
|Xác thực và bảo mật|[SECURITY](../memory/06_SECURITY.md), `Dbms12Identity.cs`, `Dbms12Host.cs`, `AppProfile.cs`|
|Chạy/provision/đóng gói|`tools/Start-Project.ps1`, `OwnerProvision.cs`, `tools/Pack-Source.ps1`|
|Điểm tiếp tục / việc chưa được giao|[CURRENT_STATE](../memory/01_CURRENT_STATE.md), [TASKS](../memory/08_TASKS.md)|
|Đã kiểm gì, giới hạn nào|[Review ứng dụng](plan/REVIEW.md), [evidence summary](evidence/summary.json), [review bàn giao tài liệu](plan/TEAM_HANDOFF_REVIEW.md)|

Các tên file C# trên đều nằm trong `backend/EnglishCenter.Dbms12/`. Không có tham chiếu build/import source cần truy cập ra ngoài project. SQL files và manifest là chuẩn cho chi tiết guard; memory không chép lại99cột hoặc mọi biểu thức SQL để tránh hai bản đặc tả lệch nhau.

## Gói không mang theo những gì

- Chat và memory khổng lồ của bản cũ, source các luồng24bảng, Word/PDF đề và báo cáo cũ: không cần để chạy bản12; chưa chứng minh toàn bộ rubric. Nếu owner giao sửa báo cáo theo đề thì lấy đúng đề trước.
- Dữ liệu thực hành, catalogID/GUID, account passwords, JWT/CSRF/private key, credential DPAPI và `.local` của tác giả: phải tạo tại máy người nhận. DBID26/GUID trong evidence là quan sát lịch sử, không phải giá trị người nhận phải nhập.
- Bằng chứng cài trên máy thứ hai/public deployment/load/backup-restore: chưa có. Không sao chép PASS máy tác giả thành PASS môi trường mới.

AGENTS nhắc APP25/demo24 để bảo vệ tài nguyên cũ nếu cùng máy;người nhận không cần tạo hay xin source của chúng. machine.example.json là placeholder;Initialize-MachineConfig sinh config theo máy nhận trước provision. Không tìm credential/key của tác giả.

## Prompt bàn giao có thể gửi kèm ZIP

> Đây là project DBMS12 độc lập. Đọc AGENTS.md và chín file memory theo thứ tự; sau đó REQUIREMENTS.md, docs/CONTEXT_MAP.md và docs/SETUP_WINDOWS.md. Trước tiên kiểm source/build, liệt kê điều kiện máy còn thiếu. Chỉ chuẩn bị account/chứng chỉ/SQL khi chủ máy giao việc và có quyền phù hợp; không bỏ TLS/runtime/schema guard. Giữ đúng12 bảng/99cột,61SP và SQL có tham số; không reset/reseed dữ liệu hiện có. Mỗi thay đổi phải ghi scope, kiểm phù hợp và cập nhật memory. Không cần project cha hoặc lịch sử chat để làm việc trong phạm vi hiện tại.

Repository độc lập: https://github.com/quangbru376-blip/DBMS12_EnglishCenter (private),source ngay gốc sau clone. Không phụ thuộc repo English-Center lớn hoặc lịch sửGit của nó. Owner cấp quyền GitHub cho thành viên trước clone.
