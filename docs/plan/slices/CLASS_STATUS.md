# CLASS_STATUS — 22/10/2026

Owner yêu cầu hiển thị trạng thái lớp ở màn Duyệt bảng điểm. Thêm thẻ thông tin ngay dưới bộ chọn lớp trong Teaching dùng dữ liệu ClassList hiện có: mã lớp, giáo viên, trạng thái lớp và bảng điểm. Màn review có giải thích theo DRAFT/RETURNED/SUBMITTED/FINALIZED đúng vai trò, thay câu hướng dẫn gửi dành cho Teacher đang hiển thị ở Giáo vụ. Shared card áp dụng cả Điểm danh/Bảng điểm Teacher.

Scope: frontend/src/features/dbms12/Teaching.tsx; docs/notes/CLASS_STATUS.md; docs/plan/CLASS_STATUS_REVIEW.md; docs/evidence/class-status/**; docs/API.md(UI note); memory/01_CURRENT_STATE.md, memory/08_TASKS.md, docs/plan/plan.md. Private read-only browser driver/before snapshot dưới .local/class-status-before. Không đổi command guards/SQL/API/quyền/dependency/dữ liệu.

Kiểm: tools/Test-Project.ps1, actual Edge Giáo vụ/Teacher ở375/768/1280, chuyển lớp cập nhật status, DRAFT không có nút duyệt và FINALIZED chỉ đọc; controlled read projections cho SUBMITTED/RETURNED, nút duyệt chỉ SUBMITTED. Không submit business command. Static assets-first/index atomic/hash/ready, scoped code-review. Status: COMPLETE / scoped code-review PASS.
