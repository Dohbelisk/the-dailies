import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { Dictionary, DictionaryDocument } from "./schemas/dictionary.schema";

@Injectable()
export class DictionaryService {
  constructor(
    @InjectModel(Dictionary.name)
    private dictionaryModel: Model<DictionaryDocument>,
  ) {}

  /**
   * Check if a word exists in the dictionary
   */
  async isValidWord(word: string): Promise<boolean> {
    const normalizedWord = word.toUpperCase().trim();
    const exists = await this.dictionaryModel.exists({ word: normalizedWord });
    return !!exists;
  }

  /**
   * Validate multiple words at once
   */
  async validateWords(
    words: string[],
  ): Promise<{ word: string; valid: boolean }[]> {
    const normalizedWords = words.map((w) => w.toUpperCase().trim());
    const validWords = await this.dictionaryModel
      .find({ word: { $in: normalizedWords } })
      .select("word")
      .lean();

    const validSet = new Set(validWords.map((w) => w.word));

    return normalizedWords.map((word) => ({
      word,
      valid: validSet.has(word),
    }));
  }

  /**
   * Find all valid words that can be made from the given letters
   * with a required center letter (for Word Forge puzzles)
   */
  async findValidWords(
    letters: string[],
    centerLetter: string,
    minLength: number = 4,
  ): Promise<string[]> {
    const normalizedLetters = letters.map((l) => l.toUpperCase());
    const normalizedCenter = centerLetter.toUpperCase();

    // Get all words that are at least minLength and contain the center letter
    const candidates = await this.dictionaryModel
      .find({
        length: { $gte: minLength },
        word: { $regex: normalizedCenter },
      })
      .select("word")
      .lean();

    // Filter to only words that can be made from the available letters
    const letterCounts = new Map<string, number>();
    for (const letter of normalizedLetters) {
      letterCounts.set(letter, (letterCounts.get(letter) || 0) + 1);
    }

    const validWords: string[] = [];

    for (const { word } of candidates) {
      if (this.canMakeWord(word, letterCounts, normalizedCenter)) {
        validWords.push(word);
      }
    }

    return validWords.sort((a, b) => b.length - a.length || a.localeCompare(b));
  }

  /**
   * Check if a word can be made from the given letters
   * Letters can be reused (Word Forge rules)
   */
  private canMakeWord(
    word: string,
    availableLetters: Map<string, number>,
    requiredLetter: string,
  ): boolean {
    // Must contain the required letter
    if (!word.includes(requiredLetter)) {
      return false;
    }

    // Each letter in the word must be in the available letters
    // (letters can be reused in Word Forge)
    for (const char of word) {
      if (!availableLetters.has(char)) {
        return false;
      }
    }

    return true;
  }

  /**
   * Check if a specific word is valid for a Word Forge puzzle
   */
  async isValidWordForPuzzle(
    word: string,
    letters: string[],
    centerLetter: string,
    minLength: number = 4,
  ): Promise<{ valid: boolean; reason?: string }> {
    const normalizedWord = word.toUpperCase().trim();
    const normalizedLetters = letters.map((l) => l.toUpperCase());
    const normalizedCenter = centerLetter.toUpperCase();

    // Check minimum length
    if (normalizedWord.length < minLength) {
      return {
        valid: false,
        reason: `Word must be at least ${minLength} letters`,
      };
    }

    // Check if word contains center letter
    if (!normalizedWord.includes(normalizedCenter)) {
      return { valid: false, reason: "Word must contain the center letter" };
    }

    // Check if all letters are available
    for (const char of normalizedWord) {
      if (!normalizedLetters.includes(char)) {
        return { valid: false, reason: `Letter "${char}" is not available` };
      }
    }

    // Check if word exists in dictionary
    const exists = await this.isValidWord(normalizedWord);
    if (!exists) {
      return { valid: false, reason: "Word not in dictionary" };
    }

    return { valid: true };
  }

  /**
   * Get word count in dictionary
   */
  async getWordCount(): Promise<number> {
    return this.dictionaryModel.countDocuments();
  }

  /**
   * Add a word to the dictionary
   */
  async addWord(word: string): Promise<Dictionary> {
    const normalizedWord = word.toUpperCase().trim();
    const letters = [...new Set(normalizedWord.split(""))].sort();

    return this.dictionaryModel.findOneAndUpdate(
      { word: normalizedWord },
      {
        word: normalizedWord,
        length: normalizedWord.length,
        letters,
      },
      { upsert: true, new: true },
    );
  }

