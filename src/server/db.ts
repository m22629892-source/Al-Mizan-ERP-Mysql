import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { MysqlDatabase } from './mysql-database.js';
export { MysqlDatabase, createDatabaseConnection, getDatabasePath, db } from './mysql-database.js';
import { db } from './mysql-database.js';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
export async function initDb(targetDb: MysqlDatabase = db) {
  try {
    await targetDb.ensureSchema();
    const schemaPath = path.resolve(__dirname, 'schema.sql');
    if (fs.existsSync(schemaPath)) {
      const schemaSql = fs.readFileSync(schemaPath, 'utf8');
      (await targetDb.exec(schemaSql));
    }

    // Incremental Safe Migrations (Sessions, Idempotency, Rate Limiting, Settings)
    /* Tables are versioned in schema.sql. */

    // Ensure default settings exist
    const negativeStockCheck = (await targetDb.prepare('SELECT setting_value FROM system_settings WHERE setting_key = ?').get('allow_negative_stock'));
    if (!negativeStockCheck) {
      (await targetDb.prepare('INSERT INTO system_settings (setting_key, setting_value) VALUES (?, ?)').run('allow_negative_stock', 'false'));
    }

    // Item Categories Table Migration
    /* Tables are versioned in schema.sql. */

    // Safely add category_id to items if it doesn't already exist
    try {
      /* Tables are versioned in schema.sql. */
    } catch {
      // Column already exists, safe to ignore
    }

    // Clean legacy generic permissions for storekeeper to enforce strict security
    try {
      (await targetDb.exec(`
        DELETE FROM user_permissions WHERE role = 'storekeeper' AND permission_key IN ('view', 'add', 'edit_draft', 'print');
        INSERT IGNORE INTO user_permissions (id, role, permission_key) VALUES ('perm_storekeeper_inventory_count_view', 'storekeeper', 'inventory_count.view');
      `));
    } catch {
      // Table might not exist yet
    }

    // Seed default categories if table is empty
    const catCount = (await targetDb.prepare('SELECT COUNT(*) as cnt FROM item_categories').get()) as { cnt: number };
    if (catCount.cnt === 0) {
      const defaultCats = [
        { id: 'cat_hardware', code: 'CAT-01', name_ar: 'أجهزة حاسب آلي', name_en: 'Computers & Laptops' },
        { id: 'cat_display', code: 'CAT-02', name_ar: 'شاشات وعرض', name_en: 'Monitors & Displays' },
        { id: 'cat_printers', code: 'CAT-03', name_ar: 'طابعات وماسحات', name_en: 'Printers & Scanners' },
        { id: 'cat_network', code: 'CAT-04', name_ar: 'شبكات واتصالات', name_en: 'Networking & Telecom' },
        { id: 'cat_accessories', code: 'CAT-05', name_ar: 'ملحقات وإكسسوارات', name_en: 'Accessories & Peripherals' },
        { id: 'cat_services', code: 'CAT-06', name_ar: 'خدمات فنية', name_en: 'Technical Services' },
      ];
      const insCat = targetDb.prepare('INSERT INTO item_categories (id, code, name_ar, name_en, is_active) VALUES (?, ?, ?, ?, 1)');
      for (const c of defaultCats) {
        (await insCat.run(c.id, c.code, c.name_ar, c.name_en));
      }
      // Link existing items to categories by matching name_ar
      (await targetDb.exec(`
        UPDATE items SET category_id = (
          SELECT id FROM item_categories WHERE item_categories.name_ar = items.category LIMIT 1
        ) WHERE category_id IS NULL;
      `));
    }

    // Ensure party_sequences and account_sequences tables exist
    /* Tables are versioned in schema.sql. */

    // Safely add original_invoice_item_id to purchase_return_items if missing
    try {
      /* Tables are versioned in schema.sql. */
    } catch {
      // Column already exists, safe to ignore
    }

    // Initialize party_sequences from existing parties
    for (const pType of ['customer', 'supplier']) {
      const pfx = pType === 'supplier' ? 'SUPP' : 'CUST';
      try {
        const rows = (await targetDb.prepare("SELECT code FROM parties WHERE code LIKE ?").all(`${pfx}-%`)) as { code: string }[];
        let maxNum = 0;
        for (const r of rows) {
          const parts = r.code.split('-');
          const n = parseInt(parts[parts.length - 1], 10);
          if (!isNaN(n) && n > maxNum) maxNum = n;
        }
        (await targetDb.prepare(`
          INSERT INTO party_sequences (type, last_number)
          VALUES (?, ?)
          ON DUPLICATE KEY UPDATE last_number = GREATEST(last_number, VALUES(last_number))
        `).run(pType, maxNum));
      } catch {
        // Table may be empty
      }
    }

    // Initialize account_sequences for roots
    const rootMap: Record<string, string> = {
      asset: '1',
      liability: '2',
      equity: '3',
      revenue: '4',
      cogs: '5',
      expense: '6'
    };
    for (const [accType, digit] of Object.entries(rootMap)) {
      try {
        const roots = (await targetDb.prepare("SELECT code FROM accounts WHERE parent_id IS NULL AND code LIKE ?").all(`${digit}%`)) as { code: string }[];
        let maxRoot = parseInt(digit, 10);
        for (const r of roots) {
          const n = parseInt(r.code, 10);
          if (!isNaN(n) && n > maxRoot) maxRoot = n;
        }
        (await targetDb.prepare(`
          INSERT INTO account_sequences (sequence_key, last_number)
          VALUES (?, ?)
          ON DUPLICATE KEY UPDATE last_number = GREATEST(last_number, VALUES(last_number))
        `).run(`root_${accType}`, maxRoot));
      } catch {
        // Table may be empty
      }
    }

    // Initialize account_sequences for parents
    try {
      const parentAccounts = (await targetDb.prepare('SELECT id, code FROM accounts WHERE is_group = 1').all()) as { id: string; code: string }[];
      for (const p of parentAccounts) {
        const siblings = (await targetDb.prepare('SELECT code FROM accounts WHERE parent_id = ?').all(p.id)) as { code: string }[];
        let maxSuffix = 0;
        for (const s of siblings) {
          if (s.code.startsWith(p.code)) {
            const suf = parseInt(s.code.slice(p.code.length), 10);
            if (!isNaN(suf) && suf > maxSuffix) maxSuffix = suf;
          }
        }
        (await targetDb.prepare(`
          INSERT INTO account_sequences (sequence_key, last_number)
          VALUES (?, ?)
          ON DUPLICATE KEY UPDATE last_number = GREATEST(last_number, VALUES(last_number))
        `).run(`parent_${p.id}`, maxSuffix));
      }
    } catch {
      // Table may be empty
    }

    // Ensure delete_draft and unit-specific screen permissions are granted to relevant roles
    const standardRolePerms: Record<string, string[]> = {
      admin: [
        'dashboard.view', 'accounts.view', 'accounts.create', 'accounts.edit', 'accounts.delete', 'accounts.manage',
        'journal.view', 'journal.create', 'journal.edit_draft', 'journal.delete_draft', 'journal.post', 'journal.reverse', 'journal.print', 'journal.export',
        'sales.view', 'sales.create', 'sales.edit_draft', 'sales.delete_draft', 'sales.post', 'sales.reverse', 'sales.print', 'sales.export',
        'sales_returns.view', 'sales_returns.create', 'sales_returns.edit_draft', 'sales_returns.delete_draft', 'sales_returns.post', 'sales_returns.reverse', 'sales_returns.print',
        'purchases.view', 'purchases.create', 'purchases.edit_draft', 'purchases.delete_draft', 'purchases.post', 'purchases.reverse', 'purchases.print', 'purchases.export',
        'purchase_returns.view', 'purchase_returns.create', 'purchase_returns.edit_draft', 'purchase_returns.delete_draft', 'purchase_returns.post', 'purchase_returns.reverse', 'purchase_returns.print',
        'parties.view', 'parties.create', 'parties.edit', 'parties.delete', 'parties.statement',
        'inventory.view', 'items.view', 'items.create', 'items.edit', 'items.delete', 'items.manage',
        'treasury.view', 'treasury.receipt.create', 'treasury.receipt', 'treasury.payment.create', 'treasury.payment', 'treasury.reverse', 'treasury.print',
        'reports.view', 'reports.print', 'reports.export', 'aging.view',
        'month_close.view', 'period.review', 'period.close', 'period.reopen',
        'excel_import.view', 'import.excel', 'excel_analytics.view', 'excel_analytics.export', 'excel_analytics.chat',
        'backup.view', 'backup.create', 'backup.restore',
        'bank_reconciliation.view', 'bank.reconcile',
        'inventory_count.view', 'inventory.count',
        'eta.view', 'eta.send', 'tests.view', 'tests.run', 'users.view', 'users.manage',
        'view_cost', 'view_profit', 'manage_settings', 'reopen_period',
        'view', 'add', 'edit_draft', 'delete_draft', 'post', 'reverse', 'print', 'export'
      ],
      finance_manager: [
        'dashboard.view', 'accounts.view', 'accounts.create', 'accounts.edit', 'accounts.manage',
        'journal.view', 'journal.create', 'journal.edit_draft', 'journal.delete_draft', 'journal.post', 'journal.reverse', 'journal.print', 'journal.export',
        'sales.view', 'sales.create', 'sales.edit_draft', 'sales.delete_draft', 'sales.post', 'sales.reverse', 'sales.print', 'sales.export',
        'sales_returns.view', 'sales_returns.create', 'sales_returns.edit_draft', 'sales_returns.delete_draft', 'sales_returns.post', 'sales_returns.reverse', 'sales_returns.print',
        'purchases.view', 'purchases.create', 'purchases.edit_draft', 'purchases.delete_draft', 'purchases.post', 'purchases.reverse', 'purchases.print', 'purchases.export',
        'purchase_returns.view', 'purchase_returns.create', 'purchase_returns.edit_draft', 'purchase_returns.delete_draft', 'purchase_returns.post', 'purchase_returns.reverse', 'purchase_returns.print',
        'parties.view', 'parties.create', 'parties.edit', 'parties.statement',
        'inventory.view', 'items.view',
        'treasury.view', 'treasury.receipt.create', 'treasury.receipt', 'treasury.payment.create', 'treasury.payment', 'treasury.reverse', 'treasury.print',
        'reports.view', 'reports.print', 'reports.export', 'aging.view',
        'month_close.view', 'period.review', 'period.close', 'period.reopen',
        'excel_import.view', 'import.excel', 'excel_analytics.view', 'excel_analytics.export', 'excel_analytics.chat',
        'bank_reconciliation.view', 'bank.reconcile',
        'inventory_count.view', 'inventory.count',
        'eta.view', 'tests.view',
        'view_cost', 'view_profit', 'reopen_period',
        'view', 'add', 'edit_draft', 'delete_draft', 'post', 'reverse', 'print', 'export'
      ],
      accountant: [
        'dashboard.view', 'accounts.view',
        'journal.view', 'journal.create', 'journal.edit_draft', 'journal.delete_draft', 'journal.post', 'journal.print', 'journal.export',
        'sales.view', 'sales.create', 'sales.edit_draft', 'sales.delete_draft', 'sales.post', 'sales.print', 'sales.export',
        'sales_returns.view', 'sales_returns.create', 'sales_returns.edit_draft', 'sales_returns.delete_draft', 'sales_returns.post', 'sales_returns.print',
        'purchases.view', 'purchases.create', 'purchases.edit_draft', 'purchases.delete_draft', 'purchases.post', 'purchases.print', 'purchases.export',
        'purchase_returns.view', 'purchase_returns.create', 'purchase_returns.edit_draft', 'purchase_returns.delete_draft', 'purchase_returns.post', 'purchase_returns.print',
        'parties.view', 'parties.create', 'parties.edit', 'parties.statement',
        'inventory.view', 'items.view',
        'treasury.view', 'treasury.receipt.create', 'treasury.receipt', 'treasury.payment.create', 'treasury.payment', 'treasury.print',
        'reports.view', 'reports.print', 'reports.export', 'aging.view',
        'month_close.view', 'period.review',
        'excel_import.view', 'import.excel', 'excel_analytics.view', 'excel_analytics.export', 'excel_analytics.chat',
        'bank_reconciliation.view', 'bank.reconcile',
        'inventory_count.view', 'inventory.count',
        'eta.view',
        'view_cost', 'view_profit',
        'view', 'add', 'edit_draft', 'delete_draft', 'post', 'print', 'export'
      ],
      sales_officer: [
        'dashboard.view',
        'sales.view', 'sales.create', 'sales.edit_draft', 'sales.delete_draft', 'sales.print', 'sales.export',
        'sales_returns.view', 'sales_returns.create', 'sales_returns.edit_draft', 'sales_returns.delete_draft', 'sales_returns.print',
        'parties.view', 'parties.create', 'parties.edit', 'parties.statement',
        'inventory.view', 'items.view'
      ],
      purchase_officer: [
        'dashboard.view',
        'purchases.view', 'purchases.create', 'purchases.edit_draft', 'purchases.delete_draft', 'purchases.print', 'purchases.export',
        'purchase_returns.view', 'purchase_returns.create', 'purchase_returns.edit_draft', 'purchase_returns.delete_draft', 'purchase_returns.print',
        'parties.view', 'parties.create', 'parties.edit', 'parties.statement',
        'inventory.view', 'items.view',
        'view_cost'
      ],
      storekeeper: [
        'inventory.view', 'items.view', 'items.create', 'items.edit', 'items.manage',
        'inventory_count.view', 'inventory.count'
      ],
      cashier: [
        'dashboard.view',
        'treasury.view', 'treasury.receipt.create', 'treasury.receipt', 'treasury.print'
      ],
      auditor_readonly: [
        'dashboard.view', 'accounts.view', 'journal.view',
        'sales.view', 'sales_returns.view', 'purchases.view', 'purchase_returns.view',
        'parties.view', 'inventory.view', 'items.view', 'treasury.view',
        'reports.view', 'reports.print', 'reports.export', 'aging.view',
        'month_close.view', 'bank_reconciliation.view', 'inventory_count.view', 'excel_analytics.view', 'excel_analytics.export',
        'view_cost', 'view_profit'
      ]
    };

    // Clean up any legacy generic permissions for specialized roles so they don't bleed across modules
    (await targetDb.exec(`
      DELETE FROM user_permissions WHERE role IN ('sales_officer', 'purchase_officer', 'storekeeper', 'cashier') 
      AND permission_key IN ('add', 'edit_draft', 'delete_draft', 'post', 'view', 'print', 'export');
    `));

    const insertPermStmt = targetDb.prepare(`
      INSERT IGNORE INTO user_permissions (id, role, permission_key)
      VALUES (?, ?, ?)
    `);

    for (const [roleName, permList] of Object.entries(standardRolePerms)) {
      for (const pKey of permList) {
        try {
          (await insertPermStmt.run(`perm_${roleName}_${pKey.replace(/\./g, '_')}`, roleName, pKey));
        } catch {
          // Safe to ignore duplicate
        }
      }
    }

    // Ensure document_sequences has valid starting points above any existing records
    const syncSequences = [
      { doc: 'PINV', branch: 'br_cairo', table: 'purchase_invoices', col: 'invoice_number', prefix: 'PINV-2026-CAI' },
      { doc: 'INV', branch: 'br_cairo', table: 'sales_invoices', col: 'invoice_number', prefix: 'INV-2026-CAI' },
      { doc: 'SR', branch: 'br_cairo', table: 'sales_returns', col: 'return_number', prefix: 'SR-2026-CAI' },
      { doc: 'PR', branch: 'br_cairo', table: 'purchase_returns', col: 'return_number', prefix: 'PR-2026-CAI' },
      { doc: 'RV', branch: 'br_cairo', table: 'payment_vouchers', col: 'voucher_number', prefix: 'RV-2026-CAI' },
      { doc: 'PV', branch: 'br_cairo', table: 'payment_vouchers', col: 'voucher_number', prefix: 'PV-2026-CAI' },
      { doc: 'JV', branch: 'br_cairo', table: 'journal_entries', col: 'entry_number', prefix: 'JV-2026-CAI' },
    ];
    for (const s of syncSequences) {
      try {
        const row = (await targetDb.prepare(`SELECT ${s.col} as num FROM ${s.table} WHERE ${s.col} LIKE ? ORDER BY ${s.col} DESC LIMIT 1`).get(`${s.prefix}-%`)) as { num: string } | undefined;
        if (row && row.num) {
          const n = parseInt(row.num.split('-').pop() || '0', 10);
          if (n > 0) {
            (await targetDb.prepare(`
              INSERT INTO document_sequences (id, doc_type, branch_id, fiscal_year_id, prefix, next_number)
              VALUES (?, ?, ?, 'fy_2026', ?, ?)
              ON DUPLICATE KEY UPDATE next_number = GREATEST(next_number, ?)
            `).run(`seq_${s.doc}_${s.branch}_2026`, s.doc, s.branch, s.prefix, n + 1, n + 1));
          }
        }
      } catch {
        // Table might be unpopulated or schema pending
      }
    }

  } catch (err) {
    console.error('Fatal Database Initialization Error:', err);
    throw err;
  }
}

