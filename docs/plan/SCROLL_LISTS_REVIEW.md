# SCROLL_LISTS — scoped review, 22/10/2026

Reviewer: Codex / skill code-review, no subagent. Slice: slices/SCROLL_LISTS.md. Owner chọn rõ giữ cột, cuộn để xem thêm. Hai nút trên ảnh bị disabled vì chỉ4hồ sơ ởtrang1; không phải lỗi mất quyền.

Diff: Workspace bỏ UI page state/previous/next, map bảy màn hình phân trang vào useScrollList; phần đọc khác và handler command/chọn/draft giữ nguyên. Hook đọc từng20 bằng GET hiện có, một request mỗi lần, append/dedup theo ID, tách metadata, dừng theo total hoặc short batch (audit không có total). Mỗi query có closure active/page/rows riêng; filter/search/revision cleanup bỏ phản hồi cũ. Lỗi không tăng page, giữ rows và yêu cầu retry tường minh. Không thêm SQL/route/library/persistent cache.

Table dùng scroll viewport chung, sticky th và IntersectionObserver gần cuối; nút Tải thêm dùng được với bàn phím. Observer ngừng khi busy/loading/error/print. Loading ban đầu không hiển thị nhầm empty state; tải thêm giữ bảng và selection. Các bảng không paged, bao gồm attendance ở Teaching, chỉ thêm viewport, không thêm API. Print mở chiều cao cho các hàng đã tải và không tải thêm.

Kiểm đã chạy:
- tools/Test-Project.ps1 PASS:62SQLpins/locked restore/backend build0warning0error/types/lint/5clienttests/build.
- Sửa cuối chỉ condition empty/loading: frontend build/types và lint PASS.
- Actual Edge/trustedHTTPS:7roles/72menu-width cases(375/768/1280), navigation/frames/focus/mobile/compact/print/nooverflow PASS; roles/acceptance.json. Suite này trước condition loading-only cuối; các controlled list cases và Teacher regression sau cùng chạy trên bundle cuối.
- Controlled browser read projections:45rows qua3pages trên Khóa học/Xếp lớp/Hồ sơ nhập học/Chọn hồ sơ xem hóa đơn/Hóa đơn/Tài khoản/Nhật ký. Tất cả45rows xuất hiện, không duplicate page3/page4, giữ selection khi append, sticky heading, ba độ rộng/nooverflow PASS.
- HTTP503 page2:20rows cũ còn, không tự retry, explicit retry cùng page rồi đi tiếp PASS. Filter đổi khi page2 đang chờ:query mới page1, late old page bỏ qua; loading state PASS.
- Teacher actual3width/chọn lớp/roster/shortcut/refresh và controlled error/retry/empty/loading/stale/dirty dismiss+accept PASS, teacher/summary.json.
- Business POST0 trong các driver; normal own login/audit/logout diễn ra. Không reset/reseed/revoke owner.
- Backend/database98fingerprints unchanged so với SQL_SECURITY, manifest62pins PASS. Static deploy assets-first/atomic index, giữ runtime; ready/hash ghi runtime.json.

Ảnh thực Xếp lớp: placement-real-{375,768,1280}.png; ảnh45rows ghi rõ mocked. Lần mock ban đầu kiểm uniqueness qua text của45audit rows giống hệt nhau nên assertion1!=45; sửa test projection cho change_details có tên riêng, không sửa app để né lỗi. Một condition loading được sửa khi rà code nhằm tránh empty flash trong request đầu. Không có lỗi scope/security/business còn mở.

Giới hạn: dữ liệu offset GET không là snapshot khi người khác đang ghi; Tải lại lấy lại danh sách. Không benchmark danh sách rất lớn/virtualization, không claim mọi thiết bị/WCAG/physical print. Không chạy lại mutation/HTTP77/native SQL vì không đổi backend/SQL. Verdict: PASS. Final evidence checked:7paged screens45rows/3batches + filter stale + Teacher regression + ready/hash; no unresolved findings.
