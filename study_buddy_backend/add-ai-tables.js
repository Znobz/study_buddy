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
  console.log('Adding AI chat tables...');
  
  // Create conversations table
  await connection.query(`
    CREATE TABLE IF NOT EXISTS conversations (
      id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT NOT NULL,
      title VARCHAR(255) DEFAULT 'New Chat',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      is_archived BOOLEAN DEFAULT FALSE,
      FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
    )
  `);
  console.log('✅ conversations table created');

  // Create messages table
  await connection.query(`
    CREATE TABLE IF NOT EXISTS messages (
      id INT PRIMARY KEY AUTO_INCREMENT,
      conversation_id INT NOT NULL,
      role ENUM('user', 'assistant') NOT NULL,
      text TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
    )
  `);
  console.log('✅ messages table created');

  // Create attachments table
  await connection.query(`
    CREATE TABLE IF NOT EXISTS attachments (
      id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT NOT NULL,
      message_id INT DEFAULT NULL,
      file_path VARCHAR(500) NOT NULL,
      file_name VARCHAR(255) NOT NULL,
      file_size INT DEFAULT NULL,
      mime_type VARCHAR(100) DEFAULT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
      FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE SET NULL
    )
  `);
  console.log('✅ attachments table created');

  console.log('✅ All AI chat tables added successfully!');
} catch (error) {
  console.error('❌ Error adding tables:', error);
  process.exit(1);
} finally {
  await connection.end();
}


