import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type FriendDocument = Friend & Document;

@Schema({ timestamps: true })
export class Friend {
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  friendId: Types.ObjectId;

  @Prop({ default: Date.now })
  friendsSince: Date;
}

export const FriendSchema = SchemaFactory.createForClass(Friend);

// Compound unique index to prevent duplicate friendships
FriendSchema.index({ userId: 1, friendId: 1 }, { unique: true });

// Index for efficient lookups
FriendSchema.index({ userId: 1 });
FriendSchema.index({ friendId: 1 });
