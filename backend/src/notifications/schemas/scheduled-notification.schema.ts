import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type ScheduledNotificationDocument = ScheduledNotification & Document;

@Schema({ timestamps: true })
export class ScheduledNotification {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ type: [String], default: [] })
  tags: string[];

  @Prop({ enum: ["AND", "OR"], default: "OR" })
  tagLogic: "AND" | "OR";

  @Prop()
  scheduledAt: Date;

  @Prop()
  cronExpression: string;

  @Prop({ default: false })
  isRecurring: boolean;

  @Prop({
    enum: ["active", "paused", "cancelled", "completed"],
    default: "active",
  })
  status: "active" | "paused" | "cancelled" | "completed";

  @Prop()
  lastRunAt: Date;

  @Prop()
  nextRunAt: Date;

  @Prop({ type: Object })
  data: Record<string, string>;
}

export const ScheduledNotificationSchema =
  SchemaFactory.createForClass(ScheduledNotification);

ScheduledNotificationSchema.index({ status: 1 });
ScheduledNotificationSchema.index({ nextRunAt: 1 });
