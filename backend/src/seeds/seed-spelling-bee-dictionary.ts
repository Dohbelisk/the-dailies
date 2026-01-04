import { NestFactory } from "@nestjs/core";
import { AppModule } from "../app.module";
import { DictionaryService } from "../dictionary/dictionary.service";
import { getConnectionToken } from "@nestjs/mongoose";
import { Connection } from "mongoose";
import * as fs from "fs";

// Path to the curated spelling bee dictionary
const DICTIONARY_PATH =
  "/Users/steedles/Downloads/Clearables/spelling_bee_dictionary.txt";

async function loadWordList(): Promise<string[]> {
  console.log("Loading word list from file...");

  const content = fs.readFileSync(DICTIONARY_PATH, "utf-8");
  const words = content
    .split("\n")
    .map((word) => word.trim().toUpperCase())
    .filter((word) => word.length >= 4 && /^[A-Z]+$/.test(word));

  console.log(`Loaded ${words.length} words (4+ letters)`);
  return words;
}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dictionaryService = app.get(DictionaryService);

  // Get MongoDB connection to clear collection
  const connection = app.get<Connection>(getConnectionToken());

  try {
    // Check current word count
    const existingCount = await dictionaryService.getWordCount();
    console.log(`Current dictionary has ${existingCount} words`);

    // Clear existing dictionary
    console.log("Clearing existing dictionary...");
    await connection.collection("dictionaries").deleteMany({});
    console.log("Dictionary cleared.");

    // Load new word list
    const words = await loadWordList();

    // Seed in batches
    const BATCH_SIZE = 1000;
    let totalAdded = 0;

    console.log(`Seeding dictionary with ${words.length} curated words...`);

    for (let i = 0; i < words.length; i += BATCH_SIZE) {
      const batch = words.slice(i, i + BATCH_SIZE);
      const added = await dictionaryService.bulkAddWords(batch);
      totalAdded += added;

      const progress = Math.min(
        100,
        Math.round(((i + batch.length) / words.length) * 100),
      );
      console.log(`Progress: ${progress}% (${totalAdded} words added)`);
    }

    const finalCount = await dictionaryService.getWordCount();
    console.log(`\n✅ Spelling Bee dictionary seeded successfully!`);
    console.log(`Total words in dictionary: ${finalCount}`);
  } catch (error) {
    console.error("Error seeding dictionary:", error);
    throw error;
  } finally {
    await app.close();
  }
}

bootstrap();
