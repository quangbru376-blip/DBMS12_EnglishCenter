# CREATE_FIRST_DIALOGS — scoped code-review PASS, 23/10/2026

Codex dùng frontend-ui và code-review, không delegation. Scope theo slices/CREATE_FIRST_DIALOGS.md; diff của5frontendfiles nằm trong ../evidence/create-first-dialogs/*.diff.

Form tạo khóa/lớp/nhân sự đứng trước tìm kiếm và danh sách; hai form tạo lịch đứng trước bảng lịch. Workspace tách creation/content/selection để giữ handlers/payload/RV/role checks hiện có. SelectionDialog dùng Modal native sẵn có: tên truy cập được, Tab trap/focus return/ESC/nút đóng, xác nhận dirty trong popup và closeDisabled khi request đang xử lý. Teacher roster/nhập điểm, schedule dời buổi, xếp lớp, thu tiền/correction, tài khoản và Student đăng ký/hóa đơn/lớp đều dùng popup. RecordDetails chỉ trình bày trường đã đọc; không thêm quyền/API hay thư viện.

Feedback, pending-command manual lookup và password tạm giữ nguyên, được đặt cả trong popup để nền inert không che lỗi/khóa phục hồi. Gửi thành công refresh/đóng selection như cũ; lỗi giữ popup/draft. Header popup và nền trang ẩn khi in hóa đơn, fresh detail read giữ nguyên;3PDF controlled đều1trangA4. Popup dài cuộn trong viewport, bảng cuộn ngang nội bộ.

Kiểm đã chạy:
- `pwsh -NoProfile -File tools/Test-Project.ps1`:62SQLpins, locked restore/audit, backend0warnings0errors, frontend types/lint/5clienttests/build PASS.
- `node tests/browser/create-first-dialogs.cjs` với installed Edge/HTTPS tin cậy:6roles×3widths,45checks, form order/các loại popup/fit/focus/Tab/ShiftTab/dirtycancel-discard/busy/error/unknownlookup-no-retry/successclose/Teacher shortcut/print/password tạm PASS. HTTP ghi được giả lập toàn bộ.
- Cùng driver với `EC_DBMS12_LIVE_READS=1`:7roles,72menu-width cases,39actualpopup cases tại375/768/1280 PASS; khôngpageerror/nooverflow, businessPOST0 bị guard, chỉ own normal login/logout/audit.
- 102backend/database files byte-identical với snapshot trước task;62SQLpin và source references inside project PASS.
- Static assets-first/atomic index, trustedHTTPS ready200 và servedindex/JS/CSS hashesmatch; host/PID/startTime giữ nguyên, không revoke owner.

Driver ban đầu gặp sandbox Edge launch refusal và selector Chọn lớp exact không khớp accessible name chứa options. Lượt actual đầu gửi ESC khi invoice read còn busy nên close guard từ chối đúng; driver đã chờ enabled, UI thêm busy status rõ ràng. Các bằng chứng failure được giữ riêng; toàn bộ lượt cuối PASS trên bundle cuối. Không bỏ guard/TLS để qua kiểm.

Đã xem PNG desktop/mobile và kiểm PDF page count. Không có finding chưa xử lý trong scope. Không chạy business mutation/nativeSQL/fullHTTPsuite mới vì SQL/backend/contract không đổi; không claim fullWCAG/load/backup/máy khác. Khôngreset/reseed/đổi credential/keys/ACL/restartowner/commit/push. Verdict: PASS.
