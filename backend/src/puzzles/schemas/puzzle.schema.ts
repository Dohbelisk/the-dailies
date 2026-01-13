import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";
import { ApiProperty } from "@nestjs/swagger";

export type PuzzleDocument = Puzzle & Document;

export enum GameType {
  SUDOKU = "sudoku",
  KILLER_SUDOKU = "killerSudoku",
  CROSSWORD = "crossword",
  WORD_SEARCH = "wordSearch",
  WORD_FORGE = "wordForge",
  NONOGRAM = "nonogram",
  NUMBER_TARGET = "numberTarget",
  BALL_SORT = "ballSort",
  PIPES = "pipes",
  LIGHTS_OUT = "lightsOut",
  WORD_LADDER = "wordLadder",
  CONNECTIONS = "connections",
  MATHORA = "mathora",
}

export enum Difficulty {
  EASY = "easy",
  MEDIUM = "medium",
  HARD = "hard",
  EXPERT = "expert",
}

export enum PuzzleStatus {
  PENDING = "pending",
  ACTIVE = "active",
  INACTIVE = "inactive",
}

@Schema({ timestamps: true })
export class Puzzle {
  @ApiProperty({ enum: GameType })
  @Prop({ required: true, enum: GameType })
  gameType: GameType;

  @ApiProperty({ enum: Difficulty })
  @Prop({ required: true, enum: Difficulty })
  difficulty: Difficulty;

  @ApiProperty({ description: "Date the puzzle is scheduled for" })
  @Prop({ required: true, type: Date })
  date: Date;

  @ApiProperty({ description: "The puzzle data (grid, clues, etc)" })
  @Prop({ required: true, type: Object })
  puzzleData: Record<string, any>;

  @ApiProperty({ description: "The solution to the puzzle" })
  @Prop({ required: true, type: Object })
  solution: Record<string, any>;

  @ApiProperty({ description: "Target completion time in seconds" })
  @Prop()
  targetTime: number;

  @ApiProperty({ description: "Whether the puzzle is active/published (deprecated, use status)" })
  @Prop({ default: true })
  isActive: boolean;

  @ApiProperty({ enum: PuzzleStatus, description: "Puzzle status: pending, active, or inactive" })
  @Prop({ enum: PuzzleStatus, default: PuzzleStatus.PENDING })
  status: PuzzleStatus;

  @ApiProperty({ description: "Optional title for the puzzle" })
  @Prop()
  title: string;

  @ApiProperty({ description: "Optional description or theme" })
  @Prop()
  description: string;
}

export const PuzzleSchema = SchemaFactory.createForClass(Puzzle);

// Indexes
PuzzleSchema.index({ gameType: 1, date: -1 });
PuzzleSchema.index({ date: 1 });
PuzzleSchema.index({ gameType: 1, isActive: 1 });
PuzzleSchema.index({ gameType: 1, status: 1 });
PuzzleSchema.index({ status: 1, date: -1 });
