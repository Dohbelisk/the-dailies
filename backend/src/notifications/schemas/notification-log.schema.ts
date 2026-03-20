import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type NotificationLogDocument = NotificationLog & Document;

@Schema({ timestamps: true })
export class NotificationLog {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({
    type: {
      type: String,
      enum: ["all", "topic", "condition"],
      required: true,
    },
    value: { type: String, required: true },
  })
  target: { type: "all" | "topic" | "condition"; value: string };

  @Prop({ type: [String], default: [] })
  tags: string[];

  @Prop({ enum: ["AND", "OR"], default: "OR" })
  tagLogic: "AND" | "OR";

  @Prop({
    enum: ["sent", "failed", "scheduled", "cancelled"],
    default: "sent",
  })
  status: "sent" | "failed" | "scheduled" | "cancelled";

  @Prop({ default: 0 })
  successCount: number;

  @Prop({ default: 0 })
  failureCount: number;

  @Prop()
  fcmMessageId: string;

  @Prop()
  sentAt: Date;

  @Prop({ type: Object })
  data: Record<string, string>;
}

export const NotificationLogSchema =
  SchemaFactory.createForClass(NotificationLog);

NotificationLogSchema.index({ sentAt: -1 });
NotificationLogSchema.index({ status: 1 });
NotificationLogSchema.index({ tags: 1 });
