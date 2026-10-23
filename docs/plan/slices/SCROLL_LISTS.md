# SCROLL_LISTS — 22/10/2026

Owner chọn giữ các cột, cuộn để xem thêm thay Trang trước/Trang sau. Ảnh Xếp lớp có4hồ sơ nên hai nút bị disabled đúng theo tổng hiện tại.

Scope: frontend/src/features/dbms12/{Workspace.tsx,controls.tsx,Teaching.tsx,dbms12.css,useScrollList.ts}; shared list viewport/sticky headings, progressive paged GET for courses/registrations/invoices/accounts/audit, including own invoice and placement selections. Giữ handler chọn/draft/command/API/backend/SQL/quyền/dependency. Các bảng không phân trang cũng dùng vùng cuộn; không đổi dữ liệu thành thẻ.

Kiểm: Test-Project; meaningful client unit tests cho nhiều batch/metadata/errors/cancel/stale nếu cần; browser actual7roles/3widths, controlled read >20/>40 rows, loading/error/retry, filter/search reset, stale response/navigation, selected row preserved, no auto duplicate request/no businessPOST. Teacher selection regression. Không thêm fixture vào DB hoặc reset/reseed/revoke owner. Static deploy assets trước/atomic index, ready/hash.

Support: tests/browser/scroll-lists.cjs, tests/browser/ui-panels.cjs (allow error message in alert as well as status), docs/notes/SCROLL_LISTS.md, docs/plan/SCROLL_LISTS_REVIEW.md, docs/evidence/scroll-lists/**, docs/API.md(UI only), memory/01_CURRENT_STATE.md, memory/08_TASKS.md, docs/plan/plan.md. Private before snapshot dưới .local/scroll-lists-before. Không thêm unit test mô phỏng lại hook; kiểm browser controlled reads phủ đường async thực. Status: COMPLETE / scoped code-review PASS.
