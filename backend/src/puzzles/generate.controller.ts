import { Controller, Post, Body, UseGuards } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import {
  IsString,
  IsOptional,
  IsArray,
  IsNumber,
  ValidateNested,
  IsIn,
} from "class-validator";
import { Type } from "class-transformer";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { AdminGuard } from "../auth/guards/admin.guard";
import {
  generateSudoku,
  generateKillerSudoku,
  generateCrossword,
  generateWordSearch,
  generateWordForge,
  generateNonogram,
  generateNumberTarget,
  generateBallSort,
  generatePipes,
  generateLightsOut,
  generateWordLadder,
  generateConnections,
  generateMathora,
} from "../utils/puzzle-generators";
import { PuzzlesService } from "./puzzles.service";
import { GameType, Difficulty, PuzzleStatus } from "./schemas/puzzle.schema";
import { DictionaryService } from "../dictionary/dictionary.service";

class GenerateSudokuDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateKillerSudokuDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class WordClueDto {
  @IsString()
  word: string;

  @IsString()
  clue: string;
}

class GenerateCrosswordDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => WordClueDto)
  wordsWithClues: WordClueDto[];

  @IsOptional()
  @IsNumber()
  rows?: number;

  @IsOptional()
  @IsNumber()
  cols?: number;

  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateWordSearchDto {
  @IsArray()
  @IsString({ each: true })
  words: string[];

  @IsOptional()
  @IsString()
  theme?: string;

  @IsOptional()
  @IsNumber()
  rows?: number;

  @IsOptional()
  @IsNumber()
  cols?: number;

  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateWeekDto {
  @IsString()
  startDate: string;

  @IsArray()
  @IsString({ each: true })
  gameTypes: string[];
}

class GenerateWordForgeDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateNonogramDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateNumberTargetDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsNumber()
  target?: number;
}

class GenerateBallSortDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GeneratePipesDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateLightsOutDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateWordLadderDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateConnectionsDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

class GenerateMathoraDto {
  @IsIn(["easy", "medium", "hard", "expert"])
  difficulty: "easy" | "medium" | "hard" | "expert";

  @IsString()
  date: string;

  @IsOptional()
  @IsString()
  title?: string;
}

@ApiTags("generate")
@Controller("generate")
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth()
export class GenerateController {
  constructor(
    private readonly puzzlesService: PuzzlesService,
    private readonly dictionaryService: DictionaryService,
  ) {}

