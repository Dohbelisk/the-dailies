import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import {
  Puzzle,
  PuzzleDocument,
  GameType,
  PuzzleStatus,
} from "./schemas/puzzle.schema";
import {
  CreatePuzzleDto,
  UpdatePuzzleDto,
  PuzzleQueryDto,
} from "./dto/puzzle.dto";
import { ValidateService } from "./validate.service";

@Injectable()
export class PuzzlesService {
  constructor(
    @InjectModel(Puzzle.name) private puzzleModel: Model<PuzzleDocument>,
    private validateService: ValidateService,
  ) {}

  async create(createPuzzleDto: CreatePuzzleDto): Promise<Puzzle> {
    const puzzle = new this.puzzleModel({
      ...createPuzzleDto,
      date: new Date(createPuzzleDto.date),
    });
    return puzzle.save();
  }

  async findAll(query: PuzzleQueryDto): Promise<Puzzle[]> {
    const filter: any = {};

    if (query.gameType) {
      filter.gameType = query.gameType;
    }

    if (query.difficulty) {
      filter.difficulty = query.difficulty;
    }

    if (query.isActive !== undefined) {
      filter.isActive = query.isActive;
    }

    if (query.status) {
      filter.status = query.status;
    }

    if (query.startDate || query.endDate) {
      filter.date = {};
      if (query.startDate) {
        filter.date.$gte = new Date(query.startDate);
      }
      if (query.endDate) {
        filter.date.$lte = new Date(query.endDate);
      }
    }

    return this.puzzleModel.find(filter).sort({ date: -1 }).exec();
  }

