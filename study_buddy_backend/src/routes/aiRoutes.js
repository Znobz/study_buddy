import express from "express";
import { verifyToken } from "../middleware/authMiddleware.js";
import db from "../config/db.js";
import * as conversation from "../controllers/conversationController.js";
import * as message from "../controllers/messageController.js";
import * as uploadCtrl from "../controllers/uploadController.js";

const router = express.Router();

// --- Conversations ---
router.post("/chats", verifyToken, conversation.create);           // create new chat
router.get("/chats", verifyToken, conversation.list);              // list chats
router.get('/chats/:id', verifyToken, conversation.getChatById);   // get single chat
router.post("/chats/:id/archive", verifyToken, conversation.archive);
router.post("/chats/:id/title", verifyToken, conversation.title);  // auto-generate title (keep this)
router.patch("/chats/:id/title", verifyToken, async (req, res) => {  // manual title update (new)
  try {
    const userId = req.user.user_id;
    const chatId = Number(req.params.id);
    const { title } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({ error: 'Title is required' });
    }

    // Verify chat belongs to user
    const [chat] = await db.execute(
      'SELECT id FROM conversations WHERE id=? AND user_id=?',
      [chatId, userId]
    );

    if (chat.length === 0) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    // Update title
    await db.execute(
      'UPDATE conversations SET title=? WHERE id=?',
      [title.trim(), chatId]
    );

    console.log(`✅ Chat ${chatId} title updated to: ${title.trim()}`);

    res.json({ id: chatId, title: title.trim() });
  } catch (err) {
    console.error('❌ Update chat title error:', err);
    res.status(500).json({ error: 'Failed to update title' });
  }
});

// --- Messages ---
router.get("/chats/:id/messages", verifyToken, message.list);      // list messages
router.post("/chats/:id/messages", verifyToken, message.send);     // send new message

// --- Uploads ---
router.post("/uploads", verifyToken, uploadCtrl.upload.single("file"), uploadCtrl.create);  // upload file
router.get("/uploads/:id", verifyToken, uploadCtrl.getAttachment);      // download/view file
router.delete("/uploads/:id", verifyToken, uploadCtrl.deleteAttachment); // delete file

export default router;
