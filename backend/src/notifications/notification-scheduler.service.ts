import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { SchedulerRegistry } from "@nestjs/schedule";
import { Cron } from "@nestjs/schedule";
import {
  ScheduledNotification,
  ScheduledNotificationDocument,
} from "./schemas/scheduled-notification.schema";
import { NotificationsService } from "./notifications.service";

@Injectable()
export class NotificationSchedulerService implements OnModuleInit {
  private readonly logger = new Logger(NotificationSchedulerService.name);

  constructor(
    @InjectModel(ScheduledNotification.name)
    private scheduledModel: Model<ScheduledNotificationDocument>,
    private schedulerRegistry: SchedulerRegistry,
    private notificationsService: NotificationsService,
  ) {}

  async onModuleInit() {
    await this.loadActiveJobs();
  }

  /**
   * Load all active scheduled notifications and register them
   */
  private async loadActiveJobs() {
    try {
      const activeJobs = await this.scheduledModel
        .find({ status: "active" })
        .exec();

      this.logger.log(
        `Loading ${activeJobs.length} active scheduled notifications`,
      );

      for (const job of activeJobs) {
        if (job.isRecurring && job.cronExpression) {
          this.registerRecurringJob(job);
        }
      }
    } catch (error) {
      this.logger.error(`Failed to load active jobs: ${error.message}`);
    }
  }

  /**
   * Register a recurring job via interval (since dynamic CronJob creation
   * requires the cron npm package; we use intervals parsed from cron expressions)
   */
  private registerRecurringJob(job: ScheduledNotificationDocument) {
    const intervalMs = this.cronToIntervalMs(job.cronExpression);
    if (!intervalMs) {
      this.logger.warn(
        `Cannot parse cron expression for job ${job._id}: ${job.cronExpression}`,
      );
      return;
    }

    const jobName = `scheduled-${job._id}`;

    // Clear existing interval if any
    try {
      this.schedulerRegistry.deleteInterval(jobName);
    } catch {
      // Not registered yet
    }

    const interval = setInterval(async () => {
      await this.executeJob(job._id.toString());
    }, intervalMs);

    this.schedulerRegistry.addInterval(jobName, interval);
    this.logger.log(
      `Registered recurring job ${jobName} (every ${intervalMs / 1000}s)`,
    );
  }

  /**
   * Parse simple cron presets into millisecond intervals.
   * Supports common patterns; complex cron expressions fall back to minute-check.
   */
  private cronToIntervalMs(expression: string): number | null {
    const presets: Record<string, number> = {
      "* * * * *": 60 * 1000, // every minute
      "*/5 * * * *": 5 * 60 * 1000, // every 5 minutes
      "*/15 * * * *": 15 * 60 * 1000, // every 15 minutes
      "*/30 * * * *": 30 * 60 * 1000, // every 30 minutes
      "0 * * * *": 60 * 60 * 1000, // every hour
      "0 */2 * * *": 2 * 60 * 60 * 1000, // every 2 hours
      "0 */6 * * *": 6 * 60 * 60 * 1000, // every 6 hours
      "0 */12 * * *": 12 * 60 * 60 * 1000, // every 12 hours
      "0 0 * * *": 24 * 60 * 60 * 1000, // daily
      "0 9 * * *": 24 * 60 * 60 * 1000, // daily at 9am
    };

    return presets[expression] || null;
  }

  /**
   * Every minute, check for one-time scheduled notifications that are due
   */
  @Cron("* * * * *")
  async checkScheduledNotifications() {
    try {
      const now = new Date();
      const dueNotifications = await this.scheduledModel
        .find({
          status: "active",
          isRecurring: false,
          scheduledAt: { $lte: now },
        })
        .exec();

      for (const notification of dueNotifications) {
        await this.executeJob(notification._id.toString());
        await this.scheduledModel.findByIdAndUpdate(notification._id, {
          status: "completed",
          lastRunAt: now,
        });
      }
    } catch (error) {
      this.logger.error(
        `Error checking scheduled notifications: ${error.message}`,
      );
    }
  }