  /**
   * Bulk add words to the dictionary
   */
  async bulkAddWords(words: string[]): Promise<number> {
    const operations = words
      .map((w) => w.toUpperCase().trim())
      .filter((w) => w.length >= 4 && /^[A-Z]+$/.test(w))
      .map((word) => ({
        updateOne: {
          filter: { word },
          update: {
            $set: {
              word,
              length: word.length,
              letters: [...new Set(word.split(""))].sort(),
            },
          },
          upsert: true,
        },
      }));

    if (operations.length === 0) return 0;

    const result = await this.dictionaryModel.bulkWrite(operations);
    return result.upsertedCount + result.modifiedCount;
  }

  // ============ Admin Methods ============

  /**
   * Find all words with pagination and filters
   */
  async findAll(params: {
    page?: number;
    limit?: number;
    search?: string;
    length?: number;
    startsWith?: string;
    hasClue?: boolean;
  }) {
    const {
      page = 1,
      limit = 50,
      search,
      length,
      startsWith,
      hasClue,
    } = params;
    const skip = (page - 1) * limit;

    // Build query
    const query: Record<string, any> = {};

    if (search) {
      query.word = { $regex: search.toUpperCase(), $options: "i" };
    }

    if (length) {
      query.length = length;
    }

    if (startsWith) {
      query.word = { ...query.word, $regex: `^${startsWith}` };
    }

    if (hasClue === true) {
      query.clue = { $ne: "", $exists: true, $not: /^Define:/ };
    } else if (hasClue === false) {
      query.$or = [
        { clue: { $exists: false } },
        { clue: "" },
        { clue: { $regex: /^Define:/ } },
      ];
    }

    const [words, total] = await Promise.all([
      this.dictionaryModel
        .find(query)
        .sort({ word: 1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      this.dictionaryModel.countDocuments(query),
    ]);

    return {
      words,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Find a single word by its value
   */
  async findByWord(word: string): Promise<Dictionary | null> {
    return this.dictionaryModel.findOne({ word: word.toUpperCase() }).lean();
  }

  /**
   * Update a word's clue
   */
  async updateClue(word: string, clue: string): Promise<Dictionary | null> {
    return this.dictionaryModel.findOneAndUpdate(
      { word: word.toUpperCase() },
      { $set: { clue } },
      { new: true },
    );
  }

  /**
   * Delete a word from the dictionary
   */
  async deleteWord(word: string): Promise<{ deleted: boolean }> {
    const result = await this.dictionaryModel.deleteOne({
      word: word.toUpperCase(),
    });
    return { deleted: result.deletedCount > 0 };
  }

  /**
   * Find all pangrams (words with exactly 7 distinct letters)
   * Used for Word Forge puzzle generation
   */
  async findAllPangrams(): Promise<string[]> {
    // Find words where the letters array has exactly 7 elements
    // (letters array contains unique sorted letters)
    const pangrams = await this.dictionaryModel
      .find({
        letters: { $size: 7 },
        length: { $gte: 7, $lte: 9 }, // Reasonable pangram length
      })
      .select("word letters")
      .lean();

    return pangrams.map((p) => p.word);
  }

  /**
   * Find all valid words with clues for a Word Forge puzzle
   * Returns words with their clues for inclusion in puzzle JSON
   */
  async findWordsWithCluesForPuzzle(
    letters: string[],
    centerLetter: string,
    minLength: number = 4,
    maxLength: number = 9,
  ): Promise<{ word: string; clue: string; isPangram: boolean }[]> {
    const normalizedLetters = letters.map((l) => l.toUpperCase());
    const normalizedCenter = centerLetter.toUpperCase();
    const letterSet = new Set(normalizedLetters);

    // Get all words that are between minLength and maxLength and contain the center letter
    const candidates = await this.dictionaryModel
      .find({
        length: { $gte: minLength, $lte: maxLength },
        word: { $regex: normalizedCenter },
      })
      .select("word clue")
      .lean();

    const validWords: { word: string; clue: string; isPangram: boolean }[] = [];

    for (const { word, clue } of candidates) {
      // Check if word can be made from available letters
      let canMake = true;

      for (const char of word) {
        if (!letterSet.has(char)) {
          canMake = false;
          break;
        }
      }

      if (canMake) {
        // Check if pangram (uses all 7 letters)
        const isPangram = normalizedLetters.every((l) => word.includes(l));

        validWords.push({
          word,
          clue: clue || `Define: ${word}`,
          isPangram,
        });
      }
    }

    // Sort: pangrams first, then by length descending, then alphabetically
    return validWords.sort((a, b) => {
      if (a.isPangram !== b.isPangram) return a.isPangram ? -1 : 1;
      if (a.word.length !== b.word.length) return b.word.length - a.word.length;
      return a.word.localeCompare(b.word);
    });
  }
}
