# DBMS12 Native Security V2

Canonical schema: 12 tables/99 columns, 61 stored procedures (56 operations + 5 infrastructure), 7 functions, 9 views, 12 triggers. All 62 SQL files are SHA256 pinned by manifest.json. queries/usp_*.sql now defines real procedures; the original 11-SP limit was superseded by owner direction A on 22/10/2026.

OwnerProvision installs installOrder only in a new isolated PROJECT catalog. Install.sql excludes the sample; it is not an upgrade script for an existing database. Never rerun schema/sample on an existing profile. Existing legacy databases use the guarded --rehearse-security-migration / --migrate-security CLI, including exact catalog identity, legacy definition hashes, transactional data fingerprints and local rollback receipts.

Business roles execute explicitly granted modules under CALLER with ownership chaining; no EXECUTE AS OWNER or direct table DML. Runtime authentication is separate and can impersonate exactly seven business users. Full model, Login/User distinction and matrix: ../../docs/SQL_SECURITY.md, ../../docs/SQL_SECURITY_MATRIX.md.

To review a SQL edit, update hashes explicitly with tools/Refresh-SqlManifest.cjs and run tools/Verify-Source.cjs. Never update a live profile merely to suppress a pin mismatch. Permissions and modules must match the reviewed version first.
