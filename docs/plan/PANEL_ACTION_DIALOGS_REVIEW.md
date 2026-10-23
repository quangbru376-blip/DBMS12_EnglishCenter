# PANEL_ACTION_DIALOGS — scoped code-review PASS, 23/10/2026

Codex/frontend-ui/code-review, không delegation. Scope slices/PANEL_ACTION_DIALOGS.md. Bốn frontend files: Table thêm optionalactions và headerflex/rightalign/wrap; bảng khôngactions giữ h2 cũ. Workspace đưa các create/search hiện có vào SelectionDialog, action cùng headercourses/classes/accounts/invoices, không thêm endpoint/search/quyền mới. Schedules có nútTạo mở2form+preview trong cùng popup; previewdirty và discardclear rõ ràng. Fields/handlers/payload/RV/query/filters/scroll/role và popupChọn giữ nguyên. Thành công create đóng/refreshtheocũ, error giữdraft, unknownlookup giữ guard và feedback. Passwordtạm vẫn một lần sau khi popup đóng. Layoutmobile wrap hàng nút trong header, khôngpageoverflow.

Kiểm đã chạy:
- `pwsh -NoProfile -File tools/Test-Project.ps1`:62SQLpins/locked restore/backend0warnings0errors/types/lint/5clienttests/build PASS.
- `node tests/browser/panel-actions.cjs` (installedEdge/trustedHTTPS,candidatebundle):7roles3757681280,33controlledchecks. Nút theoquyền/trongheader/rightalign,khônginlineform,create+searchpopup fit,dirtydismiss/accept/focusreturn,searchapply-clear-reopen,busyclose,errorretainsdraft,unknownlookupnoresend,createsuccessclose/green,selectedpopup,weeklypreviewdirty/discard,singleTVPpayload,passwordtạm PASS. Mọi POST được giả lập.
- Cùng driver với `EC_DBMS12_LIVE_READS=1`:7roles,27relevantmenu-widthcases/27actualpopup opens PASS; businessPOST0 cóguard,own normal login/logout/audit only. Khôngpageerrors/nooverflow; PNGdesktopheader/mobilepopup đã xem.
- 102backend/database sourcehash giữ nguyên;62SQLpins/referenceinsideproject PASS. Static assets-first/atomicindex,ready200/index+JS+CSShashmatch,khôngrestartowner.

Lượt controlled đầu thiếu mockGETregistrations của màn mặc định Admissions; driver đã bổ sung projection,không sửa app/guard. Lượt cuối toàn bộ PASS. Không freshrealbusinessmutation/nativeSQL/fullHTTPsuite/fullWCAG/load/máy khác claim. KhôngSQL/API contract/dependency/schema/businessdata/reset/reseed/revokeowner/commit/push. Note<=15dòng; diff/sourcehash/receipts trong evidence. Khôngfinding chưa xử lý; verdict PASS.
