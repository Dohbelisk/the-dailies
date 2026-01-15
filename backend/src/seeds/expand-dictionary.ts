import * as fs from "fs";
import * as path from "path";

/**
 * Expands a base word list with common English inflections
 * (plurals, past tense, present participle, etc.)
 *
 * This version is smarter about avoiding invalid inflections:
 * - Doesn't verb-inflect words ending in common noun/derived suffixes
 * - Doesn't double-inflect already inflected words
 * - Respects word endings that indicate word type
 */

// Read the base word list
const inputPath = "/Users/steedles/Downloads/20k.txt";
const rawWords = fs
  .readFileSync(inputPath, "utf-8")
  .split("\n")
  .map((w) => w.trim().toUpperCase())
  .filter((w) => w.length >= 4 && /^[A-Z]+$/.test(w));

// Filter out proper nouns (words that were originally capitalized in a way suggesting proper noun)
// Since we uppercased everything, we'll use heuristics:
// - Common name patterns
// - Single occurrence of capital at start in original (can't detect now, so skip)

// Suffixes that indicate the word is already derived/inflected (don't add -ED/-ING to these)
const nounSuffixes = [
  "TION", "SION", "MENT", "NESS", "ENCE", "ANCE", "SHIP", "HOOD",
  "WARD", "WARDS", "WISE", "LIKE", "ABLE", "IBLE", "ICAL", "IOUS",
  "EOUS", "UOUS", "LING", "ETTE", "ELLE", "WARE", "WORK", "LAND",
  "TOWN", "SIDE", "TIME", "ROOM", "BOOK", "BACK", "DOWN", "WAYS",
  "FUL", "LESS", "ISH", "OUS", "IVE", "ANT", "ENT", "URE", "AGE",
  "ONIC", "ATIC", "ETIC", "ITIC", // Adjective endings (-IC words shouldn't verb)
  "ULAR", "OLAR", "ILAR", // More adjective endings
];

// Suffixes that indicate already-inflected verb forms
const verbInflectionSuffixes = ["ED", "ING", "ER", "EST", "LY", "IES", "IED"];

// Words ending in these are likely nouns, not verbs (don't add -ED/-ING)
const likelyNounEndings = [
  "MAN", "MEN", "BOY", "GIRL", "KING", "LORD", "LAND", "WOOD",
  "BERG", "BURG", "FORD", "PORT", "TOWN", "CITY", "VIEW", "DALE",
  "VALE", "HILL", "MONT", "ROCK", "POOL", "LAKE", "PARK", "YARD",
  "WAY", "ROAD", "GATE", "DOOR", "HOUSE", "HOME", "SHOP", "STORE",
  "LIST", "BOARD", "CAST", "BALL", "GAME", "TEAM", "CLUB", "GROUP",
  "DESK", "BOOK", "BACK", "DOWN", "OVER", "WORK", "WARE", "SOFT",
  "HARD", "LIGHT", "FIRE", "WATER", "AIR", "NIGHT", "DAY", "OFF",
  "OUT", "LINE", "SIDE", "FRONT", "END", "BASE", "TOP", "HEAD",
  "BOX", "ROOM", "MATE", "MAIL", "WEAR", "PATH", "SPACE", "LION",
  "PHONE", "FILM", "TUBE", "WIRE", "TAPE", "DISK", "CHIP", "CART",
];

