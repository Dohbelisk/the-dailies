import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type AppConfigDocument = AppConfig & Document;

@Schema({ timestamps: true })
export class AppConfig {
  @Prop({ required: true, unique: true, default: "main" })
  configId: string; // 'main' for the primary config

  @Prop({ required: true, default: "1.0.0" })
  latestVersion: string; // Latest available app version

  @Prop({ required: true, default: "1.0.0" })
  minVersion: string; // Minimum required version (force update below this)

  @Prop({ default: "" })
  updateUrl: string; // App store URL for updates

  @Prop({ default: "" })
  updateMessage: string; // Custom message for update dialog

  @Prop({ default: "" })
  forceUpdateMessage: string; // Custom message for force update dialog

  @Prop({ default: true })
  maintenanceMode: boolean;

  @Prop({ default: "" })
  maintenanceMessage: string;
}

export const AppConfigSchema = SchemaFactory.createForClass(AppConfig);
