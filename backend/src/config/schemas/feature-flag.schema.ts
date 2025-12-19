import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type FeatureFlagDocument = FeatureFlag & Document;

@Schema({ timestamps: true })
export class FeatureFlag {
  @Prop({ required: true, unique: true })
  key: string; // e.g., 'challenges_enabled', 'dark_mode', 'new_puzzle_type'

  @Prop({ required: true })
  name: string; // Human-readable name

  @Prop({ default: '' })
  description: string;

  @Prop({ required: true, default: false })
  enabled: boolean; // Global enabled state

  @Prop({ default: null })
  minAppVersion: string; // Minimum app version required (null = all versions)

  @Prop({ default: null })
  maxAppVersion: string; // Maximum app version (null = no max)

  @Prop({ type: [String], default: [] })
  enabledForUserIds: string[]; // Specific users who have this enabled (for beta testing)

  @Prop({ default: 0 })
  rolloutPercentage: number; // 0-100, for gradual rollouts

  @Prop({ default: null })
  expiresAt: Date; // Auto-disable after this date

  @Prop({ type: Object, default: {} })
  metadata: Record<string, any>; // Additional configuration data
}

export const FeatureFlagSchema = SchemaFactory.createForClass(FeatureFlag);

// Index for efficient lookups
FeatureFlagSchema.index({ key: 1 });
FeatureFlagSchema.index({ enabled: 1 });
