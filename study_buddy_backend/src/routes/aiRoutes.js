import express from "express";
import { verifyToken as auth } from "../middleware/authMiddleware.js";
import * as conversation from "../controllers/conversationController.js";
import * as message from "../controllers/messageController.js";
import * as uploadCtrl from "../controllers/uploadController.js";
import multer from "multer";

const router = express.Router();

// Temporary file upload setup — replace with S3/Cloudinary later
const upload = multer({ dest: "uploads/" });

// --- Conversations ---
router.post("/chats", auth, conversation.create);           // create new chat
router.get("/chats", auth, conversation.list);              // list chats
router.post("/chats/:id/archive", auth, conversation.archive);
router.post("/chats/:id/title", auth, conversation.title);  // rename chat

// --- Messages ---
router.get("/chats/:id/messages", auth, message.list);      // list messages
router.post("/chats/:id/messages", auth, message.send);     // send new message

// --- Uploads ---
router.post("/uploads", auth, upload.single("file"), uploadCtrl.create);

export default router;
