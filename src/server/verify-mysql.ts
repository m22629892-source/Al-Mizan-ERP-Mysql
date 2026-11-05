import 'dotenv/config';
import assert from 'node:assert/strict';
import express from 'express';
import request from 'supertest';
process.env.MYSQL_DATABASE = 'almizan_test_integration_' + Date.now();
const { db, closeAllDatabases, createDatabaseConnection } = await import('./mysql-database.js');
const { initDb } = await import('./db.js');
const { seedInitialData } = await import('./seed.js');
const { apiRouter } = await import('./api.js');
const { Router } = await import('./mysql-router.js');
const { getNextDocumentNumber } = await import('./accounting-engine.js');
let passed = 0;
function check(name: string, action: () => Promise<void>) { return action().then(() => { passed++; console.log('PASS ' + name); }); }
try {
  await initDb(); await seedInitialData();
  const app = express(); app.use(express.json()); app.use('/api', apiRouter);
  app.use((error: any, _req: any, res: any, _next: any) => res.status(500).json({ error: error.message }));
  const login = await request(app).post('/api/auth/login').send({ username: 'owner', password: 'admin123' });
  assert.equal(login.status,200); const token = login.body.token;
  const endpoints = ['/auth/me','/company','/users','/permissions-matrix','/dashboard/stats','/accounts','/journal-entries','/parties','/parties/party_cust_001/statement','/categories','/items','/items/item_001/stock-by-warehouse','/sales/invoices','/purchases/invoices','/sales/returns','/purchases/returns','/treasury/vouchers','/reports/trial-balance','/reports/income-statement','/reports/balance-sheet','/reports/vat-return','/audit-logs','/backups','/reports/aging/receivables','/reports/aging/payables','/inventory-counts','/bank-reconciliation/data','/period-closing/status','/period-closing/history','/import/history'];
  for (const endpoint of endpoints) await check('GET '+endpoint,async()=>{
    const result=await request(app).get('/api'+endpoint).set('Authorization','Bearer '+token);
    assert.equal(result.status,200,endpoint+': '+JSON.stringify(result.body).slice(0,250));
  });
  await check('Concurrent document numbers on separate connections',async()=>{
    const other = createDatabaseConnection(db.name);
    try {
      const values = await Promise.all(Array.from({length:16},(_,i)=>{
        const connection = i%2 ? db : other;
        return connection.transaction(()=>getNextDocumentNumber('MYSQLTEST','br_cairo','fy_2026',connection))();
      }));
      assert.equal(new Set(values).size,16);
    } finally { await other.close(); }
  });
  await check('Nested transaction rollback restores original data',async()=>{
    const before=await db.prepare('SELECT quantity FROM warehouse_stock WHERE warehouse_id = ? AND item_id = ?').get('wh_main','item_001');
    await assert.rejects(db.transaction(async()=>{
      await db.prepare('UPDATE warehouse_stock SET quantity = quantity - 1 WHERE warehouse_id = ? AND item_id = ?').run('wh_main','item_001');
      await db.transaction(async()=>{ throw new Error('rollback-test'); })();
    })());
    const after=await db.prepare('SELECT quantity FROM warehouse_stock WHERE warehouse_id = ? AND item_id = ?').get('wh_main','item_001');
    assert.equal(after.quantity,before.quantity);
  });
  await check('Failed login attempts persist after HTTP 401',async()=>{
    const result=await request(app).post('/api/auth/login').send({username:'not_a_user',password:'wrong'});
    assert.equal(result.status,401);
    const row=await db.prepare('SELECT SUM(attempts) AS attempts FROM login_attempts WHERE ip_or_user LIKE ?').get('%not_a_user');
    assert.ok(row.attempts>0);
  });
  await check('HTTP error rolls back a late mutation before response',async()=>{
    const router=Router();
    router.post('/rollback',async(_req,res)=>{
      await db.prepare("INSERT INTO system_settings (setting_key,setting_value) VALUES ('test_http_rollback','1')").run();
      res.status(400).json({error:'expected'});
    });
    const isolatedApp=express();isolatedApp.use(router);
    const result=await request(isolatedApp).post('/rollback');assert.equal(result.status,400);
    assert.equal(await db.prepare("SELECT * FROM system_settings WHERE setting_key = 'test_http_rollback'").get(),undefined);
  });
  await check('Idempotent draft create is replayed without duplication',async()=>{
    const payload={branchId:'br_cairo',warehouseId:'wh_main',customerId:'party_cust_001',invoiceDate:'2026-11-05',paymentType:'credit',status:'draft',items:[{itemId:'item_001',quantity:1,unitPrice:1000,taxRate:14,whtRate:1}]};
    const first=await request(app).post('/api/sales/invoices').set('Authorization','Bearer '+token).set('Idempotency-Key','mysql-replay').send(payload);
    const second=await request(app).post('/api/sales/invoices').set('Authorization','Bearer '+token).set('Idempotency-Key','mysql-replay').send(payload);
    assert.equal(first.status,200,JSON.stringify(first.body));assert.equal(second.status,200,JSON.stringify(second.body));assert.equal(first.body.invoiceId,second.body.invoiceId);
    const conflict=await request(app).post('/api/sales/invoices').set('Authorization','Bearer '+token).set('Idempotency-Key','mysql-replay').send({...payload,notes:'changed'});assert.equal(conflict.status,409);
  });
  for (const kind of ['sales','purchases']) await check(kind+' invoice draft create/edit/delete via HTTP',async()=>{
    const payload:any={branchId:'br_cairo',warehouseId:'wh_main',invoiceDate:'2026-11-05',paymentType:'credit',status:'draft',items:[{itemId:'item_001',quantity:1,unitPrice:1000,taxRate:14,whtRate:1}]};
    payload[kind==='sales'?'customerId':'supplierId']=kind==='sales'?'party_cust_001':'party_supp_001';
    const created=await request(app).post('/api/'+kind+'/invoices').set('Authorization','Bearer '+token).send(payload);
    assert.equal(created.status,200,JSON.stringify(created.body));const id=created.body.invoiceId;assert.ok(id);
    const edited=await request(app).put('/api/'+kind+'/invoices/'+id).set('Authorization','Bearer '+token).send({...payload,notes:'edited MySQL draft'});
    assert.equal(edited.status,200,JSON.stringify(edited.body));
    const deleted=await request(app).delete('/api/'+kind+'/invoices/'+id).set('Authorization','Bearer '+token);
    assert.equal(deleted.status,200,JSON.stringify(deleted.body));
    assert.equal(await db.prepare('SELECT * FROM '+(kind==='sales'?'sales_invoices':'purchase_invoices')+' WHERE id = ?').get(id),undefined);
  });
  await check('Journal draft create/edit/delete via HTTP',async()=>{
    const payload={docType:'MANUAL',entryDate:'2026-11-05',branchId:'br_cairo',description:'MySQL draft',status:'draft',lines:[{accountId:'acc_1111',debit:50,credit:0},{accountId:'acc_4111',debit:0,credit:50}]};
    const created=await request(app).post('/api/journal-entries').set('Authorization','Bearer '+token).send(payload);
    assert.equal(created.status,200,JSON.stringify(created.body));const id=created.body.entryId;
    const edited=await request(app).put('/api/journal-entries/'+id).set('Authorization','Bearer '+token).send({...payload,description:'edited MySQL journal'});
    assert.equal(edited.status,200,JSON.stringify(edited.body));
    const deleted=await request(app).delete('/api/journal-entries/'+id).set('Authorization','Bearer '+token);
    assert.equal(deleted.status,200,JSON.stringify(deleted.body));
    assert.equal(await db.prepare('SELECT * FROM journal_entries WHERE id = ?').get(id),undefined);
  });
  for(const kind of ['sales','purchases'])await check(kind+' return draft create/edit/delete via HTTP',async()=>{
    const table=kind==='sales'?'sales_invoice_items':'purchase_invoice_items';
    const line=await db.prepare('SELECT * FROM '+table+' WHERE quantity - returned_quantity >= 1 LIMIT 1').get();assert.ok(line);
    const invoice=await db.prepare('SELECT * FROM '+(kind==='sales'?'sales_invoices':'purchase_invoices')+' WHERE id = ?').get(line.invoice_id);
    const payload={originalInvoiceId:line.invoice_id,warehouseId:invoice.warehouse_id,returnDate:'2026-11-05',refundType:'credit_note',status:'draft',items:[{originalInvoiceItemId:line.id,itemId:line.item_id,quantity:1}]};
    const created=await request(app).post('/api/'+kind+'/returns').set('Authorization','Bearer '+token).send(payload);
    assert.equal(created.status,200,JSON.stringify(created.body));const id=created.body.returnId;assert.ok(id);
    const edited=await request(app).put('/api/'+kind+'/returns/'+id).set('Authorization','Bearer '+token).send({...payload,notes:'edited MySQL return'});
    assert.equal(edited.status,200,JSON.stringify(edited.body));
    const deleted=await request(app).delete('/api/'+kind+'/returns/'+id).set('Authorization','Bearer '+token);
    assert.equal(deleted.status,200,JSON.stringify(deleted.body));
    assert.equal(await db.prepare('SELECT * FROM '+(kind==='sales'?'sales_returns':'purchase_returns')+' WHERE id = ?').get(id),undefined);
  });
  console.log(`MySQL integration: ${passed} checks passed`);
} catch(error) { console.error(error); process.exitCode=1; }
finally { await db.dropTestSchema(); await closeAllDatabases(); }
