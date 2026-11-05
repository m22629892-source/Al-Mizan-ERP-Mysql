import { initDb } from '../src/server/db.js';
import { seedInitialData } from '../src/server/seed.js';
import { closeAllDatabases, db } from '../src/server/mysql-database.js';
try {
  await initDb();
  if (process.argv.includes('--demo')) await seedInitialData();
  console.log(`MySQL database ready: ${db.name}. Demo data: ${process.argv.includes('--demo')}`);
} catch (error) { console.error(error); process.exitCode = 1; }
finally { await closeAllDatabases(); }
