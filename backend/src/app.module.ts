import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { MongooseModule } from "@nestjs/mongoose";
import { PuzzlesModule } from "./puzzles/puzzles.module";
import { ScoresModule } from "./scores/scores.module";
import { AuthModule } from "./auth/auth.module";
import { UsersModule } from "./users/users.module";
import { FriendsModule } from "./friends/friends.module";
import { ChallengesModule } from "./challenges/challenges.module";
import { EmailModule } from "./email/email.module";
import { FeedbackModule } from "./feedback/feedback.module";
import { AppConfigModule } from "./config/config.module";
import { DictionaryModule } from "./dictionary/dictionary.module";
import { GitHubModule } from "./github/github.module";
import { NotificationsModule } from "./notifications/notifications.module";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ".env",
    }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri:
          configService.get<string>("MONGODB_URI") ||
          "mongodb://localhost:27017/puzzle-daily",
      }),
      inject: [ConfigService],
    }),
    PuzzlesModule,
    ScoresModule,
    AuthModule,
    UsersModule,
    FriendsModule,
    ChallengesModule,
    EmailModule,
    FeedbackModule,
    AppConfigModule,
    DictionaryModule,
    GitHubModule,
    NotificationsModule,
  ],
})
export class AppModule {}
