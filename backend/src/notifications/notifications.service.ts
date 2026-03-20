import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import * as admin from "firebase-admin";
import * as path from "path";
import {
  NotificationLog,
  NotificationLogDocument,
} from "./schemas/notification-log.schema";
import {
  DeviceRegistration,
  DeviceRegistrationDocument,
} from "./schemas/device-registration.schema";

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
}

export interface TopicNotification extends NotificationPayload {
  topic: string;
}

export interface DeviceNotification extends NotificationPayload {
  token: string;
}

export interface MultiDeviceNotification extends NotificationPayload {
  tokens: string[];
}

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private initialized = false;

  constructor(
    @InjectModel(NotificationLog.name)
    private notificationLogModel: Model<NotificationLogDocument>,
    @InjectModel(DeviceRegistration.name)
    private deviceRegistrationModel: Model<DeviceRegistrationDocument>,
  ) {}

  async onModuleInit() {
    await this.initializeFirebase();
  }

  private async initializeFirebase() {
    if (this.initialized) return;

    // Try file path first, then base64, then JSON string
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

    if (!serviceAccountPath && !serviceAccountBase64 && !serviceAccountJson) {
      this.logger.warn(
        "No FIREBASE_SERVICE_ACCOUNT_PATH, FIREBASE_SERVICE_ACCOUNT_BASE64, or FIREBASE_SERVICE_ACCOUNT set - push notifications disabled",
      );
      return;
    }

    try {
      // Check if Firebase is already initialized
      if (admin.apps.length === 0) {
        let credential: admin.credential.Credential;

        if (serviceAccountPath) {
          // Load from file path (resolve relative to project root)
          const resolvedPath = path.isAbsolute(serviceAccountPath)
            ? serviceAccountPath
            : path.resolve(process.cwd(), serviceAccountPath);
          // eslint-disable-next-line @typescript-eslint/no-var-requires
          const serviceAccount = require(resolvedPath);
          this.logger.log(
            `Initializing Firebase from file with project: ${serviceAccount.project_id}`,
          );
          credential = admin.credential.cert(serviceAccount);
        } else if (serviceAccountBase64) {
          // Decode from base64
          const decoded = Buffer.from(serviceAccountBase64, "base64").toString(
            "utf-8",
          );
          const serviceAccount = JSON.parse(decoded);
          this.logger.log(
            `Initializing Firebase from base64 with project: ${serviceAccount.project_id}`,
          );
          credential = admin.credential.cert(serviceAccount);
        } else {
          // Parse from JSON string
          const serviceAccount = JSON.parse(serviceAccountJson);
          this.logger.log(
            `Initializing Firebase from JSON with project: ${serviceAccount.project_id}`,
          );
          credential = admin.credential.cert(serviceAccount);
        }

        admin.initializeApp({ credential });
      }
      this.initialized = true;
      this.logger.log("Firebase Admin initialized for push notifications");
    } catch (error) {
      this.logger.error("Failed to initialize Firebase Admin", error);
    }
  }

  /**
   * Build FCM platform config for Android + iOS
   */
  private buildPlatformConfig(title: string, body: string) {
    return {
      android: {
        priority: "high" as const,
        notification: {
          channelId: "the_dailies_channel",
          priority: "high" as const,
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: "default",
            badge: 1,
          },
        },
      },
    };
  }

  /**
   * Send a notification to a specific device token
   */
  async sendToDevice(notification: DeviceNotification): Promise<boolean> {
    if (!this.initialized) {
      this.logger.warn("Firebase not initialized - cannot send notification");
      return false;
    }

    try {
      const message: admin.messaging.Message = {
        token: notification.token,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: notification.data,
        ...this.buildPlatformConfig(notification.title, notification.body),
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Notification sent: ${response}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send notification: ${error.message}`);
      return false;
    }
  }

  /**
   * Send a notification to multiple device tokens
   */
  async sendToMultipleDevices(
    notification: MultiDeviceNotification,
  ): Promise<{ successCount: number; failureCount: number }> {
    if (!this.initialized) {
      this.logger.warn("Firebase not initialized - cannot send notification");
      return { successCount: 0, failureCount: notification.tokens.length };
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens: notification.tokens,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: notification.data,
        ...this.buildPlatformConfig(notification.title, notification.body),
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.log(
        `Multicast sent: ${response.successCount} success, ${response.failureCount} failures`,
      );
      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      this.logger.error(`Failed to send multicast: ${error.message}`);
      return { successCount: 0, failureCount: notification.tokens.length };
    }
  }

  /**
   * Send a notification to a topic (all subscribers)
   */
  async sendToTopic(notification: TopicNotification): Promise<boolean> {
    if (!this.initialized) {
      this.logger.warn("Firebase not initialized - cannot send notification");
      return false;
    }

    try {
      const message: admin.messaging.Message = {
        topic: notification.topic,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: notification.data,
        ...this.buildPlatformConfig(notification.title, notification.body),
      };

      const response = await admin.messaging().send(message);
      this.logger.log(
        `Topic notification sent to ${notification.topic}: ${response}`,
      );
      return true;
    } catch (error) {
      this.logger.error(`Failed to send topic notification: ${error.message}`);
      return false;
    }
  }

  /**
   * Send a notification to an FCM condition string
   */
  async sendToCondition(
    condition: string,
    payload: NotificationPayload,
  ): Promise<boolean> {
    if (!this.initialized) {
      this.logger.warn("Firebase not initialized - cannot send notification");
      return false;
    }

    try {
      const message: admin.messaging.Message = {
        condition,
        notification: {
          title: payload.title,
          body: payload.body,
          imageUrl: payload.imageUrl,
        },
        data: payload.data,
        ...this.buildPlatformConfig(payload.title, payload.body),
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Condition notification sent: ${response}`);
      return true;
    } catch (error) {
      this.logger.error(
        `Failed to send condition notification: ${error.message}`,
      );
      return false;
    }
  }

  /**
   * Send notification with tag-based targeting.
   * Single tag -> topic send. Multiple tags -> FCM condition string.
   */
  async sendWithTags(
    tags: string[],
    logic: "AND" | "OR",
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<{
    success: boolean;
    fcmMessageId?: string;
    logId?: string;
  }> {
    const payload: NotificationPayload = { title, body, data };
    let targetType: "all" | "topic" | "condition";
    let targetValue: string;
    let success = false;

    if (tags.length === 0) {
      // Send to all users via daily_puzzles topic (broadest topic)
      targetType = "all";
      targetValue = "daily_puzzles";
      success = await this.sendToTopic({
        topic: "daily_puzzles",
        ...payload,
      });
    } else if (tags.length === 1) {
      // Single tag - use topic directly
      targetType = "topic";
      targetValue = tags[0];
      success = await this.sendToTopic({ topic: tags[0], ...payload });
    } else {
      // Multiple tags - build FCM condition (max 5 topics)
      targetType = "condition";
      const joiner = logic === "AND" ? " && " : " || ";
      targetValue = tags
        .slice(0, 5)
        .map((tag) => `'${tag}' in topics`)
        .join(joiner);
      success = await this.sendToCondition(targetValue, payload);
    }

    // Log the notification
    const log = await this.logNotification({
      title,
      body,
      target: { type: targetType, value: targetValue },
      tags,
      tagLogic: logic,
      status: success ? "sent" : "failed",
      successCount: success ? 1 : 0,
      failureCount: success ? 0 : 1,
      sentAt: new Date(),
      data,
    });

    return {
      success,
      logId: log?._id?.toString(),
    };
  }

  /**
   * Persist a notification log entry
   */
  async logNotification(
    details: Partial<NotificationLog>,
  ): Promise<NotificationLogDocument> {
    try {
      return await this.notificationLogModel.create(details);
    } catch (error) {
      this.logger.error(`Failed to log notification: ${error.message}`);
      return null;
    }
  }

  /**
   * Get paginated notification history
   */
  async getHistory(
    page = 1,
    limit = 20,
  ): Promise<{
    items: NotificationLogDocument[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.notificationLogModel
        .find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.notificationLogModel.countDocuments().exec(),
    ]);

    return {
      items,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Register or update a device
   */
  async registerDevice(
    userId: string,
    fcmToken: string,
    platform: "ios" | "android",
    appVersion: string,
    tags: string[],
  ): Promise<DeviceRegistrationDocument> {
    return this.deviceRegistrationModel.findOneAndUpdate(
      { fcmToken },
      {
        userId,
        fcmToken,
        platform,
        appVersion,
        tags,
        lastActiveAt: new Date(),
      },
      { upsert: true, new: true },
    );
  }

  /**
   * Get dashboard stats: total devices, active (7d), platform split, tag counts
   */
  async getStats(): Promise<{
    totalDevices: number;
    activeDevices: number;
    iosBCount: number;
    androidCount: number;
    totalNotificationsSent: number;
  }> {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const [totalDevices, activeDevices, platformCounts, totalNotificationsSent] =
      await Promise.all([
        this.deviceRegistrationModel.countDocuments().exec(),
        this.deviceRegistrationModel
          .countDocuments({ lastActiveAt: { $gte: sevenDaysAgo } })
          .exec(),
        this.deviceRegistrationModel
          .aggregate([
            { $group: { _id: "$platform", count: { $sum: 1 } } },
          ])
          .exec(),
        this.notificationLogModel
          .countDocuments({ status: "sent" })
          .exec(),
      ]);

    const platformMap = Object.fromEntries(
      platformCounts.map((p) => [p._id, p.count]),
    );

    return {
      totalDevices,
      activeDevices,
      iosBCount: platformMap["ios"] || 0,
      androidCount: platformMap["android"] || 0,
      totalNotificationsSent,
    };
  }

  /**
   * Get distinct tags from device registrations with subscriber counts
   */
  async getTagList(): Promise<{ tag: string; count: number }[]> {
    const result = await this.deviceRegistrationModel
      .aggregate([
        { $unwind: "$tags" },
        { $group: { _id: "$tags", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $project: { _id: 0, tag: "$_id", count: 1 } },
      ])
      .exec();

    return result;
  }

  /**
   * Send daily puzzle reminder to all subscribed users
   */
  async sendDailyPuzzleReminder(): Promise<boolean> {
    return this.sendToTopic({
      topic: "daily_puzzles",
      title: "Today's Puzzles Are Ready!",
      body: "New daily puzzles are waiting for you. Keep your streak going!",
      data: {
        type: "daily_reminder",
        action: "open_home",
      },
    });
  }

  /**
   * Send challenge notification to a specific user
   */
  async sendChallengeNotification(
    token: string,
    challengerName: string,
    gameType: string,
  ): Promise<boolean> {
    return this.sendToDevice({
      token,
      title: "New Challenge!",
      body: `${challengerName} has challenged you to a ${gameType} puzzle!`,
      data: {
        type: "challenge",
        action: "open_challenges",
      },
    });
  }

  /**
   * Send friend request notification
   */
  async sendFriendRequestNotification(
    token: string,
    senderName: string,
  ): Promise<boolean> {
    return this.sendToDevice({
      token,
      title: "Friend Request",
      body: `${senderName} wants to be your friend!`,
      data: {
        type: "friend_request",
        action: "open_friends",
      },
    });
  }

  /**
   * Send streak reminder (for users about to lose their streak)
   */
  async sendStreakReminder(
    token: string,
    streakDays: number,
  ): Promise<boolean> {
    return this.sendToDevice({
      token,
      title: "Don't Lose Your Streak!",
      body: `You have a ${streakDays}-day streak. Complete a puzzle today to keep it going!`,
      data: {
        type: "streak_reminder",
        action: "open_home",
      },
    });
  }

  /**
   * Check if notifications are enabled
   */
  isEnabled(): boolean {
    return this.initialized;
  }
}
