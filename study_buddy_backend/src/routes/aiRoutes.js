const express = require('express');
const auth = require('../middleware/authMiddleware');
const conversation = require('../controllers/conversationController');
const message = require('../controllers/messageController');
const uploadCtrl = require('../controllers/uploadController');
const multer = require('multer');

const router = express.Router();

const upload = multer({ dest: 'uploads/' }); // swap with your S3/Cloudinary adapter later

// Conversations
router.post('/chats', auth, conversation.create);          // create a new chat
router.get('/chats', auth, conversation.list);             // list chats (non-archived)
router.post('/chats/:id/archive', auth, conversation.archive);
router.post('/chats/:id/title', auth, conversation.title); // auto/rename title

// Messages
router.get('/chats/:id/messages', auth, message.list);     // paginated history
router.post('/chats/:id/messages', auth, message.send);    // send + get assistant

// Uploads
router.post('/uploads', auth, upload.single('file'), uploadCtrl.create);

module.exports = router;