import express from 'express';
import { register, login, validateToken } from '../controllers/authController.js';
import { verifyToken } from '../middleware/authMiddleware.js';
const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/validate', verifyToken, validateToken);

export default router;
