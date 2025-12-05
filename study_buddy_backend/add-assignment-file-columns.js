import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const connection = await mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || 'root123',
  database: process.env.DB_NAME || 'study_buddy',
  multipleStatements: true,
});

try {
  console.log('Adding file columns to assignments table...');
  
  // Add file_path column if it doesn't exist
  await connection.query(`
    ALTER TABLE assignments 
    ADD COLUMN IF NOT EXISTS file_path VARCHAR(500) DEFAULT NULL
  `).catch(() => {
    // Column might already exist, that's okay
    console.log('file_path column may already exist');
  });
  
  // Add file_name column if it doesn't exist
  await connection.query(`
    ALTER TABLE assignments 
    ADD COLUMN IF NOT EXISTS file_name VARCHAR(255) DEFAULT NULL
  `).catch(() => {
    // Column might already exist, that's okay
    console.log('file_name column may already exist');
  });

  console.log('✅ File columns added to assignments table!');
} catch (error) {
  console.error('❌ Error adding columns:', error);
  process.exit(1);
} finally {
  await connection.end();
}





