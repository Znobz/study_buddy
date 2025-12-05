import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { dirname } from "path";
import { verifyToken } from "../middleware/authMiddleware.js";
import {
  getAssignments,
  addAssignment,
  updateAssignment,
  deleteAssignment,
} from "../controllers/assignmentController.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const router = express.Router();

// Configure multer for file uploads - use absolute path
const uploadsDir = path.join(__dirname, "../../uploads/assignments");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log(`✅ Created uploads directory: ${uploadsDir}`);
} else {
  console.log(`✅ Uploads directory exists: ${uploadsDir}`);
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit
});

router.get("/", verifyToken, getAssignments);

// temporary debug route
router.get("/debug/files", (req, res) => {
  try {
    const files = fs.readdirSync(uploadsDir);
    res.json({
      uploadsDir,
      files,
      fileCount: files.length
    });
  } catch (error) {
    res.json({ error: error.message });
  }
});

router.get("/:filename", (req, res) => {
  console.log(`🔍 File request received: ${req.params.filename}`);
  console.log(`🔍 Full request path: ${req.originalUrl}`);
  console.log(`🔍 Looking for file in: ${uploadsDir}`);

  const { filename } = req.params;
  const filePath = path.join(uploadsDir, filename);

  console.log(`🔍 Complete file path: ${filePath}`);
  console.log(`🔍 File exists: ${fs.existsSync(filePath)}`);

  if (!fs.existsSync(filePath)) {
    console.log(`❌ File not found: ${filePath}`);
    return res.status(404).json({ error: 'File not found' });
  }

  const ext = path.extname(filename).toLowerCase();
  let contentType = 'application/octet-stream';

  switch (ext) {
    case '.pdf': contentType = 'application/pdf'; break;
    case '.doc': contentType = 'application/msword'; break;
    case '.docx': contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; break;
  }

  console.log(`✅ Serving file with content type: ${contentType}`);
  res.setHeader('Content-Type', contentType);
  res.setHeader('Content-Disposition', `inline; filename="${filename}"`);
  res.sendFile(filePath);
});

// Handle POST - JSON only (file uploads removed for now)
router.post("/", verifyToken, upload.single("attachment"), addAssignment);
router.put("/:id", verifyToken, upload.single("attachment"), updateAssignment);
router.delete("/:id", verifyToken, deleteAssignment);

export default router;
