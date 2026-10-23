# Review memory và requirements bàn giao nhóm

22/10/2026 — **PASS trong phạm vi tài liệu bàn giao độc lập**. Đọc AGENTS và slice `slices/TEAM_HANDOFF.md`, dùng duy nhất skill code-review, không subagent. Owner chỉ gửi gói DBMS12 và yêu cầu ngữ cảnh đủ cho nhóm/agent, cùng requirements cài môi trường.

## Kết quả

- Memory hiện có đủ domain, model, kiến trúc, quyền, state, quyết định và đường đi source cho bản12. Đã bổ sung REQUIREMENTS, CONTEXT_MAP và SETUP_WINDOWS để người chỉ nhận ZIP biết phạm vi, nguồn cần đọc và prerequisite chưa có trên máy.
- Requirements có FR/TR, toolchain/version, named SQL instance/local Windows constraints, ba danh tính owner/runtime/SQL service, TLS SQL khác HTTPS web, config và tiêu chí nghiệm thu.
- Hướng dẫn có bước cài, tạo user/login/CLIXML, cert runtime, bind/trust SQL cert theo tài liệu Microsoft, RX source, config trước provision, build/preflight/start/health/stop/check. Không cần source project cha; example ProgramData cũ được ghi rõ phải thay.
- Không kèm rubric/Word/PDF, dữ liệu/session/key/DPAPI máy tác giả; không claim toàn bộ rubric hoặc cài máy thứ hai. Memory hướng dẫn source chuẩn, không thay source chi tiết.

## Kiểm trực tiếp

`pwsh -NoProfile -File tools/Test-Project.ps1` PASS:61SQL SHA/56operation/11SP,9memory files, không external source reference; locked restore và backend build0warnings0errors; frontend types/lint/build và5clienttests PASS. Không dùng -CheckDatabase và không chạy HTTP/UI mutation suite trong task tài liệu.

Kiểm links nội bộ, JSON mẫu và parse cú pháp các PowerShell fence; đối chiếu các tham số certificate cmdlet trên máy hiện tại. Parse không thực thi lệnh cài/user/cert/ACL/SQL. So với source-hashes trước task, chỉ các Markdown thuộc slice được sửa; executable/SQL/config/dependency lock giữ bytes. ZIP mới được kiểm toàn bộ entry/hash/loại private state sau đóng gói; receipt đóng gói được lưu ngoài ZIP để không tạo vòng hash.

Kết quả chi tiết và source/evidence hashes: `../evidence/team-handoff.json`, `source-hashes.json`, `artifact-hashes.json`. Source hashes được refresh cho bản tài liệu này; các evidence ứng dụng trước đó được giữ nguyên. Không dùng kết quả cài máy tác giả thay cho acceptance máy nhận.

## Checklist và giới hạn

Scope/structure/docs/owner understanding/security: PASS. Backend/frontend/business không đổi; đã build/test lại, không cần thêm test mô phỏng nội dung tài liệu. Không thay package/API/schema/procedure/launcher. Note12lines trong `../notes/TEAM_HANDOFF.md`; API contract không đổi nên docs/API.md giữ nguyên. Plan và current memory đã cập nhật.

Không có must-fix còn lại trong phạm vi này. Cài toolchain/account/cert/login/trust và runtime trên một máy sạch thứ hai **chưa thực thi**; chỉ hướng dẫn theo code và nguồn chính thức. Cấp cert SQL phải do operator thực hiện theo CA/chính sách máy, tài liệu không cung cấp private key/PFX dùng chung hoặc TLS bypass. Không claim installer tự động, public/LAN/load/backup-restore/fullWCAG/toàn bộrubric. Runtime/DB/keys/ACL hiện tại không được đổi trong lượt này.
