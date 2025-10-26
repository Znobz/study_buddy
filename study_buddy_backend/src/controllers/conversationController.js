import db from '../config/db.js';

// POST /api/ai/chats - Create a new conversation
export const create = (req, res) => {
  const user_id = req.user.user_id; // from verifyToken middleware
  const { title = 'New Chat' } = req.body;

  const sql = 'INSERT INTO conversations (user_id, title) VALUES (?, ?)';
  db.query(sql, [user_id, title], (err, result) => {
    if (err) {
      console.error('❌ Error creating conversation:', err);
      return res.status(500).json({ error: 'Failed to create conversation' });
    }
    res.status(201).json({
      id: result.insertId,
      user_id,
      title,
      created_at: new Date(),
      updated_at: new Date(),
      is_archived: false
    });
  });
};

// GET /api/ai/chats - List all conversations (non-archived)
export const list = (req, res) => {
  const user_id = req.user.user_id;

  const sql = `
    SELECT id, user_id, title, created_at, updated_at, is_archived 
    FROM conversations 
    WHERE user_id = ? AND is_archived = FALSE 
    ORDER BY updated_at DESC
  `;
  
  db.query(sql, [user_id], (err, results) => {
    if (err) {
      console.error('❌ Error listing conversations:', err);
      return res.status(500).json({ error: 'Failed to list conversations' });
    }
    res.json(results);
  });
};

// POST /api/ai/chats/:id/archive - Archive a conversation
export const archive = (req, res) => {
  const user_id = req.user.user_id;
  const { id } = req.params;

  const sql = 'UPDATE conversations SET is_archived = TRUE WHERE id = ? AND user_id = ?';
  db.query(sql, [id, user_id], (err, result) => {
    if (err) {
      console.error('❌ Error archiving conversation:', err);
      return res.status(500).json({ error: 'Failed to archive conversation' });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    res.json({ message: 'Conversation archived successfully' });
  });
};

// POST /api/ai/chats/:id/title - Update conversation title
export const title = (req, res) => {
  const user_id = req.user.user_id;
  const { id } = req.params;
  const { title } = req.body;

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  const sql = 'UPDATE conversations SET title = ? WHERE id = ? AND user_id = ?';
  db.query(sql, [title, id, user_id], (err, result) => {
    if (err) {
      console.error('❌ Error updating title:', err);
      return res.status(500).json({ error: 'Failed to update title' });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    res.json({ message: 'Title updated successfully', title });
  });
};