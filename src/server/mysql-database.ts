import 'dotenv/config';
import { splitSqlStatements } from './sql-statements.js';
import mysql, { Pool, PoolConnection, RowDataPacket, ResultSetHeader } from 'mysql2/promise';
import { AsyncLocalStorage } from 'node:async_hooks';
import crypto from 'node:crypto';
import path from 'node:path';

const contexts = new AsyncLocalStorage<Map<MysqlDatabase, PoolConnection>>();
const pools = new Set<MysqlDatabase>();
const schemaName = (value: string) => {
  if (!/^[a-zA-Z0-9_]{1,64}$/.test(value)) throw new Error('Invalid MySQL database name');
  return value;
};
export function getDatabasePath() { return process.env.MYSQL_DATABASE || 'almizan'; }
export function connectionConfig(database?: string) {
  return {
    host: process.env.MYSQL_HOST || '127.0.0.1',
    port: Number(process.env.MYSQL_PORT || 3306),
    user: process.env.MYSQL_USER || 'almizan_app',
    password: process.env.MYSQL_PASSWORD || '',
    ...(database ? { database: schemaName(database) } : {}),
    charset: 'utf8mb4', timezone: 'Z', dateStrings: true,
    supportBigNumbers: true, bigNumberStrings: false,
    connectionLimit: Number(process.env.MYSQL_POOL_SIZE || 10),
    waitForConnections: true, multipleStatements: false,
    // Preserve the existing numeric API contract; financial calculations use Decimal.js.
    decimalNumbers: true,
    typeCast(field: any, next: () => any) {
      if (field.type === 'DATETIME' || field.type === 'TIMESTAMP') {
        const value = field.string();
        return value ? value.replace(' ', 'T') + 'Z' : null;
      }
      return next();
    }
  };
}

function parameter(value: any) {
  if (value === undefined) return null;
  if (typeof value === 'boolean') return value ? 1 : 0;
  if (value instanceof Date) return value.toISOString().slice(0, 19).replace('T', ' ');
  if (typeof value === 'string' && /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z$/.test(value)) return value.slice(0, 19).replace('T', ' ');
  return value;
}
export class MysqlDatabase {
  readonly name: string;
  private pool: Pool;
  constructor(name: string) {
    this.name = schemaName(name);
    this.pool = mysql.createPool(connectionConfig(this.name));
    this.pool.on('connection', connection => {
      connection.query("SET time_zone = '+00:00'");
      connection.query('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED');
    });
    pools.add(this);
  }
  async ensureSchema() {
    const connection = await mysql.createConnection(connectionConfig());
    try { await connection.query(`CREATE DATABASE IF NOT EXISTS \`${this.name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`); }
    finally { await connection.end(); }
  }
  async query(sql: string, params: any[] = []): Promise<any[]> {
    const connection = contexts.getStore()?.get(this) || this.pool;
    const [rows] = await connection.query(sql, params.map(parameter));
    return rows as any[];
  }
  prepare(sql: string) {
    return {
      get: async (...params: any[]) => (await this.query(sql, params))[0],
      all: async (...params: any[]) => await this.query(sql, params),
      run: async (...params: any[]) => {
        const result = await this.query(sql, params) as unknown as ResultSetHeader;
        return { changes: result.affectedRows, lastInsertRowid: result.insertId };
      }
    };
  }
  async exec(sql: string) {
    // Schema/DML batches are trusted application files, never user-supplied SQL.
    for (const statement of splitSqlStatements(sql)) await this.query(statement);
  }
  transaction<T>(fn: (...args: any[]) => T | Promise<T>) {
    return async (...args: any[]): Promise<T> => {
      const previous = contexts.getStore();
      const active = previous?.get(this);
      if (active) {
        const savepoint = 'sp_' + crypto.randomBytes(8).toString('hex');
        await active.query(`SAVEPOINT ${savepoint}`);
        try { const result = await fn(...args); await active.query(`RELEASE SAVEPOINT ${savepoint}`); return result; }
        catch (error) { await active.query(`ROLLBACK TO SAVEPOINT ${savepoint}`); throw error; }
      }
      const connection = await this.pool.getConnection();
      const lockName = 'almizan:' + this.name;
      let locked = false;
      try {
        // One accounting writer per database: includes numbering, stock, balances and audit.
        const [rows] = await connection.query<RowDataPacket[]>('SELECT GET_LOCK(?, 30) AS acquired', [lockName]);
        if (Number(rows[0].acquired) !== 1) throw new Error('قاعدة البيانات مشغولة. أعد المحاولة.');
        locked = true;
        await connection.beginTransaction();
        const next = new Map(previous || []); next.set(this, connection);
        const result = await contexts.run(next, () => fn(...args));
        await connection.commit();
        return result;
      } catch (error) { await connection.rollback(); throw error; }
      finally {
        try { if (locked) await connection.query('SELECT RELEASE_LOCK(?)', [lockName]); }
        finally { connection.release(); }
      }
    };
  }
  async close() { await this.pool.end(); pools.delete(this); }
  async dropTestSchema() {
    if (!this.name.startsWith('almizan_test_')) throw new Error('Refusing to drop non-test database');
    const config = connectionConfig(this.name);
    delete config.database;
    const connection = await mysql.createConnection(config);
    try { await connection.query(`DROP DATABASE IF EXISTS \`${this.name}\``); }
    finally { await connection.end(); await this.close(); }
  }
}
export function createDatabaseConnection(name = getDatabasePath()) {
  // Legacy test identifiers become isolated MySQL schemas, never filesystem databases.
  if (name.includes('/') || name.includes('\\') || name.endsWith('.db')) name = 'almizan_test_' + crypto.createHash('sha256').update(path.resolve(name)).digest('hex').slice(0,20);
  return new MysqlDatabase(name);
}
export const db = createDatabaseConnection();
export async function closeAllDatabases() { await Promise.all([...pools].map(pool => pool.close())); }
