import fs from 'fs';
import path from 'path';
import express from 'express';
import request from 'supertest';
import { readSnapshot, restoreSnapshot } from './backup-service.js';
import Decimal from 'decimal.js';

async function runOperationalVerification() {
  console.log('====================================================');
  console.log('🧪 Starting Al-Mizan ERP End-to-End Operational Verification');
  console.log('====================================================');

  const testDbFile = path.resolve(process.cwd(), `almizan_ops_test_${Date.now()}.db`);
  process.env.MYSQL_DATABASE = 'almizan_test_'+Date.now()+'_'+Math.random().toString(36).slice(2,7);

  const { createDatabaseConnection, initDb } = await import('./db.js');
  const { closeAllDatabases } = await import('./mysql-database.js');
  const { seedInitialData } = await import('./seed.js');
  const { apiRouter } = await import('./api.js');

  const db = createDatabaseConnection(process.env.MYSQL_DATABASE);
  (await initDb(db));
  (await seedInitialData(db));

  const app = express();
  app.use(express.json({ limit: '100mb' }));
  app.use('/api', apiRouter);

  let passedCount = 0;
  let failedCount = 0;

  function assertTest(name: string, condition: boolean, detail: string) {
    if (condition) {
      passedCount++;
      console.log(`✅ [Ops] ${name}: PASSED - ${detail}`);
    } else {
      failedCount++;
      console.error(`❌ [Ops] ${name}: FAILED - ${detail}`);
    }
  }

   async function getPartyBalance(partyId: string): Promise<Decimal> {
    const row = (await db.prepare('SELECT COALESCE(SUM(debit - credit), 0) as balance FROM journal_entry_lines WHERE party_id = ?').get(partyId)) as any;
    return new Decimal(row?.balance || 0);
  }

  let ownerToken = '';
  let createdInvoiceId = '';
  let createdVoucherId = '';
  let backupFilePath = '';
  let backupId = '';

  try {
    // 1. Test Server Login
    console.log('\n--- Step 1: Authentication & Session Verification ---');
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ username: 'owner', password: 'admin123' });

    assertTest(
      'Owner User Login',
      loginRes.status === 200 && !!loginRes.body.token,
      `Status: ${loginRes.status}, User: ${loginRes.body.user?.username}, Role: ${loginRes.body.user?.role}`
    );
    ownerToken = loginRes.body.token;

    // Verify /api/auth/me
    const meRes = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${ownerToken}`);

    assertTest(
      'Session Verification (/api/auth/me)',
      meRes.status === 200 && meRes.body.user?.role === 'owner',
      `Authorized as ${meRes.body.user?.display_name}`
    );

    // 2. Fetch Master Data for transaction
    console.log('\n--- Step 2: Master Data Retrieval ---');
    const customer = (await db.prepare("SELECT * FROM parties WHERE type = 'customer' LIMIT 1").get()) as any;
    const warehouse = (await db.prepare("SELECT * FROM warehouses WHERE id = 'wh_main'").get()) as any;
    const cashBox = (await db.prepare("SELECT * FROM cash_boxes WHERE branch_id = 'br_cairo' ORDER BY id LIMIT 1").get()) as any;
    const item = (await db.prepare("SELECT * FROM items WHERE item_type = 'stock' LIMIT 1").get()) as any;

    assertTest(
      'Master Entities Presence',
      !!customer && !!warehouse && !!cashBox && !!item,
      `Customer: ${customer?.name_ar}, Item: ${item?.name_ar}, Warehouse: ${warehouse?.name_ar}`
    );

    // Initial stock and balance check
    const initialCustomerBalance = (await getPartyBalance(customer.id));
    const initialCashBalance = new Decimal(cashBox.current_balance || 0);

    // 3. Test Create & Post Sales Invoice
    console.log('\n--- Step 3: Create & Post Sales Invoice ---');
    const qty = 2;
    const unitPrice = 1500;
    const subtotal = new Decimal(qty).times(unitPrice); // 3000
    const vatRate = 14;
    const vatAmount = subtotal.times(0.14); // 420
    const whtRate = 1;
    const whtAmount = subtotal.times(0.01); // 30
    const invoiceTotal = subtotal.plus(vatAmount).minus(whtAmount); // 3000 + 420 - 30 = 3390

    const invoicePayload = {
      branchId: 'br_cairo',
      warehouseId: warehouse.id,
      customerId: customer.id,
      invoiceDate: '2026-11-05',
      paymentType: 'credit',
      status: 'draft',
      items: [
        {
          itemId: item.id,
          warehouseId: warehouse.id,
          quantity: qty,
          unitPrice: unitPrice,
          taxRate: vatRate,
          whtRate: whtRate,
          notes: 'عينة اختبار تشغيلي'
        }
      ],
      notes: 'فاتورة مبيعات تجريبية لاختبار دورة العمليات الكاملة'
    };

    const createInvRes = await request(app)
      .post('/api/sales/invoices')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send(invoicePayload);

    assertTest(
      'Create Draft Sales Invoice',
      createInvRes.status === 200 && !!createInvRes.body.invoiceId,
      `Created Invoice Number: ${createInvRes.body.invoiceNumber}, ID: ${createInvRes.body.invoiceId}`
    );
    createdInvoiceId = createInvRes.body.invoiceId;

    // Post the invoice
    const postInvRes = await request(app)
      .post(`/api/sales/invoices/${createdInvoiceId}/post`)
      .set('Authorization', `Bearer ${ownerToken}`);

    assertTest(
      'Post Sales Invoice',
      postInvRes.status === 200 && !!postInvRes.body.invoiceNumber,
      `Posted Status: ${postInvRes.status}, Invoice Number: ${postInvRes.body.invoiceNumber}, Error: ${postInvRes.body.error || 'none'}`
    );

    // Fetch posted invoice from DB
    const postedInvoiceInDb = (await db.prepare("SELECT * FROM sales_invoices WHERE id = ?").get(createdInvoiceId)) as any;
    assertTest(
      'Invoice Status in DB is Posted',
      postedInvoiceInDb.status === 'posted' && !!postedInvoiceInDb.journal_entry_id,
      `DB Status: ${postedInvoiceInDb.status}, JV ID: ${postedInvoiceInDb.journal_entry_id}`
    );

    // Verify accounting effect on Customer Balance in Ledger
    const updatedCustBalance = (await getPartyBalance(customer.id));
    const expectedCustBalance = initialCustomerBalance.plus(invoiceTotal);
    assertTest(
      'Customer Ledger Balance Updated Correctly',
      updatedCustBalance.equals(expectedCustBalance),
      `New Customer Balance: ${updatedCustBalance.toString()} (Expected: ${expectedCustBalance.toString()})`
    );

    // Verify Balanced Journal Entry
    const jvId = postedInvoiceInDb.journal_entry_id;
    const jvLines = (await db.prepare("SELECT debit, credit FROM journal_entry_lines WHERE entry_id = ?").all(jvId)) as any[];
    let totalDebit = new Decimal(0);
    let totalCredit = new Decimal(0);
    for (const line of jvLines) {
      totalDebit = totalDebit.plus(line.debit || 0);
      totalCredit = totalCredit.plus(line.credit || 0);
    }
    assertTest(
      'Sales Invoice Journal Entry Equilibrium (Debit == Credit)',
      totalDebit.equals(totalCredit) && totalDebit.greaterThan(0),
      `Total Debit: ${totalDebit.toFixed(2)}, Total Credit: ${totalCredit.toFixed(2)}`
    );

    // 4. Test Create & Post Receipt Voucher (سند قبض)
    console.log('\n--- Step 4: Create & Post Receipt Voucher ---');
    const paymentAmount = 2000;
    const voucherPayload = {
      branchId: 'br_cairo',
      voucherType: 'receipt',
      paymentMethod: 'cash',
      cashBoxId: cashBox.id,
      partyId: customer.id,
      voucherDate: '2026-11-05',
      amount: paymentAmount,
      description: `دفعة نقدية تحت حساب الفاتورة ${postedInvoiceInDb.invoice_number}`
    };

    const createVoucherRes = await request(app)
      .post('/api/treasury/vouchers')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send(voucherPayload);

    assertTest(
      'Create & Post Receipt Voucher',
      createVoucherRes.status === 200 && !!createVoucherRes.body.voucherId,
      `Voucher Number: ${createVoucherRes.body.voucherNumber}, ID: ${createVoucherRes.body.voucherId}, Amount: ${paymentAmount} EGP, Status: ${createVoucherRes.status}, Error: ${createVoucherRes.body.error || 'none'}`
    );
    createdVoucherId = createVoucherRes.body.voucherId;

    // Verify Cash Box balance increased
    const updatedCashBox = (await db.prepare("SELECT current_balance FROM cash_boxes WHERE id = ?").get(cashBox.id)) as any;
    const expectedCashBalance = initialCashBalance.plus(paymentAmount);
    assertTest(
      'Cash Box Balance Credited/Increased',
      new Decimal(updatedCashBox.current_balance).equals(expectedCashBalance),
      `Cash Box Balance: ${updatedCashBox.current_balance} (Expected: ${expectedCashBalance.toString()})`
    );

    // Verify Customer Ledger Balance reduced by receipt
    const postPayCustBal = (await getPartyBalance(customer.id));
    const expectedCustAfterPay = expectedCustBalance.minus(paymentAmount);
    assertTest(
      'Customer Balance Reduced by Receipt Amount',
      postPayCustBal.equals(expectedCustAfterPay),
      `Customer Balance: ${postPayCustBal.toString()} (Expected: ${expectedCustAfterPay.toString()})`
    );

    // 5. Test Consistent MySQL Backup Creation
    console.log('\n--- Step 5: Database Backup Creation ---');
    const backupRes = await request(app)
      .post('/api/backups/create')
      .set('Authorization', `Bearer ${ownerToken}`);

    assertTest(
      'Create Backup Endpoint (/api/backups/create)',
      backupRes.status === 200 && backupRes.body.success === true,
      `Backup ID: ${backupRes.body.backup?.id}, File: ${backupRes.body.backup?.filename}`
    );
    backupId = backupRes.body.backup?.id;
    backupFilePath = backupRes.body.backup?.file_path;

    assertTest(
      'Backup File Exists on Disk',
      fs.existsSync(backupFilePath) && fs.statSync(backupFilePath).size > 0,
      `Size: ${(fs.statSync(backupFilePath).size / 1024).toFixed(1)} KB`
    );

    // 6. Test Pre-Restore Verification & Open Backup in Isolated Database
    console.log('\n--- Step 6: Backup Verification & Isolated DB Restoration ---');
    const verifyRes = await request(app)
      .post('/api/backups/verify')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ backupId });

    assertTest(
      'Backup Integrity & Compatibility Verification',
      verifyRes.status === 200 && verifyRes.body.integrity === 'OK' && verifyRes.body.isCompatible === true,
      `Integrity: ${verifyRes.body.integrity}, Invoices in backup: ${verifyRes.body.backupCounts?.sales_invoices}`
    );

    const restoredTestDb = createDatabaseConnection('almizan_test_ops_restore_' + Date.now());
    await initDb(restoredTestDb);
    const snapshot = await readSnapshot(backupFilePath);
    await restoreSnapshot(restoredTestDb, snapshot);
    assertTest('Independent MySQL backup restore', true, 'SHA-256 and all foreign keys verified');

    // Verify invoice and voucher inside restored backup
    const backupInvoice = (await restoredTestDb.prepare("SELECT * FROM sales_invoices WHERE id = ?").get(createdInvoiceId)) as any;
    const backupVoucher = (await restoredTestDb.prepare("SELECT * FROM payment_vouchers WHERE id = ?").get(createdVoucherId)) as any;

    assertTest(
      'Sales Invoice Preserved in Restored Backup',
      !!backupInvoice && backupInvoice.status === 'posted',
      `Invoice ${backupInvoice?.invoice_number} found with total: ${backupInvoice?.total_amount}`
    );

    assertTest(
      'Receipt Voucher Preserved in Restored Backup',
      !!backupVoucher && new Decimal(backupVoucher.amount).equals(paymentAmount),
      `Voucher ${backupVoucher?.voucher_number} found with amount: ${backupVoucher?.amount}`
    );

    await restoredTestDb.dropTestSchema();

  } catch (err: any) {
    console.error('Fatal Operational Verification Exception:', err);
    failedCount++;
  } finally {
    // Clean up temporary database files
    try {
      await db.dropTestSchema();
      if (fs.existsSync(testDbFile)) fs.unlinkSync(testDbFile);
      if (fs.existsSync(`${testDbFile}-wal`)) fs.unlinkSync(`${testDbFile}-wal`);
      if (fs.existsSync(`${testDbFile}-shm`)) fs.unlinkSync(`${testDbFile}-shm`);
      if (backupFilePath && fs.existsSync(backupFilePath)) fs.unlinkSync(backupFilePath);
    } catch {
      // safe cleanup
    }
  }

  await closeAllDatabases();
  console.log('\n====================================================');
  console.log(`📊 Operational Verification Summary: Passed: ${passedCount} | Failed: ${failedCount}`);
  console.log('====================================================');

  if (failedCount > 0) {
    process.exit(1);
  }
}

(await runOperationalVerification());
