import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";
import { ApiProperty } from "@nestjs/swagger";

export type ScoreDocument = Score & Document;

@Schema({ timestamps: true })
export class Score {
  @ApiProperty()
  @Prop({ type: Types.ObjectId, ref: "Puzzle", required: true })
  puzzleId: Types.ObjectId;

  @ApiProperty()
  @Prop({ type: Types.ObjectId, ref: "User" })
  userId: Types.ObjectId;

  @ApiProperty({ description: "Device ID for anonymous users" })
  @Prop()
  deviceId: string;

  @ApiProperty({ description: "Completion time in seconds" })
  @Prop({ required: true })
  time: number;

  @ApiProperty()
  @Prop({ required: true })
  score: number;

  @ApiProperty()
  @Prop({ default: 0 })
  mistakes: number;

  @ApiProperty()
  @Prop({ default: 0 })
  hintsUsed: number;

  @ApiProperty()
  @Prop({ default: true })
  completed: boolean;
}

export const ScoreSchema = SchemaFactory.createForClass(Score);

ScoreSchema.index({ puzzleId: 1, userId: 1 });
ScoreSchema.index({ puzzleId: 1, deviceId: 1 });
ScoreSchema.index({ userId: 1, createdAt: -1 });
