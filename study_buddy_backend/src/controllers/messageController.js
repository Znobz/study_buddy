const db = require('../config/db').p;
const ai = require('../services/openaiService');

exports.list = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const conversationId = Number(req.params.id);

    // Ensure the conversation belongs to the user
    const [conv] = await db.query(
      'SELECT 1 FROM conversations WHERE id=? AND user_id=?',
      [conversationId, userId]
    );
    if (!conv.length) return res.status(404).json({ error: 'Not found' });

    // Sanitize limit; avoid binding LIMIT ?
    const limitRaw = parseInt(req.query.limit, 10);
    const limit = Math.min(Math.max(Number.isFinite(limitRaw) ? limitRaw : 30, 1), 100);

    // Optional cursor; we’ll use id-based pagination (simple & robust)
    const cursor = req.query.cursor ? Number(req.query.cursor) : null;

    let sql = 'SELECT id, role, text, created_at FROM messages WHERE conversation_id=?';
    const params = [conversationId];

    if (cursor) {
      sql += ' AND id < ?';
      params.push(cursor);
    }

    // Use template literal so ${limit} is interpolated; include a leading space
    sql += ` ORDER BY id DESC LIMIT ${limit}`;

    const [rows] = await db.query(sql, params);

    const next_cursor = rows.length === limit ? rows[rows.length - 1].id : null;
    return res.json({ items: rows, next_cursor });
  } catch (err) {
    console.error('list messages error', err);
    return res.status(500).json({
      code: err.code,
      error: err.sqlMessage || err.message || 'Failed to fetch messages'
    });
  }
};


exports.send = async (req, res) => {
  console.log('🔥 SEND MESSAGE HIT:', req.body);
  try {
    const userId = req.user.user_id;
    const conversationId = Number(req.params.id);
    const { text, attachmentIds = [], stream = false } = req.body || {};

    if (!text || !text.trim()) {
      return res.status(400).json({ error: 'Message text is required' });
    }

    // Ownership check
    const [conv] = await db.execute(
      'SELECT id FROM conversations WHERE id=? AND user_id=?',
      [conversationId, userId]
    );
    if (conv.length === 0) return res.status(404).json({ error: 'Not found' });

    // 1) Insert the user message
    const [userInsert] = await db.execute(
      'INSERT INTO messages (conversation_id, role, text) VALUES (?,?,?)',
      [conversationId, 'user', text.trim()]
    );
    const userMessageId = userInsert.insertId;

    // 2) Connect any pre-uploaded attachments to this message
    if (attachmentIds.length > 0) {
      // only attach rows that currently have message_id IS NULL and belong to this user (if you track owner)
      const idsPlaceholders = attachmentIds.map(() => '?').join(',');
      await db.execute(
        `UPDATE attachments
           SET message_id=?
         WHERE id IN (${idsPlaceholders})
           AND message_id IS NULL`,
        [userMessageId, ...attachmentIds]
      );
    }

    // 3) Build context for the model (last N messages + optional system)
    const [recent] = await db.execute(
      `SELECT role, text
         FROM messages
        WHERE conversation_id=?
        ORDER BY created_at DESC
        LIMIT 40`, // keep it tight; summarize older if needed
      [conversationId]
    );
    const context = recent.reverse(); // chronological

    // 4) Call model (simple completion style)
    const replyText = await ai.reply({ messages: context });

    // 5) Insert assistant reply
    const [asstInsert] = await db.execute(
      'INSERT INTO messages (conversation_id, role, text) VALUES (?,?,?)',
      [conversationId, 'assistant', replyText]
    );

    // 6) Return both messages
    res.status(201).json({
      user: { id: userMessageId, role: 'user', text: text.trim() },
      assistant: { id: asstInsert.insertId, role: 'assistant', text: replyText }
    });

    // (If you implement SSE streaming: start streaming before step 5 and patch in tokens)
  } catch (err) {
    console.error('send message error', err);
    res.status(500).json({ error: 'Failed to send message' });
  }
};