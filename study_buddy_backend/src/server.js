import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import db from './config/db.js';
import authRoutes from './routes/authRoutes.js';
import assignmentRoutes from './routes/assignmentRoutes.js';
import sessionRoutes from './routes/sessionRoutes.js';
import aiRoutes from './routes/aiRoutes.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});


app.use('/api/auth', authRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/ai', aiRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () =>
  console.log(`✅ Server running on http://0.0.0.0:${PORT}`)
);
