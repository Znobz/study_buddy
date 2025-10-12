import db from "../config/db.js";

// ✅ Get all assignments for a user
export const getAssignments = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const [rows] = await db.query("SELECT * FROM assignments WHERE user_id = ?", [userId]);
    res.json(rows);
  } catch (error) {
    console.error("Error fetching assignments:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Add new assignment
export const addAssignment = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const { title, description, due_date } = req.body;
    await db.query(
      "INSERT INTO assignments (user_id, title, description, due_date) VALUES (?, ?, ?, ?)",
      [userId, title, description, due_date]
    );
    res.json({ message: "Assignment added successfully" });
  } catch (error) {
    console.error("Error adding assignment:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Update an assignment
export const updateAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, due_date, status } = req.body;
    await db.query(
      "UPDATE assignments SET title=?, description=?, due_date=?, status=? WHERE assignment_id=?",
      [title, description, due_date, status, id]
    );
    res.json({ message: "Assignment updated successfully" });
  } catch (error) {
    console.error("Error updating assignment:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Delete an assignment
export const deleteAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    await db.query("DELETE FROM assignments WHERE assignment_id=?", [id]);
    res.json({ message: "Assignment deleted successfully" });
  } catch (error) {
    console.error("Error deleting assignment:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
