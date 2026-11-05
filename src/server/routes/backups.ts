import { Router } from '../mysql-router.js';
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { db } from '../db.js';
import { AuthenticatedRequest, requireAuth, requirePermission } from '../api.js';
import { logAudit } from '../accounting-engine.js';
import { createSnapshot, readSnapshot, restoreSnapshot, countAllRecords } from '../backup-service.js';
export { countAllRecords } from '../backup-service.js';
export const backupsRouter = Router();

async function handleCreateBackup(req: AuthenticatedRequest, res: any) {
  const { filePath, counts } = await createSnapshot(db);
  const stat = await fs.stat(filePath);
  const id = 'bk_' + crypto.randomUUID();
  await db.prepare(`INSERT INTO system_backups (id, filename, file_path, file_size, schema_version, integrity_status, record_counts_json, created_by) VALUES (?, ?, ?, ?, 'mysql-1', 'OK', ?, ?)`).run(id, path.basename(filePath), filePath, stat.size, JSON.stringify(counts), req.user!.id);
  await logAudit(req.user!.id, 'CREATE_BACKUP', 'system_backups', id, 'إنشاء نسخة MySQL متسقة مع فحص SHA-256');
  res.json({ success: true, message: 'تم إنشاء نسخة MySQL الاحتياطية', backup: { id, filename: path.basename(filePath), file_path: filePath, file_size: stat.size, record_counts: counts, integrity_status: 'OK', schema_version: 'mysql-1' } });
}
backupsRouter.post('/create', requireAuth, requirePermission('backup.create'), handleCreateBackup);
backupsRouter.post('/', requireAuth, requirePermission('backup.create'), handleCreateBackup);
backupsRouter.get('/', requireAuth, requirePermission('backup.view', 'backup.create', 'backup.restore'), async (_req, res) => {
  const rows = await db.prepare(`SELECT b.*, u.display_name AS creator_name FROM system_backups b JOIN users u ON b.created_by = u.id ORDER BY b.created_at DESC`).all();
  res.json({ success: true, backups: rows.map(row => ({ ...row, record_counts: JSON.parse(row.record_counts_json), created_by: row.creator_name })), currentCounts: await countAllRecords(db) });
});
backupsRouter.get('/:id/download', requireAuth, requirePermission('backup.download', 'backup.create', 'backup.restore'), async (req, res) => {
  const backup = await db.prepare('SELECT * FROM system_backups WHERE id = ?').get(req.params.id);
  if (!backup) { res.status(404).json({ error: 'النسخة غير موجودة' }); return; }
  await readSnapshot(backup.file_path);
  res.download(backup.file_path, backup.filename);
});
backupsRouter.post('/verify', requireAuth, requirePermission('backup.verify', 'backup.restore'), async (req, res) => {
  const backup = await db.prepare('SELECT * FROM system_backups WHERE id = ?').get(req.body.backupId);
  if (!backup) { res.status(404).json({ error: 'النسخة غير موجودة' }); return; }
  const snapshot = await readSnapshot(backup.file_path);
  const currentCounts = await countAllRecords(db);
  const isCompatible = Object.keys(currentCounts).length === Object.keys(snapshot.tables).length && Object.keys(currentCounts).every(table => Array.isArray(snapshot.tables[table]));
  res.json({ success: true, integrity: 'OK', backupCounts: Object.fromEntries(Object.entries(snapshot.tables).map(([table, rows]) => [table, rows.length])), currentCounts, isCompatible });
});
backupsRouter.post('/restore', requireAuth, requirePermission('backup.restore'), async (req: AuthenticatedRequest, res) => {
  if (req.body.confirmSafety !== true) { res.status(400).json({ error: 'يجب تأكيد استبدال البيانات الحالية' }); return; }
  const backup = await db.prepare('SELECT * FROM system_backups WHERE id = ?').get(req.body.backupId);
  if (!backup) { res.status(404).json({ error: 'النسخة غير موجودة' }); return; }
  const snapshot = await readSnapshot(backup.file_path);
  const safety = await createSnapshot(db, `almizan_pre_restore_${Date.now()}.json`);
  await restoreSnapshot(db, snapshot);
  // All tokens are invalidated after a restore; permissions are reloaded on next login.
  await db.prepare('DELETE FROM user_sessions').run();
  await logAudit(req.user!.id, 'RESTORE_DATABASE', 'system_backups', backup.id, 'استعادة MySQL؛ نسخة الأمان: ' + path.basename(safety.filePath));
  res.json({ success: true, message: 'تمت الاستعادة. سجّل الدخول مرة أخرى.', safetyBackupFile: path.basename(safety.filePath), restoredCounts: await countAllRecords(db) });
});