export async function effectivePermissions(userId: string, role: string, targetDb: MysqlDatabase = db): Promise<string[]> {
  if (role === 'owner') {
    const allP = (await targetDb.prepare('SELECT DISTINCT permission_key FROM user_permissions').all()) as { permission_key: string }[];
    const set = new Set(allP.map(p => p.permission_key));
    set.add('*');
    // Core default keys for owner
    ['view', 'add', 'edit_draft', 'delete_draft', 'post', 'reverse', 'print', 'export', 'view_cost', 'view_profit', 'treasury.receipt', 'treasury.payment', 'treasury.reverse', 'accounts.manage', 'items.manage', 'users.manage', 'manage_settings', 'reopen_period'].forEach(k => set.add(k));
    return Array.from(set);
  }

  // Check individual permissions table
  const customRow = (await targetDb.prepare('SELECT permission_keys FROM individual_permissions WHERE user_id = ?').get(userId)) as { permission_keys: string } | undefined;
  if (customRow && customRow.permission_keys !== null) {
    try {
      const parsed = JSON.parse(customRow.permission_keys);
      if (Array.isArray(parsed)) {
        return parsed; // Returns custom permissions even if empty array []
      }
    } catch {
      // Fallback
    }
  }

  // Inherit role permissions
  const rolePerms = (await targetDb.prepare('SELECT permission_key FROM user_permissions WHERE role = ?').all(role)) as { permission_key: string }[];
  return rolePerms.map(r => r.permission_key);
}

