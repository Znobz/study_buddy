import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

// Ensure environment variables are loaded
if (!process.env.DB_HOST) {
  console.error('❌ DB_HOST environment variable is required');
  process.exit(1);
}

const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  multipleStatements: true,
  // Enable SSL for Google Cloud SQL
  ssl: {
    rejectUnauthorized: false
  }
});

// Enhanced connection test
(async () => {
  try {
    console.log('🔄 Attempting to connect to Cloud SQL...');
    console.log('Connection details:', {
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      port: process.env.DB_PORT || 3306
    });

    const connection = await db.getConnection();
    console.log('✅ MySQL Connected to Google Cloud SQL');
    connection.release();
  } catch (err) {
    console.error('❌ Database connection failed:', {
      error: err.message,
      code: err.code,
      errno: err.errno
    });
    // Don't exit in development for debugging
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
})();

export default db;