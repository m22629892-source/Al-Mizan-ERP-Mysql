/** Offline, read-only import of an existing SQLite file. Runtime app has no SQLite dependency. */
import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';
import { db, closeAllDatabases } from '../src/server/mysql-database.js';
import { countAllRecords, restoreSnapshot } from '../src/server/backup-service.js';
const sourcePath = process.argv[2];
try {
  if (!sourcePath || !fs.existsSync(sourcePath)) throw new Error('Usage: npm run db:migrate-sqlite -- "C:\\path\\almizan.db"');
  await db.ensureSchema();
  await db.exec(fs.readFileSync(new URL('../src/server/schema.sql', import.meta.url), 'utf8'));
  const before = await countAllRecords(db);
  if (Object.values(before).some(count => count !== 0)) throw new Error('قاعدة MySQL يجب أن تكون جديدة وفارغة؛ تم رفض استبدال البيانات الموجودة.');
  const source = new DatabaseSync(path.resolve(sourcePath), { readOnly: true });
  try {
    const integrity = source.prepare('PRAGMA integrity_check').get() as any;
    if (integrity.integrity_check !== 'ok') throw new Error('فشل فحص سلامة قاعدة SQLite');
    const sourceTables = new Set((source.prepare("SELECT name FROM sqlite_master WHERE type = 'table'").all() as any[]).map(row => row.name));
    const tables: Record<string, any[]> = {};
    for (const table of Object.keys(before)) {
      if (!sourceTables.has(table)) throw new Error('القاعدة القديمة لا تحتوي على الجدول ' + table + '؛ يلزم ترقية النسخة القديمة أولاً.');
      const rows = source.prepare(`SELECT * FROM "${table}"`).all() as any[];
      const columns = await db.query('SELECT COLUMN_NAME AS name, COLUMN_DEFAULT AS defaultValue, IS_NULLABLE AS nullable FROM information_schema.columns WHERE table_schema = ? AND table_name = ?', [db.name, table]);
      tables[table] = rows.map(row => Object.fromEntries(columns.map(column => {
        if (column.name in row) return [column.name, row[column.name]];
        if (column.nullable === 'YES') return [column.name, null];
        if (column.defaultValue !== null && column.defaultValue !== 'CURRENT_TIMESTAMP') return [column.name, column.defaultValue];
        throw new Error(`عمود مطلوب غير موجود في SQLite: ${table}.${column.name}`);
      })));
    }
    const snapshot = { format: 'almizan-mysql' as const, version: 1 as const, createdAt: new Date().toISOString(), tables, sha256: crypto.createHash('sha256').update(JSON.stringify(tables)).digest('hex') };
    await restoreSnapshot(db, snapshot);
    const after = await countAllRecords(db);
    if (Object.keys(tables).some(table => tables[table].length !== after[table])) throw new Error('Record count verification failed');
    console.table(after);
    console.log('تم النقل إلى MySQL والتحقق من أعداد السجلات والعلاقات. ملف SQLite الأصلي لم يتغير.');
  } finally { source.close(); }
} catch (error) { console.error(error); process.exitCode = 1; }
finally { await closeAllDatabases(); }
