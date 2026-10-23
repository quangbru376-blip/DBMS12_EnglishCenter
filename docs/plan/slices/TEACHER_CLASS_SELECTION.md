# TEACHER_CLASS_SELECTION

Owner reports that Teacher → Lớp phụ trách → Chọn does not show anything. The shared class table stores picked, but only AcademicAffairs renders a detail/action section. Teacher selection also does not carry to the separate Teaching dropdown.

Scope: frontend/src/features/dbms12/{Workspace,Teaching,Dbms12App}.tsx, new TeacherClassDetails.tsx, optional local styles; tests/browser/teacher-class-selection.cjs, task review/note/API UI note/memory/evidence. No SQL/backend/permissions/dependencies or database fixture changes; preserve owner sessions and existing finalized cohorts.

Closing exception: formatting-only concurrent edits added blank separator lines in 02_functions.sql, 03_views.sql and 05_triggers.sql, breaking pinned hashes. Preserve formatted bytes in .local/teacher-class-selection, verify every nonblank line equals the reviewed canonical version and restore canonical bytes. No logic, manifest/profile pin or database definition changes; refuse any meaningful SQL difference.

Behavior: selecting a Teacher-owned class shows a named detail card with course/status/roster, visible focus, loading/empty/error/retry. Shortcuts open attendance/gradebook for the selected class. Class dropdown selection persists in Workspace RAM across Teacher views, without bypassing dirty-form confirmation or server class ownership/status guards. Non-Teacher behavior stays unchanged.

Acceptance: reproduce before fix; types/lint/5 client tests/build and tools/Test-Project.ps1; actual Edge at375/768/1280 selecting a non-first class, changing selection, correct class in attendance/gradebook, empty/error/retry and stale-response cases; read-only business navigation/no business POST; final served UI verified. scoped code-review before complete, note <=15 lines. No reset/reseed/revoke/drop/restore or old project changes.