  async findOne(id: string): Promise<Puzzle> {
    const puzzle = await this.puzzleModel.findById(id).exec();
    if (!puzzle) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }
    return puzzle;
  }

  async findTodaysPuzzles(): Promise<Puzzle[]> {
    // Use SAST (South African Standard Time, UTC+2) as the global reference
    // This means puzzles roll over at midnight SAST for all users worldwide
    const now = new Date();

    // Get current time in SAST (UTC+2)
    // Adding 2 hours to UTC gives us SAST
    const sastOffset = 2 * 60 * 60 * 1000; // 2 hours in milliseconds
    const sastNow = new Date(now.getTime() + sastOffset);

    // Get the SAST date (year, month, day)
    const sastYear = sastNow.getUTCFullYear();
    const sastMonth = sastNow.getUTCMonth();
    const sastDay = sastNow.getUTCDate();

    // Create today's start in SAST, then convert back to UTC for DB query
    // Midnight SAST = 22:00 UTC previous day
    const todayStartUTC = new Date(
      Date.UTC(sastYear, sastMonth, sastDay, 0, 0, 0, 0) - sastOffset,
    );
    const tomorrowStartUTC = new Date(
      todayStartUTC.getTime() + 24 * 60 * 60 * 1000,
    );

    // Filter by status='active' (new) or isActive=true (legacy)
    // This ensures compatibility during migration
    return this.puzzleModel
      .find({
        date: { $gte: todayStartUTC, $lt: tomorrowStartUTC },
        $or: [
          { status: PuzzleStatus.ACTIVE },
          { status: { $exists: false }, isActive: true },
        ],
      })
      .exec();
  }

  async findByTypeAndDate(gameType: GameType, date: string): Promise<Puzzle> {
    const targetDate = new Date(date);
    targetDate.setHours(0, 0, 0, 0);

    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);

    const puzzle = await this.puzzleModel
      .findOne({
        gameType,
        date: { $gte: targetDate, $lt: nextDay },
        $or: [
          { status: PuzzleStatus.ACTIVE },
          { status: { $exists: false }, isActive: true },
        ],
      })
      .exec();

    if (!puzzle) {
      throw new NotFoundException(`No ${gameType} puzzle found for ${date}`);
    }

    return puzzle;
  }

  async findByType(gameType: GameType): Promise<Puzzle[]> {
    return this.puzzleModel
      .find({
        gameType,
        $or: [
          { status: PuzzleStatus.ACTIVE },
          { status: { $exists: false }, isActive: true },
        ],
      })
      .sort({ date: -1 })
      .limit(30)
      .exec();
  }

  async update(id: string, updatePuzzleDto: UpdatePuzzleDto): Promise<Puzzle> {
    const updateData: any = { ...updatePuzzleDto };

    if (updatePuzzleDto.date) {
      updateData.date = new Date(updatePuzzleDto.date);
    }

    const puzzle = await this.puzzleModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .exec();

    if (!puzzle) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }

    return puzzle;
  }

  async remove(id: string): Promise<void> {
    const result = await this.puzzleModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }
  }

  async getStats(): Promise<any> {
    const stats = await this.puzzleModel.aggregate([
      {
        $group: {
          _id: "$gameType",
          count: { $sum: 1 },
          activeCount: {
            $sum: { $cond: ["$isActive", 1, 0] },
          },
        },
      },
    ]);

    const totalPuzzles = await this.puzzleModel.countDocuments();
    const todaysPuzzles = await this.findTodaysPuzzles();

    return {
      totalPuzzles,
      todaysPuzzlesCount: todaysPuzzles.length,
      byGameType: stats.reduce((acc, s) => {
        acc[s._id] = { total: s.count, active: s.activeCount };
        return acc;
      }, {}),
    };
  }

  // Bulk operations for admin
  async createMany(puzzles: CreatePuzzleDto[]): Promise<Puzzle[]> {
    const puzzleDocs = puzzles.map((p) => ({
      ...p,
      date: new Date(p.date),
      solution: p.solution || {},
    }));
    const created = await this.puzzleModel.insertMany(puzzleDocs);
    return created as Puzzle[];
  }

  async toggleActive(id: string): Promise<Puzzle> {
    const puzzle = await this.puzzleModel.findById(id);
    if (!puzzle) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }
    puzzle.isActive = !puzzle.isActive;
    return puzzle.save();
  }

  async updateStatus(id: string, status: PuzzleStatus): Promise<Puzzle> {
    const puzzle = await this.puzzleModel.findById(id);
    if (!puzzle) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }

    // Validate puzzle before activation
    if (status === PuzzleStatus.ACTIVE) {
      const validationResult = await this.validatePuzzleForActivation(puzzle);
      if (!validationResult.isValid) {
        throw new BadRequestException(validationResult.error);
      }
    }

    // Update status and sync isActive for backwards compatibility
    puzzle.status = status;
    puzzle.isActive = status === PuzzleStatus.ACTIVE;
    return puzzle.save();
  }

  private async validatePuzzleForActivation(
    puzzle: PuzzleDocument,
  ): Promise<{ isValid: boolean; error?: string }> {
    const puzzleData = puzzle.puzzleData as Record<string, any>;
    const solution = puzzle.solution as Record<string, any>;

    switch (puzzle.gameType) {
      case GameType.SUDOKU: {
        const result = this.validateService.validateSudoku(puzzleData.grid);
        if (!result.isValid) {
          return {
            isValid: false,
            error: `Sudoku validation failed: ${result.errors?.map((e) => e.message).join(", ")}`,
          };
        }
        if (!result.hasUniqueSolution) {
          return { isValid: false, error: "Sudoku has multiple solutions" };
        }
        return { isValid: true };
      }

      case GameType.KILLER_SUDOKU: {
        const result = this.validateService.validateKillerSudoku(
          puzzleData.cages,
        );
        if (!result.isValid) {
          return {
            isValid: false,
            error: `Killer Sudoku validation failed: ${result.errors?.map((e) => e.message).join(", ")}`,
          };
        }
        if (!result.hasUniqueSolution) {
          return {
            isValid: false,
            error: "Killer Sudoku has multiple solutions",
          };
        }
        return { isValid: true };
      }

      case GameType.CROSSWORD: {
        return this.validateCrossword(puzzleData);
      }

      case GameType.WORD_SEARCH: {
        return this.validateWordSearch(puzzleData);
      }

      case GameType.WORD_FORGE: {
        return this.validateWordForge(puzzleData, solution);
      }

      case GameType.NONOGRAM: {
        return this.validateNonogram(puzzleData, solution);
      }

      case GameType.NUMBER_TARGET: {
        return this.validateNumberTarget(puzzleData, solution);
      }

      case GameType.BALL_SORT: {
        return this.validateBallSort(puzzleData);
      }

      case GameType.PIPES: {
        return this.validatePipes(puzzleData, solution);
      }

      case GameType.LIGHTS_OUT: {
        return this.validateLightsOut(puzzleData);
      }

      case GameType.WORD_LADDER: {
        return this.validateWordLadder(puzzleData, solution);
      }

      case GameType.CONNECTIONS: {
        return this.validateConnections(puzzleData);
      }

      case GameType.MATHORA: {
        return this.validateMathora(puzzleData, solution);
      }

      default:
        return { isValid: true };
    }
  }

  // Validation methods for each game type

  private validateCrossword(puzzleData: Record<string, any>): {
    isValid: boolean;
    error?: string;
  } {
    const { grid, clues } = puzzleData;
    if (!grid || !clues || !Array.isArray(clues)) {
      return { isValid: false, error: "Crossword missing grid or clues" };
    }
    // Check all clues have answers that fit in grid
    for (const clue of clues) {
      if (!clue.answer || clue.answer.length === 0) {
        return {
          isValid: false,
          error: `Clue ${clue.number} ${clue.direction} has no answer`,
        };
      }
    }
    return { isValid: true };
  }

  private validateWordSearch(puzzleData: Record<string, any>): {
    isValid: boolean;
    error?: string;
  } {
    const { grid, words } = puzzleData;
    if (!grid || !words || !Array.isArray(words)) {
      return { isValid: false, error: "Word Search missing grid or words" };
    }
    if (words.length === 0) {
      return { isValid: false, error: "Word Search has no words" };
    }
    // Check each word exists in the grid at specified positions
    for (const wordObj of words) {
      if (!wordObj.word) {
        return { isValid: false, error: "Word Search has word with no text" };
      }
    }
    return { isValid: true };
  }

  private validateWordForge(
    puzzleData: Record<string, any>,
    solution: Record<string, any>,
  ): { isValid: boolean; error?: string } {
    const { letters, centerLetter } = puzzleData;
    if (!letters || letters.length !== 7) {
      return {
        isValid: false,
        error: "Word Forge must have exactly 7 letters",
      };
    }
    if (!centerLetter || !letters.includes(centerLetter)) {
      return {
        isValid: false,
        error: "Word Forge center letter must be one of the 7 letters",
      };
    }
    if (!solution?.allWords || solution.allWords.length === 0) {
      return { isValid: false, error: "Word Forge has no valid words" };
    }
    if (!solution?.pangrams || solution.pangrams.length === 0) {
      return { isValid: false, error: "Word Forge has no pangrams" };
    }
    return { isValid: true };
  }

  private validateNonogram(
    puzzleData: Record<string, any>,
    solution: Record<string, any>,
  ): { isValid: boolean; error?: string } {
    const { rowClues, colClues, rows, cols } = puzzleData;
    if (!rowClues || !colClues) {
      return { isValid: false, error: "Nonogram missing row or column clues" };
    }
    if (rowClues.length !== rows || colClues.length !== cols) {
      return {
        isValid: false,
        error: "Nonogram clue count doesn't match grid size",
      };
    }
    if (!solution?.grid) {
      return { isValid: false, error: "Nonogram missing solution grid" };
    }
    return { isValid: true };
  }

  private validateNumberTarget(
    puzzleData: Record<string, any>,
    solution: Record<string, any>,
  ): { isValid: boolean; error?: string } {
    const { numbers, target } = puzzleData;
    if (!numbers || numbers.length !== 4) {
      return {
        isValid: false,
        error: "Number Target must have exactly 4 numbers",
      };
    }
    if (target === undefined || target === null) {
      return { isValid: false, error: "Number Target missing target value" };
    }
    if (!solution?.expression) {
      return {
        isValid: false,
        error: "Number Target missing solution expression",
      };
    }
    return { isValid: true };
  }

  private validateBallSort(puzzleData: Record<string, any>): {
    isValid: boolean;
    error?: string;
  } {
    const { initialState } = puzzleData;
    if (!initialState || !Array.isArray(initialState)) {
      return { isValid: false, error: "Ball Sort missing initialState" };
    }
    if (initialState.length < 2) {
      return { isValid: false, error: "Ball Sort needs at least 2 tubes" };
    }
    return { isValid: true };
  }

  private validatePipes(
    puzzleData: Record<string, any>,
    solution: Record<string, any>,
  ): { isValid: boolean; error?: string } {
    const { grid } = puzzleData;
    if (!grid || !Array.isArray(grid)) {
      return { isValid: false, error: "Pipes missing grid" };
    }
    if (!solution?.grid) {
      return { isValid: false, error: "Pipes missing solution" };
    }
    return { isValid: true };
  }

  private validateLightsOut(puzzleData: Record<string, any>): {
    isValid: boolean;
    error?: string;
  } {
    const { initialState, rows, cols } = puzzleData;
    if (!initialState || !Array.isArray(initialState)) {
      return { isValid: false, error: "Lights Out missing initial state" };
    }
    if (!rows || !cols || rows < 2 || cols < 2) {
      return { isValid: false, error: "Lights Out invalid grid size" };
    }
    return { isValid: true };
  }

  private validateWordLadder(
    puzzleData: Record<string, any>,
    solution: Record<string, any>,
  ): { isValid: boolean; error?: string } {
    const { startWord, targetWord } = puzzleData;
    if (!startWord || !targetWord) {
      return {
        isValid: false,
        error: "Word Ladder missing start or target word",
      };
    }
    if (startWord.length !== targetWord.length) {
      return {
        isValid: false,
        error: "Word Ladder start and target must be same length",
      };
    }
    if (!solution?.path || solution.path.length < 2) {
      return {
        isValid: false,
        error: "Word Ladder missing valid solution path",
      };
    }
    return { isValid: true };
  }

  private validateConnections(puzzleData: Record<string, any>): {
    isValid: boolean;
    error?: string;
  } {
    const { categories } = puzzleData;
    if (!categories || categories.length !== 4) {
      return {
        isValid: false,
        error: "Connections must have exactly 4 categories",
      };
    }
    // Check each category has 4 words
    for (const cat of categories) {
      if (!cat.words || cat.words.length !== 4) {
        return {
          isValid: false,
          error: `Category "${cat.name}" must have exactly 4 words`,
        };
      }
      if (!cat.name) {
        return { isValid: false, error: "Connections category missing name" };
      }
    }
    // Check for duplicate words across categories
    const allWords = categories.flatMap((c: any) =>
      c.words.map((w: string) => w.toUpperCase()),
    );
    const uniqueWords = new Set(allWords);
    if (uniqueWords.size !== 16) {
      return {
        isValid: false,
        error: "Connections has duplicate words across categories",
      };
    }
    return { isValid: true };
  }

  private validateMathora(
    puzzleData: Record<string, any>,
    solution: Record<string, any>,
  ): { isValid: boolean; error?: string } {
    const { startValue, targetValue, maxMoves, operations } = puzzleData;
    if (startValue === undefined || targetValue === undefined) {
      return { isValid: false, error: "Mathora missing start or target value" };
    }
    if (!maxMoves || maxMoves < 1) {
      return { isValid: false, error: "Mathora missing or invalid max moves" };
    }
    if (!operations || operations.length === 0) {
      return { isValid: false, error: "Mathora missing operations" };
    }
    if (!solution?.moves || solution.moves.length === 0) {
      return { isValid: false, error: "Mathora missing solution moves" };
    }
    return { isValid: true };
  }
}
