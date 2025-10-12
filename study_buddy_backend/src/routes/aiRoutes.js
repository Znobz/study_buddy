import express from 'express';
import { askTutor, getChatHistory } from '../controllers/aiController.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Protected: requires Authorization: Bearer <token>
router.post('/ask', verifyToken, askTutor);
router.get('/history/:userId', verifyToken, getChatHistory);

export default router;
