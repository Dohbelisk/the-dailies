import mongoose from "mongoose";
import * as fs from "fs";
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

interface DictionaryData {
  metadata: {
    totalWords: number;
    generatedAt: string;
  };
  words: WordEntry[];
}

async function seedDictionary() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log("Connected to MongoDB");

    // Load dictionary JSON
    const dataPath = path.join(__dirname, "data", "dictionary-with-clues.json");
    console.log(`Loading dictionary from ${dataPath}...`);

    const rawData = fs.readFileSync(dataPath, "utf-8");
    const data: DictionaryData = JSON.parse(rawData);

    console.log(`Loaded ${data.words.length.toLocaleString()} words`);

    // Get existing word count
    const existingCount = await Dictionary.countDocuments();
    console.log(
      `Existing dictionary entries: ${existingCount.toLocaleString()}`,
    );

    // Prepare bulk operations
    console.log("Preparing bulk upsert operations...");
    const bulkOps = data.words.map((entry) => {
      // Calculate sorted unique letters for the word
      const letters = [...new Set(entry.word.toUpperCase().split(""))].sort();

      return {
        updateOne: {
          filter: { word: entry.word.toUpperCase() },
          update: {
            $set: {
              word: entry.word.toUpperCase(),
              length: entry.length,
              letters: letters,
              clue: entry.clue,
            },
          },
          upsert: true,
        },
      };
    });

    // Execute in batches of 10000 for better performance
    const BATCH_SIZE = 10000;
    let processed = 0;
    let upserted = 0;
    let modified = 0;

    console.log(
      `Processing ${bulkOps.length.toLocaleString()} words in batches of ${BATCH_SIZE}...`,
    );

    for (let i = 0; i < bulkOps.length; i += BATCH_SIZE) {
      const batch = bulkOps.slice(i, i + BATCH_SIZE);
      const result = await Dictionary.bulkWrite(batch, { ordered: false });

      upserted += result.upsertedCount;
      modified += result.modifiedCount;
      processed += batch.length;

      const percent = ((processed / bulkOps.length) * 100).toFixed(1);
      console.log(
        `  Batch ${Math.floor(i / BATCH_SIZE) + 1}: ` +
          `${processed.toLocaleString()}/${bulkOps.length.toLocaleString()} (${percent}%) - ` +
          `${result.upsertedCount} new, ${result.modifiedCount} updated`,
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
