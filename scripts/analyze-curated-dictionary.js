#!/usr/bin/env node
/**
 * Analyze curated spelling bee dictionary for missing word variations
 */

const fs = require('fs');
const path = '/Users/steedles/Downloads/Clearables/spelling_bee_dictionary.txt';

const words = fs.readFileSync(path, 'utf-8')
  .split('\n')
  .map(w => w.trim().toUpperCase())
  .filter(w => w.length >= 4);

const wordSet = new Set(words);
console.log(`Loaded ${wordSet.size} words from curated dictionary\n`);

// Common base words to check
const commonWords = [
  'CLEAN', 'PLAY', 'WORK', 'WALK', 'TALK', 'JUMP', 'HELP', 'LOVE', 'LIKE',
  'LOOK', 'WANT', 'NEED', 'CALL', 'MOVE', 'LIVE', 'MAKE', 'TAKE', 'GIVE',
  'FIND', 'TELL', 'FEEL', 'SEEM', 'SHOW', 'HEAR', 'TURN', 'KEEP', 'READ',
  'WRITE', 'THINK', 'START', 'STOP', 'OPEN', 'CLOSE', 'CHANGE', 'LEARN',
  'TEACH', 'SPEAK', 'BREAK', 'DRINK', 'DRIVE', 'BUILD', 'SPEND', 'STAND',
  'UNDERSTAND', 'BEGIN', 'BRING', 'BUY', 'CATCH', 'CHOOSE', 'COME', 'COST',
  'CUT', 'DEAL', 'DRAW', 'EAT', 'FALL', 'FIGHT', 'FORGET', 'GET', 'GROW',
  'HANG', 'HAVE', 'HIDE', 'HIT', 'HOLD', 'HURT', 'KNOW', 'LEAD', 'LEAVE',
  'LEND', 'LET', 'LOSE', 'MEAN', 'MEET', 'PAY', 'PUT', 'RUN', 'SAY', 'SEE',
  'SELL', 'SEND', 'SET', 'SIT', 'SLEEP', 'SPEAK', 'SPEND', 'STAND', 'STEAL',
  'STICK', 'SWIM', 'TEACH', 'THROW', 'WAKE', 'WEAR', 'WIN', 'WRITE',
];

console.log('=== Checking common words for missing variations ===\n');

const allMissing = [];

for (const baseWord of commonWords) {
  const hasBase = wordSet.has(baseWord);
  if (!hasBase) continue;

  const missing = [];

  // Check -S (plural/3rd person)
  const sForm = baseWord + 'S';
  if (sForm.length >= 4 && !wordSet.has(sForm)) missing.push(sForm);

  // Check -ED (past tense) - handle spelling rules
  let edForm;
  if (baseWord.endsWith('E')) {
    edForm = baseWord + 'D';
  } else if (baseWord.endsWith('Y') && baseWord.length > 1 && !'AEIOU'.includes(baseWord[baseWord.length - 2])) {
    edForm = baseWord.slice(0, -1) + 'IED';
  } else {
    edForm = baseWord + 'ED';
  }
  if (edForm.length >= 4 && !wordSet.has(edForm)) missing.push(edForm);

  // Check -ING (present participle)
  let ingForm;
  if (baseWord.endsWith('E') && !baseWord.endsWith('EE')) {
    ingForm = baseWord.slice(0, -1) + 'ING';
  } else {
    ingForm = baseWord + 'ING';
  }
  if (ingForm.length >= 4 && !wordSet.has(ingForm)) missing.push(ingForm);

  // Check -ER (comparative/agent noun)
  let erForm;
  if (baseWord.endsWith('E')) {
    erForm = baseWord + 'R';
  } else {
    erForm = baseWord + 'ER';
  }
  if (erForm.length >= 4 && !wordSet.has(erForm)) missing.push(erForm);

  if (missing.length > 0) {
    console.log(`${baseWord}: Missing: ${missing.join(', ')}`);
    allMissing.push(...missing);
  }
}

// Also find words that exist in the dictionary that might need variations
console.log('\n=== Scanning all words for missing -ED/-ING ===\n');

let scanCount = 0;
for (const word of words) {
  if (word.length < 4 || word.length > 8) continue;

  // Skip words that are already variations
  if (word.endsWith('ED') || word.endsWith('ING') || word.endsWith('TION') ||
      word.endsWith('NESS') || word.endsWith('MENT') || word.endsWith('LY')) continue;

  // Check for missing -ING
  let ingForm;
  if (word.endsWith('E') && !word.endsWith('EE')) {
    ingForm = word.slice(0, -1) + 'ING';
  } else {
    ingForm = word + 'ING';
  }

  // Check for missing -ED
  let edForm;
  if (word.endsWith('E')) {
    edForm = word + 'D';
  } else if (word.endsWith('Y') && word.length > 1 && !'AEIOU'.includes(word[word.length - 2])) {
    edForm = word.slice(0, -1) + 'IED';
  } else {
    edForm = word + 'ED';
  }

  const needsIng = !wordSet.has(ingForm);
  const needsEd = !wordSet.has(edForm);

  // Only report if the word has -S form (suggests it's a verb)
  if (wordSet.has(word + 'S') && (needsIng || needsEd)) {
    const missing = [];
    if (needsEd) missing.push(edForm);
    if (needsIng) missing.push(ingForm);

    if (scanCount < 100) {
      console.log(`${word}: Missing: ${missing.join(', ')}`);
      allMissing.push(...missing);
    }
    scanCount++;
  }
}

if (scanCount > 100) {
  console.log(`... and ${scanCount - 100} more`);
}

// Remove duplicates
const uniqueMissing = [...new Set(allMissing)];
console.log(`\n=== Summary ===`);
console.log(`Total unique missing variations: ${uniqueMissing.length}`);
console.log(`\nFirst 50 words to add:`);
uniqueMissing.slice(0, 50).forEach(w => console.log(w));
