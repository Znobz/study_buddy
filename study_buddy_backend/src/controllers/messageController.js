import db from "../config/db.js";
import * as ai from "../services/openaiService.js";
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const list = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const conversationId = Number(req.params.id);

    // Ensure conversation belongs to the user
    const [conv] = await db.execute(
      "SELECT 1 FROM conversations WHERE id=? AND user_id=?",
      [conversationId, userId]
    );
    if (!conv.length) return res.status(404).json({ error: 'Not found' });

    const limitRaw = parseInt(req.query.limit, 10);
    const limit = Math.min(Math.max(Number.isFinite(limitRaw) ? limitRaw : 30, 1), 100);
    const cursor = req.query.cursor ? Number(req.query.cursor) : null;

    let sql = `
      SELECT
        m.id,
        m.role,
        m.text,
        m.created_at,
        m.sources,
        (SELECT JSON_ARRAYAGG(
          JSON_OBJECT(
            'id', a.id,
            'filename', a.filename,
            'original_filename', a.original_filename,
            'kind', a.kind,
            'mime', a.mime,
            'size', a.size
          )
        )
        FROM attachments a
        WHERE a.message_id = m.id) as attachments
      FROM messages m
      WHERE m.conversation_id=?
    `;
    const params = [conversationId];

    if (cursor) {
      sql += " AND m.id < ?";
      params.push(cursor);
    }

    sql += ` ORDER BY m.id DESC LIMIT ${limit}`;

    const [rows] = await db.execute(sql, params);

    // Parse attachments and sources safely
    const items = rows.map(row => {
      let attachments = [];
      let sources = [];

      if (row.attachments) {
        if (typeof row.attachments === 'string') {
          try {
            attachments = JSON.parse(row.attachments);
          } catch (e) {
            console.warn('Failed to parse attachments:', e);
          }
        } else if (Array.isArray(row.attachments)) {
          attachments = row.attachments;
        }
      }

      if (row.sources) {
        if (typeof row.sources === 'string') {
          try {
            sources = JSON.parse(row.sources);
          } catch (e) {
            console.warn('Failed to parse sources:', e);
          }
        } else if (Array.isArray(row.sources)) {
          sources = row.sources;
        }
      }

      return {
        ...row,
        attachments: attachments,
        sources: sources
      };
    });

    const next_cursor = rows.length === limit ? rows[rows.length - 1].id : null;

    return res.json({ items, next_cursor });
  } catch (err) {
    console.error('list messages error', err);
    return res.status(500).json({
      code: err.code,
      error: err.sqlMessage || err.message || 'Failed to fetch messages'
    });
  }
};

export const send = async (req, res) => {
  console.log('🔥 SEND MESSAGE HIT:', req.body);
  try {
    const userId = req.user.user_id;
    const conversationId = Number(req.params.id);
    const { text, attachmentIds = [], researchMode = false } = req.body || {};

    if (!text || !text.trim()) {
      return res.status(400).json({ error: 'Message text is required' });
    }

    const [conv] = await db.execute(
      'SELECT id FROM conversations WHERE id=? AND user_id=?',
      [conversationId, userId]
    );
    if (conv.length === 0) return res.status(404).json({ error: 'Not found' });

    // Insert user message
    const [userInsert] = await db.execute(
      'INSERT INTO messages (conversation_id, role, text) VALUES (?,?,?)',
      [conversationId, 'user', text.trim()]
    );
    const userMessageId = userInsert.insertId;

    // Link attachments to the message
    if (attachmentIds.length > 0) {
      const idsPlaceholders = attachmentIds.map(() => '?').join(',');
      await db.execute(
        `UPDATE attachments
         SET message_id=?
         WHERE id IN (${idsPlaceholders})
           AND message_id IS NULL
           AND user_id=?`,
        [userMessageId, ...attachmentIds, userId]
      );
    }

    // Fetch recent conversation history WITH attachments
    const [recent] = await db.execute(
      `SELECT
         m.id,
         m.role,
         m.text,
         (SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
             'id', a.id,
             'filename', a.filename,
             'original_filename', a.original_filename,
             'kind', a.kind,
             'file_path', a.file_path,
             'mime', a.mime,
             'size', a.size
           )
         )
         FROM attachments a
         WHERE a.message_id = m.id) as attachments_json
       FROM messages m
       WHERE m.conversation_id=?
       ORDER BY m.created_at DESC
       LIMIT 40`,
      [conversationId]
    );

    // Build context with attachment data safely
    const context = recent.reverse().map(msg => {
      let attachments = [];

      if (msg.attachments_json) {
        if (typeof msg.attachments_json === 'string') {
          try {
            attachments = JSON.parse(msg.attachments_json);
          } catch (e) {
            console.warn('Failed to parse attachments_json:', e);
          }
        } else if (Array.isArray(msg.attachments_json)) {
          attachments = msg.attachments_json;
        }
      }

      return {
        role: msg.role,
        text: msg.text,
        attachments: attachments
      };
    });

    // Choose AI response mode based on researchMode flag
    let replyText;
    let sources = null;

    if (researchMode) {
      // Research mode - search web and cite sources
      console.log('🔬 Research mode activated');
      const researchResult = await ai.replyWithResearch({
        messages: context,
        query: text.trim()
      });
      replyText = researchResult.text;
      sources = researchResult.sources;
    } else {
      // Normal flow with attachments
      replyText = await ai.replyWithAttachments({ messages: context });
    }

    // Insert AI response with sources column
    const [asstInsert] = await db.execute(
      "INSERT INTO messages (conversation_id, role, text, sources) VALUES (?,?,?,?)",
      [conversationId, "assistant", replyText, sources ? JSON.stringify(sources) : null]
    );

    console.log("✅ Message sent with", attachmentIds.length, "attachments",
                sources ? `and ${sources.length} sources` : "");

    // Return sources in response
    res.status(201).json({
      user: {
        id: userMessageId,
        role: "user",
        text: text.trim(),
        attachments: attachmentIds.length > 0 ? attachmentIds : []
      },
      assistant: {
        id: asstInsert.insertId,
        role: "assistant",
        text: replyText,
        sources: sources || []
      },
    });

  } catch (err) {
    console.error("❌ send message error", err);
    res.status(500).json({ error: "Failed to send message" });
  }
};