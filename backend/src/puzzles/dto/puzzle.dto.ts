import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsDateString,
  IsNumber,
  IsObject,
  IsBoolean,
  IsString,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional, PartialType } from "@nestjs/swagger";
import { GameType, Difficulty, PuzzleStatus } from "../schemas/puzzle.schema";

export class CreatePuzzleDto {
  @ApiProperty({ enum: GameType })
  @IsEnum(GameType)
  @IsNotEmpty()
  gameType: GameType;

  @ApiProperty({ enum: Difficulty })
  @IsEnum(Difficulty)
  @IsNotEmpty()
  difficulty: Difficulty;

  @ApiProperty({ description: "Date for the puzzle (YYYY-MM-DD)" })
  @IsDateString()
  @IsNotEmpty()
  date: string;

  @ApiProperty({ description: "Puzzle data object" })
  @IsObject()
  @IsNotEmpty()
  puzzleData: Record<string, any>;

  @ApiPropertyOptional({ description: "Solution data object" })
  @IsObject()
  @IsOptional()
  solution?: Record<string, any>;

  @ApiPropertyOptional({ description: "Target time in seconds" })
  @IsNumber()
  @IsOptional()
  targetTime?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  title?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional({
    enum: PuzzleStatus,
    description: "Puzzle status (pending, active, inactive)",
  })
  @IsEnum(PuzzleStatus)
  @IsOptional()
  status?: PuzzleStatus;
}

export class UpdatePuzzleDto extends PartialType(CreatePuzzleDto) {}

export class UpdatePuzzleStatusDto {
  @ApiProperty({ enum: PuzzleStatus, description: "New status for the puzzle" })
  @IsEnum(PuzzleStatus)
  @IsNotEmpty()
  status: PuzzleStatus;
}

export class PuzzleQueryDto {
  @ApiPropertyOptional({ enum: GameType })
  @IsEnum(GameType)
  @IsOptional()
  gameType?: GameType;

  @ApiPropertyOptional({ enum: Difficulty })
  @IsEnum(Difficulty)
  @IsOptional()
  difficulty?: Difficulty;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  endDate?: string;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional({ enum: PuzzleStatus })
  @IsEnum(PuzzleStatus)
  @IsOptional()
  status?: PuzzleStatus;
}

// Specific puzzle data DTOs for validation

export class SudokuPuzzleDataDto {
  @ApiProperty({ description: "9x9 grid, 0 for empty cells" })
  grid: number[][];

  @ApiProperty({ description: "9x9 solution grid" })
  solution: number[][];
}

export class KillerSudokuCageDto {
  @ApiProperty()
  sum: number;

  @ApiProperty({ description: "Array of [row, col] pairs" })
  cells: number[][];
}

export class KillerSudokuPuzzleDataDto extends SudokuPuzzleDataDto {
  @ApiProperty({ type: [KillerSudokuCageDto] })
  cages: KillerSudokuCageDto[];
}

export class CrosswordClueDto {
  @ApiProperty()
  number: number;

  @ApiProperty({ enum: ["across", "down"] })
  direction: "across" | "down";

  @ApiProperty()
  clue: string;

  @ApiProperty()
  answer: string;

  @ApiProperty()
  startRow: number;

  @ApiProperty()
  startCol: number;
}

export class CrosswordPuzzleDataDto {
  @ApiProperty()
  rows: number;

  @ApiProperty()
  cols: number;

  @ApiProperty({ description: "Grid with letters and # for black cells" })
  grid: string[][];

  @ApiProperty({ type: [CrosswordClueDto] })
  clues: CrosswordClueDto[];
}

export class WordSearchWordDto {
  @ApiProperty()
  word: string;

  @ApiProperty()
  startRow: number;

  @ApiProperty()
  startCol: number;

  @ApiProperty()
  endRow: number;

  @ApiProperty()
  endCol: number;
}

export class WordSearchPuzzleDataDto {
  @ApiProperty()
  rows: number;

  @ApiProperty()
  cols: number;

  @ApiProperty()
  grid: string[][];

  @ApiProperty({ type: [WordSearchWordDto] })
  words: WordSearchWordDto[];

  @ApiPropertyOptional()
  theme?: string;
}

// Word Forge DTOs

export class WordForgePuzzleDataDto {
  @ApiProperty({ description: "Array of 7 uppercase letters" })
  letters: string[];

  @ApiProperty({ description: "The center letter (must be in every word)" })
  centerLetter: string;

  @ApiProperty({ description: "List of valid words that can be formed" })
  validWords: string[];

  @ApiProperty({ description: "Words that use all 7 letters" })
  pangrams: string[];
}

export class WordForgeSolutionDto {
  @ApiProperty({ description: "All valid words" })
  allWords: string[];

  @ApiProperty({ description: "Pangram words" })
  pangrams: string[];

  @ApiProperty({ description: "Maximum possible score" })
  maxScore: number;
}

// Nonogram DTOs

export class NonogramPuzzleDataDto {
  @ApiProperty()
  rows: number;

  @ApiProperty()
  cols: number;

  @ApiProperty({ description: "Row clues - array of number arrays" })
  rowClues: number[][];

  @ApiProperty({ description: "Column clues - array of number arrays" })
  colClues: number[][];
}

export class NonogramSolutionDto {
  @ApiProperty({ description: "Solution grid (1 = filled, 0 = empty)" })
  grid: number[][];
}

// Number Target DTOs

export class NumberTargetPuzzleDataDto {
  @ApiProperty({ description: "Array of 4 numbers to use" })
  numbers: number[];

  @ApiProperty({ description: "Target number to reach" })
  target: number;
}

export class NumberTargetSolutionDto {
  @ApiProperty({ description: "One valid expression that reaches target" })
  expression: string;

  @ApiPropertyOptional({ description: "Alternative valid expressions" })
  alternates?: string[];
}
