import db from '../config/db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const register = async (req, res) => {
  const { first_name, last_name, email, password } = req.body;

  if (!email || !password)
    return res.status(400).json({ error: 'Email and password required' });

  try {
    const checkEmail = 'SELECT * FROM users WHERE email = ?';
    const [existingUsers] = await db.execute(checkEmail, [email]);
    
    if (existingUsers.length > 0) 
      return res.status(400).json({ error: 'Email already in use' });

    const hashed = bcrypt.hashSync(password, 10);
    const sql = 'INSERT INTO users (first_name, last_name, email, password_hash) VALUES (?, ?, ?, ?)';
    const [result] = await db.execute(sql, [first_name, last_name, email, hashed]);
    
    res.json({ message: 'User registered successfully', user_id: result.insertId });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Registration failed' });
  }
};

export const login = async (req, res) => {
  const { email, password } = req.body;

  console.log('\n🔐 POST /api/auth/login');
  console.log('📧 Email:', email);

  try {
    console.log('💾 SQL: SELECT * FROM users WHERE email = ?');
    const sql = 'SELECT * FROM users WHERE email = ?';
    const [results] = await db.execute(sql, [email]);
    
    if (results.length === 0) {
      console.log('❌ Login failed: User not found');
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = results[0];
    const validPass = bcrypt.compareSync(password, user.password_hash);
    if (!validPass) {
      console.log('❌ Login failed: Invalid password');
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    console.log('✅ Password verified');
    console.log('🔑 Generating JWT token for user_id:', user.user_id);
    
    const token = jwt.sign({ user_id: user.user_id }, process.env.JWT_SECRET || 'fallback-secret-key', { expiresIn: '1d' });
    
    // remove password_hash before sending user object
    delete user.password_hash;
    
    console.log('✅ Login successful! Welcome,', user.first_name);
    
    res.json({ message: 'Login successful', token, user });
  } catch (err) {
    console.error('❌ Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  }
};

export const validateToken = async (req, res) => {
  // This endpoint is protected by authMiddleware, so if we reach here, token is valid
  try {
    const sql = 'SELECT user_id, first_name, last_name, email FROM users WHERE user_id = ?';
    const [results] = await db.execute(sql, [req.user.user_id]);
    
    if (results.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ valid: true, user: results[0] });
  } catch (err) {
    console.error('Token validation error:', err);
    res.status(500).json({ error: 'Token validation failed' });
  }
};