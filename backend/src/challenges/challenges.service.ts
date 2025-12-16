import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Challenge, ChallengeDocument, ChallengeStatus, GameType, Difficulty } from './schemas/challenge.schema';
import { CreateChallengeDto, SubmitChallengeResultDto, ChallengeResponseDto, ChallengeStatsDto } from './dto/challenge.dto';
import { PuzzlesService } from '../puzzles/puzzles.service';
import { UsersService } from '../users/users.service';
import { FriendsService } from '../friends/friends.service';

@Injectable()
export class ChallengesService {
  constructor(
    @InjectModel(Challenge.name) private challengeModel: Model<ChallengeDocument>,
    private puzzlesService: PuzzlesService,
    private usersService: UsersService,
    private friendsService: FriendsService,
  ) {}

  /**
   * Create a new challenge
   */
  async createChallenge(challengerId: string, dto: CreateChallengeDto): Promise<ChallengeResponseDto> {
    // Verify opponent exists
    const opponent = await this.usersService.findById(dto.opponentId);
    if (!opponent) {
      throw new NotFoundException('Opponent not found');
    }

    // Verify they are friends
    const areFriends = await this.friendsService.areFriends(challengerId, dto.opponentId);
    if (!areFriends) {
      throw new ForbiddenException('You can only challenge friends');
    }

    // Check for existing pending challenge between these users
    const existingChallenge = await this.challengeModel.findOne({
      $or: [
        { challengerId: new Types.ObjectId(challengerId), opponentId: new Types.ObjectId(dto.opponentId) },
        { challengerId: new Types.ObjectId(dto.opponentId), opponentId: new Types.ObjectId(challengerId) },
      ],
      status: { $in: [ChallengeStatus.PENDING, ChallengeStatus.ACCEPTED] },
    });

    if (existingChallenge) {
      throw new BadRequestException('There is already an active challenge between you and this friend');
    }

    // Find a suitable puzzle for the challenge
    const puzzle = await this.findPuzzleForChallenge(dto.gameType, dto.difficulty);

    // Set expiry to 24 hours from now
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const challenge = new this.challengeModel({
      challengerId: new Types.ObjectId(challengerId),
      opponentId: new Types.ObjectId(dto.opponentId),
      puzzleId: puzzle._id,
      gameType: dto.gameType,
      difficulty: dto.difficulty,
      status: ChallengeStatus.PENDING,
      message: dto.message,
      expiresAt,
    });

    const saved = await challenge.save();
    return this.toChallengeResponse(saved);
  }

  /**
   * Find a random puzzle for the challenge
   */
  private async findPuzzleForChallenge(gameType: GameType, difficulty: Difficulty): Promise<any> {
    // Get puzzles of the specified type and difficulty
    const puzzles = await this.puzzlesService.findAll({
      gameType: gameType as any,
      difficulty: difficulty as any,
      isActive: true,
    });

    if (puzzles.length === 0) {
      throw new NotFoundException(`No puzzles available for ${gameType} ${difficulty}`);
    }

    // Select a random puzzle
    const randomIndex = Math.floor(Math.random() * puzzles.length);
    return puzzles[randomIndex];
  }

  /**
   * Accept a challenge
   */
  async acceptChallenge(userId: string, challengeId: string): Promise<ChallengeResponseDto> {
    const challenge = await this.findChallengeById(challengeId);

    if (challenge.opponentId.toString() !== userId) {
      throw new ForbiddenException('You are not the opponent of this challenge');
    }

    if (challenge.status !== ChallengeStatus.PENDING) {
      throw new BadRequestException(`Challenge is not pending (current status: ${challenge.status})`);
    }

    // Check if expired
    if (new Date() > challenge.expiresAt) {
      challenge.status = ChallengeStatus.EXPIRED;
      await challenge.save();
      throw new BadRequestException('This challenge has expired');
    }

    challenge.status = ChallengeStatus.ACCEPTED;
    const saved = await challenge.save();
    return this.toChallengeResponse(saved);
  }

  /**
   * Decline a challenge
   */
  async declineChallenge(userId: string, challengeId: string): Promise<ChallengeResponseDto> {
    const challenge = await this.findChallengeById(challengeId);

    if (challenge.opponentId.toString() !== userId) {
      throw new ForbiddenException('You are not the opponent of this challenge');
    }

    if (challenge.status !== ChallengeStatus.PENDING) {
      throw new BadRequestException(`Challenge is not pending (current status: ${challenge.status})`);
    }

    challenge.status = ChallengeStatus.DECLINED;
    const saved = await challenge.save();
    return this.toChallengeResponse(saved);
  }

  /**
   * Cancel a challenge (by challenger)
   */
  async cancelChallenge(userId: string, challengeId: string): Promise<ChallengeResponseDto> {
    const challenge = await this.findChallengeById(challengeId);

    if (challenge.challengerId.toString() !== userId) {
      throw new ForbiddenException('You are not the challenger');
    }

    if (challenge.status !== ChallengeStatus.PENDING) {
      throw new BadRequestException(`Can only cancel pending challenges (current status: ${challenge.status})`);
    }

    challenge.status = ChallengeStatus.CANCELLED;
    const saved = await challenge.save();
    return this.toChallengeResponse(saved);
  }

