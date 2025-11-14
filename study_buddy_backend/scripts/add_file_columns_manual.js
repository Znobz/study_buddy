import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

async function run() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || 'root123',
    database: process.env.DB_NAME || 'study_buddy',
  });

  try {
    console.log('Adding file_path column…');
    await conn.query(
      "ALTER TABLE assignments ADD COLUMN file_path VARCHAR(500) NULL"
    );
    console.log('Adding file_name column…');
    await conn.query(
      "ALTER TABLE assignments ADD COLUMN file_name VARCHAR(255) NULL"
    );
    console.log('✅ Done');
  } finally {
    await conn.end();
  }
}

run().catch((err) => {
  console.error('❌ Failed to add columns:', err);
  process.exit(1);
});


