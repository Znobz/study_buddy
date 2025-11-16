import db from '../config/db.js';

// POST /api/ai/chats - Create a new conversation
export const create = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { title = "New Chat" } = req.body;

    const sql = "INSERT INTO conversations (user_id, title) VALUES (?, ?)";
    const [result] = await db.query(sql, [user_id, title]);

    const chatData = {
      id: result.insertId,
      user_id,
      title,
      created_at: new Date(),
      updated_at: new Date(),
      is_archived: false,
    };

    console.log("✅ Chat created:", chatData);
    res.status(201).json(chatData);

  } catch (err) {
    console.error("❌ Error creating conversation:", err);
    res.status(500).json({ error: "Failed to create conversation" });
  }
};

// GET /api/ai/chats - List all conversations (non-archived)
export const list = async (req, res) => {  // ← Add async
  try {
    const user_id = req.user.user_id;
    console.log('📋 Listing chats for user:', user_id);

    const sql = `
      SELECT id, user_id, title, created_at, updated_at, is_archived
      FROM conversations
      WHERE user_id = ? AND is_archived = FALSE
      ORDER BY updated_at DESC
    `;

    const [results] = await db.query(sql, [user_id]);  // ← Use await with array destructuring

    console.log(`✅ Found ${results.length} chats for user ${user_id}`);
    res.json(results);

  } catch (err) {
    console.error('❌ Error listing conversations:', err);
    res.status(500).json({ error: 'Failed to list conversations' });
  }
};

// POST /api/ai/chats/:id/archive - Archive a conversation
export const archive = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { id } = req.params;

    const sql = "UPDATE conversations SET is_archived = TRUE WHERE id = ? AND user_id = ?";
    const [result] = await db.query(sql, [id, user_id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    console.log("✅ Chat archived:", id);
    res.json({ message: "Conversation archived successfully" });

  } catch (err) {
    console.error("❌ Error archiving conversation:", err);
    res.status(500).json({ error: "Failed to archive conversation" });
  }
};

// POST /api/ai/chats/:id/title - Update conversation title (or auto-generate)
export const title = async (req, res) => {
  try {
    const chatId = parseInt(req.params.id);
    const userId = req.user.user_id;
    let { title } = req.body;

    // Auto-generate title if not provided
    if (!title || title.trim() === '') {
      console.log('🤖 No title provided, auto-generating from first message...');

      // Get the first user message from this conversation
      const [messages] = await db.query(
        'SELECT text FROM messages WHERE conversation_id = ? AND role = "user" ORDER BY created_at ASC LIMIT 1',
        [chatId]
      );

      if (messages.length === 0) {
        return res.status(400).json({ error: 'Cannot generate title: no messages found' });
      }

      const firstMessage = messages[0].text;

      // Generate title using OpenAI (simple summarization)
      const { OpenAI } = await import('openai');
      const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

      const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'Generate a short, descriptive title (max 6 words) for this conversation based on the user\'s first message. Only return the title, nothing else.'
          },
          {
            role: 'user',
            content: firstMessage
          }
        ],
        max_tokens: 20,
        temperature: 0.7
      });

      title = completion.choices[0].message.content.trim();
      console.log('✅ Auto-generated title:', title);
    }

    // Update the title in database
    const sql = "UPDATE conversations SET title = ?, updated_at = NOW() WHERE id = ? AND user_id = ?";
    const [result] = await db.query(sql, [title, chatId, userId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Chat not found" });
    }

    console.log("✅ Title updated for chat", chatId, ":", title);
    res.json({ title });

  } catch (err) {
    console.error("❌ Error updating title:", err);
    res.status(500).json({ error: "Failed to update title" });
  }
};

// GET /api/ai/chats/:id - Get single chat details
export const getChatById = async (req, res) => {
  try {
    const chatId = parseInt(req.params.id);
    const userId = req.user.user_id;

    const [chats] = await db.query(
      'SELECT id, user_id, title, created_at, updated_at, is_archived FROM conversations WHERE id = ? AND user_id = ?',
      [chatId, userId]
    );

    if (chats.length === 0) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    console.log('✅ Chat details retrieved:', chats[0]);
    res.json(chats[0]);

  } catch (err) {
    console.error('❌ Error fetching chat:', err);
    res.status(500).json({ error: 'Failed to fetch chat' });
  }
};