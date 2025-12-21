import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type FriendRequestDocument = FriendRequest & Document;

export enum RequestStatus {
  PENDING = "pending",
  ACCEPTED = "accepted",
  DECLINED = "declined",
}

@Schema({ timestamps: true })
export class FriendRequest {
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  senderId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  receiverId: Types.ObjectId;

  @Prop({ type: String, enum: RequestStatus, default: RequestStatus.PENDING })
  status: RequestStatus;
}

export const FriendRequestSchema = SchemaFactory.createForClass(FriendRequest);

// Indexes for efficient queries
FriendRequestSchema.index({ receiverId: 1, status: 1 });
FriendRequestSchema.index({ senderId: 1, status: 1 });
FriendRequestSchema.index({ senderId: 1, receiverId: 1 });
