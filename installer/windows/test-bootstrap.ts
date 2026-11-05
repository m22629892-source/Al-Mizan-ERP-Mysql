import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync,spawn} from 'node:child_process';
import {createDatabaseConnection,closeAllDatabases} from '../../src/server/mysql-database.js';
import {verifyPassword} from '../../src/server/seed.js';
const name='almizan_test_customer_setup_'+Date.now();
const database=createDatabaseConnection(name);const filename=path.join(os.tmpdir(),'almizan-setup-test-'+Date.now()+'.json');
const answers={privateDatabase:false,mysqlHost:process.env.MYSQL_HOST||'127.0.0.1',mysqlPort:Number(process.env.MYSQL_PORT||3306),mysqlDatabase:name,mysqlUser:process.env.MYSQL_USER||'root',mysqlPassword:process.env.MYSQL_PASSWORD||'',companyName:'Real customer setup test',ownerName:'Customer Owner',ownerUsername:'customer_owner',ownerPassword:'Customer-Test-Pass-123!'};
try{
 fs.writeFileSync(filename,JSON.stringify(answers),{mode:0o600});
 const bootstrap=()=>execFileSync(process.execPath,['installer/stage/app/bootstrap.mjs',filename],{cwd:process.cwd(),encoding:'utf8'});
 bootstrap();
 assert.equal((await database.query('SELECT COUNT(*) AS cnt FROM users'))[0].cnt,1);
 assert.equal((await database.query('SELECT COUNT(*) AS cnt FROM accounts'))[0].cnt,65);
 for(const table of ['parties','items','sales_invoices','purchase_invoices','journal_entries','payment_vouchers'])assert.equal((await database.query(`SELECT COUNT(*) AS cnt FROM ${table}`))[0].cnt,0,table);
 assert.equal((await database.query('SELECT current_balance FROM cash_boxes'))[0].current_balance,0);
 const owner=(await database.query('SELECT * FROM users'))[0];assert.equal(owner.username,'customer_owner');assert.ok(verifyPassword(answers.ownerPassword,owner.password_hash).valid);
 fs.writeFileSync(filename,JSON.stringify({...answers,companyName:'must not replace company',ownerPassword:'Changed-Password-123!'}));bootstrap();
 assert.equal((await database.query('SELECT name_ar FROM companies'))[0].name_ar,answers.companyName);
 assert.equal((await database.query('SELECT password_hash FROM users'))[0].password_hash,owner.password_hash);
 const port=34123;let logs='';
 const server=spawn(process.execPath,['installer/stage/app/server.mjs'],{env:{...process.env,MYSQL_DATABASE:name,NODE_ENV:'production',BIND_HOST:'127.0.0.1',PORT:String(port)},stdio:['ignore','pipe','pipe']});server.stdout.on('data',d=>logs+=d);server.stderr.on('data',d=>logs+=d);
 try{
  let health:any;for(let i=0;i<80;i++){try{health=await(await fetch(`http://127.0.0.1:${port}/api/health`)).json();if(health.status==='ok')break}catch{}await new Promise(r=>setTimeout(r,100))}
  assert.equal(health?.database,'mysql',logs);
  assert.equal((await fetch(`http://127.0.0.1:${port}/`)).status,200);
  const login=await fetch(`http://127.0.0.1:${port}/api/auth/login`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({username:answers.ownerUsername,password:answers.ownerPassword})});assert.equal(login.status,200,await login.text());
 }finally{server.kill('SIGTERM');await new Promise(r=>server.once('exit',r))}
 console.log('PASS bundled clean customer bootstrap, zero demo records, custom owner, repeat setup preserves data/password, production HTTP login.');
}finally{fs.rmSync(filename,{force:true});await database.dropTestSchema();await closeAllDatabases()}
