import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DictionaryService } from '../dictionary/dictionary.service';
import * as https from 'https';

// Word list URL - using dwyl/english-words which has ~466k words
const WORD_LIST_URL = 'https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt';

async function downloadWordList(): Promise<string[]> {
  return new Promise((resolve, reject) => {
    console.log('Downloading word list...');

    https.get(WORD_LIST_URL, (response) => {
      let data = '';

      response.on('data', (chunk) => {
        data += chunk;
      });

      response.on('end', () => {
        const words = data
          .split('\n')
          .map(word => word.trim().toUpperCase())
          .filter(word => word.length >= 4 && /^[A-Z]+$/.test(word));

        console.log(`Downloaded ${words.length} words (4+ letters)`);
        resolve(words);
      });

      response.on('error', reject);
    }).on('error', reject);
  });
}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dictionaryService = app.get(DictionaryService);

  try {
    // Check current word count
    const existingCount = await dictionaryService.getWordCount();
    console.log(`Current dictionary has ${existingCount} words`);

    if (existingCount > 100000) {
      console.log('Dictionary already seeded. Skipping...');
      console.log('To force re-seed, manually clear the dictionary collection first.');
      await app.close();
      return;
    }

    // Download word list
    const words = await downloadWordList();

    // Seed in batches
    const BATCH_SIZE = 10000;
    let totalAdded = 0;

    console.log(`Seeding dictionary with ${words.length} words...`);

    for (let i = 0; i < words.length; i += BATCH_SIZE) {
      const batch = words.slice(i, i + BATCH_SIZE);
      const added = await dictionaryService.bulkAddWords(batch);
      totalAdded += added;

      const progress = Math.min(100, Math.round(((i + batch.length) / words.length) * 100));
      console.log(`Progress: ${progress}% (${totalAdded} words added)`);
    }

    const finalCount = await dictionaryService.getWordCount();
    console.log(`\n✅ Dictionary seeded successfully!`);
    console.log(`Total words in dictionary: ${finalCount}`);

  } catch (error) {
    console.error('Error seeding dictionary:', error);
    throw error;
  } finally {
    await app.close();
  }
}

bootstrap();
