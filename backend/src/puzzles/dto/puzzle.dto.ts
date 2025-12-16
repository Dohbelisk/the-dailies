import { IsEnum, IsNotEmpty, IsOptional, IsDateString, IsNumber, IsObject, IsBoolean, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { GameType, Difficulty } from '../schemas/puzzle.schema';

export class CreatePuzzleDto {
  @ApiProperty({ enum: GameType })
  @IsEnum(GameType)
  @IsNotEmpty()
  gameType: GameType;

  @ApiProperty({ enum: Difficulty })
  @IsEnum(Difficulty)
  @IsNotEmpty()
  difficulty: Difficulty;

  @ApiProperty({ description: 'Date for the puzzle (YYYY-MM-DD)' })
  @IsDateString()
  @IsNotEmpty()
  date: string;

  @ApiProperty({ description: 'Puzzle data object' })
  @IsObject()
  @IsNotEmpty()
  puzzleData: Record<string, any>;

  @ApiPropertyOptional({ description: 'Solution data object' })
  @IsObject()
  @IsOptional()
  solution?: Record<string, any>;

  @ApiPropertyOptional({ description: 'Target time in seconds' })
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
}

export class UpdatePuzzleDto extends PartialType(CreatePuzzleDto) {}

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
}

// Specific puzzle data DTOs for validation

export class SudokuPuzzleDataDto {
  @ApiProperty({ description: '9x9 grid, 0 for empty cells' })
  grid: number[][];

  @ApiProperty({ description: '9x9 solution grid' })
  solution: number[][];
}

export class KillerSudokuCageDto {
  @ApiProperty()
  sum: number;

  @ApiProperty({ description: 'Array of [row, col] pairs' })
  cells: number[][];
}

export class KillerSudokuPuzzleDataDto extends SudokuPuzzleDataDto {
  @ApiProperty({ type: [KillerSudokuCageDto] })
  cages: KillerSudokuCageDto[];
}

export class CrosswordClueDto {
  @ApiProperty()
  number: number;

  @ApiProperty({ enum: ['across', 'down'] })
  direction: 'across' | 'down';

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

  @ApiProperty({ description: 'Grid with letters and # for black cells' })
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
