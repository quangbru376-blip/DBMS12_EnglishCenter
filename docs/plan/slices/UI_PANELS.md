# UI_PANELS — 22/10/2026

Owner yêu cầu thêm khung cho vùng hiển thị chính và tab, áp dụng toàn project DBMS12.

Scope: frontend/src/features/dbms12/{dbms12.css,controls.tsx,Workspace.tsx,Teaching.tsx,Dbms12App.tsx}; shared Table có nền/viền, page header/filter/pagination có khung, navigation có khung và trạng thái đang chọn. Giữ nguyên handler/API/quyền/dữ liệu/dependency. Không sửa SQL/backend hoặc các app cũ.

Support files: tests/browser/ui-panels.cjs; docs/notes/UI_PANELS.md; docs/plan/UI_PANELS_REVIEW.md; docs/evidence/ui-panels/**; docs/API.md (UI note only); memory/{01_CURRENT_STATE,08_TASKS}.md; docs/plan/plan.md. Private before snapshot/diagnostics under .local/ui-panels-before, outside source pack.

Kiểm: tools/Test-Project.ps1; actual Edge 7 vai trò, mọi menu ở 375/768/1280, khung/table/filter/nav/active state/no page overflow, mobile drawer và keyboard focus, chọn lớp Teacher; loading/empty/error qua controlled read mocks. Chỉ đọc nghiệp vụ, không submit form. Deploy static assets main8446 khi kiểm xong; không reset/reseed/revoke phiên owner.

Tài liệu: note <=15 dòng, review code-review, evidence ui-panels, CURRENT_STATE/TASKS/plan. Status: COMPLETE / scoped code-review PASS.
