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

// Handle POST - JSON only (file uploads removed for now)
router.post("/", verifyToken, upload.single("attachment"), addAssignment);
router.put("/:id", verifyToken, upload.single("attachment"), updateAssignment);
router.delete("/:id", verifyToken, deleteAssignment);

export default router;
