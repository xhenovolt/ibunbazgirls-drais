import mysql from 'mysql2/promise';

let pool: mysql.Pool | null = null;

const dbConfig = {
  host: process.env.MYSQL_HOST || process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.MYSQL_PORT || process.env.DB_PORT || '3306', 10),
  user: process.env.MYSQL_USER || process.env.DB_USER || 'root',
  password: process.env.MYSQL_PASSWORD || process.env.DB_PASS || '',
  database: process.env.MYSQL_DB || process.env.DB_NAME || 'ibunbaz_drais',
};

export function getPool() {
  if (pool) return pool;
  pool = mysql.createPool({
    host: dbConfig.host,
    port: dbConfig.port,
    user: dbConfig.user,
    password: dbConfig.password,
    database: dbConfig.database,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    timezone: 'Z',
  });
  return pool;
}

export async function query(sql: string, params: unknown[] = []) {
  const p = getPool();
  const [rows] = await p.execute(sql, params);
  return rows;
}

export async function getConnection() {
  try {
    return await mysql.createConnection({
      host: dbConfig.host,
      port: dbConfig.port,
      user: dbConfig.user,
      password: dbConfig.password,
      database: dbConfig.database,
    });
  } catch (error) {
    console.error('Database connection error:', error);
    throw new Error('Failed to connect to the database. Please check your database configuration.');
  }
}

export async function withTransaction<T>(fn: (conn: mysql.PoolConnection) => Promise<T>): Promise<T> {
  const p = getPool();
  const conn = await p.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}