  /**
   * Submit challenge result
   */
  async submitResult(userId: string, dto: SubmitChallengeResultDto): Promise<ChallengeResponseDto> {
    const challenge = await this.findChallengeById(dto.challengeId);

    if (challenge.status !== ChallengeStatus.ACCEPTED) {
      throw new BadRequestException(`Cannot submit result for challenge with status: ${challenge.status}`);
    }

    const isChallenger = challenge.challengerId.toString() === userId;
    const isOpponent = challenge.opponentId.toString() === userId;

    if (!isChallenger && !isOpponent) {
      throw new ForbiddenException('You are not a participant in this challenge');
    }

    // Update the appropriate player's result
    if (isChallenger) {
      if (challenge.challengerCompleted) {
        throw new BadRequestException('You have already submitted your result');
      }
      challenge.challengerScore = dto.score;
      challenge.challengerTime = dto.time;
      challenge.challengerMistakes = dto.mistakes;
      challenge.challengerCompleted = true;
    } else {
      if (challenge.opponentCompleted) {
        throw new BadRequestException('You have already submitted your result');
      }
      challenge.opponentScore = dto.score;
      challenge.opponentTime = dto.time;
      challenge.opponentMistakes = dto.mistakes;
      challenge.opponentCompleted = true;
    }

    // Check if both players have completed
    if (challenge.challengerCompleted && challenge.opponentCompleted) {
      challenge.status = ChallengeStatus.COMPLETED;

      // Determine winner (higher score wins, time is tiebreaker)
      if (challenge.challengerScore > challenge.opponentScore) {
        challenge.winnerId = challenge.challengerId;
      } else if (challenge.opponentScore > challenge.challengerScore) {
        challenge.winnerId = challenge.opponentId;
      } else {
        // Tie on score, use time (lower is better)
        if (challenge.challengerTime < challenge.opponentTime) {
          challenge.winnerId = challenge.challengerId;
        } else if (challenge.opponentTime < challenge.challengerTime) {
          challenge.winnerId = challenge.opponentId;
        }
        // If still tied, winnerId remains null (tie)
      }
    }

    const saved = await challenge.save();
    return this.toChallengeResponse(saved);
  }

  /**
   * Get challenges for a user
   */
  async getChallenges(userId: string, status?: ChallengeStatus): Promise<ChallengeResponseDto[]> {
    const query: any = {
      $or: [
        { challengerId: new Types.ObjectId(userId) },
        { opponentId: new Types.ObjectId(userId) },
      ],
    };

    if (status) {
      query.status = status;
    }

    const challenges = await this.challengeModel
      .find(query)
      .sort({ createdAt: -1 })
      .exec();

    return Promise.all(challenges.map(c => this.toChallengeResponse(c)));
  }

  /**
   * Get pending challenges (received)
   */
  async getPendingChallenges(userId: string): Promise<ChallengeResponseDto[]> {
    const challenges = await this.challengeModel
      .find({
        opponentId: new Types.ObjectId(userId),
        status: ChallengeStatus.PENDING,
        expiresAt: { $gt: new Date() },
      })
      .sort({ createdAt: -1 })
      .exec();

    return Promise.all(challenges.map(c => this.toChallengeResponse(c)));
  }

  /**
   * Get active challenges (in progress)
   */
  async getActiveChallenges(userId: string): Promise<ChallengeResponseDto[]> {
    const challenges = await this.challengeModel
      .find({
        $or: [
          { challengerId: new Types.ObjectId(userId) },
          { opponentId: new Types.ObjectId(userId) },
        ],
        status: ChallengeStatus.ACCEPTED,
      })
      .sort({ createdAt: -1 })
      .exec();

    return Promise.all(challenges.map(c => this.toChallengeResponse(c)));
  }

  /**
   * Get challenge by ID
   */
  async getChallenge(userId: string, challengeId: string): Promise<ChallengeResponseDto> {
    const challenge = await this.findChallengeById(challengeId);

    // Verify user is a participant
    const isParticipant =
      challenge.challengerId.toString() === userId ||
      challenge.opponentId.toString() === userId;

    if (!isParticipant) {
      throw new ForbiddenException('You are not a participant in this challenge');
    }

    return this.toChallengeResponse(challenge);
  }

