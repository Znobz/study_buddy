import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

const db = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || 'root123',
  database: process.env.DB_NAME || 'study_buddy',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  multipleStatements: true,
});

// Test the connection
(async () => {
  try {
    const connection = await db.getConnection();
    console.log('✅ MySQL Connected');
    connection.release();
  } catch (err) {
    console.error('Database connection failed:', err);
    process.exit(1);
  }
})();

export default db;
