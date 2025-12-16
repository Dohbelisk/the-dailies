import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { generateSudoku, generateKillerSudoku, generateCrossword, generateWordSearch } from '../utils/puzzle-generators';
import { PuzzlesService } from './puzzles.service';
import { GameType, Difficulty } from './schemas/puzzle.schema';

class GenerateSudokuDto {
  difficulty: 'easy' | 'medium' | 'hard' | 'expert';
  date: string;
  title?: string;
}

class GenerateKillerSudokuDto {
  difficulty: 'easy' | 'medium' | 'hard' | 'expert';
  date: string;
  title?: string;
}

class GenerateCrosswordDto {
  wordsWithClues: Array<{ word: string; clue: string }>;
  rows?: number;
  cols?: number;
  difficulty: 'easy' | 'medium' | 'hard' | 'expert';
  date: string;
  title?: string;
}

class GenerateWordSearchDto {
  words: string[];
  theme?: string;
  rows?: number;
  cols?: number;
  difficulty: 'easy' | 'medium' | 'hard' | 'expert';
  date: string;
  title?: string;
}

class GenerateWeekDto {
  startDate: string;
  gameTypes: string[];
}

@ApiTags('generate')
@Controller('generate')
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth()
export class GenerateController {
  constructor(private readonly puzzlesService: PuzzlesService) {}

  @Post('sudoku')
  @ApiOperation({ summary: 'Generate a new Sudoku puzzle' })
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

  @Post('killer-sudoku')
  @ApiOperation({ summary: 'Generate a new Killer Sudoku puzzle' })
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

