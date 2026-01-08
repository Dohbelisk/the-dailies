#!/usr/bin/env node
/**
 * Analyze dictionary for missing word variations
 * Checks for missing -ED, -ING, -S, -ER, -EST endings
 */

const fs = require('fs');
const path = require('path');

// Load dictionary
const dictPath = path.join(__dirname, '../flutter_app/assets/data/words.txt');
const words = fs.readFileSync(dictPath, 'utf-8')
  .split('\n')
  .map(w => w.trim().toUpperCase())
  .filter(w => w.length >= 4);

const wordSet = new Set(words);
console.log(`Loaded ${wordSet.size} words from dictionary\n`);

// Common suffixes to check
const variations = [
  { suffix: 'S', description: 'plural/verb' },
  { suffix: 'ED', description: 'past tense' },
  { suffix: 'ING', description: 'present participle' },
  { suffix: 'ER', description: 'comparative/noun' },
  { suffix: 'EST', description: 'superlative' },
  { suffix: 'LY', description: 'adverb' },
];

// Words to specifically check (common base words)
const commonWords = [
  'CLEAN', 'PLAY', 'WORK', 'WALK', 'TALK', 'JUMP', 'HELP', 'LOVE', 'LIKE',
  'LOOK', 'WANT', 'NEED', 'CALL', 'MOVE', 'LIVE', 'MAKE', 'TAKE', 'GIVE',
  'FIND', 'TELL', 'FEEL', 'SEEM', 'SHOW', 'HEAR', 'TURN', 'KEEP', 'READ',
  'WRITE', 'THINK', 'START', 'STOP', 'OPEN', 'CLOSE', 'CHANGE', 'LEARN',
];

console.log('=== Checking specific common words ===\n');

for (const baseWord of commonWords) {
  const hasBase = wordSet.has(baseWord);
  const missing = [];

  for (const { suffix } of variations) {
    let variantWord;

    // Handle spelling rules
    if (suffix === 'S') {
      variantWord = baseWord + 'S';
    } else if (suffix === 'ED') {
      if (baseWord.endsWith('E')) {
        variantWord = baseWord + 'D';
      } else {
        variantWord = baseWord + 'ED';
      }
    } else if (suffix === 'ING') {
      if (baseWord.endsWith('E')) {
        variantWord = baseWord.slice(0, -1) + 'ING';
      } else {
        variantWord = baseWord + 'ING';
      }
    } else if (suffix === 'ER') {
      if (baseWord.endsWith('E')) {
        variantWord = baseWord + 'R';
      } else {
        variantWord = baseWord + 'ER';
      }
    } else if (suffix === 'EST') {
      if (baseWord.endsWith('E')) {
        variantWord = baseWord + 'ST';
      } else {
        variantWord = baseWord + 'EST';
      }
    } else {
      variantWord = baseWord + suffix;
    }

    if (!wordSet.has(variantWord)) {
      missing.push(variantWord);
    }
  }

  if (missing.length > 0) {
    console.log(`${baseWord} (${hasBase ? '✓' : '✗'}): Missing: ${missing.join(', ')}`);
  }
}

console.log('\n=== Finding base words missing common variations ===\n');

// Find words that have the base but missing variations
const missingVariations = [];
let count = 0;

for (const word of words) {
  if (word.length < 4 || word.length > 8) continue; // Focus on reasonable length words

  // Skip words that are already variations
  if (word.endsWith('ED') || word.endsWith('ING') || word.endsWith('ER') ||
      word.endsWith('EST') || word.endsWith('LY')) continue;

  // Check for missing -ED and -ING (most important for verbs)
  const hasS = wordSet.has(word + 'S');
  const needsED = !wordSet.has(word + 'ED') && !wordSet.has(word + 'D');
  const needsING = !wordSet.has(word + 'ING') && !wordSet.has(word.slice(0, -1) + 'ING');

  // Only report if it has plural (suggesting it's a verb) but missing tenses
  if (hasS && (needsED || needsING)) {
    missingVariations.push({ word, needsED, needsING });
    count++;
    if (count >= 50) break; // Limit output
  }
}

for (const { word, needsED, needsING } of missingVariations) {
  const missing = [];
  if (needsED) missing.push(word.endsWith('E') ? word + 'D' : word + 'ED');
  if (needsING) missing.push(word.endsWith('E') ? word.slice(0, -1) + 'ING' : word + 'ING');
  console.log(`${word}: Suggest adding: ${missing.join(', ')}`);
}

console.log(`\n... (showing first 50 of potential missing variations)`);
console.log(`\nTotal words in dictionary: ${wordSet.size}`);
