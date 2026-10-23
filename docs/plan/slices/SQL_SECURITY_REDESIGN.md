# SQL_SECURITY_REDESIGN — implementation

Owner assigned implementation after choosing A on 22/10/2026. Supersedes D02's exact 11-SP limit for this task; preserves 12 tables/99 columns, seven roles and existing HTTP/UI contracts. No delegation.

Files: SQL package/manifest (procedures, infrastructure, permissions, installer), Data executor/repository, Identity password lookup, profile/provision/inspect and guarded migration CLI; tools verifier/test/migration/rehearsal; tests/browser configuration and native SQL security tests; relevant README/API/setup/requirements/security report, plan/notes/memory/evidence. No dependency or frontend product changes.

Design: seven WITHOUT LOGIN business users in seven native database roles. The existing Windows login maps to a technical runtime user with module-only auth rights and explicit IMPERSONATE on these seven users. Fixed backend mapping, no browser-supplied principal. All domain procedures verify SQL role against the role from SID/epoch. Ownership chaining under CALLER, no EXECUTE AS OWNER, dynamic domain SQL, or grants on global student/teacher views. Authentication remains a trusted backend responsibility.

All 56 operations become stored procedures. Command procedures derive actor/action internally, validate the session before/after business work and perform audit/replay completion inside the caller's transaction. Add five infrastructure SPs (begin read/write, validated session, password snapshot, failure audit): 61 SP total. C# retains COMMIT/ROLLBACK and unknown-ACK behavior. Helpers have explicit grants or are private nested modules.

Acceptance: fresh isolated PROJECT fixture install; native role/user matrix and direct table SELECT/INSERT/UPDATE/DELETE denied; wrong module, wrong role SID, forged Actor and cross-owner access denied; GRANT/REVOKE/DENY proof; auth/operator isolation; successful SQL/HTTP/UI workflows and audit rollback/replay/lost ACK; context REVERT after errors/cancellation; build/frontend checks; guarded transactional migration preserves every existing row and module/permission rollback artifacts. No shared SQL auth-mode changes, owner session revocation or data reset.

Existing instance is Windows-authentication-only. Do not enable Mixed Mode or create Windows accounts. Seven business users are actual impersonation contexts, not seven separately authenticated SQL logins. Document Login → technical User → controlled business User/Role honestly; optional existing Windows staff login binding is an operator task.
