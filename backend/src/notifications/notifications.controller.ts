import {
  Controller,
  Post,
  Body,
  UseGuards,
  Get,
  Patch,
  Delete,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  Request,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiBody,
  ApiQuery,
} from "@nestjs/swagger";
import {
  IsString,
  IsOptional,
  IsArray,
  IsEnum,
  IsBoolean,
  IsDateString,
  MaxLength,
  ArrayMaxSize,
} from "class-validator";
import { NotificationsService } from "./notifications.service";
import { NotificationSchedulerService } from "./notification-scheduler.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { AdminGuard } from "../auth/guards/admin.guard";

// --- DTOs ---

class SendToTopicDto {
  @IsString()
  topic: string;

  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsOptional()
  data?: Record<string, string>;
}

class SendToDeviceDto {
  @IsString()
  token: string;

  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsOptional()
  data?: Record<string, string>;
}

class SendToMultipleDto {
  @IsArray()
  @IsString({ each: true })
  tokens: string[];

  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsOptional()
  data?: Record<string, string>;
}

class SendWithTagsDto {
  @IsString()
  @MaxLength(100)
  title: string;

  @IsString()
  @MaxLength(500)
  body: string;

  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(5)
  tags: string[];

  @IsEnum(["AND", "OR"])
  @IsOptional()
  tagLogic?: "AND" | "OR" = "OR";

  @IsOptional()
  data?: Record<string, string>;
}

class CreateScheduledDto {
  @IsString()
  @MaxLength(100)
  title: string;

  @IsString()
  @MaxLength(500)
  body: string;

  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(5)
  @IsOptional()
  tags?: string[] = [];

  @IsEnum(["AND", "OR"])
  @IsOptional()
  tagLogic?: "AND" | "OR" = "OR";

  @IsDateString()
  @IsOptional()
  scheduledAt?: string;

  @IsString()
  @IsOptional()
  cronExpression?: string;

  @IsBoolean()
  @IsOptional()
  isRecurring?: boolean = false;

  @IsOptional()
  data?: Record<string, string>;
}

class UpdateScheduledDto {
  @IsString()
  @IsOptional()
  @MaxLength(100)
  title?: string;

  @IsString()
  @IsOptional()
  @MaxLength(500)
  body?: string;

  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(5)
  @IsOptional()
  tags?: string[];

  @IsEnum(["AND", "OR"])
  @IsOptional()
  tagLogic?: "AND" | "OR";

  @IsDateString()
  @IsOptional()
  scheduledAt?: string;

  @IsString()
  @IsOptional()
  cronExpression?: string;

  @IsBoolean()
  @IsOptional()
  isRecurring?: boolean;

  @IsEnum(["active", "paused", "cancelled"])
  @IsOptional()
  status?: string;

  @IsOptional()
  data?: Record<string, string>;
}

class RegisterDeviceDto {
  @IsString()
  fcmToken: string;

  @IsEnum(["ios", "android"])
  platform: "ios" | "android";

  @IsString()
  @IsOptional()
  appVersion?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[] = [];
}

// --- Controller ---

