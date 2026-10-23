# SQL_SECURITY_REDESIGN — scoped code-review PASS

22/10/2026. Reviewer: Codex, skill code-review, no delegation. Scope: [slice](slices/SQL_SECURITY_REDESIGN.md), [design](../SQL_SECURITY.md), [matrix](../SQL_SECURITY_MATRIX.md). This verdict covers native SQL permissions/backend integration and the guarded PROJECT migration, not the entire course rubric.

## Final behavior

Seven native business role/user contexts are used by the backend after verified authentication. Direct table SELECT/INSERT/UPDATE/DELETE is denied; legacy runtime column grants are removed. Runtime retains only the authentication/infrastructure modules, schema metadata needed by profile verification and explicit impersonation of these seven users. SQL Server remains Windows-authentication-only. Business users are WITHOUT LOGIN, not seven separately authenticated server logins.

All 56 operations are real stored procedures; five infrastructure procedures bring the total to 61. CALLER/ownership chaining retains row ownership and role checks without EXECUTE AS OWNER or dynamic business SQL. Commands derive Actor/action internally, check replay, and complete audit/receipt inside the C# caller transaction. HTTP routes/DTOs and frontend product code are unchanged. C# explicitly cancels SqlCommand, rolls back incomplete work, reverts native context and uses unpooled connections. Cleanup failure after commit remains HTTP503/uncertain rather than a definite authorization error.

## Checks performed

| Check | Result |
|---|---|
| tools/Test-Project.ps1 | PASS: 62 SQL hashes/56 operations/61 SP, locked restore/audit, backend zero warnings/errors, frontend types/lint/build and 5 tests |
| Native fixture SQL | PASS: 1,475 checks across seven role/user contexts, table and column denials, module matrix, helper isolation, ownership, forged Actor, wrong epoch/SID role, GRANT–REVOKE–DENY |
| Executor context | PASS: success, SQL permission failure, actual lock/cancellation, next request; runtime principal restored and transaction depth zero |
| Real Edge/HTTPS fixture | PASS: seven roles at 375/768/1280, Teacher attendance/grade writes, 77-step HTTP journey, 12-case UI journey including lost ACK/manual lookup/one write, weekly batch/move, audit rollback, validation/CSV |
| Migration rehearsal | PASS: exact name/ID/database GUID/file GUID/legacy hash guards; forward modules/permissions, generated rollback SQL executed inside transaction, body/permission/data comparison, outer rollback |
| PROJECT migration | PASS: DB26/GUID E94F523E-AC86-448C-8E5B-79BE6C31D97B; before/after fingerprints of all rows in 12 tables and invoice sequence unchanged; profile promoted only after successful commit |
| Migrated PROJECT read-only inspect | PASS: 12 tables/99 columns/61 SP/7 FN/9 views/12 triggers, trusted/enabled constraints, DBCC |
| Migrated PROJECT Edge smoke | PASS: seven roles at three widths, read-only business navigation, no failed API/page errors/overflow; login/logout create normal auth/audit writes |
| Normal stop/restart/reuse | PASS: exit0, ready200, every table count and invoice sequence unchanged across restart, runtime key hashes unchanged, launcher reused verified process |

Evidence: [summary](../evidence/sql-security/summary.json), [native](../evidence/sql-security/rehearsal/sql-native-security.json), [HTTP](../evidence/sql-security/rehearsal/http-journey.json), [main smoke](../evidence/sql-security/main-smoke/browser-smoke.json), [runtime](../evidence/sql-security/runtime.json). Private rollback definitions/permissions/profiles remain in the operator folder, excluded from source sharing.

## Findings addressed during implementation

- Native permission tests initially passed while HTTP exposed error266: a helper SP opened a transaction without closing it. C# now opens the transaction; helper SP only checks depth and acquires the lock.
- Cancellation while blocked did not complete reliably with the token alone. Explicit SqlCommand.Cancel plus rollback/REVERT is covered by the actual lock test.
- The generated rollback needed to remove the new table DENYs before restoring legacy grants. The complete script was then exercised, with permissions restored exactly.
- SQL Server normalizes the CREATE OR ALTER introducer in stored metadata. Definition comparison normalizes only that introducer and line endings; procedure bodies remain exact. Raw metadata receipts are retained.
- A post-commit context cleanup error must remain uncertain. It now raises an infrastructure failure instead of returning a definite role-denied status.

## Limits

The full HTTP/UI journey ran on a new isolated fixture; existing owner cohorts were not reset or reused for writes. Main verification after migration used read-only business navigation with normal authentication/audit writes. Full workflow evidence preceded the final cleanup/error-mapping refinement; the final build additionally passed native context tests and main seven-role UI smoke. Evidence is not presented as a second full journey on finalized data.

The security fixture remains retained with its own profile, keys and test data; it was not dropped. APP25/demo24, owner Word artifacts and other catalogs were not changed. No claim of seven separate staff server logins, second-machine installation, public deployment, backup/restore, load/WCAG or complete rubric acceptance. Earlier 11-SP evidence/source ZIPs are historical; pack new source explicitly when needed.
