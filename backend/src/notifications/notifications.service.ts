import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import * as admin from "firebase-admin";
import * as path from "path";

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

  async onModuleInit() {
    await this.initializeFirebase();
  }

  private async initializeFirebase() {
    if (this.initialized) return;

    // Try file path first, then JSON string
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

    if (!serviceAccountPath && !serviceAccountJson) {
      this.logger.warn(
        "Neither FIREBASE_SERVICE_ACCOUNT_PATH nor FIREBASE_SERVICE_ACCOUNT set - push notifications disabled",
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
        android: {
          priority: "high",
          notification: {
            channelId: "the_dailies_channel",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
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
        android: {
          priority: "high",
          notification: {
            channelId: "the_dailies_channel",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
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
        android: {
          priority: "high",
          notification: {
            channelId: "the_dailies_channel",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
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
