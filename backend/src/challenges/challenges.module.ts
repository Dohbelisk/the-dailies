import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChallengesService } from './challenges.service';
import { ChallengesController } from './challenges.controller';
import { Challenge, ChallengeSchema } from './schemas/challenge.schema';
import { PuzzlesModule } from '../puzzles/puzzles.module';
import { UsersModule } from '../users/users.module';
import { FriendsModule } from '../friends/friends.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Challenge.name, schema: ChallengeSchema },
    ]),
    PuzzlesModule,
    UsersModule,
    FriendsModule,
  ],
  controllers: [ChallengesController],
  providers: [ChallengesService],
  exports: [ChallengesService],
})
export class ChallengesModule {}
