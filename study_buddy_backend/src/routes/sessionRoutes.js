import express from "express";
import { verifyToken } from "../middleware/authMiddleware.js";
import {
  getSessions,
  addSession,
  updateSession,
  deleteSession,
} from "../controllers/sessionController.js";

const router = express.Router();

router.get("/", verifyToken, getSessions);
router.post("/", verifyToken, addSession);
router.put("/:id", verifyToken, updateSession);
router.delete("/:id", verifyToken, deleteSession);

export default router;
