import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsString, IsEnum, IsOptional, IsMongoId } from "class-validator";
import { GameType, Difficulty } from "../schemas/challenge.schema";

export class CreateChallengeDto {
  @ApiProperty({ description: "ID of the user to challenge" })
  @IsMongoId()
  opponentId: string;

  @ApiProperty({ enum: GameType, description: "Type of puzzle game" })
  @IsEnum(GameType)
  gameType: GameType;

  @ApiProperty({ enum: Difficulty, description: "Puzzle difficulty" })
  @IsEnum(Difficulty)
  difficulty: Difficulty;

  @ApiPropertyOptional({ description: "Optional message to opponent" })
  @IsString()
  @IsOptional()
  message?: string;
}

export class SubmitChallengeResultDto {
  @ApiProperty({ description: "Challenge ID" })
  @IsMongoId()
  challengeId: string;

  @ApiProperty({ description: "Final score" })
  score: number;

  @ApiProperty({ description: "Completion time in seconds" })
  time: number;

  @ApiProperty({ description: "Number of mistakes made" })
  mistakes: number;
}

export class ChallengeResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  challengerId: string;

  @ApiProperty()
  challengerUsername: string;

  @ApiProperty()
  opponentId: string;

  @ApiProperty()
  opponentUsername: string;

  @ApiProperty()
  puzzleId: string;

  @ApiProperty({ enum: GameType })
  gameType: GameType;

  @ApiProperty({ enum: Difficulty })
  difficulty: Difficulty;

  @ApiProperty()
  status: string;

  @ApiPropertyOptional()
  challengerScore?: number;

  @ApiPropertyOptional()
  challengerTime?: number;

  @ApiPropertyOptional()
  challengerCompleted?: boolean;

  @ApiPropertyOptional()
  opponentScore?: number;

  @ApiPropertyOptional()
  opponentTime?: number;

  @ApiPropertyOptional()
  opponentCompleted?: boolean;

  @ApiPropertyOptional()
  winnerId?: string;

  @ApiPropertyOptional()
  winnerUsername?: string;

  @ApiPropertyOptional()
  message?: string;

  @ApiProperty()
  expiresAt: Date;

  @ApiProperty()
  createdAt: Date;
}

export class ChallengeStatsDto {
  @ApiProperty()
  totalChallenges: number;

  @ApiProperty()
  wins: number;

  @ApiProperty()
  losses: number;

  @ApiProperty()
  ties: number;

  @ApiProperty()
  pending: number;

  @ApiProperty()
  winRate: number;
}
