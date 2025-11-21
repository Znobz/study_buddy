import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import db from '../config/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ===== MULTER CONFIGURATION =====
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads');

    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const nameWithoutExt = path.basename(file.originalname, ext);
    cb(null, `${uniqueSuffix}-${nameWithoutExt}${ext}`);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type ${file.mimetype} not supported`), false);
  }
};

export const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

// ===== CREATE ATTACHMENT =====
export const create = async (req, res) => {
  try {
    const user_id = req.user.user_id; // From auth middleware
    const { conversation_id } = req.body;

    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    if (!conversation_id) {
      return res.status(400).json({ error: "conversation_id required" });
    }

    // Verify user owns this conversation
    const [convs] = await db.execute(
      'SELECT id FROM conversations WHERE id = ? AND user_id = ?',
      [conversation_id, user_id]
    );

    if (convs.length === 0) {
      fs.unlinkSync(req.file.path); // Delete uploaded file
      return res.status(403).json({ error: 'Conversation not found or access denied' });
    }

    const { mimetype, size, filename, originalname, path: filePath } = req.file;
    const kind = mimetype.startsWith("image/") ? "image" : "file";
    const relativeFilePath = `uploads/${filename}`;

    // Insert with all required fields
    const [result] = await db.execute(
      `INSERT INTO attachments
       (conversation_id, user_id, filename, original_filename, kind, file_path, mime, size)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [conversation_id, user_id, filename, originalname, kind, relativeFilePath, mimetype, size]
    );

    console.log('✅ File uploaded:', originalname);

    res.status(201).json({
      id: result.insertId,
      conversation_id,
      filename,
      original_filename: originalname,
      kind,
      mime: mimetype,
      size,
      created_at: new Date(),
    });

  } catch (err) {
    console.error("❌ upload error:", err);

    // Cleanup file if error occurred
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }

    res.status(500).json({ error: "Upload failed" });
  }
};

// ===== GET ATTACHMENT =====
export const getAttachment = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { id } = req.params;

    const [attachments] = await db.execute(
      'SELECT * FROM attachments WHERE id = ? AND user_id = ?',
      [id, user_id]
    );

    if (attachments.length === 0) {
      return res.status(404).json({ error: 'Attachment not found' });
    }

    const attachment = attachments[0];
    const filePath = path.join(__dirname, '../../', attachment.file_path);

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'File not found on server' });
    }

    res.sendFile(filePath);

  } catch (err) {
    console.error('❌ Error retrieving attachment:', err);
    res.status(500).json({ error: 'Failed to retrieve attachment' });
  }
};

// ===== DELETE ATTACHMENT =====
export const deleteAttachment = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { id } = req.params;

    const [attachments] = await db.execute(
      'SELECT * FROM attachments WHERE id = ? AND user_id = ?',
      [id, user_id]
    );

    if (attachments.length === 0) {
      return res.status(404).json({ error: 'Attachment not found' });
    }

    const attachment = attachments[0];
    const filePath = path.join(__dirname, '../../', attachment.file_path);

    await db.execute('DELETE FROM attachments WHERE id = ?', [id]);

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }

    console.log('✅ Attachment deleted:', id);
    res.status(200).json({ message: 'Attachment deleted' });

  } catch (err) {
    console.error('❌ Error deleting attachment:', err);
    res.status(500).json({ error: 'Failed to delete attachment' });
  }
};
