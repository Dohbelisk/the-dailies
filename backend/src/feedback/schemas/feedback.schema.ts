import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { GameType, Difficulty } from "../../puzzles/schemas/puzzle.schema";

export type FeedbackDocument = Feedback & Document;

export enum FeedbackType {
  BUG_REPORT = "bug_report",
  NEW_GAME_SUGGESTION = "new_game_suggestion",
  PUZZLE_SUGGESTION = "puzzle_suggestion",
  PUZZLE_MISTAKE = "puzzle_mistake",
  GENERAL = "general",
}

export enum FeedbackStatus {
  NEW = "new",
  IN_PROGRESS = "in_progress",
  RESOLVED = "resolved",
  DISMISSED = "dismissed",
}

@Schema({ timestamps: true })
export class Feedback {
  @ApiProperty({ enum: FeedbackType, description: "Type of feedback" })
  @Prop({ required: true, enum: FeedbackType })
  type: FeedbackType;

  @ApiProperty({ description: "Feedback message content" })
  @Prop({ required: true })
  message: string;

  @ApiPropertyOptional({ description: "Optional contact email for follow-up" })
  @Prop()
  email?: string;

  @ApiProperty({ enum: FeedbackStatus, description: "Status of the feedback" })
  @Prop({ enum: FeedbackStatus, default: FeedbackStatus.NEW })
  status: FeedbackStatus;

  @ApiPropertyOptional({ description: "Admin notes for tracking resolution" })
  @Prop()
  adminNotes?: string;

  // Game context (optional - populated when submitted from within a game)
  @ApiPropertyOptional({ description: "Related puzzle ID" })
  @Prop()
  puzzleId?: string;

  @ApiPropertyOptional({
    enum: GameType,
    description: "Game type of related puzzle",
  })
  @Prop({ enum: GameType })
  gameType?: GameType;

  @ApiPropertyOptional({
    enum: Difficulty,
    description: "Difficulty of related puzzle",
  })
  @Prop({ enum: Difficulty })
  difficulty?: Difficulty;

  @ApiPropertyOptional({ description: "Date of related puzzle" })
  @Prop({ type: Date })
  puzzleDate?: Date;

  // Additional context
  @ApiPropertyOptional({ description: "Device and app version info" })
  @Prop()
  deviceInfo?: string;
}

export const FeedbackSchema = SchemaFactory.createForClass(Feedback);

// Indexes for common queries
FeedbackSchema.index({ type: 1, status: 1 });
FeedbackSchema.index({ createdAt: -1 });
FeedbackSchema.index({ status: 1 });
FeedbackSchema.index({ puzzleId: 1 });
