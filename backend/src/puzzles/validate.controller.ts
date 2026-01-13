import { Controller, Post, Body, UseGuards } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { IsArray, IsString, IsNumber, IsInt, Min, Max } from "class-validator";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { AdminGuard } from "../auth/guards/admin.guard";
import {
  ValidateService,
  SudokuValidationResult,
  SudokuSolveResult,
  KillerSudokuValidationResult,
  KillerSudokuSolveResult,
  WordLadderValidationResult,
  NumberTargetValidationResult,
  WordForgeValidationResult,
  Cage,
} from "./validate.service";

class SudokuGridDto {
  @IsArray()
  grid: number[][];
}

class KillerSudokuCagesDto {
  @IsArray()
  cages: Cage[];
}

class WordLadderDto {
  @IsString()
  startWord: string;

  @IsString()
  targetWord: string;

  @IsInt()
  @Min(3)
  @Max(5)
  wordLength: number;
}

class NumberTargetDto {
  @IsArray()
  numbers: number[];

  @IsArray()
  targets: { target: number; difficulty: string }[];
}

class WordForgeDto {
  @IsArray()
  letters: string[];

  @IsString()
  centerLetter: string;
}

@ApiTags("validate")
@Controller("validate")
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth()
export class ValidateController {
  constructor(private readonly validateService: ValidateService) {}

  @Post("sudoku")
  @ApiOperation({ summary: "Validate a Sudoku puzzle" })
  validateSudoku(@Body() dto: SudokuGridDto): SudokuValidationResult {
    return this.validateService.validateSudoku(dto.grid);
  }

  @Post("sudoku/solve")
  @ApiOperation({ summary: "Solve a Sudoku puzzle" })
  solveSudoku(@Body() dto: SudokuGridDto): SudokuSolveResult {
    return this.validateService.solveSudoku(dto.grid);
  }

  @Post("killer-sudoku")
  @ApiOperation({ summary: "Validate a Killer Sudoku puzzle" })
  validateKillerSudoku(
    @Body() dto: KillerSudokuCagesDto,
  ): KillerSudokuValidationResult {
    return this.validateService.validateKillerSudoku(dto.cages);
  }

  @Post("killer-sudoku/solve")
  @ApiOperation({ summary: "Solve a Killer Sudoku puzzle" })
  solveKillerSudoku(
    @Body() dto: KillerSudokuCagesDto,
  ): KillerSudokuSolveResult {
    return this.validateService.solveKillerSudoku(dto.cages);
  }

  @Post("word-ladder")
  @ApiOperation({ summary: "Validate a Word Ladder puzzle and find solution path" })
  validateWordLadder(
    @Body() dto: WordLadderDto,
  ): Promise<WordLadderValidationResult> {
    return this.validateService.validateWordLadder(
      dto.startWord,
      dto.targetWord,
      dto.wordLength,
    );
  }

  @Post("number-target")
  @ApiOperation({ summary: "Validate a Number Target puzzle and find solutions" })
  validateNumberTarget(
    @Body() dto: NumberTargetDto,
  ): NumberTargetValidationResult {
    return this.validateService.validateNumberTarget(dto.numbers, dto.targets);
  }

  @Post("word-forge")
  @ApiOperation({ summary: "Validate Word Forge letters and generate valid words" })
  validateWordForge(
    @Body() dto: WordForgeDto,
  ): Promise<WordForgeValidationResult> {
    return this.validateService.validateWordForge(dto.letters, dto.centerLetter);
  }
}
