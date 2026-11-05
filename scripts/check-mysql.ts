import { db, closeAllDatabases } from '../src/server/mysql-database.js';
try {
  const rows = await db.query('SELECT VERSION() AS version, DATABASE() AS database_name, @@port AS port');
  console.table(rows);
  console.log('MySQL connection successful');
} catch (error: any) {
  console.error('تعذر الاتصال بـMySQL. راجع الخدمة وملف .env:', error.code || error.message); process.exitCode = 1;
} finally { await closeAllDatabases(); }
