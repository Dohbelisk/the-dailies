import { Injectable, Logger } from "@nestjs/common";
import Anthropic from "@anthropic-ai/sdk";

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
      this.logger.log("Anthropic client initialized");
    } else {
      this.logger.warn("ANTHROPIC_API_KEY not set - AI features disabled");
    }
  }

  async generateCrosswordWords(
    theme: string,
    count: number = 10,
    minLength: number = 3,
    maxLength: number = 12,
  ): Promise<CrosswordWord[]> {
    if (!this.client) {
      throw new Error("AI service not configured - ANTHROPIC_API_KEY not set");
    }

    // Parse comma-separated themes
    const themes = theme
      .split(",")
      .map((t) => t.trim())
      .filter((t) => t.length > 0);

    if (themes.length === 0) {
      throw new Error("At least one theme is required");
    }

    // Generate a random seed for variety
    const randomSeed = Math.random().toString(36).substring(2, 10);

    // Build theme instruction based on single or multiple themes
    let themeInstruction: string;
    if (themes.length === 1) {
      themeInstruction = `for the theme: "${themes[0]}"`;
    } else {
      themeInstruction = `mixing words from these themes: ${themes.map((t) => `"${t}"`).join(", ")}. Distribute words roughly evenly across all themes`;
    }

    const prompt = `Generate ${count} crossword puzzle words and clues ${themeInstruction}.

Requirements:
- Each word should be ${minLength}-${maxLength} letters long
- Words should be common English words that fit the theme(s)
- Clues should be concise (under 50 characters) and suitable for a crossword puzzle
- Mix of easy and moderately challenging clues
- No proper nouns unless they're very well-known
- Words should work well in a crossword grid (avoid unusual letter combinations)
- IMPORTANT: Be creative and varied - avoid common/obvious words. Think of interesting, unexpected words that still fit the theme(s).
- Use this random seed to inspire unique choices: ${randomSeed}

Return ONLY a valid JSON array with no markdown formatting, like this:
[{"word": "EXAMPLE", "clue": "A sample or specimen"}]

Generate exactly ${count} unique and creative word/clue pairs:`;

    try {
      const response = await this.client.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      });

      // Extract text content from response
      const textContent = response.content.find(
        (block) => block.type === "text",
      );
      if (!textContent || textContent.type !== "text") {
        throw new Error("No text content in AI response");
      }

      // Parse JSON response
      const jsonText = textContent.text.trim();
      const words: CrosswordWord[] = JSON.parse(jsonText);

      // Validate, clean up, and shuffle for additional randomness
      const validWords = words
        .filter(
          (w) =>
            w.word &&
            w.clue &&
            w.word.length >= minLength &&
            w.word.length <= maxLength,
        )
        .map((w) => ({
          word: w.word.toUpperCase().replace(/[^A-Z]/g, ""),
          clue: w.clue.trim(),
        }));

      // Shuffle the results for additional variety
      return this.shuffleArray(validWords);
    } catch (error) {
      this.logger.error("Failed to generate crossword words", error);
      throw new Error(`AI generation failed: ${error.message}`);
    }
  }

  private shuffleArray<T>(array: T[]): T[] {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  async generateConnections(theme?: string): Promise<ConnectionsCategory[]> {
    if (!this.client) {
      throw new Error("AI service not configured - ANTHROPIC_API_KEY not set");
    }

    const themeText = theme
      ? `for the theme "${theme}"`
      : "with any creative themes you choose";

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
        model: "claude-sonnet-4-20250514",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      });

      // Extract text content from response
      const textContent = response.content.find(
        (block) => block.type === "text",
      );
      if (!textContent || textContent.type !== "text") {
        throw new Error("No text content in AI response");
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
          words: c.words.map((w) => w.toUpperCase().replace(/[^A-Z]/g, "")),
          difficulty: c.difficulty,
        }))
        .sort((a, b) => a.difficulty - b.difficulty);
    } catch (error) {
      this.logger.error("Failed to generate connections puzzle", error);
      throw new Error(`AI generation failed: ${error.message}`);
    }
  }

  async generateWordClues(
    words: string[],
  ): Promise<{ word: string; clue: string }[]> {
    if (!this.client) {
      throw new Error("AI service not configured - ANTHROPIC_API_KEY not set");
    }

    if (words.length === 0) {
      return [];
    }

    // Batch words to avoid token limits (max ~50 words per request)
    const BATCH_SIZE = 50;
    const results: { word: string; clue: string }[] = [];

    for (let i = 0; i < words.length; i += BATCH_SIZE) {
      const batch = words.slice(i, i + BATCH_SIZE);
      const batchResults = await this.generateCluesBatch(batch);
      results.push(...batchResults);
    }

    return results;
  }

  private async generateCluesBatch(
    words: string[],
  ): Promise<{ word: string; clue: string }[]> {
    const wordList = words.map((w) => w.toUpperCase()).join(", ");

    const prompt = `Generate short dictionary-style clues for these words: ${wordList}

Requirements:
- Each clue should be 3-8 words maximum
- Clues should be simple definitions suitable for a word puzzle hint
- Use the style of crossword puzzle clues (concise, no articles at the start)
- For verbs, use infinitive form in the clue (e.g., "To walk slowly")
- For nouns, give a brief definition (e.g., "Large body of water")
- For adjectives, describe what it means (e.g., "Full of joy")

Return ONLY a valid JSON array with no markdown formatting, like this:
[{"word": "EXAMPLE", "clue": "Sample or specimen"}]

Generate clues for all ${words.length} words:`;

    try {
      const response = await this.client.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      });

      const textContent = response.content.find(
        (block) => block.type === "text",
      );
      if (!textContent || textContent.type !== "text") {
        throw new Error("No text content in AI response");
      }

      const jsonText = textContent.text.trim();
      const clues: { word: string; clue: string }[] = JSON.parse(jsonText);

      return clues
        .filter((c) => c.word && c.clue)
        .map((c) => ({
          word: c.word.toUpperCase().replace(/[^A-Z]/g, ""),
          clue: c.clue.trim(),
        }));
    } catch (error) {
      this.logger.error("Failed to generate word clues", error);
      throw new Error(`AI clue generation failed: ${error.message}`);
    }
  }

  /**
   * Generate crossword words that contain specific letters at specific positions.
   * Used for iterative grid building to find words that can intersect with placed words.
   */
  async generateCrosswordWordsWithConstraints(
    theme: string,
    constraints: {
      letter: string;
      minLength: number;
      maxLength: number;
      preferredLengths?: number[];
    }[],
    existingWords: string[],
    count: number = 15,
  ): Promise<CrosswordWord[]> {
    if (!this.client) {
      throw new Error("AI service not configured - ANTHROPIC_API_KEY not set");
    }

    // Parse themes
    const themes = theme
      .split(",")
      .map((t) => t.trim())
      .filter((t) => t.length > 0);

    if (themes.length === 0) {
      throw new Error("At least one theme is required");
    }

    const randomSeed = Math.random().toString(36).substring(2, 10);

    // Build theme instruction
    let themeInstruction: string;
    if (themes.length === 1) {
      themeInstruction = `for the theme: "${themes[0]}"`;
    } else {
      themeInstruction = `mixing words from these themes: ${themes.map((t) => `"${t}"`).join(", ")}`;
    }

    // Build constraint descriptions
    const letterConstraints = constraints
      .map((c) => {
        const lengths = c.preferredLengths?.length
          ? c.preferredLengths.join(", ")
          : `${c.minLength}-${c.maxLength}`;
        return `- Words containing the letter "${c.letter}" (${lengths} letters preferred)`;
      })
      .join("\n");

    const existingList =
      existingWords.length > 0
        ? `\nDO NOT include these words (already used): ${existingWords.join(", ")}`
        : "";

    const prompt = `Generate ${count} crossword puzzle words and clues ${themeInstruction}.

IMPORTANT REQUIREMENTS:
- Words must contain at least one of these letters (to allow grid intersections):
${letterConstraints}
- Each word should be ${Math.min(...constraints.map((c) => c.minLength))}-${Math.max(...constraints.map((c) => c.maxLength))} letters long
- Words should be common English words that fit the theme(s)
- Clues should be concise (under 50 characters) and suitable for a crossword puzzle
- Mix of easy and moderately challenging clues
- No proper nouns unless they're very well-known
- IMPORTANT: Prioritize words with common letters (E, A, R, S, T, N, O, I, L) that appear in multiple positions${existingList}
- Random seed for variety: ${randomSeed}

Return ONLY a valid JSON array with no markdown formatting:
[{"word": "EXAMPLE", "clue": "A sample or specimen"}]

Generate ${count} unique word/clue pairs:`;

    try {
      const response = await this.client.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      });

      const textContent = response.content.find(
        (block) => block.type === "text",
      );
      if (!textContent || textContent.type !== "text") {
        throw new Error("No text content in AI response");
      }

      const jsonText = textContent.text.trim();
      const words: CrosswordWord[] = JSON.parse(jsonText);

      const minLen = Math.min(...constraints.map((c) => c.minLength));
      const maxLen = Math.max(...constraints.map((c) => c.maxLength));

      // Filter and clean
      const validWords = words
        .filter(
          (w) =>
            w.word &&
            w.clue &&
            w.word.length >= minLen &&
            w.word.length <= maxLen &&
            !existingWords.includes(w.word.toUpperCase()),
        )
        .map((w) => ({
          word: w.word.toUpperCase().replace(/[^A-Z]/g, ""),
          clue: w.clue.trim(),
        }));

      return this.shuffleArray(validWords);
    } catch (error) {
      this.logger.error(
        "Failed to generate crossword words with constraints",
        error,
      );
      throw new Error(`AI generation failed: ${error.message}`);
    }
  }

  /**
   * Build a complete crossword grid iteratively.
   * Generates words, places them, then generates more words that fit the gaps.
   */
  async buildCrosswordGrid(
    theme: string,
    gridSize: number,
    targetClueCount?: number,
  ): Promise<{
    words: CrosswordWord[];
    placedCount: number;
    iterations: number;
  }> {
    // Target clue count based on grid size if not specified
    const target = targetClueCount || Math.floor(gridSize * 1.5);
    const maxIterations = 5;
    const allWords: CrosswordWord[] = [];
    const placedWords: Set<string> = new Set();

    // Initial generation - more words for larger grids
    const initialCount = Math.max(15, gridSize * 2);
    const initialWords = await this.generateCrosswordWords(
      theme,
      initialCount,
      3,
      gridSize,
    );
    allWords.push(...initialWords);

    let iterations = 1;

    // Simulate placement to know what letters are available for intersection
    // This is a simplified version - the actual placement happens in the frontend
    const getAvailableLetters = (words: CrosswordWord[]): string[] => {
      const letterCounts = new Map<string, number>();
      for (const w of words) {
        for (const letter of w.word) {
          letterCounts.set(letter, (letterCounts.get(letter) || 0) + 1);
        }
      }
      // Return letters sorted by frequency (most common first)
      return Array.from(letterCounts.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10)
        .map(([letter]) => letter);
    };

    // Generate more words if we don't have enough
    while (allWords.length < target * 3 && iterations < maxIterations) {
      iterations++;

      const availableLetters = getAvailableLetters(allWords);
      const constraints = availableLetters.map((letter) => ({
        letter,
        minLength: 3,
        maxLength: gridSize,
        preferredLengths: [4, 5, 6, 7].filter((l) => l <= gridSize),
      }));

      const moreWords = await this.generateCrosswordWordsWithConstraints(
        theme,
        constraints,
        allWords.map((w) => w.word),
        15,
      );

      // Add new unique words
      for (const w of moreWords) {
        if (!allWords.some((existing) => existing.word === w.word)) {
          allWords.push(w);
        }
      }
    }

    return {
      words: allWords,
      placedCount: 0, // Actual placement happens in frontend
      iterations,
    };
  }

  isAvailable(): boolean {
    return this.client !== null;
  }
}
