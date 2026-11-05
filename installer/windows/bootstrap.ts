import fs from 'node:fs';
import mysql from 'mysql2/promise';
import { createDatabaseConnection, closeAllDatabases } from '../../src/server/mysql-database.js';
import { initializeCustomer } from '../../src/server/customer-bootstrap.js';
const path=process.argv[2];
try {
  const input=JSON.parse(fs.readFileSync(path,'utf8').replace(/^\uFEFF/,''));
  if(input.privateDatabase){
    const admin=await mysql.createConnection({host:'127.0.0.1',port:input.mysqlPort,user:'root',password:input.rootPassword,connectTimeout:5000});
    try{
      await admin.query('CREATE DATABASE IF NOT EXISTS `almizan` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin');
      await admin.query("CREATE USER IF NOT EXISTS 'almizan_app'@'localhost' IDENTIFIED BY ?",[input.mysqlPassword]);
      await admin.query("GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, REFERENCES ON almizan.* TO 'almizan_app'@'localhost'");
    }finally{await admin.end()}
  }
  process.env.MYSQL_HOST=input.mysqlHost;process.env.MYSQL_PORT=String(input.mysqlPort);process.env.MYSQL_DATABASE=input.mysqlDatabase;process.env.MYSQL_USER=input.mysqlUser;process.env.MYSQL_PASSWORD=input.mysqlPassword;
  const database=createDatabaseConnection();
  const result=await initializeCustomer(database,input);
  console.log(JSON.stringify({success:true,created:result.created}));
}catch(error:any){console.error('Database setup failed: '+(error.code||error.message));process.exitCode=1}
finally{await closeAllDatabases()}
