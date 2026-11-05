import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { MysqlDatabase } from './mysql-database.js';

export interface DatabaseSnapshot {
  format: 'almizan-mysql'; version: 1; createdAt: string;
  tables: Record<string, any[]>; sha256: string;
}
export const backupDirectory = path.resolve(process.env.ALMIZAN_BACKUP_DIR || 'backups');
export async function tableNames(database: MysqlDatabase): Promise<string[]> {
  const rows = await database.query('SELECT TABLE_NAME AS name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY TABLE_NAME', [database.name, 'BASE TABLE']);
  return rows.map(row => row.name);
}
export async function countAllRecords(database: MysqlDatabase) {
  const counts: Record<string, number> = {};
  for (const table of await tableNames(database)) {
    const rows = await database.query(`SELECT COUNT(*) AS cnt FROM \`${table}\``);
    counts[table] = Number(rows[0].cnt);
  }
  return counts;
}
export async function createSnapshot(database: MysqlDatabase, filename?: string) {
  const snapshot = await database.transaction(async () => {
    const tables: Record<string, any[]> = {};
    for (const table of await tableNames(database)) tables[table] = await database.query(`SELECT * FROM \`${table}\``);
    return { format: 'almizan-mysql', version: 1, createdAt: new Date().toISOString(), tables,
      sha256: crypto.createHash('sha256').update(JSON.stringify(tables)).digest('hex') } as DatabaseSnapshot;
  })();
  await fs.mkdir(backupDirectory, { recursive: true });
  const filePath = path.join(backupDirectory, filename || `almizan_${Date.now()}_${crypto.randomBytes(4).toString('hex')}.json`);
  await fs.writeFile(filePath, JSON.stringify(snapshot), { mode: 0o600, flag: 'wx' });
  return { filePath, snapshot, counts: Object.fromEntries(Object.entries(snapshot.tables).map(([table, rows]) => [table, rows.length])) };
}
export async function readSnapshot(filePath: string): Promise<DatabaseSnapshot> {
  if (path.dirname(path.resolve(filePath)) !== backupDirectory) throw new Error('مسار النسخة الاحتياطية غير مسموح به');
  const snapshot = JSON.parse(await fs.readFile(filePath, 'utf8')) as DatabaseSnapshot;
  if (snapshot.format !== 'almizan-mysql' || snapshot.version !== 1 || !snapshot.tables ||
      snapshot.sha256 !== crypto.createHash('sha256').update(JSON.stringify(snapshot.tables)).digest('hex')) throw new Error('النسخة الاحتياطية غير متوافقة أو فشل فحص سلامتها');
  return snapshot;
}
export async function restoreSnapshot(database: MysqlDatabase, snapshot: DatabaseSnapshot) {
  const tables = await tableNames(database);
  if (tables.length !== Object.keys(snapshot.tables).length || tables.some(table => !Array.isArray(snapshot.tables[table]))) throw new Error('جداول النسخة لا تطابق إصدار البرنامج');
  await database.transaction(async () => {
    // Constraint checks are restored on this same connection even on failure. Validate every FK before COMMIT.
    await database.query('SET FOREIGN_KEY_CHECKS = 0');
    try {
      for (const table of tables) await database.query(`DELETE FROM \`${table}\``);
      for (const table of tables) {
        const columns = (await database.query('SELECT COLUMN_NAME AS name FROM information_schema.columns WHERE table_schema = ? AND table_name = ?', [database.name, table])).map(row => row.name);
        for (const row of snapshot.tables[table]) {
          const keys = Object.keys(row);
          if (keys.length !== columns.length || keys.some(key => !columns.includes(key))) throw new Error('أعمدة غير متوافقة: ' + table);
          await database.query(`INSERT INTO \`${table}\` (${keys.map(key => `\`${key}\``).join(',')}) VALUES (${keys.map(() => '?').join(',')})`, keys.map(key => row[key]));
        }
      }
      const relations = await database.query(`SELECT TABLE_NAME AS child, COLUMN_NAME AS col, REFERENCED_TABLE_NAME AS parent, REFERENCED_COLUMN_NAME AS ref FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL`, [database.name]);
      for (const relation of relations) {
        const rows = await database.query(`SELECT COUNT(*) AS cnt FROM \`${relation.child}\` c LEFT JOIN \`${relation.parent}\` p ON c.\`${relation.col}\` = p.\`${relation.ref}\` WHERE c.\`${relation.col}\` IS NOT NULL AND p.\`${relation.ref}\` IS NULL`);
        if (Number(rows[0].cnt)) throw new Error('علاقات غير سليمة: ' + relation.child + '.' + relation.col);
      }
    } finally { await database.query('SET FOREIGN_KEY_CHECKS = 1'); }
  })();
}
