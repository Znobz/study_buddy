import db from "../config/db.js";

// ✅ Get all sessions for a user
export const getSessions = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const [rows] = await db.query("SELECT * FROM study_sessions WHERE user_id = ?", [userId]);
    res.json(rows);
  } catch (error) {
    console.error("Error fetching sessions:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Add a new study session
export const addSession = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const { topic, date, duration, notes } = req.body;
    await db.query(
      "INSERT INTO study_sessions (user_id, topic, date, duration, notes) VALUES (?, ?, ?, ?, ?)",
      [userId, topic, date, duration, notes]
    );
    res.json({ message: "Session added successfully" });
  } catch (error) {
    console.error("Error adding session:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Update a session
export const updateSession = async (req, res) => {
  try {
    const { id } = req.params;
    const { topic, date, duration, notes } = req.body;
    await db.query(
      "UPDATE study_sessions SET topic=?, date=?, duration=?, notes=? WHERE session_id=?",
      [topic, date, duration, notes, id]
    );
    res.json({ message: "Session updated successfully" });
  } catch (error) {
    console.error("Error updating session:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ✅ Delete a session
export const deleteSession = async (req, res) => {
  try {
    const { id } = req.params;
    await db.query("DELETE FROM study_sessions WHERE session_id=?", [id]);
    res.json({ message: "Session deleted successfully" });
  } catch (error) {
    console.error("Error deleting session:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
