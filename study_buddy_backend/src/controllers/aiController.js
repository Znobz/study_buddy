import dotenv from 'dotenv';
import OpenAI from 'openai';
import db from '../config/db.js';
dotenv.config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// POST /api/ai/ask
export const askTutor = async (req, res) => {
  // prefer user id from token (req.user from verifyToken)
  const tokenUserId = req.user?.user_id;
  const { user_id: bodyUserId, question, session_id = null } = req.body;
  const user_id = tokenUserId || bodyUserId || null;

  if (!question) return res.status(400).json({ error: 'Question is required' });

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are Study Buddy, a helpful AI study assistant." },
        { role: "user", content: question }
      ],
      max_tokens: 800,
    });

    const answer = completion.choices[0].message.content;

    const sql = `
      INSERT INTO chat_history (user_id, session_id, question, ai_response)
      VALUES (?, ?, ?, ?)
    `;
    db.query(sql, [user_id, session_id, question, answer], (err) => {
      if (err) console.error('❌ Failed to save chat history:', err);
    });

    res.json({ question, answer });
  } catch (err) {
    console.error('AI Tutor Error:', err);
    res.status(500).json({ error: 'AI Tutor service failed', details: err.message });
  }
};

export const getChatHistory = (req, res) => {
  // ensure token user matches requested userId or admin (simple check)
  const tokenUserId = req.user?.user_id;
  const { userId } = req.params;

  if (!tokenUserId || Number(tokenUserId) !== Number(userId)) {
    // restrict access to users accessing their own history
    return res.status(403).json({ error: 'Forbidden — token does not match requested user' });
  }

  const sql = 'SELECT chat_id, user_id, session_id, question, ai_response, timestamp FROM chat_history WHERE user_id = ? ORDER BY timestamp DESC';
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    res.json(results);
  });
};