  /**
   * Execute a scheduled notification job
   */
  private async executeJob(jobId: string) {
    try {
      const job = await this.scheduledModel.findById(jobId);
      if (!job || job.status !== "active") return;

      this.logger.log(`Executing scheduled notification: ${job.title}`);

      await this.notificationsService.sendWithTags(
        job.tags,
        job.tagLogic,
        job.title,
        job.body,
        job.data,
      );

      await this.scheduledModel.findByIdAndUpdate(jobId, {
        lastRunAt: new Date(),
        nextRunAt: job.isRecurring ? this.calculateNextRun(job) : undefined,
      });
    } catch (error) {
      this.logger.error(
        `Failed to execute scheduled notification ${jobId}: ${error.message}`,
      );
    }
  }

  /**
   * Calculate next run time for a recurring job
   */
  private calculateNextRun(
    job: ScheduledNotificationDocument,
  ): Date | undefined {
    const intervalMs = this.cronToIntervalMs(job.cronExpression);
    if (!intervalMs) return undefined;
    return new Date(Date.now() + intervalMs);
  }

  /**
   * Create a new scheduled notification
   */
  async create(dto: {
    title: string;
    body: string;
    tags: string[];
    tagLogic: "AND" | "OR";
    scheduledAt?: Date;
    cronExpression?: string;
    isRecurring?: boolean;
    data?: Record<string, string>;
  }): Promise<ScheduledNotificationDocument> {
    const doc = await this.scheduledModel.create({
      ...dto,
      status: "active",
      nextRunAt: dto.isRecurring
        ? this.calculateNextRunFromCron(dto.cronExpression)
        : dto.scheduledAt,
    });

    if (dto.isRecurring && dto.cronExpression) {
      this.registerRecurringJob(doc);
    }

    return doc;
  }

  private calculateNextRunFromCron(expression: string): Date | undefined {
    const intervalMs = this.cronToIntervalMs(expression);
    if (!intervalMs) return undefined;
    return new Date(Date.now() + intervalMs);
  }

  /**
   * Pause a scheduled notification
   */
  async pause(id: string): Promise<ScheduledNotificationDocument> {
    const job = await this.scheduledModel.findByIdAndUpdate(
      id,
      { status: "paused" },
      { new: true },
    );

    // Remove interval if recurring
    try {
      this.schedulerRegistry.deleteInterval(`scheduled-${id}`);
    } catch {
      // Not registered
    }

    return job;
  }

  /**
   * Resume a paused scheduled notification
   */
  async resume(id: string): Promise<ScheduledNotificationDocument> {
    const job = await this.scheduledModel.findByIdAndUpdate(
      id,
      { status: "active" },
      { new: true },
    );

    if (job?.isRecurring && job?.cronExpression) {
      this.registerRecurringJob(job);
    }

    return job;
  }

  /**
   * Cancel a scheduled notification
   */
  async cancel(id: string): Promise<ScheduledNotificationDocument> {
    const job = await this.scheduledModel.findByIdAndUpdate(
      id,
      { status: "cancelled" },
      { new: true },
    );

    try {
      this.schedulerRegistry.deleteInterval(`scheduled-${id}`);
    } catch {
      // Not registered
    }

    return job;
  }

  /**
   * Delete a scheduled notification
   */
  async delete(id: string): Promise<void> {
    try {
      this.schedulerRegistry.deleteInterval(`scheduled-${id}`);
    } catch {
      // Not registered
    }
    await this.scheduledModel.findByIdAndDelete(id);
  }

  /**
   * List scheduled notifications with optional status filter
   */
  async list(
    status?: string,
    page = 1,
    limit = 20,
  ): Promise<{
    items: ScheduledNotificationDocument[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    const filter = status ? { status } : {};
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      this.scheduledModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.scheduledModel.countDocuments(filter).exec(),
    ]);

    return {
      items,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Update a scheduled notification
   */
  async update(
    id: string,
    dto: Partial<{
      title: string;
      body: string;
      tags: string[];
      tagLogic: "AND" | "OR";
      scheduledAt: Date;
      cronExpression: string;
      isRecurring: boolean;
      status: string;
      data: Record<string, string>;
    }>,
  ): Promise<ScheduledNotificationDocument> {
    const job = await this.scheduledModel.findByIdAndUpdate(id, dto, {
      new: true,
    });

    // Re-register if recurring settings changed
    if (dto.cronExpression || dto.isRecurring !== undefined) {
      try {
        this.schedulerRegistry.deleteInterval(`scheduled-${id}`);
      } catch {
        // Not registered
      }

      if (job?.isRecurring && job?.cronExpression && job?.status === "active") {
        this.registerRecurringJob(job);
      }
    }

    return job;
  }
}
