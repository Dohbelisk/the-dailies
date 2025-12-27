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
import { GameType, Difficulty } from "./schemas/puzzle.schema";

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
  constructor(private readonly puzzlesService: PuzzlesService) {}

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

    return this.puzzlesService.create({
      gameType: GameType.SUDOKU,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Daily Sudoku - ${dto.difficulty}`,
      isActive: true,
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

    return this.puzzlesService.create({
      gameType: GameType.KILLER_SUDOKU,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Killer Sudoku - ${dto.difficulty}`,
      isActive: true,
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

    return this.puzzlesService.create({
      gameType: GameType.CROSSWORD,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Daily Crossword - ${dto.difficulty}`,
      isActive: true,
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

    return this.puzzlesService.create({
      gameType: GameType.WORD_SEARCH,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Word Search - ${dto.theme || "Mixed"}`,
      isActive: false, // Word Search is currently removed from circulation
    });
  }

  @Post("word-forge")
  @ApiOperation({ summary: "Generate a new Word Forge puzzle" })
  async generateWordForge(@Body() dto: GenerateWordForgeDto) {
    const result = generateWordForge(dto.difficulty);

    const targetTimes = {
      easy: 300,
      medium: 480,
      hard: 600,
      expert: 900,
    };

    return this.puzzlesService.create({
      gameType: GameType.WORD_FORGE,
      difficulty: dto.difficulty as Difficulty,
      date: dto.date,
      puzzleData: result.puzzleData,
      solution: result.solution,
      targetTime: targetTimes[dto.difficulty],
      title: dto.title || `Word Forge - ${dto.difficulty}`,
      isActive: true,
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
      isActive: true,
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
      isActive: true,
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
      isActive: true,
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
      isActive: true,
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
      isActive: true,
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
      isActive: true,
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
      isActive: true,
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
      isActive: true,
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
      {
        words: [
          { word: "FLUTTER", clue: "Google UI toolkit for mobile apps" },
          { word: "REACT", clue: "Popular JavaScript library for UIs" },
          { word: "CODE", clue: "What programmers write" },
          { word: "DEBUG", clue: "Find and fix errors" },
          { word: "API", clue: "Application Programming Interface" },
        ],
      },
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
          { word: "TRAVEL", clue: "Journey to distant places" },
          { word: "VACATION", clue: "Holiday or time off" },
          { word: "HOTEL", clue: "Place to stay overnight" },
          { word: "BEACH", clue: "Sandy shore" },
          { word: "TOURIST", clue: "Person visiting places" },
        ],
      },
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
          { word: "NATURE", clue: "The natural world" },
          { word: "FOREST", clue: "Dense woods" },
          { word: "MOUNTAIN", clue: "High elevation" },
          { word: "RIVER", clue: "Flowing water" },
          { word: "OCEAN", clue: "Large body of salt water" },
        ],
      },
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
          { word: "FOOD", clue: "What we eat" },
          { word: "PIZZA", clue: "Italian flatbread with toppings" },
          { word: "PASTA", clue: "Italian noodles" },
          { word: "SALAD", clue: "Mixed vegetables" },
          { word: "DESSERT", clue: "Sweet course" },
        ],
      },
    ];

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
          puzzleData: sudokuData,
          targetTime: { easy: 300, medium: 600, hard: 900, expert: 1200 }[
            difficulty
          ],
          title: `Daily Sudoku`,
          isActive: true,
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
          puzzleData: killerData,
          targetTime: { easy: 450, medium: 900, hard: 1200, expert: 1800 }[
            difficulty
          ],
          title: `Killer Sudoku`,
          isActive: true,
        });
        createdPuzzles.push(killerSudoku);
      }

      // Generate Crossword if requested
      if (dto.gameTypes.includes("crossword")) {
        const cwData = crosswordData[i % crosswordData.length];
        const crosswordPuzzle = generateCrossword(cwData.words, 10, 10);
        const crossword = await this.puzzlesService.create({
          gameType: GameType.CROSSWORD,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: crosswordPuzzle,
          targetTime: { easy: 360, medium: 600, hard: 900, expert: 1200 }[
            difficulty
          ],
          title: `Daily Crossword`,
          isActive: true,
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
          targetTime: { easy: 180, medium: 300, hard: 420, expert: 600 }[
            difficulty
          ],
          title: `Word Search - ${themeData.theme}`,
          isActive: false, // Word Search is currently removed from circulation
        });
        createdPuzzles.push(wordSearch);
      }

      // Generate Word Forge if requested
      if (dto.gameTypes.includes("wordForge")) {
        const wfResult = generateWordForge(difficulty);
        const wordForge = await this.puzzlesService.create({
          gameType: GameType.WORD_FORGE,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: wfResult.puzzleData,
          solution: wfResult.solution,
          targetTime: { easy: 300, medium: 480, hard: 600, expert: 900 }[
            difficulty
          ],
          title: `Word Forge`,
          isActive: true,
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
          isActive: true,
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
          isActive: true,
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
          isActive: true,
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
          isActive: true,
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
          isActive: true,
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
          isActive: true,
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
          isActive: true,
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
          isActive: true,
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
