import express from "express";
import { verifyToken } from "../middleware/authMiddleware.js";
import {
  getAssignments,
  addAssignment,
  updateAssignment,
  deleteAssignment,
} from "../controllers/assignmentController.js";

const router = express.Router();

router.get("/", verifyToken, getAssignments);
router.post("/", verifyToken, addAssignment);
router.put("/:id", verifyToken, updateAssignment);
router.delete("/:id", verifyToken, deleteAssignment);

export default router;
