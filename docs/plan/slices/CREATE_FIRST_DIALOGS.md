# CREATE_FIRST_DIALOGS — 23/10/2026

Owner yêu cầu đưa giao diện Tạo lên đầu trang và chuyển giao diện sau nút Chọn thành popup.

Scope: frontend/src/features/dbms12/{Workspace,Schedules,Teaching,controls}.tsx và dbms12.css; tests/browser/create-first-dialogs.cjs; docs/evidence/create-first-dialogs/**; docs/notes/CREATE_FIRST_DIALOGS.md; docs/plan/CREATE_FIRST_DIALOGS_REVIEW.md; docs/plan/plan.md; docs/API.md (UI note); memory/01_CURRENT_STATE.md và memory/08_TASKS.md.

Tạo khóa/lớp/nhân sự đứng trước tìm kiếm và danh sách; tạo lịch đứng trước bảng lịch. Các Chọn ở khóa/hồ sơ/lớp/xếp lớp/hóa đơn/tài khoản/lịch/nhập điểm mở Modal sẵn có. Giữ nguyên endpoint/payload/role/SQL/command/replay. Popup có nhãn, focus/ESC/đóng, dirty confirmation, chặn đóng khi đang gửi, feedback/lost-ACK lookup hiện được; giữ password tạm một lần và in hóa đơn.

Kiểm: tools/Test-Project.ps1; browser Edge375/768/1280, tất cả loại popup và vị trí form tạo, keyboard/focus/dirty/error/busy/unknown/lookup/print/Teacher shortcuts. Dùng controlled HTTP projections/commands cho nhánh ghi, không business POST tới DB owner; actual role navigation/read riêng. So hash backend/database,62SQLpins; static assets-first/index atomic/ready sau khi PASS, không restart/revoke owner.

Status: COMPLETE / scoped code-review PASS. Test-Project/62SQLpins/5clienttests/types/lint/build;45controlledchecks và72actualmenu-width/39popup cases, businessPOST0 PASS. Chỉ frontend/tài liệu; không dependency/SQL/API contract/schema/businessdata/keys/ACL/reset/reseed/commit/push.
