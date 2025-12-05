import { tavily } from '@tavily/core';

const tv = tavily({ apiKey: process.env.TAVILY_API_KEY });

export async function searchWeb(query) {
  try {
    console.log('🔍 Tavily search query:', query);

    const response = await tv.search(query, {
      searchDepth: 'basic',
      maxResults: 5,
      includeAnswer: false,
    });

    console.log('✅ Tavily results:', response.results?.length || 0);

    if (!response.results || response.results.length === 0) {
      return [];
    }

    return response.results.map(result => ({
      title: result.title || 'Untitled',
      url: result.url || '',
      content: result.content || result.snippet || '',
      score: result.score || 0,
    }));

  } catch (err) {
    console.error('❌ Tavily search error:', err);
    return [];
  }
}