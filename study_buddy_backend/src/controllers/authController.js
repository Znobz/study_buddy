import db from '../config/db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const register = (req, res) => {
  const { first_name, last_name, email, password } = req.body;

  if (!email || !password)
    return res.status(400).json({ error: 'Email and password required' });

  const checkEmail = 'SELECT * FROM users WHERE email = ?';
  db.query(checkEmail, [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length > 0) return res.status(400).json({ error: 'Email already in use' });

    const hashed = bcrypt.hashSync(password, 10);
    const sql = 'INSERT INTO users (first_name, last_name, email, password_hash) VALUES (?, ?, ?, ?)';
    db.query(sql, [first_name, last_name, email, hashed], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2 });
      res.json({ message: 'User registered successfully', user_id: result.insertId });
    });
  });
};

export const login = (req, res) => {
  const { email, password } = req.body;

  const sql = 'SELECT * FROM users WHERE email = ?';
  db.query(sql, [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length === 0) return res.status(401).json({ error: 'Invalid credentials' });

    const user = results[0];
    const validPass = bcrypt.compareSync(password, user.password_hash);
    if (!validPass) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ user_id: user.user_id }, process.env.JWT_SECRET, { expiresIn: '1d' });
    // remove password_hash before sending user object
    delete user.password_hash;
    res.json({ message: 'Login successful', token, user });
  });
};
