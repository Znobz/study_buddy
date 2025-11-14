// backend/src/controllers/assignmentController.js
import db from "../config/db.js";
import path from "path";

const ATTACHMENT_SUBDIR = "assignments";

const getStoredFilePath = (file) => {
  if (!file) return { storedPath: null, originalName: null };
  const storedPath = path.posix.join(ATTACHMENT_SUBDIR, file.filename);
  const originalName = file.originalname ?? file.filename;
  return { storedPath, originalName };
};

/** Ensure a default "General" course exists for the user; return its course_id */
async function ensureDefaultCourse(userId) {
  const [rows] = await db.query(
    'SELECT course_id FROM courses WHERE user_id=? AND course_name=? LIMIT 1',
    [userId, 'General']
  );
  if (rows.length) return rows[0].course_id;

  const [ins] = await db.query(
    'INSERT INTO courses (user_id, course_name) VALUES (?,?)',
    [userId, 'General']
  );
  return ins.insertId;
}

// Helpers to accept both camelCase and snake_case
const pick = (obj, ...keys) => keys.find(k => obj?.[k] !== undefined) && obj[keys.find(k => obj?.[k] !== undefined)];
const getUserId = (req) => req.user?.user_id ?? req.query.userId ?? req.body?.userId;
const normalizeDate = (d) => {
  if (!d) return null;
  const s = String(d).trim();
  // Accept "YYYY-MM-DD" or full ISO strings; store as "YYYY-MM-DD 00:00:00"
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
  return m ? `${m[1]}-${m[2]}-${m[3]} 00:00:00` : null;
};

// ✅ Get all assignments for a user
export const getAssignments = async (req, res) => {
  try {
    const userId = getUserId(req);
    if (!userId) return res.status(400).json({ error: "userId missing" });

    console.log('\n📥 GET /api/assignments - Fetching assignments for user:', userId);
    
    const [rows] = await db.query(
      `SELECT assignment_id, course_id, user_id, title, description,
              DATE_FORMAT(due_date, "%Y-%m-%d") AS due_date,
              priority, status, file_path, file_name, created_at
       FROM assignments
       WHERE user_id = ?
       ORDER BY (due_date IS NULL), due_date ASC, assignment_id DESC`,
      [userId]
    );
    
    console.log('📊 SQL: SELECT * FROM assignments WHERE user_id =', userId);
    console.log(`✅ Found ${rows.length} assignments`);
    
    res.json(rows);
  } catch (error) {
    console.error("❌ Error fetching assignments:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Add new assignment
export const addAssignment = async (req, res) => {
  try {
    const userId = getUserId(req);
    const title = pick(req.body, 'title');
    const description = pick(req.body, 'description');
    const dueRaw = pick(req.body, 'due_date', 'dueDate');
    const courseIdRaw = pick(req.body, 'courseId', 'course_id');
    const priority = pick(req.body, 'priority') ?? 'medium';
    const status = pick(req.body, 'status') ?? 'pending';

    if (!userId || !title) {
      return res.status(400).json({ error: "userId and title are required" });
    }

    const due = normalizeDate(dueRaw);
    if (!due) {
      return res.status(400).json({ error: "due_date is required and must be YYYY-MM-DD format" });
    }

    // course_id NOT NULL in schema: use provided or fallback to General
    const cid = courseIdRaw ? Number(courseIdRaw) : await ensureDefaultCourse(Number(userId));

    const { storedPath, originalName } = getStoredFilePath(req.file);

    const [ins] = await db.query(
      `INSERT INTO assignments (course_id, user_id, title, description, due_date, priority, status, file_path, file_name)
       VALUES (?,?,?,?,?,?,?,?,?)`,
      [cid, userId, String(title).trim(), String(description ?? '').trim(), due, priority, status, storedPath, originalName]
    );

    const [rows] = await db.query(
      `SELECT assignment_id, course_id, user_id, title, description,
              DATE_FORMAT(due_date, "%Y-%m-%d") AS due_date,
              priority, status, file_path, file_name, created_at
       FROM assignments
       WHERE assignment_id = ?`,
      [ins.insertId]
    );

    return res.status(201).json(rows[0]);
  } catch (error) {
    console.error("Error adding assignment:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Update an assignment (partial)
export const updateAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    if (!id) return res.status(400).json({ error: "invalid id" });

    const body = req.body || {};
    const fields = [];
    const vals = [];

    if (body.title !== undefined) { fields.push('title=?'); vals.push(String(body.title).trim()); }
    if (body.description !== undefined) { fields.push('description=?'); vals.push(String(body.description ?? '').trim()); }

    const dueRaw = pick(body, 'due_date', 'dueDate');
    if (dueRaw !== undefined) {
      const due = normalizeDate(dueRaw);
      if (!due) return res.status(400).json({ error: "due_date must be YYYY-MM-DD (or omit it)" });
      fields.push('due_date=?'); vals.push(due);
    }

    if (body.status !== undefined) { fields.push('status=?'); vals.push(body.status); }
    if (body.priority !== undefined) { fields.push('priority=?'); vals.push(body.priority); }
    
    // Handle file upload if present
    if (req.file) {
      const { storedPath, originalName } = getStoredFilePath(req.file);
      fields.push('file_path=?'); vals.push(storedPath);
      fields.push('file_name=?'); vals.push(originalName);
    }

    const courseIdRaw = pick(body, 'courseId', 'course_id');
    if (courseIdRaw !== undefined) { fields.push('course_id=?'); vals.push(Number(courseIdRaw)); }

    if (!fields.length) return res.status(400).json({ error: "no fields to update" });

    await db.query(
      `UPDATE assignments SET ${fields.join(', ')} WHERE assignment_id=?`,
      [...vals, id]
    );

    const [rows] = await db.query(
      `SELECT assignment_id, course_id, user_id, title, description,
              DATE_FORMAT(due_date, "%Y-%m-%d") AS due_date,
              priority, status, file_path, file_name, created_at
       FROM assignments
       WHERE assignment_id = ?`,
      [id]
    );

    res.json(rows[0] ?? { message: "Assignment updated successfully", id });
  } catch (error) {
    console.error("Error updating assignment:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Delete an assignment
export const deleteAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('\n🗑️ DELETE /api/assignments/' + id);
    console.log('💾 SQL: DELETE FROM assignments WHERE assignment_id =', id);
    
    await db.query("DELETE FROM assignments WHERE assignment_id=?", [id]);
    
    console.log('✅ Assignment deleted successfully');
    
    res.json({ ok: true, deleted: Number(id) });
  } catch (error) {
    console.error("❌ Error deleting assignment:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
