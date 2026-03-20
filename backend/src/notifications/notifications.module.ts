import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { NotificationsService } from "./notifications.service";
import { NotificationsController } from "./notifications.controller";
import { NotificationSchedulerService } from "./notification-scheduler.service";
import {
  NotificationLog,
  NotificationLogSchema,
} from "./schemas/notification-log.schema";
import {
  ScheduledNotification,
  ScheduledNotificationSchema,
} from "./schemas/scheduled-notification.schema";
import {
  DeviceRegistration,
  DeviceRegistrationSchema,
} from "./schemas/device-registration.schema";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: NotificationLog.name, schema: NotificationLogSchema },
      {
        name: ScheduledNotification.name,
        schema: ScheduledNotificationSchema,
      },
      { name: DeviceRegistration.name, schema: DeviceRegistrationSchema },
    ]),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationSchedulerService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
