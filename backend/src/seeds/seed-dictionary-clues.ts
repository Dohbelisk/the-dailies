import mongoose from "mongoose";
import * as fs from "fs";
import * as readline from "readline";
import * as path from "path";

const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/the-dailies";

// Dictionary Schema (must match the NestJS schema)
const dictionarySchema = new mongoose.Schema(
  {
    word: { type: String, required: true, unique: true, index: true },
    length: { type: Number, required: true, index: true },
    letters: { type: [String], index: true },
    clue: { type: String, default: "" },
  },
  { collection: "dictionary" },
);

// Create compound index
dictionarySchema.index({ length: 1, letters: 1 });

const Dictionary = mongoose.model("Dictionary", dictionarySchema);

interface WordEntry {
  word: string;
  clue: string;
  length: number;
  distinctLetters: number;
}

/**
 * Memory-efficient streaming JSON parser for the dictionary file.
 * Processes line by line instead of loading entire file into memory.
 */
async function* streamWords(
  filePath: string,
): AsyncGenerator<WordEntry, void, unknown> {
  const fileStream = fs.createReadStream(filePath, { encoding: "utf-8" });
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  let inWordsArray = false;
  let currentEntry: Partial<WordEntry> = {};
  let braceDepth = 0;

  for await (const line of rl) {
    const trimmed = line.trim();

    // Detect when we enter the "words" array
    if (trimmed.includes('"words"')) {
      inWordsArray = true;
      continue;
    }

    if (!inWordsArray) continue;

    // Track object boundaries
    if (trimmed.startsWith("{")) {
      braceDepth++;
      currentEntry = {};
    }

    // Parse word entry fields
    const wordMatch = trimmed.match(/"word":\s*"([^"]+)"/);
    if (wordMatch) currentEntry.word = wordMatch[1];

    const clueMatch = trimmed.match(/"clue":\s*"([^"]+)"/);
    if (clueMatch) currentEntry.clue = clueMatch[1];

    const lengthMatch = trimmed.match(/"length":\s*(\d+)/);
    if (lengthMatch) currentEntry.length = parseInt(lengthMatch[1], 10);

    const distinctMatch = trimmed.match(/"distinctLetters":\s*(\d+)/);
    if (distinctMatch)
      currentEntry.distinctLetters = parseInt(distinctMatch[1], 10);

    // End of object - yield if we have a complete entry
    if (trimmed.startsWith("}") || trimmed.endsWith("},") || trimmed === "}") {
      braceDepth--;
      if (
        braceDepth === 0 &&
        currentEntry.word &&
        currentEntry.length !== undefined
      ) {
        yield currentEntry as WordEntry;
        currentEntry = {};
      }
    }
  }
}

async function seedDictionary() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log("Connected to MongoDB");

    const dataPath = path.join(__dirname, "data", "dictionary-with-clues.json");
    console.log(`Streaming dictionary from ${dataPath}...`);

    // Get existing word count
    const existingCount = await Dictionary.countDocuments();
    console.log(
      `Existing dictionary entries: ${existingCount.toLocaleString()}`,
    );

    const BATCH_SIZE = 1000;
    let batch: ReturnType<typeof createBulkOp>[] = [];
    let processed = 0;
    let upserted = 0;
    let modified = 0;

    function createBulkOp(entry: WordEntry) {
      const letters = [...new Set(entry.word.toUpperCase().split(""))].sort();
      return {
        updateOne: {
          filter: { word: entry.word.toUpperCase() },
          update: {
            $set: {
              word: entry.word.toUpperCase(),
              length: entry.length,
              letters: letters,
              clue: entry.clue || "",
            },
          },
          upsert: true,
        },
      };
    }

    console.log(`Processing words in batches of ${BATCH_SIZE}...`);

    for await (const entry of streamWords(dataPath)) {
      batch.push(createBulkOp(entry));

      if (batch.length >= BATCH_SIZE) {
        const result = await Dictionary.bulkWrite(batch, { ordered: false });
        upserted += result.upsertedCount;
        modified += result.modifiedCount;
        processed += batch.length;

        console.log(
          `  Processed ${processed.toLocaleString()} words - ${result.upsertedCount} new, ${result.modifiedCount} updated`,
        );

        batch = []; // Clear batch

        // Force garbage collection hint
        if (global.gc) global.gc();
      }
    }

    // Process remaining batch
    if (batch.length > 0) {
      const result = await Dictionary.bulkWrite(batch, { ordered: false });
      upserted += result.upsertedCount;
      modified += result.modifiedCount;
      processed += batch.length;
      console.log(
        `  Processed ${processed.toLocaleString()} words - ${result.upsertedCount} new, ${result.modifiedCount} updated`,
      );
    }

    // Verify final count
    const finalCount = await Dictionary.countDocuments();

    console.log("\n========================================");
    console.log("DICTIONARY SEED COMPLETE");
    console.log("========================================");
    console.log(`Total words processed: ${processed.toLocaleString()}`);
    console.log(`New words added: ${upserted.toLocaleString()}`);
    console.log(`Words updated: ${modified.toLocaleString()}`);
    console.log(`Final dictionary size: ${finalCount.toLocaleString()}`);
    console.log("========================================");

    await mongoose.disconnect();
    console.log("\nDisconnected from MongoDB");
  } catch (error) {
    console.error("Error seeding dictionary:", error);
    process.exit(1);
  }
}

seedDictionary();
