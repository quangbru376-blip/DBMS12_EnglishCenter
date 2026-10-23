# TEAM_HANDOFF — memory và yêu cầu cài môi trường

Owner chỉ gửi gói DBMS12 cho nhóm, cần agent hiểu độc lập và tài liệu requirements để cài máy khác. Phạm vi: README.md, REQUIREMENTS.md, AGENTS.md, memory/{00_START_HERE,01_CURRENT_STATE,05_RUNBOOK,07_DECISIONS,08_TASKS}.md; docs/CONTEXT_MAP.md, docs/SETUP_WINDOWS.md, docs/plan/{plan,TEAM_HANDOFF_REVIEW}.md, slice này, docs/notes/TEAM_HANDOFF.md, docs/evidence/team-handoff.json. Refresh source-hashes/artifact-hashes; tạo ZIP bàn giao mới. Parent chỉ thêm receipt/task bàn giao, không sửa source cũ.

Không sửa backend/frontend/SQL/config/launcher hoặc khóa dependency; không cài phần mềm, tạo account/cert/login, đổi ACL, provision/reset/reseed/restore, ghi DB hoặc restart runtime trong lượt tài liệu. Chỉ skill code-review; không subagent.

Acceptance: memory đủ ngữ cảnh model12, phân biệt bản cũ/rubric gốc không kèm; requirements chức năng và môi trường đúng code; hướng dẫn Windows theo danh tính owner/runtime/SQL service, SQL TLS và HTTPS riêng, config đầy đủ, lệnh kiểm và xử lý lỗi. Không hứa one-click trên máy mới. Links nội bộ không trỏ project cha; bản ZIP mới không private state, source executable/SQL/lock byte-identical trước task; kiểm source/links và syntax lệnh PowerShell mẫu, giải nén ZIP kiểm lại. Thực thi build/test phù hợp, ghi rõ hướng dẫn cài mới chưa được chạy trên máy khác; không chạy mutation suite.
