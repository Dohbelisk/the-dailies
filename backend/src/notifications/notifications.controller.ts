import {
  Controller,
  Post,
  Body,
  UseGuards,
  Get,
  HttpCode,
  HttpStatus,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth, ApiBody } from "@nestjs/swagger";
import { IsString, IsOptional, IsArray } from "class-validator";
import { NotificationsService } from "./notifications.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { AdminGuard } from "../auth/guards/admin.guard";

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

@ApiTags("notifications")
@Controller("notifications")
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get("status")
  @ApiOperation({ summary: "Check if push notifications are enabled" })
  getStatus() {
    return {
      enabled: this.notificationsService.isEnabled(),
    };
  }

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
}