  @Post("sudoku")
  @ApiOperation({ summary: "Generate a new Sudoku puzzle" })
  async generateSudoku(@Body() dto: GenerateSudokuDto) {
    const puzzleData = generateSudoku(dto.difficulty);

    const targetTimes = {
      easy: 300,
      medium: 600,
      hard: 900,
      expert: 1200,
    };

    // Extract solution from puzzleData
    const solution = { grid: puzzleData.solution };

    return this.puzzlesService.create({
      gameType: GameType.SUDOKU,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: { grid: puzzleData.grid },
      solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Daily Sudoku - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("killer-sudoku")
  @ApiOperation({ summary: "Generate a new Killer Sudoku puzzle" })
  async generateKillerSudoku(@Body() dto: GenerateKillerSudokuDto) {
    const puzzleData = generateKillerSudoku(dto.difficulty);

    const targetTimes = {
      easy: 450,
      medium: 900,
      hard: 1200,
      expert: 1800,
    };

    // Extract solution from puzzleData
    const solution = { grid: puzzleData.solution };

    return this.puzzlesService.create({
      gameType: GameType.KILLER_SUDOKU,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: { grid: puzzleData.grid, cages: puzzleData.cages },
      solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Killer Sudoku - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("crossword")
  @ApiOperation({ summary: "Generate a new Crossword puzzle" })
  async generateCrossword(@Body() dto: GenerateCrosswordDto) {
    const puzzleData = generateCrossword(
      dto.wordsWithClues,
      dto.rows || 10,
      dto.cols || 10,
    );

    const targetTimes = {
      easy: 360,
      medium: 600,
      hard: 900,
      expert: 1200,
    };

    // For crossword, the grid contains the solution (letters)
    // Extract answers from clues for the solution object
    const solution = {
      grid: puzzleData.grid,
      answers: puzzleData.clues.map((c: any) => ({
        number: c.number,
        direction: c.direction,
        answer: c.answer,
      })),
    };

    return this.puzzlesService.create({
      gameType: GameType.CROSSWORD,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData,
      solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Daily Crossword - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("word-search")
  @ApiOperation({ summary: "Generate a new Word Search puzzle" })
  async generateWordSearch(@Body() dto: GenerateWordSearchDto) {
    const puzzleData = generateWordSearch(
      dto.words,
      dto.rows || 12,
      dto.cols || 12,
      dto.theme,
    );

    const targetTimes = {
      easy: 180,
      medium: 300,
      hard: 420,
      expert: 600,
    };

    // For word search, words array contains word positions (the solution)
    const solution = {
      words: puzzleData.words,
    };

    return this.puzzlesService.create({
      gameType: GameType.WORD_SEARCH,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData,
      solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Word Search - ${dto.theme || "Mixed"}`,
      status: PuzzleStatus.INACTIVE, // Word Search is currently removed from circulation
    });
  }

  @Post("word-forge")
  @ApiOperation({ summary: "Generate a new Word Forge puzzle" })
  async generateWordForge(@Body() dto: GenerateWordForgeDto) {
    const maxWordCount = 75;
    const maxAttempts = 200; // Increased to find valid configs

    // Step 1: Get all pangrams from dictionary (words with exactly 7 distinct letters)
    const allPangrams = await this.dictionaryService.findAllPangrams();
    if (allPangrams.length === 0) {
      throw new Error("No pangrams found in dictionary");
    }

    let letters: string[] = [];
    let centerLetter: string = "";
    let wordsWithClues: { word: string; clue: string; isPangram: boolean }[] =
      [];
    let attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;

      // Step 2: Pick a random pangram
      const randomPangram =
        allPangrams[Math.floor(Math.random() * allPangrams.length)];

      // Step 3: Extract the 7 unique letters from the pangram
      letters = [...new Set(randomPangram.split(""))].sort();
      if (letters.length !== 7) {
        continue; // Skip if not exactly 7 letters
      }

      // Step 4: Pick a random center letter
      centerLetter = letters[Math.floor(Math.random() * letters.length)];

      // Step 5: Get all valid words for this configuration
      wordsWithClues = await this.dictionaryService.findWordsWithCluesForPuzzle(
        letters,
        centerLetter,
        4, // minimum word length
        9, // maximum word length
      );

      // Step 6: Check if word count is acceptable (max 75)
      if (
        wordsWithClues.length <= maxWordCount &&
        wordsWithClues.length >= 20
      ) {
        console.log(
          `Word Forge: Found valid config after ${attempts} attempts - ${wordsWithClues.length} words from pangram "${randomPangram}"`,
        );
        break;
      }

      // Log attempt for debugging
      if (attempts % 10 === 0) {
        console.log(
          `Word Forge attempt ${attempts}: ${wordsWithClues.length} words from "${randomPangram}" (max: ${maxWordCount})`,
        );
      }
    }

    // If we couldn't find a good config, use the last one anyway
    if (wordsWithClues.length > maxWordCount) {
      console.warn(
        `Word Forge: Using config with ${wordsWithClues.length} words after ${maxAttempts} attempts`,
      );
    }

    // Calculate max score (4-letter = 1pt, 5+ = length, pangram bonus = +7)
    let maxScore = 0;
    let pangramCount = 0;
    for (const { word, isPangram } of wordsWithClues) {
      const wordScore = word.length === 4 ? 1 : word.length;
      maxScore += wordScore + (isPangram ? 7 : 0);
      if (isPangram) pangramCount++;
    }

    const targetTimes = {
      easy: 300,
      medium: 480,
      hard: 600,
      expert: 900,
    };

    // Shuffle letters for display (center letter will be highlighted separately)
    const shuffledLetters = [...letters].sort(() => Math.random() - 0.5);

    // New puzzle structure with words and clues
    const puzzleData = {
      letters: shuffledLetters,
      centerLetter,
      words: wordsWithClues, // Array of {word, clue, isPangram}
    };

    const solution = {
      maxScore,
      pangramCount,
      totalWords: wordsWithClues.length,
    };

    return this.puzzlesService.create({
      gameType: GameType.WORD_FORGE,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData,
      solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Word Forge - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("nonogram")
  @ApiOperation({ summary: "Generate a new Nonogram puzzle" })
  async generateNonogram(@Body() dto: GenerateNonogramDto) {
    const result = generateNonogram(dto.difficulty);

    const targetTimes = {
      easy: 180,
      medium: 360,
      hard: 600,
      expert: 900,
    };

    return this.puzzlesService.create({
      gameType: GameType.NONOGRAM,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Nonogram - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("number-target")
  @ApiOperation({ summary: "Generate a new Number Target puzzle" })
  async generateNumberTarget(@Body() dto: GenerateNumberTargetDto) {
    const result = generateNumberTarget(dto.difficulty);

    const targetTimes = {
      easy: 60,
      medium: 120,
      hard: 180,
      expert: 300,
    };

    return this.puzzlesService.create({
      gameType: GameType.NUMBER_TARGET,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Number Target - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("ball-sort")
  @ApiOperation({ summary: "Generate a new Ball Sort puzzle" })
  async generateBallSort(@Body() dto: GenerateBallSortDto) {
    const result = generateBallSort(dto.difficulty);

    const targetTimes = {
      easy: 120,
      medium: 180,
      hard: 300,
      expert: 420,
    };

    return this.puzzlesService.create({
      gameType: GameType.BALL_SORT,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Ball Sort - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("pipes")
  @ApiOperation({ summary: "Generate a new Pipes puzzle" })
  async generatePipes(@Body() dto: GeneratePipesDto) {
    const result = generatePipes(dto.difficulty);

    const targetTimes = {
      easy: 60,
      medium: 120,
      hard: 180,
      expert: 300,
    };

    return this.puzzlesService.create({
      gameType: GameType.PIPES,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Pipes - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("lights-out")
  @ApiOperation({ summary: "Generate a new Lights Out puzzle" })
  async generateLightsOut(@Body() dto: GenerateLightsOutDto) {
    const result = generateLightsOut(dto.difficulty);

    const targetTimes = {
      easy: 30,
      medium: 60,
      hard: 120,
      expert: 180,
    };

    return this.puzzlesService.create({
      gameType: GameType.LIGHTS_OUT,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Lights Out - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("word-ladder")
  @ApiOperation({ summary: "Generate a new Word Ladder puzzle" })
  async generateWordLadder(@Body() dto: GenerateWordLadderDto) {
    const result = generateWordLadder(dto.difficulty);

    const targetTimes = {
      easy: 60,
      medium: 120,
      hard: 180,
      expert: 300,
    };

    return this.puzzlesService.create({
      gameType: GameType.WORD_LADDER,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Word Ladder - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("connections")
  @ApiOperation({ summary: "Generate a new Connections puzzle" })
  async generateConnections(@Body() dto: GenerateConnectionsDto) {
    const result = generateConnections(dto.difficulty);

    const targetTimes = {
      easy: 120,
      medium: 180,
      hard: 300,
      expert: 420,
    };

    return this.puzzlesService.create({
      gameType: GameType.CONNECTIONS,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Connections - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("mathora")
  @ApiOperation({ summary: "Generate a new Mathora puzzle" })
  async generateMathora(@Body() dto: GenerateMathoraDto) {
    const result = generateMathora(dto.difficulty);

    const targetTimes = {
      easy: 60,
      medium: 90,
      hard: 120,
      expert: 180,
    };

    return this.puzzlesService.create({
      gameType: GameType.MATHORA,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Mathora - ${dto.difficulty}`,
      status: PuzzleStatus.PENDING,
    });
  }

  @Post("week")
  @ApiOperation({ summary: "Generate puzzles for an entire week" })
  async generateWeek(@Body() dto: GenerateWeekDto) {
    const startDate = new Date(dto.startDate);
    const createdPuzzles = [];

    const difficulties: Array<"easy" | "medium" | "hard" | "expert"> = [
      "easy",
      "medium",
      "medium",
      "hard",
      "hard",
      "expert",
      "medium",
    ];

    const wordSearchThemes = [
      {
        theme: "Technology",
        words: [
          "COMPUTER",
          "INTERNET",
          "SOFTWARE",
          "HARDWARE",
          "DATABASE",
          "NETWORK",
          "MOBILE",
          "CLOUD",
        ],
      },
      {
        theme: "Animals",
        words: [
          "ELEPHANT",
          "GIRAFFE",
          "PENGUIN",
          "DOLPHIN",
          "KANGAROO",
          "TIGER",
          "EAGLE",
          "SNAKE",
        ],
      },
      {
        theme: "Food",
        words: [
          "PIZZA",
          "BURGER",
          "SUSHI",
          "PASTA",
          "SALAD",
          "STEAK",
          "TACO",
          "CURRY",
        ],
      },
      {
        theme: "Sports",
        words: [
          "SOCCER",
          "BASKETBALL",
          "TENNIS",
          "SWIMMING",
          "GOLF",
          "BASEBALL",
          "HOCKEY",
          "CRICKET",
        ],
      },
      {
        theme: "Countries",
        words: [
          "JAPAN",
          "BRAZIL",
          "FRANCE",
          "CANADA",
          "AUSTRALIA",
          "INDIA",
          "MEXICO",
          "ITALY",
        ],
      },
      {
        theme: "Music",
        words: [
          "GUITAR",
          "PIANO",
          "DRUMS",
          "VIOLIN",
          "TRUMPET",
          "SAXOPHONE",
          "FLUTE",
          "BASS",
        ],
      },
      {
        theme: "Science",
        words: [
          "ATOM",
          "MOLECULE",
          "GRAVITY",
          "ENERGY",
          "ELECTRON",
          "NEUTRON",
          "PROTON",
          "PLASMA",
        ],
      },
    ];

    const crosswordData = [
      // Technology
      {
        words: [
          { word: "FLUTTER", clue: "Google UI toolkit for mobile apps" },
          { word: "REACT", clue: "Popular JavaScript library for UIs" },
          { word: "CODE", clue: "What programmers write" },
          { word: "DEBUG", clue: "Find and fix errors" },
          { word: "API", clue: "Application Programming Interface" },
          { word: "SERVER", clue: "Computer that serves data" },
        ],
      },
      {
        words: [
          { word: "DATABASE", clue: "Organized collection of data" },
          { word: "QUERY", clue: "Database request" },
          { word: "TABLE", clue: "Database structure" },
          { word: "INDEX", clue: "Speeds up searches" },
          { word: "CACHE", clue: "Temporary storage" },
        ],
      },
      {
        words: [
          { word: "PYTHON", clue: "Snake or programming language" },
          { word: "JAVA", clue: "Island or programming language" },
          { word: "SWIFT", clue: "Apple programming language" },
          { word: "RUST", clue: "Systems programming language" },
          { word: "RUBY", clue: "Gem or programming language" },
        ],
      },
      // Science
      {
        words: [
          { word: "SCIENCE", clue: "Study of the natural world" },
          { word: "PHYSICS", clue: "Study of matter and energy" },
          { word: "ATOM", clue: "Smallest unit of matter" },
          { word: "CHEMISTRY", clue: "Study of substances" },
          { word: "BIOLOGY", clue: "Study of life" },
        ],
      },
      {
        words: [
          { word: "GRAVITY", clue: "Force that pulls things down" },
          { word: "ORBIT", clue: "Path around a planet" },
          { word: "PLANET", clue: "Celestial body" },
          { word: "STAR", clue: "Burning ball of gas" },
          { word: "MOON", clue: "Natural satellite" },
          { word: "COMET", clue: "Icy space traveler" },
        ],
      },
      {
        words: [
          { word: "EVOLUTION", clue: "Change over generations" },
          { word: "SPECIES", clue: "Group of similar organisms" },
          { word: "GENE", clue: "Unit of heredity" },
          { word: "CELL", clue: "Basic unit of life" },
          { word: "DNA", clue: "Genetic code carrier" },
        ],
      },
      // Travel & Geography
      {
        words: [
          { word: "TRAVEL", clue: "Journey to distant places" },
          { word: "VACATION", clue: "Holiday or time off" },
          { word: "HOTEL", clue: "Place to stay overnight" },
          { word: "BEACH", clue: "Sandy shore" },
          { word: "TOURIST", clue: "Person visiting places" },
        ],
      },
      {
        words: [
          { word: "AIRPORT", clue: "Planes take off here" },
          { word: "FLIGHT", clue: "Air travel" },
          { word: "PASSPORT", clue: "Travel document" },
          { word: "LUGGAGE", clue: "Travel bags" },
          { word: "TICKET", clue: "Proof of booking" },
        ],
      },
      {
        words: [
          { word: "CONTINENT", clue: "Large landmass" },
          { word: "ISLAND", clue: "Land surrounded by water" },
          { word: "DESERT", clue: "Dry sandy region" },
          { word: "JUNGLE", clue: "Dense tropical forest" },
          { word: "GLACIER", clue: "Slow moving ice" },
        ],
      },
      // Music
      {
        words: [
          { word: "MUSIC", clue: "Art of sound" },
          { word: "GUITAR", clue: "String instrument" },
          { word: "PIANO", clue: "Keyboard instrument" },
          { word: "RHYTHM", clue: "Beat or tempo" },
          { word: "MELODY", clue: "Tune or song" },
        ],
      },
      {
        words: [
          { word: "CONCERT", clue: "Live music performance" },
          { word: "ORCHESTRA", clue: "Large musical group" },
          { word: "CONDUCTOR", clue: "Leads the musicians" },
          { word: "SYMPHONY", clue: "Long orchestral piece" },
          { word: "VIOLIN", clue: "Stringed instrument with bow" },
        ],
      },
      {
        words: [
          { word: "JAZZ", clue: "Improvisational music genre" },
          { word: "BLUES", clue: "Sad music genre" },
          { word: "ROCK", clue: "Loud guitar music" },
          { word: "DRUM", clue: "Percussion instrument" },
          { word: "BASS", clue: "Low frequency instrument" },
          { word: "TEMPO", clue: "Speed of music" },
        ],
      },
      // Nature
      {
        words: [
          { word: "NATURE", clue: "The natural world" },
          { word: "FOREST", clue: "Dense woods" },
          { word: "MOUNTAIN", clue: "High elevation" },
          { word: "RIVER", clue: "Flowing water" },
          { word: "OCEAN", clue: "Large body of salt water" },
        ],
      },
      {
        words: [
          { word: "WILDLIFE", clue: "Animals in nature" },
          { word: "EAGLE", clue: "Bird of prey" },
          { word: "WOLF", clue: "Pack animal" },
          { word: "BEAR", clue: "Large furry mammal" },
          { word: "DEER", clue: "Animal with antlers" },
          { word: "FOX", clue: "Clever canine" },
        ],
      },
      {
        words: [
          { word: "GARDEN", clue: "Cultivated outdoor space" },
          { word: "FLOWER", clue: "Blooming plant" },
          { word: "TREE", clue: "Tall woody plant" },
          { word: "SEED", clue: "Plant embryo" },
          { word: "SOIL", clue: "Earth for planting" },
          { word: "ROOT", clue: "Underground plant part" },
        ],
      },
      // Sports
      {
        words: [
          { word: "SPORTS", clue: "Physical activities" },
          { word: "SOCCER", clue: "Football with feet" },
          { word: "TENNIS", clue: "Racket sport" },
          { word: "RUNNING", clue: "Fast movement on foot" },
          { word: "SWIMMING", clue: "Moving through water" },
        ],
      },
      {
        words: [
          { word: "BASKETBALL", clue: "Hoop sport" },
          { word: "COURT", clue: "Playing surface" },
          { word: "SCORE", clue: "Points earned" },
          { word: "TEAM", clue: "Group of players" },
          { word: "COACH", clue: "Team leader" },
        ],
      },
      {
        words: [
          { word: "OLYMPICS", clue: "International sports event" },
          { word: "MEDAL", clue: "Prize for winners" },
          { word: "GOLD", clue: "First place color" },
          { word: "ATHLETE", clue: "Sports competitor" },
          { word: "STADIUM", clue: "Sports venue" },
        ],
      },
      // Food & Cooking
      {
        words: [
          { word: "FOOD", clue: "What we eat" },
          { word: "PIZZA", clue: "Italian flatbread with toppings" },
          { word: "PASTA", clue: "Italian noodles" },
          { word: "SALAD", clue: "Mixed vegetables" },
          { word: "DESSERT", clue: "Sweet course" },
        ],
      },
      {
        words: [
          { word: "KITCHEN", clue: "Room for cooking" },
          { word: "RECIPE", clue: "Cooking instructions" },
          { word: "CHEF", clue: "Professional cook" },
          { word: "OVEN", clue: "Baking appliance" },
          { word: "STOVE", clue: "Cooking surface" },
          { word: "PAN", clue: "Cooking vessel" },
        ],
      },
      {
        words: [
          { word: "BREAKFAST", clue: "Morning meal" },
          { word: "LUNCH", clue: "Midday meal" },
          { word: "DINNER", clue: "Evening meal" },
          { word: "SNACK", clue: "Small bite to eat" },
          { word: "BRUNCH", clue: "Late morning meal" },
        ],
      },
      // Arts & Literature
      {
        words: [
          { word: "PAINTING", clue: "Artwork on canvas" },
          { word: "ARTIST", clue: "Creator of art" },
          { word: "BRUSH", clue: "Painting tool" },
          { word: "CANVAS", clue: "Painting surface" },
          { word: "GALLERY", clue: "Art display space" },
        ],
      },
      {
        words: [
          { word: "NOVEL", clue: "Long fictional book" },
          { word: "AUTHOR", clue: "Book writer" },
          { word: "CHAPTER", clue: "Book section" },
          { word: "PLOT", clue: "Story events" },
          { word: "CHARACTER", clue: "Story person" },
        ],
      },
      {
        words: [
          { word: "THEATER", clue: "Stage performance venue" },
          { word: "ACTOR", clue: "Stage performer" },
          { word: "SCRIPT", clue: "Play text" },
          { word: "DRAMA", clue: "Serious play" },
          { word: "COMEDY", clue: "Funny play" },
          { word: "SCENE", clue: "Part of a play" },
        ],
      },
      // Weather & Seasons
      {
        words: [
          { word: "WEATHER", clue: "Atmospheric conditions" },
          { word: "STORM", clue: "Violent weather" },
          { word: "THUNDER", clue: "Sound after lightning" },
          { word: "RAIN", clue: "Water from clouds" },
          { word: "CLOUD", clue: "Floating water vapor" },
        ],
      },
      {
        words: [
          { word: "SUMMER", clue: "Warm season" },
          { word: "WINTER", clue: "Cold season" },
          { word: "SPRING", clue: "Blooming season" },
          { word: "AUTUMN", clue: "Falling leaves season" },
          { word: "SEASON", clue: "Part of the year" },
        ],
      },
      // Architecture & Buildings
      {
        words: [
          { word: "BUILDING", clue: "Structure with walls and roof" },
          { word: "ARCHITECT", clue: "Building designer" },
          { word: "TOWER", clue: "Tall structure" },
          { word: "BRIDGE", clue: "Spans over water" },
          { word: "DOME", clue: "Rounded roof" },
        ],
      },
      // Health & Medicine
      {
        words: [
          { word: "DOCTOR", clue: "Medical professional" },
          { word: "HOSPITAL", clue: "Medical facility" },
          { word: "MEDICINE", clue: "Treatment substance" },
          { word: "HEALTH", clue: "State of wellbeing" },
          { word: "NURSE", clue: "Patient caregiver" },
        ],
      },
      // History
      {
        words: [
          { word: "HISTORY", clue: "Study of the past" },
          { word: "ANCIENT", clue: "Very old" },
          { word: "EMPIRE", clue: "Large territory under one ruler" },
          { word: "KING", clue: "Male monarch" },
          { word: "QUEEN", clue: "Female monarch" },
          { word: "CASTLE", clue: "Medieval fortress" },
        ],
      },
    ];

    // Randomly select a word set for more variety
    const shuffleArray = <T>(arr: T[]): T[] => {
      const shuffled = [...arr];
      for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
      }
      return shuffled;
    };
    const shuffledCrosswordData = shuffleArray(crosswordData);

    for (let i = 0; i < 7; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split("T")[0];
      const difficulty = difficulties[i];

      // Generate Sudoku if requested
      if (dto.gameTypes.includes("sudoku")) {
        const sudokuData = generateSudoku(difficulty);
        const sudoku = await this.puzzlesService.create({
          gameType: GameType.SUDOKU,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: { grid: sudokuData.grid },
          solution: { grid: sudokuData.solution },
          targetTime: { easy: 300, medium: 600, hard: 900, expert: 1200 }[
            difficulty
          ],
          title: `Daily Sudoku`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(sudoku);
      }

      // Generate Killer Sudoku if requested
      if (dto.gameTypes.includes("killerSudoku")) {
        const killerData = generateKillerSudoku(difficulty);
        const killerSudoku = await this.puzzlesService.create({
          gameType: GameType.KILLER_SUDOKU,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: { grid: killerData.grid, cages: killerData.cages },
          solution: { grid: killerData.solution },
          targetTime: { easy: 450, medium: 900, hard: 1200, expert: 1800 }[
            difficulty
          ],
          title: `Killer Sudoku`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(killerSudoku);
      }

      // Generate Crossword if requested
      if (dto.gameTypes.includes("crossword")) {
        const cwData = shuffledCrosswordData[i % shuffledCrosswordData.length];
        const crosswordPuzzle = generateCrossword(cwData.words, 10, 10);
        const crossword = await this.puzzlesService.create({
          gameType: GameType.CROSSWORD,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: crosswordPuzzle,
          solution: {
            grid: crosswordPuzzle.grid,
            answers: crosswordPuzzle.clues.map((c: any) => ({
              number: c.number,
              direction: c.direction,
              answer: c.answer,
            })),
          },
          targetTime: { easy: 360, medium: 600, hard: 900, expert: 1200 }[
            difficulty
          ],
          title: `Daily Crossword`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(crossword);
      }

      // Generate Word Search if requested
      if (dto.gameTypes.includes("wordSearch")) {
        const themeData = wordSearchThemes[i % wordSearchThemes.length];
        const wsData = generateWordSearch(
          themeData.words,
          12,
          12,
          themeData.theme,
        );
        const wordSearch = await this.puzzlesService.create({
          gameType: GameType.WORD_SEARCH,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: wsData,
          solution: { words: wsData.words },
          targetTime: { easy: 180, medium: 300, hard: 420, expert: 600 }[
            difficulty
          ],
          title: `Word Search - ${themeData.theme}`,
          status: PuzzleStatus.INACTIVE, // Word Search is currently removed from circulation
        });
        createdPuzzles.push(wordSearch);
      }

      // Generate Word Forge if requested
      if (dto.gameTypes.includes("wordForge")) {
        // Target word counts by difficulty
        const wfTargets = {
          easy: { min: 20, max: 50 },
          medium: { min: 30, max: 70 },
          hard: { min: 40, max: 80 },
          expert: { min: 50, max: 100 },
        };
        const targets = wfTargets[difficulty];

        // Try up to 10 times to find a good letter combination
        let wfWords: { word: string; clue: string; isPangram: boolean }[] = [];
        let wfResult: ReturnType<typeof generateWordForge>;
        let wfAttempts = 0;

        while (wfAttempts < 10) {
          wfAttempts++;
          wfResult = generateWordForge(difficulty);
          wfWords = await this.dictionaryService.findWordsWithCluesForPuzzle(
            wfResult.puzzleData.letters,
            wfResult.puzzleData.centerLetter,
            4,
            9, // max 9 letters
          );
          if (wfWords.length >= targets.min && wfWords.length <= targets.max) {
            break;
          }
        }

        let maxScore = 0;
        let pangramCount = 0;
        for (const { word, isPangram } of wfWords) {
          const wordScore = word.length === 4 ? 1 : word.length;
          maxScore += wordScore + (isPangram ? 7 : 0);
          if (isPangram) pangramCount++;
        }

        const wordForge = await this.puzzlesService.create({
          gameType: GameType.WORD_FORGE,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: {
            letters: wfResult!.puzzleData.letters,
            centerLetter: wfResult!.puzzleData.centerLetter,
            words: wfWords,
          },
          solution: { maxScore, pangramCount, totalWords: wfWords.length },
          targetTime: { easy: 300, medium: 480, hard: 600, expert: 900 }[
            difficulty
          ],
          title: `Word Forge`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(wordForge);
      }

      // Generate Nonogram if requested
      if (dto.gameTypes.includes("nonogram")) {
        const ngResult = generateNonogram(difficulty);
        const nonogram = await this.puzzlesService.create({
          gameType: GameType.NONOGRAM,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: ngResult.puzzleData,
          solution: ngResult.solution,
          targetTime: { easy: 180, medium: 360, hard: 600, expert: 900 }[
            difficulty
          ],
          title: `Nonogram`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(nonogram);
      }

      // Generate Number Target if requested
      if (dto.gameTypes.includes("numberTarget")) {
        const ntResult = generateNumberTarget(difficulty);
        const numberTarget = await this.puzzlesService.create({
          gameType: GameType.NUMBER_TARGET,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: ntResult.puzzleData,
          solution: ntResult.solution,
          targetTime: { easy: 60, medium: 120, hard: 180, expert: 300 }[
            difficulty
          ],
          title: `Number Target`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(numberTarget);
      }

      // Generate Ball Sort if requested
      if (dto.gameTypes.includes("ballSort")) {
        const bsResult = generateBallSort(difficulty);
        const ballSort = await this.puzzlesService.create({
          gameType: GameType.BALL_SORT,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: bsResult.puzzleData,
          solution: bsResult.solution,
          targetTime: { easy: 120, medium: 180, hard: 300, expert: 420 }[
            difficulty
          ],
          title: `Ball Sort`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(ballSort);
      }

      // Generate Pipes if requested
      if (dto.gameTypes.includes("pipes")) {
        const pipesResult = generatePipes(difficulty);
        const pipes = await this.puzzlesService.create({
          gameType: GameType.PIPES,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: pipesResult.puzzleData,
          solution: pipesResult.solution,
          targetTime: { easy: 60, medium: 120, hard: 180, expert: 300 }[
            difficulty
          ],
          title: `Pipes`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(pipes);
      }

      // Generate Lights Out if requested
      if (dto.gameTypes.includes("lightsOut")) {
        const loResult = generateLightsOut(difficulty);
        const lightsOut = await this.puzzlesService.create({
          gameType: GameType.LIGHTS_OUT,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: loResult.puzzleData,
          solution: loResult.solution,
          targetTime: { easy: 30, medium: 60, hard: 120, expert: 180 }[
            difficulty
          ],
          title: `Lights Out`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(lightsOut);
      }

      // Generate Word Ladder if requested
      if (dto.gameTypes.includes("wordLadder")) {
        const wlResult = generateWordLadder(difficulty);
        const wordLadder = await this.puzzlesService.create({
          gameType: GameType.WORD_LADDER,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: wlResult.puzzleData,
          solution: wlResult.solution,
          targetTime: { easy: 60, medium: 120, hard: 180, expert: 300 }[
            difficulty
          ],
          title: `Word Ladder`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(wordLadder);
      }

      // Generate Connections if requested
      if (dto.gameTypes.includes("connections")) {
        const connResult = generateConnections(difficulty);
        const connections = await this.puzzlesService.create({
          gameType: GameType.CONNECTIONS,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: connResult.puzzleData,
          solution: connResult.solution,
          targetTime: { easy: 120, medium: 180, hard: 300, expert: 420 }[
            difficulty
          ],
          title: `Connections`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(connections);
      }

      // Generate Mathora if requested
      if (dto.gameTypes.includes("mathora")) {
        const mathResult = generateMathora(difficulty);
        const mathora = await this.puzzlesService.create({
          gameType: GameType.MATHORA,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: mathResult.puzzleData,
          solution: mathResult.solution,
          targetTime: { easy: 60, medium: 90, hard: 120, expert: 180 }[
            difficulty
          ],
          title: `Mathora`,
          status: PuzzleStatus.PENDING,
        });
        createdPuzzles.push(mathora);
      }
    }

    return {
      message: `Generated ${createdPuzzles.length} puzzles for the week`,
      puzzles: createdPuzzles,
    };
  }
}
