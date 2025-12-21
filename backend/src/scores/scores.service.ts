import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { Score, ScoreDocument } from "./schemas/score.schema";

export class CreateScoreDto {
  puzzleId: string;
  userId?: string;
  deviceId?: string;
  time: number;
  score: number;
  mistakes?: number;
  hintsUsed?: number;
}

@Injectable()
export class ScoresService {
  constructor(
    @InjectModel(Score.name) private scoreModel: Model<ScoreDocument>,
  ) {}

  async create(createScoreDto: CreateScoreDto): Promise<Score> {
    const score = new this.scoreModel({
      ...createScoreDto,
      puzzleId: new Types.ObjectId(createScoreDto.puzzleId),
      userId: createScoreDto.userId
        ? new Types.ObjectId(createScoreDto.userId)
        : undefined,
    });
    return score.save();
  }

  async findByPuzzle(puzzleId: string): Promise<Score[]> {
    return this.scoreModel
      .find({ puzzleId: new Types.ObjectId(puzzleId) })
      .sort({ score: -1 })
      .limit(100)
      .exec();
  }

  async findByUser(userId: string): Promise<Score[]> {
    return this.scoreModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .populate("puzzleId")
      .exec();
  }

  async findByDevice(deviceId: string): Promise<Score[]> {
    return this.scoreModel
      .find({ deviceId })
      .sort({ createdAt: -1 })
      .populate("puzzleId")
      .exec();
  }

  async getUserStats(userId?: string, deviceId?: string): Promise<any> {
    const filter: any = {};
    if (userId) {
      filter.userId = new Types.ObjectId(userId);
    } else if (deviceId) {
      filter.deviceId = deviceId;
    } else {
      return this.getEmptyStats();
    }

    const scores = await this.scoreModel
      .find(filter)
      .populate("puzzleId")
      .exec();

    if (scores.length === 0) {
      return this.getEmptyStats();
    }

    // Calculate stats
    const completedScores = scores.filter((s) => s.completed);
    const totalGamesPlayed = scores.length;
    const totalGamesWon = completedScores.length;
    const averageTime =
      completedScores.length > 0
        ? Math.round(
            completedScores.reduce((sum, s) => sum + s.time, 0) /
              completedScores.length,
          )
        : 0;

    // Count by game type
    const gameTypeCounts: Record<string, number> = {};
    scores.forEach((s) => {
      const puzzle = s.puzzleId as any;
      if (puzzle?.gameType) {
        gameTypeCounts[puzzle.gameType] =
          (gameTypeCounts[puzzle.gameType] || 0) + 1;
      }
    });

    // Calculate streak
    const { currentStreak, longestStreak } = await this.calculateStreak(filter);

    return {
      totalGamesPlayed,
      totalGamesWon,
      currentStreak,
      longestStreak,
      gameTypeCounts,
      averageTime,
    };
  }

  private async calculateStreak(
    filter: any,
  ): Promise<{ currentStreak: number; longestStreak: number }> {
    const scores = await this.scoreModel
      .find({ ...filter, completed: true })
      .sort({ createdAt: -1 })
      .exec();

    if (scores.length === 0) {
      return { currentStreak: 0, longestStreak: 0 };
    }

    // Get unique dates
    const dates = [
      ...new Set(
        scores.map((s) => {
          const date = new Date(s["createdAt"]);
          return `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
        }),
      ),
    ];

    let currentStreak = 0;
    let longestStreak = 0;
    let tempStreak = 1;

    const today = new Date();
    const todayStr = `${today.getFullYear()}-${today.getMonth()}-${today.getDate()}`;

    // Check if played today or yesterday
    if (dates[0] === todayStr) {
      currentStreak = 1;
    } else {
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = `${yesterday.getFullYear()}-${yesterday.getMonth()}-${yesterday.getDate()}`;
      if (dates[0] === yesterdayStr) {
        currentStreak = 1;
      }
    }

    // Calculate streaks
    for (let i = 1; i < dates.length; i++) {
      const prev = this.parseDate(dates[i - 1]);
      const curr = this.parseDate(dates[i]);
      const diffDays = Math.floor(
        (prev.getTime() - curr.getTime()) / (1000 * 60 * 60 * 24),
      );

      if (diffDays === 1) {
        tempStreak++;
        if (i <= currentStreak || currentStreak > 0) {
          currentStreak = tempStreak;
        }
      } else {
        longestStreak = Math.max(longestStreak, tempStreak);
        tempStreak = 1;
      }
    }

    longestStreak = Math.max(longestStreak, tempStreak, currentStreak);

    return { currentStreak, longestStreak };
  }

  private parseDate(dateStr: string): Date {
    const [year, month, day] = dateStr.split("-").map(Number);
    return new Date(year, month, day);
  }

  private getEmptyStats() {
    return {
      totalGamesPlayed: 0,
      totalGamesWon: 0,
      currentStreak: 0,
      longestStreak: 0,
      gameTypeCounts: {},
      averageTime: 0,
    };
  }

  async getLeaderboard(puzzleId: string, limit = 10): Promise<Score[]> {
    return this.scoreModel
      .find({ puzzleId: new Types.ObjectId(puzzleId), completed: true })
      .sort({ score: -1, time: 1 })
      .limit(limit)
      .populate("userId", "username")
      .exec();
  }
}
