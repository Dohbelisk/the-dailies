import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';

export interface CrosswordWord {
  word: string;
  clue: string;
}

export interface ConnectionsCategory {
  name: string;
  words: string[];
  difficulty: number;
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private client: Anthropic | null = null;

  constructor() {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (apiKey) {
      this.client = new Anthropic({ apiKey });
      this.logger.log('Anthropic client initialized');
    } else {
      this.logger.warn('ANTHROPIC_API_KEY not set - AI features disabled');
    }
  }

  async generateCrosswordWords(
    theme: string,
    count: number = 10,
    minLength: number = 3,
    maxLength: number = 12,
  ): Promise<CrosswordWord[]> {
    if (!this.client) {
      throw new Error('AI service not configured - ANTHROPIC_API_KEY not set');
    }

    const prompt = `Generate ${count} crossword puzzle words and clues for the theme: "${theme}"

Requirements:
- Each word should be ${minLength}-${maxLength} letters long
- Words should be common English words that fit the theme
- Clues should be concise (under 50 characters) and suitable for a crossword puzzle
- Mix of easy and moderately challenging clues
- No proper nouns unless they're very well-known
- Words should work well in a crossword grid (avoid unusual letter combinations)

Return ONLY a valid JSON array with no markdown formatting, like this:
[{"word": "EXAMPLE", "clue": "A sample or specimen"}]

Generate exactly ${count} word/clue pairs for the theme "${theme}":`;

    try {
      const response = await this.client.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
      });

      // Extract text content from response
      const textContent = response.content.find((block) => block.type === 'text');
      if (!textContent || textContent.type !== 'text') {
        throw new Error('No text content in AI response');
      }

      // Parse JSON response
      const jsonText = textContent.text.trim();
      const words: CrosswordWord[] = JSON.parse(jsonText);

      // Validate and clean up
      return words
        .filter(
          (w) =>
            w.word &&
            w.clue &&
            w.word.length >= minLength &&
            w.word.length <= maxLength,
        )
        .map((w) => ({
          word: w.word.toUpperCase().replace(/[^A-Z]/g, ''),
          clue: w.clue.trim(),
        }));
    } catch (error) {
      this.logger.error('Failed to generate crossword words', error);
      throw new Error(`AI generation failed: ${error.message}`);
    }
  }

  async generateConnections(theme?: string): Promise<ConnectionsCategory[]> {
    if (!this.client) {
      throw new Error('AI service not configured - ANTHROPIC_API_KEY not set');
    }

    const themeText = theme ? `for the theme "${theme}"` : 'with any creative themes you choose';

    const prompt = `Generate a Connections puzzle ${themeText}. This is a word puzzle where players must find 4 groups of 4 related words.

Requirements:
- Create exactly 4 categories with exactly 4 words each (16 words total)
- Each word should be a single word (no spaces), 3-10 letters long
- Words should be common English words (no obscure terms)
- Categories should range from obvious to tricky:
  - Difficulty 1 (Yellow/Easiest): Very obvious connection
  - Difficulty 2 (Green/Easy): Clear connection but slightly less obvious
  - Difficulty 3 (Blue/Medium): Requires more thought, could have red herrings
  - Difficulty 4 (Purple/Hardest): Clever or unexpected connection, may have words that seem to fit other categories
- Category names should be SHORT (2-4 words max) but descriptive
- Include some "red herrings" - words that could plausibly fit multiple categories
- All 16 words must be UNIQUE (no duplicates)
- Words should be ALL CAPS

Return ONLY a valid JSON array with no markdown formatting, like this:
[{"name": "CATEGORY NAME", "words": ["WORD1", "WORD2", "WORD3", "WORD4"], "difficulty": 1}]

Generate the 4 categories now:`;

    try {
      const response = await this.client.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
      });

      // Extract text content from response
      const textContent = response.content.find((block) => block.type === 'text');
      if (!textContent || textContent.type !== 'text') {
        throw new Error('No text content in AI response');
      }

      // Parse JSON response
      const jsonText = textContent.text.trim();
      const categories: ConnectionsCategory[] = JSON.parse(jsonText);

      // Validate and clean up
      return categories
        .filter(
          (c) =>
            c.name &&
            Array.isArray(c.words) &&
            c.words.length === 4 &&
            c.difficulty >= 1 &&
            c.difficulty <= 4,
        )
        .map((c) => ({
          name: c.name.trim(),
          words: c.words.map((w) => w.toUpperCase().replace(/[^A-Z]/g, '')),
          difficulty: c.difficulty,
        }))
        .sort((a, b) => a.difficulty - b.difficulty);
    } catch (error) {
      this.logger.error('Failed to generate connections puzzle', error);
      throw new Error(`AI generation failed: ${error.message}`);
    }
  }

  isAvailable(): boolean {
    return this.client !== null;
  }
}
