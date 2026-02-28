import mysql from 'mysql2/promise';

const config = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'ibunbaz_drais',
};

try {
  console.log('Attempting to connect with config:', { ...config, password: '***' });
  const conn = await mysql.createConnection(config);
  console.log('✅ Connected to database');
  
  const [rows] = await conn.execute('SELECT * FROM curriculums');
  console.log('✅ Curriculums table query successful');
  console.log('Curriculums:', rows);
  
  await conn.end();
  console.log('✅ Connection closed');
} catch (error) {
  console.error('❌ Error:', error.message);
  process.exit(1);
}
