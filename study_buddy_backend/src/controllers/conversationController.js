import db from "../config/db.js";

// POST /api/ai/chats - Create a new conversation
export const create = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { title = "New Chat" } = req.body;

    console.log('💬 Creating conversation for user:', user_id, 'title:', title);

    const sql = "INSERT INTO conversations (user_id, title) VALUES (?, ?)";
    const [result] = await db.execute(sql, [user_id, title]);
    
    console.log('✅ Conversation created with ID:', result.insertId);
    
    res.status(201).json({
      id: result.insertId,
      user_id,
      title,
      created_at: new Date(),
      updated_at: new Date(),
      is_archived: false,
    });
  } catch (err) {
    console.error("❌ Error creating conversation:", err);
    res.status(500).json({ error: "Failed to create conversation", details: err.message });
  }
};

// GET /api/ai/chats - List all conversations (non-archived)
export const list = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    console.log("📋 Listing conversations for user:", user_id);

    const sql = `
      SELECT id, user_id, title, created_at, updated_at, is_archived 
      FROM conversations 
      WHERE user_id = ? AND is_archived = FALSE 
      ORDER BY updated_at DESC
    `;

    const [results] = await db.query(sql, [user_id]);
    console.log("✅ Conversations fetched:", results);
    res.json(results);
  } catch (err) {
    console.error("❌ Error listing conversations:", err);
    res.status(500).json({ error: "Failed to list conversations" });
  }
};


// POST /api/ai/chats/:id/archive - Archive a conversation
export const archive = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { id } = req.params;

    const sql = "UPDATE conversations SET is_archived = TRUE WHERE id = ? AND user_id = ?";
    const [result] = await db.execute(sql, [id, user_id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Conversation not found" });
    }
    res.json({ message: "Conversation archived successfully" });
  } catch (err) {
    console.error("❌ Error archiving conversation:", err);
    res.status(500).json({ error: "Failed to archive conversation", details: err.message });
  }
};

// POST /api/ai/chats/:id/title - Update conversation title
export const title = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { id } = req.params;
    const { title } = req.body;

    if (!title) {
      return res.status(400).json({ error: "Title is required" });
    }

    const sql = "UPDATE conversations SET title = ? WHERE id = ? AND user_id = ?";
    const [result] = await db.execute(sql, [title, id, user_id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Conversation not found" });
    }
    res.json({ message: "Title updated successfully", title });
  } catch (err) {
    console.error("❌ Error updating title:", err);
    res.status(500).json({ error: "Failed to update title", details: err.message });
  }
};
