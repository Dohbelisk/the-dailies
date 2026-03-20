import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type DeviceRegistrationDocument = DeviceRegistration & Document;

@Schema({ timestamps: true })
export class DeviceRegistration {
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  userId: Types.ObjectId;

  @Prop({ required: true, unique: true })
  fcmToken: string;

  @Prop({ enum: ["ios", "android"], required: true })
  platform: "ios" | "android";

  @Prop()
  appVersion: string;

  @Prop({ type: [String], default: [] })
  tags: string[];

  @Prop({ default: () => new Date() })
  lastActiveAt: Date;
}

export const DeviceRegistrationSchema =
  SchemaFactory.createForClass(DeviceRegistration);

DeviceRegistrationSchema.index({ userId: 1 });
DeviceRegistrationSchema.index({ tags: 1 });
DeviceRegistrationSchema.index({ lastActiveAt: 1 });
