import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsArray, IsNumber } from 'class-validator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import {
  ValidateService,
  SudokuValidationResult,
  SudokuSolveResult,
  KillerSudokuValidationResult,
  KillerSudokuSolveResult,
  Cage,
} from './validate.service';

class SudokuGridDto {
  @IsArray()
  grid: number[][];
}

class KillerSudokuCagesDto {
  @IsArray()
  cages: Cage[];
}

@ApiTags('validate')
@Controller('validate')
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth()
export class ValidateController {
  constructor(private readonly validateService: ValidateService) {}

  @Post('sudoku')
  @ApiOperation({ summary: 'Validate a Sudoku puzzle' })
  validateSudoku(@Body() dto: SudokuGridDto): SudokuValidationResult {
    return this.validateService.validateSudoku(dto.grid);
  }

  @Post('sudoku/solve')
  @ApiOperation({ summary: 'Solve a Sudoku puzzle' })
  solveSudoku(@Body() dto: SudokuGridDto): SudokuSolveResult {
    return this.validateService.solveSudoku(dto.grid);
  }

  @Post('killer-sudoku')
  @ApiOperation({ summary: 'Validate a Killer Sudoku puzzle' })
  validateKillerSudoku(@Body() dto: KillerSudokuCagesDto): KillerSudokuValidationResult {
    return this.validateService.validateKillerSudoku(dto.cages);
  }

  @Post('killer-sudoku/solve')
  @ApiOperation({ summary: 'Solve a Killer Sudoku puzzle' })
  solveKillerSudoku(@Body() dto: KillerSudokuCagesDto): KillerSudokuSolveResult {
    return this.validateService.solveKillerSudoku(dto.cages);
  }
}
