import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsEmail,
  IsDateString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FeedbackType, FeedbackStatus } from '../schemas/feedback.schema';
import { GameType, Difficulty } from '../../puzzles/schemas/puzzle.schema';

export class CreateFeedbackDto {
  @ApiProperty({ enum: FeedbackType, description: 'Type of feedback' })
  @IsEnum(FeedbackType)
  @IsNotEmpty()
  type: FeedbackType;

  @ApiProperty({ description: 'Feedback message content', maxLength: 2000 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  message: string;

  @ApiPropertyOptional({ description: 'Optional contact email for follow-up' })
  @IsEmail()
  @IsOptional()
  email?: string;

  // Game context (optional)
  @ApiPropertyOptional({ description: 'Related puzzle ID' })
  @IsString()
  @IsOptional()
  puzzleId?: string;

  @ApiPropertyOptional({ enum: GameType, description: 'Game type of related puzzle' })
  @IsEnum(GameType)
  @IsOptional()
  gameType?: GameType;

  @ApiPropertyOptional({ enum: Difficulty, description: 'Difficulty of related puzzle' })
  @IsEnum(Difficulty)
  @IsOptional()
  difficulty?: Difficulty;

  @ApiPropertyOptional({ description: 'Date of related puzzle' })
  @IsDateString()
  @IsOptional()
  puzzleDate?: string;

  @ApiPropertyOptional({ description: 'Device and app version info' })
  @IsString()
  @IsOptional()
  deviceInfo?: string;
}

export class UpdateFeedbackDto {
  @ApiPropertyOptional({ enum: FeedbackStatus, description: 'Status of the feedback' })
  @IsEnum(FeedbackStatus)
  @IsOptional()
  status?: FeedbackStatus;

  @ApiPropertyOptional({ description: 'Admin notes for tracking resolution', maxLength: 1000 })
  @IsString()
  @IsOptional()
  @MaxLength(1000)
  adminNotes?: string;
}

export class FeedbackQueryDto {
  @ApiPropertyOptional({ enum: FeedbackType, description: 'Filter by feedback type' })
  @IsEnum(FeedbackType)
  @IsOptional()
  type?: FeedbackType;

  @ApiPropertyOptional({ enum: FeedbackStatus, description: 'Filter by status' })
  @IsEnum(FeedbackStatus)
  @IsOptional()
  status?: FeedbackStatus;

  @ApiPropertyOptional({ description: 'Filter by start date' })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Filter by end date' })
  @IsDateString()
  @IsOptional()
  endDate?: string;

  @ApiPropertyOptional({ description: 'Filter by related puzzle ID' })
  @IsString()
  @IsOptional()
  puzzleId?: string;
}

export class FeedbackStatsDto {
  @ApiProperty({ description: 'Total feedback count' })
  total: number;

  @ApiProperty({ description: 'Count by type' })
  byType: Record<string, number>;

  @ApiProperty({ description: 'Count by status' })
  byStatus: Record<string, number>;

  @ApiProperty({ description: 'New feedback count (unread)' })
  newCount: number;
}
