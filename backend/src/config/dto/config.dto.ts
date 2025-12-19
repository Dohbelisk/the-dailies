import { IsString, IsBoolean, IsOptional, IsNumber, Min, Max, IsArray, IsDate } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class UpdateAppConfigDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  latestVersion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  minVersion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  updateUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  updateMessage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  forceUpdateMessage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  maintenanceMode?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  maintenanceMessage?: string;
}

export class CreateFeatureFlagDto {
  @ApiProperty({ example: 'challenges_enabled' })
  @IsString()
  key: string;

  @ApiProperty({ example: 'Challenges Feature' })
  @IsString()
  name: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({ example: '1.2.0' })
  @IsOptional()
  @IsString()
  minAppVersion?: string;

  @ApiPropertyOptional({ example: '2.0.0' })
  @IsOptional()
  @IsString()
  maxAppVersion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  enabledForUserIds?: string[];

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  rolloutPercentage?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  expiresAt?: Date;

  @ApiPropertyOptional()
  @IsOptional()
  metadata?: Record<string, any>;
}

export class UpdateFeatureFlagDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  minAppVersion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  maxAppVersion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  enabledForUserIds?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  rolloutPercentage?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  expiresAt?: Date;

  @ApiPropertyOptional()
  @IsOptional()
  metadata?: Record<string, any>;
}

// Response DTOs
export class AppConfigResponseDto {
  @ApiProperty()
  latestVersion: string;

  @ApiProperty()
  minVersion: string;

  @ApiProperty()
  updateUrl: string;

  @ApiProperty()
  updateMessage: string;

  @ApiProperty()
  forceUpdateMessage: string;

  @ApiProperty()
  maintenanceMode: boolean;

  @ApiProperty()
  maintenanceMessage: string;
}

export class FeatureFlagResponseDto {
  @ApiProperty()
  key: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  enabled: boolean;

  @ApiPropertyOptional()
  minAppVersion?: string;

  @ApiPropertyOptional()
  maxAppVersion?: string;

  @ApiPropertyOptional()
  metadata?: Record<string, any>;
}

export class FeatureFlagsQueryDto {
  @ApiPropertyOptional({ description: 'App version for filtering flags' })
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional({ description: 'User ID for personalized flags' })
  @IsOptional()
  @IsString()
  userId?: string;
}
