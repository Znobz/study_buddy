import OpenAI from 'openai';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Helper to convert LaTeX-like notation to Unicode
function cleanMathNotation(text) {
  return text
    .replace(/\\times/g, '×')
    .replace(/\\div/g, '÷')
    .replace(/\\pm/g, '±')
    .replace(/\\approx/g, '≈')
    .replace(/\\neq/g, '≠')
    .replace(/\\leq/g, '≤')
    .replace(/\\geq/g, '≥')
    .replace(/\\sqrt/g, '√')
    .replace(/\\pi/g, 'π')
    .replace(/\\theta/g, 'θ')
    .replace(/\\alpha/g, 'α')
    .replace(/\\beta/g, 'β')
    .replace(/\\gamma/g, 'γ')
    .replace(/\\delta/g, 'δ')
    .replace(/\\lambda/g, 'λ')
    .replace(/\\mu/g, 'μ')
    .replace(/\\sigma/g, 'σ')
    .replace(/\\infty/g, '∞')
    .replace(/\\rightarrow/g, '→')
    .replace(/\\leftarrow/g, '←')
    .replace(/\\Rightarrow/g, '⇒')
    .replace(/\\Leftarrow/g, '⇐')
    .replace(/\^2/g, '²')
    .replace(/\^3/g, '³')
    .replace(/_2/g, '₂')
    .replace(/_3/g, '₃');
}

export async function replyWithAttachments({ messages }) {
  try {
    const formattedMessages = [];

    for (const msg of messages) {
      if (msg.role === 'user' && msg.attachments && msg.attachments.length > 0) {
        const content = [{ type: 'text', text: msg.text }];

        for (const att of msg.attachments) {
          if (att.kind === 'image') {
            const imagePath = path.join(__dirname, '../../', att.file_path);

            if (fs.existsSync(imagePath)) {
              const imageBuffer = fs.readFileSync(imagePath);
              const base64Image = imageBuffer.toString('base64');
              const mimeType = att.mime || 'image/jpeg';

              content.push({
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${base64Image}`,
                },
              });
            } else {
              console.warn(`Image not found: ${imagePath}`);
            }
          }
        }

        formattedMessages.push({
          role: msg.role,
          content: content,
        });
      } else {
        formattedMessages.push({
          role: msg.role,
          content: msg.text,
        });
      }
    }

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: `You are a helpful study assistant. When explaining math or science concepts:
- Use clear, simple Unicode symbols (×, ÷, ², ³, √, π, etc.) instead of LaTeX
- Format equations naturally like: E = mc²  or  a² + b² = c²
- Use → for "leads to" or "results in"
- Keep explanations clear and educational
- Break down complex problems step by step`
        },
        ...formattedMessages,
      ],
      max_tokens: 1500,
    });

    let responseText = completion.choices[0].message.content;
    responseText = cleanMathNotation(responseText);

    return responseText;
  } catch (err) {
    console.error('OpenAI API error:', err);
    throw new Error('Failed to get AI response');
  }
}

export async function replyWithResearch({ messages, query }) {
  try {
    const { searchWeb } = await import('./searchService.js');

    console.log('🔍 Searching web for:', query);
    const searchResults = await searchWeb(query);

    if (!searchResults || searchResults.length === 0) {
      console.warn('⚠️ No search results found, falling back to normal response');
      return {
        text: await replyWithAttachments({ messages }),
        sources: []
      };
    }

    const contextText = searchResults
      .map((result, idx) => `[Source ${idx + 1}] ${result.title}\n${result.content}`)
      .join('\n\n');

    const formattedMessages = messages.map(msg => ({
      role: msg.role,
      content: msg.text,
    }));

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: `You are a research assistant. Use the provided search results to answer the user's question.

CRITICAL RULES:
1. Cite sources using [Source X] notation after EACH claim
2. Use clear Unicode symbols (×, ÷, ², ³, √, π) instead of LaTeX
3. Only use information from the provided sources
4. If sources don't have the answer, say so clearly
5. Be concise but informative

Search Results:
${contextText}`
        },
        ...formattedMessages,
      ],
      max_tokens: 2000,
    });

    let responseText = completion.choices[0].message.content;
    responseText = cleanMathNotation(responseText);

    return {
      text: responseText,
      sources: searchResults.map(r => ({
        title: r.title,
        url: r.url,
        snippet: r.content.substring(0, 200)
      }))
    };

  } catch (err) {
    console.error('❌ Research mode error:', err);
    return {
      text: await replyWithAttachments({ messages }),
      sources: []
    };
  }
}