  /**
   * Get challenge stats for a user
   */
  async getChallengeStats(userId: string): Promise<ChallengeStatsDto> {
    const userObjectId = new Types.ObjectId(userId);

    const [stats] = await this.challengeModel.aggregate([
      {
        $match: {
          $or: [
            { challengerId: userObjectId },
            { opponentId: userObjectId },
          ],
        },
      },
      {
        $group: {
          _id: null,
          totalChallenges: { $sum: 1 },
          completed: {
            $sum: { $cond: [{ $eq: ['$status', ChallengeStatus.COMPLETED] }, 1, 0] },
          },
          pending: {
            $sum: {
              $cond: [
                { $in: ['$status', [ChallengeStatus.PENDING, ChallengeStatus.ACCEPTED]] },
                1,
                0,
              ],
            },
          },
          wins: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$status', ChallengeStatus.COMPLETED] },
                    { $eq: ['$winnerId', userObjectId] },
                  ],
                },
                1,
                0,
              ],
            },
          },
          losses: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$status', ChallengeStatus.COMPLETED] },
                    { $ne: ['$winnerId', null] },
                    { $ne: ['$winnerId', userObjectId] },
                  ],
                },
                1,
                0,
              ],
            },
          },
          ties: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$status', ChallengeStatus.COMPLETED] },
                    { $eq: ['$winnerId', null] },
                  ],
                },
                1,
                0,
              ],
            },
          },
        },
      },
    ]);

    const result = stats || {
      totalChallenges: 0,
      completed: 0,
      pending: 0,
      wins: 0,
      losses: 0,
      ties: 0,
    };

    return {
      totalChallenges: result.totalChallenges,
      wins: result.wins,
      losses: result.losses,
      ties: result.ties,
      pending: result.pending,
      winRate: result.completed > 0 ? Math.round((result.wins / result.completed) * 100) : 0,
    };
  }

  /**
   * Get challenge stats between two users
   */
  async getChallengeStatsBetweenUsers(userId: string, friendId: string): Promise<ChallengeStatsDto> {
    const userObjectId = new Types.ObjectId(userId);
    const friendObjectId = new Types.ObjectId(friendId);

    const [stats] = await this.challengeModel.aggregate([
      {
        $match: {
          $or: [
            { challengerId: userObjectId, opponentId: friendObjectId },
            { challengerId: friendObjectId, opponentId: userObjectId },
          ],
        },
      },
      {
        $group: {
          _id: null,
          totalChallenges: { $sum: 1 },
          completed: {
            $sum: { $cond: [{ $eq: ['$status', ChallengeStatus.COMPLETED] }, 1, 0] },
          },
          pending: {
            $sum: {
              $cond: [
                { $in: ['$status', [ChallengeStatus.PENDING, ChallengeStatus.ACCEPTED]] },
                1,
                0,
              ],
            },
          },
          wins: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$status', ChallengeStatus.COMPLETED] },
                    { $eq: ['$winnerId', userObjectId] },
                  ],
                },
                1,
                0,
              ],
            },
          },
          losses: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$status', ChallengeStatus.COMPLETED] },
                    { $eq: ['$winnerId', friendObjectId] },
                  ],
                },
                1,
                0,
              ],
            },
          },
          ties: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$status', ChallengeStatus.COMPLETED] },
                    { $eq: ['$winnerId', null] },
                  ],
                },
                1,
                0,
              ],
            },
          },
        },
      },
    ]);

    const result = stats || {
      totalChallenges: 0,
      completed: 0,
      pending: 0,
      wins: 0,
      losses: 0,
      ties: 0,
    };

    return {
      totalChallenges: result.totalChallenges,
      wins: result.wins,
      losses: result.losses,
      ties: result.ties,
      pending: result.pending,
      winRate: result.completed > 0 ? Math.round((result.wins / result.completed) * 100) : 0,
    };
  }

  /**
   * Helper: Find challenge by ID
   */
  private async findChallengeById(id: string): Promise<ChallengeDocument> {
    const challenge = await this.challengeModel.findById(id).exec();
    if (!challenge) {
      throw new NotFoundException(`Challenge with ID ${id} not found`);
    }
    return challenge;
  }

  /**
   * Helper: Convert challenge document to response DTO
   */
  private async toChallengeResponse(challenge: ChallengeDocument): Promise<ChallengeResponseDto> {
    const challenger = await this.usersService.findById(challenge.challengerId.toString());
    const opponent = await this.usersService.findById(challenge.opponentId.toString());

    let winnerUsername: string | undefined;
    if (challenge.winnerId) {
      const winner = await this.usersService.findById(challenge.winnerId.toString());
      winnerUsername = winner?.username;
    }

    return {
      id: (challenge as any)._id.toString(),
      challengerId: challenge.challengerId.toString(),
      challengerUsername: challenger?.username || 'Unknown',
      opponentId: challenge.opponentId.toString(),
      opponentUsername: opponent?.username || 'Unknown',
      puzzleId: challenge.puzzleId.toString(),
      gameType: challenge.gameType,
      difficulty: challenge.difficulty,
      status: challenge.status,
      challengerScore: challenge.challengerScore,
      challengerTime: challenge.challengerTime,
      challengerCompleted: challenge.challengerCompleted,
      opponentScore: challenge.opponentScore,
      opponentTime: challenge.opponentTime,
      opponentCompleted: challenge.opponentCompleted,
      winnerId: challenge.winnerId?.toString(),
      winnerUsername,
      message: challenge.message,
      expiresAt: challenge.expiresAt,
      createdAt: (challenge as any).createdAt,
    };
  }
}
