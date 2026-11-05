import fs from 'node:fs';
import mysql from 'mysql2';
import { db, closeAllDatabases } from '../src/server/mysql-database.js';
// Development utility: exports only a fresh, seeded test schema to a Workbench SQL file.
if (!db.name.startsWith('almizan_test_')) throw new Error('Demo export requires an isolated test schema');
const { initDb } = await import('../src/server/db.js');
const { seedInitialData } = await import('../src/server/seed.js');
try {
  await initDb(); await seedInitialData();
  const schema = fs.readFileSync(new URL('../src/server/schema.sql', import.meta.url), 'utf8');
  const tables = [...schema.matchAll(/CREATE TABLE IF NOT EXISTS `(\w+)`/g)].map(match => match[1]);
  const output = ['-- Al-Mizan ERP DEMO ONLY. Run on a NEW database. Demo owner: owner / admin123.\n-- No real customer data is included.\nCREATE DATABASE IF NOT EXISTS almizan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\nUSE almizan;\nSET NAMES utf8mb4;\nSET time_zone = \'+00:00\';\n', schema, 'START TRANSACTION;'];
  for (const table of tables) {
    const rows = await db.query(`SELECT * FROM \`${table}\``);
    // Order self-referencing master data by parent dependency.
    const pending = [...rows]; const done = new Set<string>(); const ordered: any[] = [];
    const selfKeys = (await db.query('SELECT COLUMN_NAME AS col FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND REFERENCED_TABLE_NAME = ?', [db.name, table, table])).map(row => row.col);
    while (pending.length) {
      const index = pending.findIndex(row => selfKeys.every(col => row[col] == null || done.has(row[col])));
      if (index < 0) throw new Error('Cyclic demo data: ' + table);
      const row = pending.splice(index,1)[0]; ordered.push(row); done.add(row.id);
    }
    for (const row of ordered) {
      const keys = Object.keys(row);
      const values = keys.map(key => typeof row[key] === 'string' && /^\d{4}-\d\d-\d\dT/.test(row[key]) ? row[key].slice(0,19).replace('T',' ') : row[key]);
      output.push(mysql.format(`INSERT INTO \`${table}\` (${keys.map(key=>`\`${key}\``).join(',')}) VALUES (${keys.map(()=>'?').join(',')});`, values));
    }
  }
  output.push('COMMIT;\nSELECT \'Al-Mizan demo database ready\' AS result;');
  fs.writeFileSync(new URL('../database/almizan_mysql_demo.sql', import.meta.url), output.join('\n'));
  console.log('Workbench demo SQL exported.');
} finally { await db.dropTestSchema(); await closeAllDatabases(); }
