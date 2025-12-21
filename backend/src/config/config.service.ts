import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { AppConfig, AppConfigDocument } from "./schemas/app-config.schema";
import {
  FeatureFlag,
  FeatureFlagDocument,
} from "./schemas/feature-flag.schema";
import {
  CreateFeatureFlagDto,
  UpdateFeatureFlagDto,
  UpdateAppConfigDto,
} from "./dto/config.dto";

@Injectable()
export class AppConfigService {
  constructor(
    @InjectModel(AppConfig.name)
    private appConfigModel: Model<AppConfigDocument>,
    @InjectModel(FeatureFlag.name)
    private featureFlagModel: Model<FeatureFlagDocument>,
  ) {}

  // ============ App Config Methods ============

  async getAppConfig(): Promise<AppConfig> {
    let config = await this.appConfigModel.findOne({ configId: "main" });

    if (!config) {
      // Create default config if it doesn't exist
      config = await this.appConfigModel.create({
        configId: "main",
        latestVersion: "1.0.0",
        minVersion: "1.0.0",
        updateUrl: "",
        updateMessage:
          "A new version is available. Please update for the best experience.",
        forceUpdateMessage:
          "This version is no longer supported. Please update to continue.",
        maintenanceMode: false,
        maintenanceMessage:
          "We are currently performing maintenance. Please try again later.",
      });
    }

    return config;
  }

  async updateAppConfig(updateDto: UpdateAppConfigDto): Promise<AppConfig> {
    const config = await this.appConfigModel.findOneAndUpdate(
      { configId: "main" },
      { $set: updateDto },
      { new: true, upsert: true },
    );
    return config;
  }

  /**
   * Compare two semantic version strings
   * Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
   */
  compareVersions(v1: string, v2: string): number {
    const parts1 = v1.split(".").map((p) => parseInt(p, 10) || 0);
    const parts2 = v2.split(".").map((p) => parseInt(p, 10) || 0);

    const maxLength = Math.max(parts1.length, parts2.length);

    for (let i = 0; i < maxLength; i++) {
      const p1 = parts1[i] || 0;
      const p2 = parts2[i] || 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  // ============ Feature Flag Methods ============

  async createFeatureFlag(
    createDto: CreateFeatureFlagDto,
  ): Promise<FeatureFlag> {
    const flag = await this.featureFlagModel.create(createDto);
    return flag;
  }

  async getAllFeatureFlags(): Promise<FeatureFlag[]> {
    return this.featureFlagModel.find().sort({ key: 1 });
  }

  async getFeatureFlag(key: string): Promise<FeatureFlag | null> {
    return this.featureFlagModel.findOne({ key });
  }

  async updateFeatureFlag(
    key: string,
    updateDto: UpdateFeatureFlagDto,
  ): Promise<FeatureFlag | null> {
    return this.featureFlagModel.findOneAndUpdate(
      { key },
      { $set: updateDto },
      { new: true },
    );
  }

  async deleteFeatureFlag(key: string): Promise<boolean> {
    const result = await this.featureFlagModel.deleteOne({ key });
    return result.deletedCount > 0;
  }

  /**
   * Get feature flags filtered for a specific app version and user
   */
  async getFeatureFlagsForClient(
    appVersion?: string,
    userId?: string,
  ): Promise<Record<string, boolean>> {
    const allFlags = await this.getAllFeatureFlags();
    const result: Record<string, boolean> = {};

    for (const flag of allFlags) {
      let isEnabled = flag.enabled;

      // Check expiry
      if (flag.expiresAt && new Date() > flag.expiresAt) {
        isEnabled = false;
      }

      // Check version requirements
      if (isEnabled && appVersion) {
        if (
          flag.minAppVersion &&
          this.compareVersions(appVersion, flag.minAppVersion) < 0
        ) {
          isEnabled = false;
        }
        if (
          flag.maxAppVersion &&
          this.compareVersions(appVersion, flag.maxAppVersion) > 0
        ) {
          isEnabled = false;
        }
      }

      // Check user-specific enablement
      if (!isEnabled && userId && flag.enabledForUserIds?.includes(userId)) {
        isEnabled = true;
      }

      // Check rollout percentage (simple hash-based rollout)
      if (
        isEnabled &&
        flag.rolloutPercentage > 0 &&
        flag.rolloutPercentage < 100
      ) {
        if (userId) {
          // Deterministic rollout based on user ID
          const hash = this.simpleHash(userId + flag.key);
          const bucket = hash % 100;
          isEnabled = bucket < flag.rolloutPercentage;
        } else {
          // Without user ID, just use the percentage as probability
          isEnabled = Math.random() * 100 < flag.rolloutPercentage;
        }
      }

      result[flag.key] = isEnabled;
    }

    return result;
  }

  /**
   * Simple hash function for deterministic rollouts
   */
  private simpleHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
  }

  /**
   * Check if a specific feature is enabled for a client
   */
  async isFeatureEnabled(
    key: string,
    appVersion?: string,
    userId?: string,
  ): Promise<boolean> {
    const flags = await this.getFeatureFlagsForClient(appVersion, userId);
    return flags[key] ?? false;
  }

  // ============ Seed Default Flags ============

  async seedDefaultFlags(): Promise<void> {
    const defaultFlags: CreateFeatureFlagDto[] = [
      {
        key: "challenges_enabled",
        name: "Challenges",
        description: "Enable head-to-head puzzle challenges between friends",
        enabled: true,
        minAppVersion: "1.0.0",
      },
      {
        key: "friends_enabled",
        name: "Friends System",
        description: "Enable friends list and friend requests",
        enabled: true,
        minAppVersion: "1.0.0",
      },
      {
        key: "archive_enabled",
        name: "Puzzle Archive",
        description: "Enable access to past puzzles",
        enabled: true,
        minAppVersion: "1.0.0",
      },
      {
        key: "ads_enabled",
        name: "Advertisements",
        description: "Enable AdMob advertisements",
        enabled: true,
        minAppVersion: "1.0.0",
      },
      {
        key: "iap_enabled",
        name: "In-App Purchases",
        description: "Enable premium subscription purchases",
        enabled: true,
        minAppVersion: "1.0.0",
      },
      {
        key: "dark_mode_enabled",
        name: "Dark Mode",
        description: "Enable dark mode theme option",
        enabled: true,
        minAppVersion: "1.0.0",
      },
      {
        key: "debug_menu_enabled",
        name: "Debug Menu",
        description: "Enable hidden debug menu access",
        enabled: true,
        minAppVersion: "1.0.0",
      },
    ];

    for (const flag of defaultFlags) {
      const exists = await this.featureFlagModel.findOne({ key: flag.key });
      if (!exists) {
        await this.featureFlagModel.create(flag);
      }
    }
  }
}
