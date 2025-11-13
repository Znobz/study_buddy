import db from "../config/db.js";
import * as ai from "../services/openaiService.js";

export const list = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const conversationId = Number(req.params.id);

    // Ensure conversation belongs to the user
    const [conv] = await db.query(
      "SELECT 1 FROM conversations WHERE id=? AND user_id=?",
      [conversationId, userId]
    );
    if (!conv.length) return res.status(404).json({ error: "Not found" });

    const limitRaw = parseInt(req.query.limit, 10);
    const limit = Math.min(Math.max(Number.isFinite(limitRaw) ? limitRaw : 30, 1), 100);
    const cursor = req.query.cursor ? Number(req.query.cursor) : null;

    let sql = "SELECT id, role, text, created_at FROM messages WHERE conversation_id=?";
    const params = [conversationId];

    if (cursor) {
      sql += " AND id < ?";
      params.push(cursor);
    }

    sql += ` ORDER BY id DESC LIMIT ${limit}`;

    const [rows] = await db.query(sql, params);
    const next_cursor = rows.length === limit ? rows[rows.length - 1].id : null;

    return res.json({ items: rows, next_cursor });
  } catch (err) {
    console.error("list messages error", err);
    return res.status(500).json({
      code: err.code,
      error: err.sqlMessage || err.message || "Failed to fetch messages",
    });
  }
};

export const send = async (req, res) => {
  console.log("🔥 SEND MESSAGE HIT:", req.body);
  try {
    const userId = req.user.user_id;
    const conversationId = Number(req.params.id);
    const { text, attachmentIds = [] } = req.body || {};

    if (!text || !text.trim()) {
      return res.status(400).json({ error: "Message text is required" });
    }

    const [conv] = await db.execute(
      "SELECT id FROM conversations WHERE id=? AND user_id=?",
      [conversationId, userId]
    );
    if (conv.length === 0) return res.status(404).json({ error: "Not found" });

    const [userInsert] = await db.execute(
      "INSERT INTO messages (conversation_id, role, text) VALUES (?,?,?)",
      [conversationId, "user", text.trim()]
    );
    const userMessageId = userInsert.insertId;

    if (attachmentIds.length > 0) {
      const idsPlaceholders = attachmentIds.map(() => "?").join(",");
      await db.execute(
        `UPDATE attachments
         SET message_id=?
         WHERE id IN (${idsPlaceholders})
           AND message_id IS NULL`,
        [userMessageId, ...attachmentIds]
      );
    }

    const [recent] = await db.execute(
      `SELECT role, text
         FROM messages
        WHERE conversation_id=?
        ORDER BY created_at DESC
        LIMIT 40`,
      [conversationId]
    );
    const context = recent.reverse();

    const replyText = await ai.reply({ messages: context });

    const [asstInsert] = await db.execute(
      "INSERT INTO messages (conversation_id, role, text) VALUES (?,?,?)",
      [conversationId, "assistant", replyText]
    );

    res.status(201).json({
      user: { id: userMessageId, role: "user", text: text.trim() },
      assistant: { id: asstInsert.insertId, role: "assistant", text: replyText },
    });
  } catch (err) {
    console.error("send message error", err);
    res.status(500).json({ error: "Failed to send message" });
  }
};