  @Post('crossword')
  @ApiOperation({ summary: 'Generate a new Crossword puzzle' })
  async generateCrossword(@Body() dto: GenerateCrosswordDto) {
    const puzzleData = generateCrossword(
      dto.wordsWithClues,
      dto.rows || 10,
      dto.cols || 10
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

  @Post('word-search')
  @ApiOperation({ summary: 'Generate a new Word Search puzzle' })
  async generateWordSearch(@Body() dto: GenerateWordSearchDto) {
    const puzzleData = generateWordSearch(
      dto.words,
      dto.rows || 12,
      dto.cols || 12,
      dto.theme
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
      title: dto.title || `Word Search - ${dto.theme || 'Mixed'}`,
      isActive: true,
    });
  }

  @Post('week')
  @ApiOperation({ summary: 'Generate puzzles for an entire week' })
  async generateWeek(@Body() dto: GenerateWeekDto) {
    const startDate = new Date(dto.startDate);
    const createdPuzzles = [];
    
    const difficulties: Array<'easy' | 'medium' | 'hard' | 'expert'> = [
      'easy', 'medium', 'medium', 'hard', 'hard', 'expert', 'medium'
    ];

    const wordSearchThemes = [
      { theme: 'Technology', words: ['COMPUTER', 'INTERNET', 'SOFTWARE', 'HARDWARE', 'DATABASE', 'NETWORK', 'MOBILE', 'CLOUD'] },
      { theme: 'Animals', words: ['ELEPHANT', 'GIRAFFE', 'PENGUIN', 'DOLPHIN', 'KANGAROO', 'TIGER', 'EAGLE', 'SNAKE'] },
      { theme: 'Food', words: ['PIZZA', 'BURGER', 'SUSHI', 'PASTA', 'SALAD', 'STEAK', 'TACO', 'CURRY'] },
      { theme: 'Sports', words: ['SOCCER', 'BASKETBALL', 'TENNIS', 'SWIMMING', 'GOLF', 'BASEBALL', 'HOCKEY', 'CRICKET'] },
      { theme: 'Countries', words: ['JAPAN', 'BRAZIL', 'FRANCE', 'CANADA', 'AUSTRALIA', 'INDIA', 'MEXICO', 'ITALY'] },
      { theme: 'Music', words: ['GUITAR', 'PIANO', 'DRUMS', 'VIOLIN', 'TRUMPET', 'SAXOPHONE', 'FLUTE', 'BASS'] },
      { theme: 'Science', words: ['ATOM', 'MOLECULE', 'GRAVITY', 'ENERGY', 'ELECTRON', 'NEUTRON', 'PROTON', 'PLASMA'] },
    ];

    const crosswordData = [
      { words: [
        { word: 'FLUTTER', clue: 'Google UI toolkit for mobile apps' },
        { word: 'REACT', clue: 'Popular JavaScript library for UIs' },
        { word: 'CODE', clue: 'What programmers write' },
        { word: 'DEBUG', clue: 'Find and fix errors' },
        { word: 'API', clue: 'Application Programming Interface' },
      ]},
      { words: [
        { word: 'SCIENCE', clue: 'Study of the natural world' },
        { word: 'PHYSICS', clue: 'Study of matter and energy' },
        { word: 'ATOM', clue: 'Smallest unit of matter' },
        { word: 'CHEMISTRY', clue: 'Study of substances' },
        { word: 'BIOLOGY', clue: 'Study of life' },
      ]},
      { words: [
        { word: 'TRAVEL', clue: 'Journey to distant places' },
        { word: 'VACATION', clue: 'Holiday or time off' },
        { word: 'HOTEL', clue: 'Place to stay overnight' },
        { word: 'BEACH', clue: 'Sandy shore' },
        { word: 'TOURIST', clue: 'Person visiting places' },
      ]},
      { words: [
        { word: 'MUSIC', clue: 'Art of sound' },
        { word: 'GUITAR', clue: 'String instrument' },
        { word: 'PIANO', clue: 'Keyboard instrument' },
        { word: 'RHYTHM', clue: 'Beat or tempo' },
        { word: 'MELODY', clue: 'Tune or song' },
      ]},
      { words: [
        { word: 'NATURE', clue: 'The natural world' },
        { word: 'FOREST', clue: 'Dense woods' },
        { word: 'MOUNTAIN', clue: 'High elevation' },
        { word: 'RIVER', clue: 'Flowing water' },
        { word: 'OCEAN', clue: 'Large body of salt water' },
      ]},
      { words: [
        { word: 'SPORTS', clue: 'Physical activities' },
        { word: 'SOCCER', clue: 'Football with feet' },
        { word: 'TENNIS', clue: 'Racket sport' },
        { word: 'RUNNING', clue: 'Fast movement on foot' },
        { word: 'SWIMMING', clue: 'Moving through water' },
      ]},
      { words: [
        { word: 'FOOD', clue: 'What we eat' },
        { word: 'PIZZA', clue: 'Italian flatbread with toppings' },
        { word: 'PASTA', clue: 'Italian noodles' },
        { word: 'SALAD', clue: 'Mixed vegetables' },
        { word: 'DESSERT', clue: 'Sweet course' },
      ]},
    ];

    for (let i = 0; i < 7; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      const difficulty = difficulties[i];

      // Generate Sudoku if requested
      if (dto.gameTypes.includes('sudoku')) {
        const sudokuData = generateSudoku(difficulty);
        const sudoku = await this.puzzlesService.create({
          gameType: GameType.SUDOKU,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: sudokuData,
          targetTime: { easy: 300, medium: 600, hard: 900, expert: 1200 }[difficulty],
          title: `Daily Sudoku`,
          isActive: true,
        });
        createdPuzzles.push(sudoku);
      }

      // Generate Killer Sudoku if requested
      if (dto.gameTypes.includes('killerSudoku')) {
        const killerData = generateKillerSudoku(difficulty);
        const killerSudoku = await this.puzzlesService.create({
          gameType: GameType.KILLER_SUDOKU,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: killerData,
          targetTime: { easy: 450, medium: 900, hard: 1200, expert: 1800 }[difficulty],
          title: `Killer Sudoku`,
          isActive: true,
        });
        createdPuzzles.push(killerSudoku);
      }

      // Generate Crossword if requested
      if (dto.gameTypes.includes('crossword')) {
        const cwData = crosswordData[i % crosswordData.length];
        const crosswordPuzzle = generateCrossword(cwData.words, 10, 10);
        const crossword = await this.puzzlesService.create({
          gameType: GameType.CROSSWORD,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: crosswordPuzzle,
          targetTime: { easy: 360, medium: 600, hard: 900, expert: 1200 }[difficulty],
          title: `Daily Crossword`,
          isActive: true,
        });
        createdPuzzles.push(crossword);
      }

      // Generate Word Search if requested
      if (dto.gameTypes.includes('wordSearch')) {
        const themeData = wordSearchThemes[i % wordSearchThemes.length];
        const wsData = generateWordSearch(themeData.words, 12, 12, themeData.theme);
        const wordSearch = await this.puzzlesService.create({
          gameType: GameType.WORD_SEARCH,
          difficulty: difficulty as Difficulty,
          date: dateStr,
          puzzleData: wsData,
          targetTime: { easy: 180, medium: 300, hard: 420, expert: 600 }[difficulty],
          title: `Word Search - ${themeData.theme}`,
          isActive: true,
        });
        createdPuzzles.push(wordSearch);
      }
    }

    return {
      message: `Generated ${createdPuzzles.length} puzzles for the week`,
      puzzles: createdPuzzles,
    };
  }
}
