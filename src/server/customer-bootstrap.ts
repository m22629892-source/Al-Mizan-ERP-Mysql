import { initDb } from './db.js';
import { MysqlDatabase } from './mysql-database.js';
import { defaultAccountsData } from './default-accounts.js';
import { hashPassword } from './seed.js';
export interface CustomerSetup {
  companyName: string; companyAddress?: string; taxId?: string;
  ownerName: string; ownerUsername: string; ownerPassword: string; fiscalYear?: number;
}
export function validateCustomerSetup(input: CustomerSetup) {
  if (!input.companyName?.trim() || !input.ownerName?.trim()) throw new Error('Company and administrator names are required');
  if (!/^[a-zA-Z0-9_.@-]{3,80}$/.test(input.ownerUsername || '')) throw new Error('Administrator username must be 3-80 letters, numbers or . _ @ -');
  if (typeof input.ownerPassword !== 'string' || input.ownerPassword.length < 12 || Buffer.byteLength(input.ownerPassword,'utf8') > 72) throw new Error('Administrator password must be at least 12 characters and at most 72 UTF-8 bytes');
  const year = input.fiscalYear ?? new Date().getFullYear();
  if (!Number.isInteger(year) || year < 2000 || year > 2100) throw new Error('Invalid fiscal year');
  return year;
}
/** New-company setup never inserts demo customers, invoices, users or opening balances. */
export async function initializeCustomer(database: MysqlDatabase, input: CustomerSetup) {
  await initDb(database);
  return database.transaction(async () => {
    const existing = await database.prepare('SELECT COUNT(*) AS cnt FROM companies').get();
    if (existing.cnt > 0) {
      const owner = await database.prepare("SELECT id FROM users WHERE role = 'owner' AND is_active = 1 LIMIT 1").get();
      if (!owner) throw new Error('Existing company has no active owner. Setup will not overwrite or reset existing users.');
      return { created: false };
    }
    const year = validateCustomerSetup(input);
    // Refuse to combine pre-existing financial data with a fresh company.
    for (const table of ['users','branches','accounts','journal_entries','sales_invoices','purchase_invoices']) {
      const row=await database.prepare(`SELECT COUNT(*) AS cnt FROM ${table}`).get();
      if(row.cnt>0)throw new Error('Database is partially populated: '+table+'. Use the existing installation or a new empty database.');
    }
    await database.prepare(`INSERT INTO companies (id,name_ar,name_en,legal_name,commercial_registry,tax_id,address_ar,city,country,currency_code) VALUES ('comp_al_mizan',?,?,?,'',?,?,'','مصر','EGP')`).run(input.companyName.trim(),input.companyName.trim(),input.companyName.trim(),input.taxId?.trim()||'',input.companyAddress?.trim()||'');
    await database.prepare(`INSERT INTO branches (id,company_id,code,name_ar,name_en) VALUES ('br_cairo','comp_al_mizan','MAIN','الفرع الرئيسي','Main Branch')`).run();
    await database.prepare(`INSERT INTO currencies (code,name_ar,name_en,symbol,decimal_places,is_base) VALUES ('EGP','الجنيه المصري','Egyptian Pound','ج.م',2,1),('USD','الدولار الأمريكي','US Dollar','$',2,0),('EUR','اليورو','Euro','€',2,0),('SAR','الريال السعودي','Saudi Riyal','ر.س',2,0)`).run();
    for (const account of defaultAccountsData) {
      const name = account.name_ar.replace(/القاهرة/g,'الفرع الرئيسي').replace(/الإسكندرية/g,'فرع إضافي');
      await database.prepare(`INSERT INTO accounts (id,code,name_ar,name_en,parent_id,account_type,nature,is_group,level,is_reconciliation) VALUES (?,?,?,?,?,?,?,?,?,?)`).run(account.id,account.code,name,account.name_en,account.parent,account.type,account.nature,account.is_group,account.level,(account as any).is_reconciliation||0);
    }
    await database.prepare(`INSERT INTO fiscal_years (id,code,name_ar,name_en,start_date,end_date,is_closed) VALUES (?,?,?,?,?,?,0)`).run('fy_'+year,String(year),'السنة المالية '+year,'Fiscal Year '+year,`${year}-01-01`,`${year}-12-31`);
    for(let month=1;month<=12;month++){
      const mm=String(month).padStart(2,'0'); const last = new Date(Date.UTC(year,month,0)).getUTCDate();
      await database.prepare(`INSERT INTO fiscal_periods (id,fiscal_year_id,period_number,name_ar,name_en,start_date,end_date) VALUES (?,?,?,?,?,?,?)`).run(`fp_${year}_${mm}`,'fy_'+year,month,'الفترة '+month,'Period '+month,`${year}-${mm}-01`,`${year}-${mm}-${last}`);
    }
    await database.prepare(`INSERT INTO warehouses (id,branch_id,code,name_ar,name_en) VALUES ('wh_main','br_cairo','WH-MAIN','المخزن الرئيسي','Main Warehouse')`).run();
    await database.prepare(`INSERT INTO cash_boxes (id,branch_id,code,name_ar,name_en,account_id,currency_code,current_balance) VALUES ('cash_cairo','br_cairo','CASH-MAIN','الخزينة الرئيسية','Main Cash Box','acc_1111','EGP',0)`).run();
    await database.prepare(`INSERT INTO users (id,username,password_hash,display_name,role,is_active,allowed_branch_ids,allowed_warehouse_ids,allowed_cashbox_ids) VALUES ('usr_owner',?,?,?,'owner',1,'*','*','*')`).run(input.ownerUsername,hashPassword(input.ownerPassword),input.ownerName.trim());
    return { created: true };
  })();
}
