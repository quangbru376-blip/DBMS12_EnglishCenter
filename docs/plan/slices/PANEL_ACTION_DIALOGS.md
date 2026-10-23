# PANEL_ACTION_DIALOGS — 23/10/2026

Owner muốn form Tạo/Tìm kiếm thành popup, nút mở ở góc trên phải danh sách tương ứng (ví dụ Danh sách khóa học). Chỉ gắn các action vốn có: courses/search mọi role được xem; courses/create và classes/create Giáo vụ; accounts/create+search Admin; invoices/search Kế toán; schedules/create Giáo vụ với2form và preview trong popup. Không tự thêm search vào API chưa có. Giữ popup Chọn, filters/columns/scroll,dirty/focus/busy/feedback/unknownlookup/passwordtạm/print. Search áp dụng khi submit rồi đóng; create chỉ đóng khi thành công, lỗi giữ draft. Schedule preview chưa lưu có dirty guard.

Scope: frontend/src/features/dbms12/{Workspace,Schedules,controls}.tsx và dbms12.css; tests/browser/panel-actions.cjs; docs/evidence/panel-actions/**; docs/notes/PANEL_ACTION_DIALOGS.md; docs/plan/PANEL_ACTION_DIALOGS_REVIEW.md; docs/plan/plan.md; docs/API.md(UI note); memory/01_CURRENT_STATE.md và memory/08_TASKS.md. Snapshot .local/panel-actions-before.

Kiểm: Test-Project/62SQLpins/5client/types/lint/build; Edge375/768/1280 allrelevantrole/list actionplacement/hiddeninlineforms/create+search+selectionpopup,dirtyclose/focus/keyboard/searchquery/createerror-success/unknownlookup/weeklypreview giữ đúng bằng controlledAPI,businessPOSTtoDB0. Actualread smoke riêng,protectedsourcehash/staticassets-first/atomicindex/readyhash,khôngrestart/reset/reseed/revokeowner/SQL/dependency/commit/push.

Status: COMPLETE / scoped code-review PASS. Test-Project/33controlledchecks+27livecases/27popups3757681280 PASS,businessPOSTtoDB0. Bản mới phục vụ8446,khôngrestartowner.
