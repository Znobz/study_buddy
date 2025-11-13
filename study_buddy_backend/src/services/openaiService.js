import OpenAI from "openai";

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export const reply = async ({ messages }) => {
  try {
    // 🧹 Normalize messages to the correct OpenAI format
    const formatted = messages
      .filter(
        (m) => m && m.role && typeof m.text === "string" && m.text.trim() !== ""
      )
      .map((m) => ({
        role: m.role,
        content: m.text.trim(),
      }));

    if (formatted.length === 0) {
      console.warn("⚠️ No valid messages to send to OpenAI:", messages);
      return "Sorry, I didn’t receive a valid question.";
    }

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini", // or "gpt-3.5-turbo" if you prefer
      messages: formatted,
    });

    const replyText =
      response.choices[0].message?.content?.trim() ||
      "Sorry, I couldn’t generate a response.";

    console.log("🧠 AI Reply:", replyText);
    return replyText;
  } catch (err) {
    console.error("❌ OpenAI API error:", err);
    return "Sorry, I had trouble generating a response.";
  }
};
