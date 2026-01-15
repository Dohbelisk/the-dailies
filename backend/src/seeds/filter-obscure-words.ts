import * as fs from "fs";
import * as https from "https";
import * as path from "path";

interface WordEntry {
  word: string;
  clue: string;
  length: number;
  distinctLetters: number;
}

interface DictionaryData {
  metadata: Record<string, any>;
  words: WordEntry[];
}

// Download a word list from URL
function downloadList(url: string): Promise<Set<string>> {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        const words = new Set(
          data
            .split("\n")
            .map((w) => w.trim().toUpperCase())
            .filter((w) => w && w.length >= 4),
        );
        resolve(words);
      });
      res.on("error", reject);
    });
  });
}

async function main() {
  console.log("Loading common words list...");
  const commonWords = await downloadList(
    "https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt",
  );
  console.log(`Loaded ${commonWords.size} common words`);

  const dataPath = path.join(__dirname, "data", "dictionary-with-clues.json");
  console.log(`Loading dictionary from ${dataPath}...`);
  const data: DictionaryData = JSON.parse(fs.readFileSync(dataPath, "utf-8"));
  console.log(`Loaded ${data.words.length} words`);

  // Patterns that indicate obscure words
  const obscurePatterns = [
    /^Q[^U]/i, // Q not followed by U (QADI, QOPH, etc.)
    /^AAL/i, // AALII, AALS
    /^AASV/i, // AASVOGEL
    /^CWM/i, // Welsh
    /^CRWTH/i, // Welsh
    /^PFENN/i, // German coins (Pfennig)
    /^VROU?W/i, // Dutch/Afrikaans
    /RRGH/i, // AARRGH, AARRGHH
    /^XANTH/i, // Chemical XANTH- prefix
    /^BAAS/i, // Afrikaans
    /^MBIRA/i, // Obscure African instrument
    /^NGUL/i, // Obscure currency
    /^UHLAN/i, // Obscure military
  ];

  // Obscure endings (taxonomic, highly technical)
  const obscureEndings = [
    /ACEAE$/i, // Plant family names
    /IDAE$/i, // Animal family names
    /INAE$/i, // Subfamily names (but protect FEMININE, etc.)
    /OIDEA$/i, // Superfamily names
  ];

  // Specific obscure words to remove
  const obscureWords = new Set([
    // Q without U
    "QABALA", "QABALAH", "QABALAHS", "QABALAS", "QADI", "QADIS", "QAID", "QAIDS",
    "QANAT", "QANATS", "QATS", "QINDAR", "QINDARKA", "QINDARS", "QINTAR", "QINTARS",
    "QIVIUT", "QIVIUTS", "QOPH", "QOPHS", "QORMA", "QORMAS", "QWERTY", "QWERTYS",
    // Obscure AA words
    "AALII", "AALIIS", "AALS", "AASVOGEL", "AASVOGELS", "AARRGH", "AARRGHH",
    // Obscure religious/cultural
    "BAAL", "BAALIM", "BAALISM", "BAALISMS", "BAALS",
    // Latin plurals that are too obscure
    "NAEVI", "NAEVUS", "NAEVOID",
    // Obscure X words
    "XEBEC", "XEBECS", "XENIA", "XENIAS",
    // Obscure Z words
    "ZABAIONE", "ZABAJONE", "ZACATON", "ZACATONS",
    "ZADDICK", "ZADDIK", "ZADDIKIM",
    "ZAFFAR", "ZAFFARS", "ZAFFER", "ZAFFERS", "ZAFFIR", "ZAFFIRS", "ZAFFRE", "ZAFFRES",
    "ZAIBATSU", "ZAKAT", "ZAKATS",
    "ZAMARRA", "ZAMARRAS", "ZAMARRO", "ZAMARROS",
    "ZAMIA", "ZAMIAS", "ZAMINDAR", "ZAMINDARI", "ZAMINDARS",
    "ZANANA", "ZANANAS", "ZANDER", "ZANDERS",
    "ZANJA", "ZANJAS", "ZANTE", "ZANTES",
    "ZANZA", "ZANZAS", "ZAPATEADO", "ZAPATEO", "ZAPATEOS",
    "ZAPTIAH", "ZAPTIAHS", "ZAPTIEH", "ZAPTIEHS",
    "ZARAPE", "ZARAPES", "ZAREBA", "ZAREBAS", "ZAREEBA", "ZAREEBAS",
    "ZARIBA", "ZARIBAS", "ZARZUELA", "ZARZUELAS",
    "ZASTRUGA", "ZASTRUGI", "ZAYIN", "ZAYINS", "ZAZEN", "ZAZENS",
    "ZEDOARY", "ZEDOARIES", "ZELKOVA", "ZELKOVAS",
    "ZENAIDA", "ZENAIDAS", "ZENANA", "ZENANAS",
    "ZEPHYR", "ZEPHYRS", // Actually somewhat common, keep these
    "ZEPPELIN", "ZEPPELINS", // Keep - common enough
    // Obscure J words
    "JNANA", "JNANAS",
    // Other obscure
    "TORII", "TORIIS",
    "SEIDEL", "SEIDELS",
    "REBBE", "REBBES",
    "SFERICS", "SFERIC",
    "CWMS", "CRWTH", "CRWTHS",
    "VROWS", "VROW", "VROUW", "VROUWS",
  ]);

  // Words to explicitly KEEP (override other rules)
  const keepWords = new Set([
    "ZEPHYR", "ZEPHYRS", "ZEPPELIN", "ZEPPELINS", "ZEALOT", "ZEALOTS",
    "ZENITH", "ZENITHS", "ZESTY", "ZESTIER", "ZESTIEST",
    "ZIGZAG", "ZIGZAGS", "ZIGZAGGED", "ZIGZAGGING",
    "ZODIAC", "ZODIACS", "ZOMBIE", "ZOMBIES",
    "FEMININE", "MASCULIN",
    "XYLOPHONE", "XYLOPHONES",
  ]);

  function shouldRemove(word: string): boolean {
    const w = word.toUpperCase();

    // Always keep if in explicit keep list
    if (keepWords.has(w)) return false;

    // Never remove if in common words list
    if (commonWords.has(w)) return false;

    // Remove specific obscure words
    if (obscureWords.has(w)) return true;

    // Remove if matches obscure patterns
    if (obscurePatterns.some((p) => p.test(w))) return true;

    // Remove if matches obscure endings (but be careful)
    if (obscureEndings.some((p) => p.test(w))) {
      // Don't remove common words ending in -INAE that aren't taxonomic
      if (w.endsWith("INAE") && (w.includes("FEMIN") || w.includes("MASCUL"))) {
        return false;
      }
      return true;
    }

    return false;
  }

  const kept = data.words.filter((w) => !shouldRemove(w.word));
  const removed = data.words.filter((w) => shouldRemove(w.word));

  console.log(`\nFiltering results:`);
  console.log(`  Original: ${data.words.length}`);
  console.log(`  Kept: ${kept.length}`);
  console.log(`  Removed: ${removed.length}`);

  // Save filtered dictionary
  const filteredData: DictionaryData = {
    metadata: {
      ...data.metadata,
      filteredAt: new Date().toISOString(),
      originalCount: data.words.length,
      filteredCount: kept.length,
      removedCount: removed.length,
    },
    words: kept,
  };

  const outputPath = path.join(__dirname, "data", "dictionary-with-clues.json");
  fs.writeFileSync(outputPath, JSON.stringify(filteredData, null, 2));
  console.log(`\nSaved filtered dictionary to ${outputPath}`);

  // Also save removed words for reference
  const removedPath = path.join(__dirname, "data", "removed-obscure-words.txt");
  fs.writeFileSync(removedPath, removed.map((w) => w.word).join("\n"));
  console.log(`Saved removed words list to ${removedPath}`);

  console.log(`\n=== Sample of removed words ===`);
  removed.slice(0, 50).forEach((w) => console.log(w.word));
}

main().catch(console.error);
