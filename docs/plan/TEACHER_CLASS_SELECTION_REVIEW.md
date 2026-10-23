# TEACHER_CLASS_SELECTION — scoped code-review PASS

22/10/2026. Codex applied frontend-ui and code-review; no delegation. Scope: [slice](slices/TEACHER_CLASS_SELECTION.md).

The original Teacher class-list button only set picked; the detail section was restricted to AcademicAffairs. A real Edge run reproduced the missing detail heading after selecting a non-first class. Teacher now sees a named class card, course/status/capacity/grade state and the existing authorized roster projection. The selection is held in Workspace RAM and carried to attendance/gradebook shortcuts and their class dropdowns.

TeacherClassDetails uses the shared Table/Button, scoped deferred reads, an active guard plus class key for stale responses, focus on the selected detail, loading/empty/error/retry and the Workspace refresh revision. Teaching clears obsolete roster/lesson/selection state on a genuine class change and disables actions until the roster matches the current class. Dirty confirmation remains enforced; choosing the current class again is a no-op. Role restrictions and finalized-grade editing guards are unchanged.

Validation performed:

- tools/Test-Project.ps1 PASS: 62 SQL hashes, locked restore/audit, backend build zero warnings/errors, frontend types/lint/5 client tests/build. Final small UI refinements rechecked with lint/types/build.
- Actual installed Edge over trusted localhost HTTPS at375/768/1280 PASS: selecting a non-first owned class, roster, changing classes, correct class in attendance/gradebook, selection retained when returning, same-class reselection, refresh performs one roster read, no page overflow. Screenshots at all three widths visually inspected.
- Controlled browser read mocks PASS: error/explicit retry/empty/loading, stale previous-class response ignored, decline/accept dirty-draft confirmation. Mocks change only this test browser's read projection; no grading save is attempted.
- Every targeted browser run recorded zero business POSTs. Login/logout cause ordinary authentication/audit writes; each test logs out only its own session.
- Seven-role navigation smoke at all three widths PASS on the final served UI. Backend/database source fingerprints unchanged for98 files; no SQL/permission/backend/dependency changes.
- The local host was stopped normally and restarted with the updated UI. The final small frontend build was published assets-first followed by atomic index replacement, retaining old assets for already-open tabs. Main remains at8446; runtime receipt `.local/running.json`.
- At closing, unrelated blank separator lines in02_functions/03_views/05_triggers broke pinned source hashes and prevented a later launcher run. Formatted bytes were retained privately, every nonblank line was checked against the reviewed version, and canonical bytes were restored. No function/view/trigger body, manifest/profile pin or database change; final62hash verification passes.

Evidence: [targeted checks](../evidence/teacher-class-selection/summary.json), [role smoke](../evidence/teacher-class-selection/roles-smoke/browser-smoke.json), image files and source hashes in the same task folder.

Verdict: PASS for the scoped Teacher selection fix. No fresh business-write/SQL/full workflow suite is claimed. Existing owner/finalized data, owner sessions, APP25/demo24, credentials, SQL definitions and report Word files were not reset or modified; no commit/push.
