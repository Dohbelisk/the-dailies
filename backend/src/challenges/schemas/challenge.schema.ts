import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";
import { ApiProperty } from "@nestjs/swagger";

export type ChallengeDocument = Challenge & Document;

export enum ChallengeStatus {
  PENDING = "pending", // Waiting for opponent to accept
  ACCEPTED = "accepted", // Opponent accepted, game in progress
  DECLINED = "declined", // Opponent declined
  COMPLETED = "completed", // Both players finished
  EXPIRED = "expired", // Challenge expired (not accepted in time)
  CANCELLED = "cancelled", // Challenger cancelled
}

export enum GameType {
  SUDOKU = "sudoku",
  KILLER_SUDOKU = "killerSudoku",
  CROSSWORD = "crossword",
  WORD_SEARCH = "wordSearch",
}

export enum Difficulty {
  EASY = "easy",
  MEDIUM = "medium",
  HARD = "hard",
  EXPERT = "expert",
}

@Schema({ timestamps: true })
export class Challenge {
  @ApiProperty({ description: "User who created the challenge" })
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  challengerId: Types.ObjectId;

  @ApiProperty({ description: "User who was challenged" })
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  opponentId: Types.ObjectId;

  @ApiProperty({ description: "The puzzle to play" })
  @Prop({ type: Types.ObjectId, ref: "Puzzle", required: true })
  puzzleId: Types.ObjectId;

  @ApiProperty({ enum: GameType })
  @Prop({ type: String, enum: GameType, required: true })
  gameType: GameType;

  @ApiProperty({ enum: Difficulty })
  @Prop({ type: String, enum: Difficulty, required: true })
  difficulty: Difficulty;

  @ApiProperty({ enum: ChallengeStatus })
  @Prop({
    type: String,
    enum: ChallengeStatus,
    default: ChallengeStatus.PENDING,
  })
  status: ChallengeStatus;

  // Challenger's game result
  @ApiProperty({ description: "Challenger score" })
  @Prop()
  challengerScore: number;

  @ApiProperty({ description: "Challenger completion time in seconds" })
  @Prop()
  challengerTime: number;

  @ApiProperty({ description: "Challenger mistakes count" })
  @Prop()
  challengerMistakes: number;

  @ApiProperty({ description: "Whether challenger has completed the puzzle" })
  @Prop({ default: false })
  challengerCompleted: boolean;

  // Opponent's game result
  @ApiProperty({ description: "Opponent score" })
  @Prop()
  opponentScore: number;

  @ApiProperty({ description: "Opponent completion time in seconds" })
  @Prop()
  opponentTime: number;

  @ApiProperty({ description: "Opponent mistakes count" })
  @Prop()
  opponentMistakes: number;

  @ApiProperty({ description: "Whether opponent has completed the puzzle" })
  @Prop({ default: false })
  opponentCompleted: boolean;

  // Winner determination
  @ApiProperty({ description: "Winner user ID (null if tie or not completed)" })
  @Prop({ type: Types.ObjectId, ref: "User" })
  winnerId: Types.ObjectId;

  @ApiProperty({ description: "Challenge expiry date" })
  @Prop({ type: Date })
  expiresAt: Date;

  @ApiProperty({ description: "Optional message from challenger" })
  @Prop()
  message: string;
}

export const ChallengeSchema = SchemaFactory.createForClass(Challenge);

// Indexes for efficient queries
ChallengeSchema.index({ challengerId: 1, status: 1 });
ChallengeSchema.index({ opponentId: 1, status: 1 });
ChallengeSchema.index({ status: 1, expiresAt: 1 });
ChallengeSchema.index({ challengerId: 1, opponentId: 1, createdAt: -1 });
