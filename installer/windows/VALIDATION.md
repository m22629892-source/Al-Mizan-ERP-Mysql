# Windows installer validation

Build: Node.js 26.13.0, Windows x64. New private database: MySQL Community Server 8.4.13, downloaded directly from Oracle and checked against the build manifest SHA-256. Existing ERP databases remain supported by the MySQL runtime.

## Automated verification

`Build Windows Setup` compiles an actual Inno Setup EXE on windows-2022, then installs it with an answers file. Assertions cover:

- Real LAN server install with a private MySQL Windows service.
- New company and chosen owner credentials, no demo invoices or users, zero opening cash balance.
- ERP and database services, MySQL health endpoint, application login and a Private-profile local-subnet firewall rule.
- Upgrade/reinstall preserves the DPAPI-protected configuration, chosen administrator password and a customer record created before upgrading.
- Uninstall removes services while retaining the database directory.
- Client-only installation points to the entered server URL without installing Node.js, the ERP server or a MySQL database. Client URL verification uses a local HTTP fixture.
- Fresh standalone install binds to 127.0.0.1 and creates no LAN firewall exception; services run as LocalService.

`installer/windows/test-bootstrap.ts` was also executed against a local MySQL 8.0.46 instance with the bundled server/bootstrap JavaScript: clean production bootstrap, 65 baseline accounts, no demo business records, chosen owner, repeat setup preserving name/password, and production HTTP login passed.

The existing regression checks passed after extracting the shared chart of accounts: 48 financial/statistical suites, 23 security checks, 17 operational checks and 40 MySQL integration checks. The repository's MySQL/Windows workflow runs separately from the installer build.

## Limits

- This is automated Windows Server 2022 runner verification, not certification of every Windows 10/11 machine or group policy. The interactive wizard is compiled and validated, but its pages are not driven by UI automation.
- Actual connectivity between two physical customer computers must be checked on their LAN. Client-only verification does not prove a particular router/firewall configuration.
- Setup is unsigned by a commercial certificate. SHA256SUMS.txt accompanies the EXE. No security software needs to be disabled.
- A new private MySQL needs internet during first setup and disk space for its download/extraction. Existing database/client modes do not download MySQL. Data, backups and credentials are kept outside Program Files; uninstall preserves them.
- MySQL engine upgrades and moving DPAPI-protected configuration to a different Windows machine are not automatic. Use application backups for moving data.

## Rebuild

Run the **Build Windows Setup** workflow on branch `codex/windows-setup`. Its successful build produces the `AlMizanERP-Windows-Setup` artifact containing the EXE, checksums and Arabic customer guide. Download and retain that artifact before its retention period expires. MySQL binaries are downloaded by the customer's installer from Oracle, not redistributed inside the ERP EXE; bundled runtime/dependency license notices are included.