// Filter function to check if a word looks like it's already inflected or derived
function isLikelyDerivedOrInflected(word: string): boolean {
  // Check for verb inflection suffixes
  for (const suffix of verbInflectionSuffixes) {
    if (word.endsWith(suffix) && word.length > suffix.length + 2) {
      return true;
    }
  }
  // Check for noun suffixes
  for (const suffix of nounSuffixes) {
    if (word.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}

// Short nouns that shouldn't be verb-inflected (true nouns, not verbs)
const shortNouns = new Set([
  "PATH", "LION", "SPACE", "CHATEAU", "BUREAU", "PLATEAU", "TABLEAU",
  "PAVILION", "INBOX", "AVATAR", "ICON", "MENU", "PIXEL", "WIDGET",
  // Note: FILM, WIRE, TAPE, CHIP, etc. CAN be verbs, so keep them
]);

// Check if word should NOT get verb inflections (-ED, -ING)
function shouldSkipVerbInflections(word: string): boolean {
  // Skip specific short nouns
  if (shortNouns.has(word)) return true;

  // Skip if already inflected
  if (isLikelyDerivedOrInflected(word)) return true;

  // Skip words ending in likely noun patterns (for compound words)
  for (const ending of likelyNounEndings) {
    if (word.endsWith(ending) && word.length > ending.length) {
      return true;
    }
  }

  // Skip words ending in -ER, -OR, -AR (agent nouns, comparatives)
  if (/[AEIOUY](R|RS)$/.test(word) && word.length > 4) return true;
  if (word.endsWith("ER") || word.endsWith("OR") || word.endsWith("AR")) return true;

  // Skip words ending in -LY (adverbs)
  if (word.endsWith("LY")) return true;

  // Skip words ending in -S (likely plurals or 3rd person verbs already)
  if (word.endsWith("S") && !word.endsWith("SS")) return true;

  // Skip words ending in -A (often foreign origin nouns: PIZZA, AGENDA, etc.)
  if (word.endsWith("A")) return true;

  // Skip words ending in -Y after consonant (adjectives: HAPPY, FUNNY)
  // These get -IER/-IEST, not -ED/-ING
  const lastChar = word[word.length - 1];
  const secondLast = word[word.length - 2];
  if (lastChar === "Y" && isConsonant(secondLast)) return true;

  // Skip long words (likely compounds or derived forms)
  if (word.length > 8) return true;

  return false;
}

// Common proper nouns to exclude
const properNouns = new Set([
  // Names
  "JOHN", "JAMES", "MARY", "MICHAEL", "DAVID", "CHRIS", "STEVE", "PAUL", "PETER", "MARK",
  "ROBERT", "WILLIAM", "RICHARD", "THOMAS", "CHARLES", "DANIEL", "MATTHEW", "ANTHONY",
  "SARAH", "JENNIFER", "JESSICA", "AMANDA", "ASHLEY", "STEPHANIE", "NICOLE", "MELISSA",
  "MICHELE", "CLAUDIA", "BENEDICT", "COOPER", "PATRICK", "KEVIN", "BRIAN", "JASON",
  "TOLKIEN", "SHAKESPEARE", "DARWIN", "EINSTEIN", "NEWTON", "BLAKE", "DARREN", "ALAIN",
  "ESTES", "NATHAN", "SCOTT", "ALEX", "RYAN", "SEAN", "KYLE", "ADAM", "ERIC", "JUSTIN",
  // Tech companies/products
  "GOOGLE", "FACEBOOK", "TWITTER", "AMAZON", "MICROSOFT", "YOUTUBE", "LINKEDIN",
  "NETFLIX", "SPOTIFY", "INSTAGRAM", "TIKTOK", "SNAPCHAT", "PINTEREST", "REDDIT",
  "MATLAB", "DRUPAL", "WORDPRESS", "MYSQL", "LINUX", "UBUNTU", "DEBIAN", "APACHE",
  // Days/months
  "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY",
  "JANUARY", "FEBRUARY", "MARCH", "APRIL", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER",
  // Places
  "AMERICA", "EUROPE", "AFRICA", "ASIA", "AUSTRALIA", "CANADA", "MEXICO", "BRAZIL",
  "CHINA", "JAPAN", "INDIA", "RUSSIA", "GERMANY", "FRANCE", "ITALY", "SPAIN",
  "CALIFORNIA", "TEXAS", "FLORIDA", "YORK", "LONDON", "PARIS", "TOKYO", "BEIJING",
  "BELGIUM", "CAMBRIDGE", "ABERDEEN", "BANFF", "OXFORD", "HARVARD", "STANFORD", "PRINCETON",
  // More tech/brands
  "FINEPIX", "FORTRAN", "COBOL", "PASCAL", "FINDLAW", "HOTMAIL", "NOKIA", "MOTOROLA",
  // More names
  "WILHELM", "HEINRICH", "FRIEDRICH", "HERMANN", "WERNER", "RUDOLF", "HANS", "KARL",
  // More places
  "ARMENIA", "GEORGIA", "UKRAINE", "POLAND", "SWEDEN", "NORWAY", "FINLAND", "DENMARK",
  "AUSTRIA", "HUNGARY", "ROMANIA", "BULGARIA", "SERBIA", "CROATIA", "SLOVENIA",
  "VIETNAM", "THAILAND", "INDONESIA", "MALAYSIA", "SINGAPORE", "PHILIPPINES",
]);

// Inappropriate/vulgar words to exclude
const inappropriateWords = new Set([
  "CLIT", "CLITS", "COCK", "COCKS", "CUNT", "CUNTS", "DICK", "DICKS",
  "FUCK", "FUCKS", "FUCKED", "FUCKING", "SHIT", "SHITS", "SHITTED", "SHITTING",
  "BITCH", "BITCHES", "DAMN", "DAMNS", "DAMNED", "DAMNING", "ASSHOLE", "ASSHOLES",
  "PISS", "PISSES", "PISSED", "PISSING", "SLUT", "SLUTS", "WHORE", "WHORES",
]);

// Filter base words to remove obvious proper nouns and problematic entries
const baseWords = rawWords.filter((w) => {
  // Remove known proper nouns
  if (properNouns.has(w)) return false;

  // Remove inappropriate words
  if (inappropriateWords.has(w)) return false;

  return true;
});

console.log(`Base words (4+ letters, filtered): ${baseWords.length}`);

const allWords = new Set<string>(baseWords);

// Helper to check if word ends with a consonant
const isConsonant = (char: string) => !"AEIOU".includes(char);
const isVowel = (char: string) => "AEIOU".includes(char);

// Generate variations for each word
for (const word of baseWords) {
  const len = word.length;
  const lastChar = word[len - 1];
  const secondLast = word[len - 2];
  const lastTwo = word.slice(-2);

  // Skip very short words for some variations
  if (len < 4) continue;

  const skipVerbs = shouldSkipVerbInflections(word);

  // === PLURALS (apply to most nouns) ===
  // Skip if word already ends in S, ED, ING, or other suffixes that don't pluralize well
  const skipPlural =
    word.endsWith("S") ||
    word.endsWith("ED") ||
    word.endsWith("ING") ||
    word.endsWith("LY") ||
    word.endsWith("FUL") ||
    word.endsWith("LESS") ||
    word.endsWith("NESS") ||
    word.endsWith("MENT") ||
    word.endsWith("IER") || // Comparatives don't pluralize (HAPPIER)
    word.endsWith("IEST"); // Superlatives don't pluralize (HAPPIEST)

  if (!skipPlural) {
    // Words ending in S, X, Z, CH, SH -> add ES
    if (
      lastChar === "X" ||
      lastChar === "Z" ||
      lastTwo === "CH" ||
      lastTwo === "SH"
    ) {
      allWords.add(word + "ES");
    }
    // Words ending in consonant + Y -> would normally change Y to IES
    // BUT this creates invalid forms for adjectives (HAPPIES)
    // The base 20k list already includes common plurals like STORIES, CITIES, BABIES
    // So we skip this transformation entirely to avoid errors
    else if (lastChar === "Y" && isConsonant(secondLast)) {
      // Don't pluralize - base list has the important ones
    }
    // Words ending in F or FE - just add S (VES forms are too irregular)
    // Only a few words use -VES: LEAF, LOAF, KNIFE, WIFE, LIFE, etc.
    else if (lastChar === "F" || lastTwo === "FE") {
      allWords.add(word + "S");
    }
    // Regular plurals
    else {
      allWords.add(word + "S");
    }
  }

  // === PAST TENSE (-ED) - only for likely verbs ===
  if (!skipVerbs) {
    // Words ending in E -> just add D
    if (lastChar === "E") {
      allWords.add(word + "D");
    }
    // Words ending in consonant + Y -> change Y to IED
    else if (lastChar === "Y" && isConsonant(secondLast)) {
      allWords.add(word.slice(0, -1) + "IED");
    }
    // Words ending in single consonant after single vowel (CVC pattern) -> double consonant + ED
    else if (
      len >= 3 &&
      len <= 6 && // Only double for short words
      isConsonant(lastChar) &&
      isVowel(secondLast) &&
      isConsonant(word[len - 3]) &&
      !["W", "X", "Y"].includes(lastChar)
    ) {
      allWords.add(word + lastChar + "ED");
    }
    // Regular -ED (but not for words ending in consonant clusters)
    else if (!word.endsWith("ED")) {
      allWords.add(word + "ED");
    }
  }

  // === PRESENT PARTICIPLE (-ING) - only for likely verbs ===
  if (!skipVerbs) {
    // Words ending in E -> drop E and add ING
    if (lastChar === "E" && lastTwo !== "EE") {
      allWords.add(word.slice(0, -1) + "ING");
    }
    // Words ending in IE -> change to YING
    else if (lastTwo === "IE") {
      allWords.add(word.slice(0, -2) + "YING");
    }
    // CVC pattern -> double consonant + ING (only for short words)
    else if (
      len >= 3 &&
      len <= 6 &&
      isConsonant(lastChar) &&
      isVowel(secondLast) &&
      isConsonant(word[len - 3]) &&
      !["W", "X", "Y"].includes(lastChar)
    ) {
      allWords.add(word + lastChar + "ING");
    }
    // Regular -ING (but not for words ending in -ING already)
    else if (!word.endsWith("ING")) {
      allWords.add(word + "ING");
    }
  }

  // === COMPARATIVE/SUPERLATIVE (-ER/-EST) for short adjectives only ===
  // Only apply to words ending in consonant+Y (HAPPY -> HAPPIER)
  // Skip -ER/-EST for other forms as they create too many invalid words
  if (len <= 6 && !isLikelyDerivedOrInflected(word)) {
    if (lastChar === "Y" && isConsonant(secondLast)) {
      allWords.add(word.slice(0, -1) + "IER");
      allWords.add(word.slice(0, -1) + "IEST");
    }
    // Don't add -ER/-EST to words ending in E (CREATE->CREATER is wrong)
  }
}

// Filter to only valid-looking words (no weird combinations)
const validWords = Array.from(allWords)
  .filter((w) => w.length >= 4 && w.length <= 15)
  .filter((w) => /^[A-Z]+$/.test(w))
  .sort();

console.log(`Expanded word count: ${validWords.length}`);

// Build the new dictionary (without clues for now)
const newDictWords = validWords.map((word) => ({
  word: word,
  clue: `Define: ${word}`,
  length: word.length,
  distinctLetters: new Set(word.split("")).size,
}));

console.log(`Words in new dictionary: ${newDictWords.length}`);

// Save the new dictionary
const outputData = {
  metadata: {
    createdAt: new Date().toISOString(),
    source: "20k common words + inflections",
    wordCount: newDictWords.length,
  },
  words: newDictWords,
};

const outputPath = path.join(__dirname, "data", "dictionary-20k-expanded.json");
fs.writeFileSync(outputPath, JSON.stringify(outputData, null, 2));
console.log(`\nSaved expanded dictionary to ${outputPath}`);

// Sample some words - specifically show variations of common words
console.log("\n=== Sample variations ===");
const testWords = ["PLAY", "HELP", "WALK", "HAPPY", "RUN", "LOVE", "CREATE"];
for (const base of testWords) {
  const variations = validWords.filter(
    (w) => w === base || w.startsWith(base) || w === "UN" + base || w === "RE" + base
  );
  console.log(`${base}: ${variations.slice(0, 10).join(", ")}`);
}

// Show stats
console.log("\n=== Statistics ===");
console.log(`Base words: ${baseWords.length}`);
console.log(`Total expanded: ${validWords.length}`);
console.log(`Expansion ratio: ${(validWords.length / baseWords.length).toFixed(2)}x`);
