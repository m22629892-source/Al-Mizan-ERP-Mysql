# MySQL conversion validation — 2026-11-05

Source baseline: `0726ded708c12981e2b8ef12546cac3f1d293ff1`.

## Implemented

- Replaced the application SQLite runtime with mysql2 connection pools and awaited database calls throughout authentication, permissions, accounting, invoices, treasury, reports, import and AI settings.
- Converted SQL dialect and 55 tables / 104 foreign keys to MySQL InnoDB. Fixed point storage uses DECIMAL(24,8); the existing numeric JSON contract is preserved. Case-sensitive table collation preserves SQLite identifier equality.
- Kept one checked-out connection for each transaction using AsyncLocalStorage, nested savepoints, and a per-database advisory writer lock. HTTP mutation responses are buffered until commit; errors roll back. Login failures explicitly retain rate-limit counters.
- Added independent transactional wrappers to accounting operations, including numbering, posting, reversal and stock deduction.
- Replaced SQLite file backups with logical MySQL snapshots, SHA-256 checks, column/FK validation, transactional restore and a safety copy. Restoring invalidates sessions.
- Fixed request-body hashing for replay of sales/purchase invoice idempotency keys.
- Provided schema-only SQL, a full Workbench demo SQL file, least-privilege local app-user SQL, .env template and Arabic Windows instructions.
- Added read-only SQLite migration using Node's built-in node:sqlite; refuses a nonempty MySQL target, checks source integrity and all target FKs, and reports record counts.
- Removed better-sqlite3 and its types from package.json/package-lock, and removed the obsolete Bun lockfile.

## Executed locally

Runtime: **Node.js v26.13.0**, **MySQL Community Server 8.0.46**, Linux.

| Check | Result |
|---|---|
| npm ci with Node 26.13.0 | Passed |
| TypeScript check | Passed |
| Vite production build | Passed; existing bundle-size warning remains |
| Financial/statistical acceptance suites | 48 passed / 0 failed |
| Authentication and permission audit | 23 passed / 0 failed |
| Operational API verification | 17 passed / 0 failed |
| MySQL-specific integration checks | 40 passed / 0 failed |
| Workbench demo SQL executed as a complete script | Imported all 55 tables and demo records |
| SQLite → MySQL fixture migration | Record counts and journal debit/credit totals matched; source file SHA-256 unchanged |
| Application user with the supplied limited grants | Initialization, demo seeding and reads passed |
| Production HTTP server smoke check | MySQL health, HTML/JS assets, login and dashboard passed |

MySQL-specific checks cover 30 read endpoints, concurrent document numbering using separate connection pools, nested rollback, HTTP rollback before response, persistent failed-login counters, idempotent replay/conflict, and HTTP create/edit/delete of journal and all four invoice/return draft types.

## Scope and limits

- The user's screenshot shows MySQL **8.0.28**. The workflow targets exactly mysql:8.0.28 with Node 26.13.0. Its remote outcome is separate from the local MySQL 8.0.46 results above.
- Windows workflow checks clean dependency installation, TypeScript and build; database integration runs on Linux. This is not a claim that every Windows UI interaction was manually tested.
- No real user database was supplied or migrated. Use the migration on a copy and reconcile financial reports before replacing a live system.
- Backups are plaintext JSON, contain sensitive data and are not encrypted. SHA-256 detects accidental corruption, not authenticated tampering. Keep a protected off-machine copy.
- The writer lock favors accounting consistency over maximum write throughput. No high-load benchmark or broad security/production certification is claimed. Direct external SQL writes must be stopped during backup/restore.
- Demo login is owner / admin123. It is explicitly demo data; change it before allowing other users access.
