# Project memory — bắt đầu ở đây

Đây là bộ memory của **DBMS12 EnglishCenter**, một project riêng phục vụ môn Hệ quản trị CSDL. Không cần lịch sử chat hay source của project cha để hiểu hoặc build. Ngày tạo:22/10/2026.

Đọc đúng thứ tự trong `AGENTS.md`: CURRENT_STATE → DOMAIN → ARCHITECTURE → DATABASE → RUNBOOK → SECURITY → DECISIONS → TASKS. Sau đó mở task và các file source được chỉ trong nhiệm vụ. Không đọc hàng loạt log/screenshot khi chưa cần.

## Chuẩn ưu tiên khi thông tin mâu thuẫn

1. Yêu cầu hiện tại của owner.
2. Source hiện tại, `database/dbms12-compact/manifest.json`, schema và contract thực; receipt DB/runtime local đã được so khớp ID/GUID.
3. Bằng chứng có source hashes và ngày chạy trong `docs/evidence/`.
4. Memory/README giúp định hướng; cập nhật nếu source đã đổi.

Không lấy kết quả kiểm của bản24bảng hoặc bảnAPP25 làm kết quả kiểm project này. Các số kiểm trong memory phải có file bằng chứng của project mới. Không đưa password/SID/key/profile cá nhân vào memory.

## Bản đồ nhanh

- `README.md`: cách mở và nơi tìm tài khoản.
- `DBMS12.slnx`, `backend/EnglishCenter.Dbms12/`: host ASP.NETCore/.NET10.
- `frontend/`: React/TypeScript chỉ có7vai trò của model12.
- `database/dbms12-compact/`: bộ SQL gốc với SHA256; không chỉnh nhẹ file SQL mà quên manifest.
- `tools/Start-Project.ps1`: build/provision/start/reuse/stop local.
- `tools/Test-Project.ps1`, `tests/browser/`: kiểm nhanh và kiểm tích hợp tách riêng.
- `docs/API.md`, `docs/plan/REVIEW.md`: contract và review/bằng chứng hiện tại.
- `.local/`: state cá nhân được ignore; không copy vào ZIP/Git.
- `REQUIREMENTS.md`: đặc tả phạm vi và yêu cầu môi trường; `docs/SETUP_WINDOWS.md`: cài máy mới theo từng danh tính.
- `docs/CONTEXT_MAP.md`: nguồn đủ trong gói, lịch sử quyết định cần giữ, phần không chuyển và prompt bàn giao agent.

“Đủ ngữ cảnh” nghĩa là đủ hiểu và tiếp tục bản12 hiện tại với source đi kèm, không cần chat/project cha. Không bao gồm lịch sử từng lần sửa bản24, dữ liệu/custody máy tác giả hoặc Word/PDF rubric gốc. Muốn chứng minh đáp ứng toàn đề phải yêu cầu đúng rubric từ owner; không đoán hoặc dựng lại từ memory. Evidence DBID/GUID là lịch sử máy kiểm, không hardcode cho máy người nhận.

Khi kết thúc task: cập nhật CURRENT_STATE/TASKS, ghi decision nếu thay contract/kiến trúc, note <=15dòng và kết quả kiểm thật. Giữ các quyết định đã chốt; giữ12 bảng/99 cột,61SP theo D14,hướng A và7vai trò; 11SP là quyết định lịch sử đã được owner thay thế.

Từ25/10 owner đã cung cấp toàn nội dung phầnSQL3.1–3.5 (không phải toàn đề): docs/study/RUBRIC_SQL_SERVER.md. Khi chuẩn bị bảo vệ đọc SQL_LEARNING_START.md, SQL_RUBRIC_MATRIX.md và database/practice/README.md. Đủ107bài chạy riêng trên learning fixture; source cài đặt vẫn ở dbms12-compact.