@ApiTags("notifications")
@Controller("notifications")
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly schedulerService: NotificationSchedulerService,
  ) {}

  // ==================== STATUS ====================

  @Get("status")
  @ApiOperation({ summary: "Check if push notifications are enabled" })
  getStatus() {
    return {
      enabled: this.notificationsService.isEnabled(),
    };
  }

  // ==================== SEND ENDPOINTS ====================

  @Post("send/topic")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Send notification to a topic (Admin only)" })
  @ApiBody({ type: SendToTopicDto })
  async sendToTopic(@Body() dto: SendToTopicDto) {
    const success = await this.notificationsService.sendToTopic({
      topic: dto.topic,
      title: dto.title,
      body: dto.body,
      data: dto.data,
    });
    return { success };
  }

  @Post("send/device")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Send notification to a specific device (Admin only)",
  })
  @ApiBody({ type: SendToDeviceDto })
  async sendToDevice(@Body() dto: SendToDeviceDto) {
    const success = await this.notificationsService.sendToDevice({
      token: dto.token,
      title: dto.title,
      body: dto.body,
      data: dto.data,
    });
    return { success };
  }

  @Post("send/multiple")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Send notification to multiple devices (Admin only)",
  })
  @ApiBody({ type: SendToMultipleDto })
  async sendToMultiple(@Body() dto: SendToMultipleDto) {
    const result = await this.notificationsService.sendToMultipleDevices({
      tokens: dto.tokens,
      title: dto.title,
      body: dto.body,
      data: dto.data,
    });
    return result;
  }

  @Post("send/daily-reminder")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Send daily puzzle reminder to all subscribers (Admin only)",
  })
  async sendDailyReminder() {
    const success = await this.notificationsService.sendDailyPuzzleReminder();
    return { success };
  }

  @Post("send/tags")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Send notification to tag-based audience (Admin only)",
  })
  @ApiBody({ type: SendWithTagsDto })
  async sendWithTags(@Body() dto: SendWithTagsDto) {
    const result = await this.notificationsService.sendWithTags(
      dto.tags,
      dto.tagLogic || "OR",
      dto.title,
      dto.body,
      dto.data,
    );
    return result;
  }

  // ==================== HISTORY & STATS ====================

  @Get("history")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Get notification history (Admin only)" })
  @ApiQuery({ name: "page", required: false })
  @ApiQuery({ name: "limit", required: false })
  async getHistory(
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.notificationsService.getHistory(
      parseInt(page) || 1,
      parseInt(limit) || 20,
    );
  }

  @Get("stats")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Get notification dashboard stats (Admin only)" })
  async getStats() {
    return this.notificationsService.getStats();
  }

  @Get("tags")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Get all tags with subscriber counts (Admin only)" })
  async getTags() {
    return this.notificationsService.getTagList();
  }

  // ==================== SCHEDULING ====================

  @Post("schedule")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Create scheduled notification (Admin only)" })
  @ApiBody({ type: CreateScheduledDto })
  async createScheduled(@Body() dto: CreateScheduledDto) {
    return this.schedulerService.create({
      title: dto.title,
      body: dto.body,
      tags: dto.tags || [],
      tagLogic: dto.tagLogic || "OR",
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
      cronExpression: dto.cronExpression,
      isRecurring: dto.isRecurring || false,
      data: dto.data,
    });
  }

  @Get("schedule")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "List scheduled notifications (Admin only)" })
  @ApiQuery({ name: "status", required: false })
  @ApiQuery({ name: "page", required: false })
  @ApiQuery({ name: "limit", required: false })
  async listScheduled(
    @Query("status") status?: string,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.schedulerService.list(
      status,
      parseInt(page) || 1,
      parseInt(limit) || 20,
    );
  }

  @Patch("schedule/:id")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Update scheduled notification (Admin only)" })
  async updateScheduled(
    @Param("id") id: string,
    @Body() dto: UpdateScheduledDto,
  ) {
    // Handle status changes via dedicated methods
    if (dto.status === "paused") {
      return this.schedulerService.pause(id);
    }
    if (dto.status === "active") {
      return this.schedulerService.resume(id);
    }
    if (dto.status === "cancelled") {
      return this.schedulerService.cancel(id);
    }

    return this.schedulerService.update(id, {
      ...dto,
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
    } as any);
  }

  @Delete("schedule/:id")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: "Delete scheduled notification (Admin only)" })
  async deleteScheduled(@Param("id") id: string) {
    await this.schedulerService.delete(id);
  }

  // ==================== DEVICE REGISTRATION ====================

  @Post("device/register")
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Register device for push notifications" })
  @ApiBody({ type: RegisterDeviceDto })
  async registerDevice(@Request() req, @Body() dto: RegisterDeviceDto) {
    const userId = req.user.userId;
    return this.notificationsService.registerDevice(
      userId,
      dto.fcmToken,
      dto.platform,
      dto.appVersion || "",
      dto.tags || [],
    );
  }
}
