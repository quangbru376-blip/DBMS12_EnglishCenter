# HORIZONTAL_CREATE — 23/10/2026

Owner đổi bố cục: khung Tạo trải ngang, nằm trên Tìm kiếm. Tạo khóa/lớp/nhân sự/lịch dùng một khung fullwidth, fields1cột mobile/2cột>=768/3cột>=1100; nút lưu dòng riêng. Hai khung tạo lịch xếp dọc để mỗi khung đủ rộng. Tạo và Tìm kiếm xếp dọc ở mọi viewport, thay CREATE_SEARCH_ROW. Popup/handler/payload/query/dirty/role giữ nguyên.

Scope: frontend/src/features/dbms12/{Workspace,Schedules,controls}.tsx và dbms12.css; docs/evidence/horizontal-create/**; docs/notes/HORIZONTAL_CREATE.md; docs/plan/HORIZONTAL_CREATE_REVIEW.md; docs/plan/plan.md; docs/API.md(UI note); memory/01_CURRENT_STATE.md và memory/08_TASKS.md. Snapshot/driver riêng .local/horizontal-create-before.

Kiểm: Test-Project/62SQLpins/types/lint/5client/build; Edge375/768/1280 course/class/account/schedule form widths+field columns+order+nooverflow, query/popup/readstates. Không gửi businessPOST vào DB owner; static assets-first/atomicindex/ready/hash. Khôngdependency/SQL/reset/reseed/revokeowner/restart/commit/push.

Status: COMPLETE / scoped code-review PASS. Test-Project và Edge15form-layoutcases/6popup/query/readstates PASS,businessPOST0. Bản mới phục vụ8446,khôngrestartowner.
