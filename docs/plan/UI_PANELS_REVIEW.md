# UI_PANELS — scoped review, 22/10/2026

Reviewer: Codex, skill code-review; không subagent. Slice: slices/UI_PANELS.md.

Owner yêu cầu khung cho các vùng nội dung và tab trên toàn DBMS12. Diff ứng dụng chỉ có 5 file: lớp bọc ec12-app, các class trình bày trên Workspace/Teaching/Table, và CSS dùng token hiện có. Đối chiếu bản trước tại .local/ui-panels-before: không đổi state, effect, fetch, handler, DTO, điều kiện quyền hoặc command. Form/Table dùng shared controls; không library mới. Shell chung không đổi, CSS giới hạn dưới ec12-app.

Nội dung chính và bộ lọc có nền trắng/viền/khoảng đệm; tiêu đề card có đường phân cách. Navigation có khung và mục đang chọn có viền/vạch xanh, dòng bảng đang chọn có nền xanh nhạt. Bảng giữ region/keyboard focus và cuộn ngang nội bộ, mobile giảm padding. Cards lồng nhau dùng divider nhẹ hơn. Print bỏ card border và ẩn header/filter/pagination.

Kiểm thực tế:
- tools/Test-Project.ps1 PASS: 62 SQL pins, locked restore/build 0 warning/error, frontend typecheck/lint/5 client tests/build.
- Sau sửa selector print-only: npm --prefix frontend run build PASS; final build/types clean.
- Edge HTTPS thật, 7 vai trò, 24 menu × 3 widths 375/768/1280; khung, background/padding, active border, keyboard focus, mobile drawer, compact frame/buttons, no page overflow. Kết quả cuối ghi acceptance.json.
- Teacher regression: 3 widths/selected roster/shortcut/refresh; controlled read error/retry/empty/loading/stale và dirty dismiss/accept PASS. Business writes 0.
- Controlled Admissions read empty/error/loading PASS; print computed CSS kiểm bằng Edge, không claim printer/PDF.
- Backend/database 98 fingerprints khớp baseline SQL_SECURITY; không đổi dependencies/SQL quyền/DB schema, không reset/reseed/revoke owner.
- Static assets copy trước rồi thay index atomically; index hash khớp frontend/dist, ready200; giữ runtime PID/start receipt và phiên owner.

Đã xem trực tiếp ảnh Admissions desktop/mobile, Student375, AcademicAffairs768 và Teacher selected1280. Ảnh và JSON dưới ../evidence/ui-panels/. Bản thử ban đầu: assertion bắt trúng transition màu180ms/đang tải, đã đợi stable; print test phát hiện specificity làm viền chưa mất, đã tăng selector và kiểm lại. Lần staging index đầu bị PowerShell bind null backup path thành chuỗi rỗng; thay bằng backup path thật và xác minh SHA, không phục vụ index dở.

Không thấy lỗi scope/business/security cần sửa. Phạm vi kiểm là UI hiển thị/navigation; không chạy lại business write/HTTP77/native SQL suite vì không đổi nghiệp vụ. Không claim mọi tương tác/mọi thiết bị/WCAG đầy đủ/physical printing. Verdict: PASS. Final acceptance 72/72 menu-width cases, all seven roles print CSS, business POST0.
