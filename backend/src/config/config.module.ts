import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AppConfigService } from './config.service';
import { ConfigController } from './config.controller';
import { AppConfig, AppConfigSchema } from './schemas/app-config.schema';
import { FeatureFlag, FeatureFlagSchema } from './schemas/feature-flag.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AppConfig.name, schema: AppConfigSchema },
      { name: FeatureFlag.name, schema: FeatureFlagSchema },
    ]),
  ],
  controllers: [ConfigController],
  providers: [AppConfigService],
  exports: [AppConfigService],
})
export class AppConfigModule {}
