import {
  Injectable,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import {
  ScheduledNotification,
  ScheduledNotificationDocument,
} from "./schemas/scheduled-notification.schema";
import { NotificationsService } from "./notifications.service";

@Injectable()
export class NotificationSchedulerService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(NotificationSchedulerService.name);
  private readonly intervals = new Map<string, NodeJS.Timeout>();
  private cronCheckInterval: NodeJS.Timeout | null = null;

  constructor(
    @InjectModel(ScheduledNotification.name)
    private scheduledModel: Model<ScheduledNotificationDocument>,
    private notificationsService: NotificationsService,
  ) {}

  async onModuleInit() {
    // Start the 1-minute cron check for one-time scheduled notifications
    this.cronCheckInterval = setInterval(
      () => this.checkScheduledNotifications(),
      60 * 1000,
    );
    await this.loadActiveJobs();
  }

  onModuleDestroy() {
    // Clean up all intervals
    if (this.cronCheckInterval) clearInterval(this.cronCheckInterval);
    for (const interval of this.intervals.values()) {
      clearInterval(interval);
    }
    this.intervals.clear();
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
    const existing = this.intervals.get(jobName);
    if (existing) clearInterval(existing);

    const interval = setInterval(async () => {
      await this.executeJob(job._id.toString());
    }, intervalMs);

    this.intervals.set(jobName, interval);
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
  private async checkScheduledNotifications() {
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
    const existing = this.intervals.get(`scheduled-${id}`);
    if (existing) {
      clearInterval(existing);
      this.intervals.delete(`scheduled-${id}`);
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

    const cancelExisting = this.intervals.get(`scheduled-${id}`);
    if (cancelExisting) {
      clearInterval(cancelExisting);
      this.intervals.delete(`scheduled-${id}`);
    }

    return job;
  }

  /**
   * Delete a scheduled notification
   */
  async delete(id: string): Promise<void> {
    const deleteExisting = this.intervals.get(`scheduled-${id}`);
    if (deleteExisting) {
      clearInterval(deleteExisting);
      this.intervals.delete(`scheduled-${id}`);
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
      const updateExisting = this.intervals.get(`scheduled-${id}`);
      if (updateExisting) {
        clearInterval(updateExisting);
        this.intervals.delete(`scheduled-${id}`);
      }

      if (job?.isRecurring && job?.cronExpression && job?.status === "active") {
        this.registerRecurringJob(job);
      }
    }

    return job;
  }
}
