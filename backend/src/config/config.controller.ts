import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AppConfigService } from './config.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import {
  UpdateAppConfigDto,
  CreateFeatureFlagDto,
  UpdateFeatureFlagDto,
  FeatureFlagsQueryDto,
} from './dto/config.dto';

@ApiTags('config')
@Controller('config')
export class ConfigController {
  constructor(private readonly configService: AppConfigService) {}

  // ============ Public Endpoints ============

  @Get()
  @ApiOperation({ summary: 'Get app configuration (versions, maintenance status)' })
  async getAppConfig() {
    const config = await this.configService.getAppConfig();
    return {
      latestVersion: config.latestVersion,
      minVersion: config.minVersion,
      updateUrl: config.updateUrl,
      updateMessage: config.updateMessage,
      forceUpdateMessage: config.forceUpdateMessage,
      maintenanceMode: config.maintenanceMode,
      maintenanceMessage: config.maintenanceMessage,
    };
  }

  @Get('feature-flags')
  @ApiOperation({ summary: 'Get feature flags for client' })
  @ApiQuery({ name: 'appVersion', required: false })
  @ApiQuery({ name: 'userId', required: false })
  async getFeatureFlags(@Query() query: FeatureFlagsQueryDto) {
    const flags = await this.configService.getFeatureFlagsForClient(
      query.appVersion,
      query.userId,
    );
    return { flags };
  }

  @Get('feature-flags/:key')
  @ApiOperation({ summary: 'Check if a specific feature is enabled' })
  @ApiQuery({ name: 'appVersion', required: false })
  @ApiQuery({ name: 'userId', required: false })
  async checkFeatureFlag(
    @Param('key') key: string,
    @Query() query: FeatureFlagsQueryDto,
  ) {
    const enabled = await this.configService.isFeatureEnabled(
      key,
      query.appVersion,
      query.userId,
    );
    return { key, enabled };
  }

  // ============ Admin Endpoints ============

  @Patch()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update app configuration (admin only)' })
  async updateAppConfig(@Body() updateDto: UpdateAppConfigDto) {
    return this.configService.updateAppConfig(updateDto);
  }

  @Get('admin/feature-flags')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all feature flags with full details (admin only)' })
  async getAllFeatureFlags() {
    return this.configService.getAllFeatureFlags();
  }

  @Post('feature-flags')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new feature flag (admin only)' })
  async createFeatureFlag(@Body() createDto: CreateFeatureFlagDto) {
    return this.configService.createFeatureFlag(createDto);
  }

  @Patch('feature-flags/:key')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a feature flag (admin only)' })
  async updateFeatureFlag(
    @Param('key') key: string,
    @Body() updateDto: UpdateFeatureFlagDto,
  ) {
    return this.configService.updateFeatureFlag(key, updateDto);
  }

  @Delete('feature-flags/:key')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a feature flag (admin only)' })
  async deleteFeatureFlag(@Param('key') key: string) {
    await this.configService.deleteFeatureFlag(key);
  }

  @Post('seed-defaults')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Seed default feature flags (admin only)' })
  async seedDefaults() {
    await this.configService.seedDefaultFlags();
    return { message: 'Default feature flags seeded successfully' };
  }
}
