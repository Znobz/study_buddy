import mysql from 'mysql2';
import fs from 'fs';
import path from 'path';

// Create database connection
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'root123',
  multipleStatements: true,
});

// Read and execute schema
const schema = fs.readFileSync(path.join(process.cwd(), 'db', 'schema.sql'), 'utf8').replace(/^\uFEFF/, '');

connection.query(schema, (err, results) => {
  if (err) {
    console.error('Database setup failed:', err);
    process.exit(1);
  }
  console.log('✅ Database and tables created successfully!');
  connection.end();
});
