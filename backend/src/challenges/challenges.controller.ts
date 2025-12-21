import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from "@nestjs/swagger";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { ChallengesService } from "./challenges.service";
import {
  CreateChallengeDto,
  SubmitChallengeResultDto,
  ChallengeResponseDto,
  ChallengeStatsDto,
} from "./dto/challenge.dto";
import { ChallengeStatus } from "./schemas/challenge.schema";

@ApiTags("challenges")
@Controller("challenges")
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChallengesController {
  constructor(private readonly challengesService: ChallengesService) {}

  @Post()
  @ApiOperation({ summary: "Create a new challenge" })
  @ApiResponse({
    status: 201,
    description: "Challenge created",
    type: ChallengeResponseDto,
  })
  async createChallenge(
    @Request() req,
    @Body() dto: CreateChallengeDto,
  ): Promise<ChallengeResponseDto> {
    return this.challengesService.createChallenge(req.user.userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "Get all challenges for current user" })
  @ApiQuery({ name: "status", required: false, enum: ChallengeStatus })
  @ApiResponse({
    status: 200,
    description: "List of challenges",
    type: [ChallengeResponseDto],
  })
  async getChallenges(
    @Request() req,
    @Query("status") status?: ChallengeStatus,
  ): Promise<ChallengeResponseDto[]> {
    return this.challengesService.getChallenges(req.user.userId, status);
  }

  @Get("pending")
  @ApiOperation({ summary: "Get pending challenges (received)" })
  @ApiResponse({
    status: 200,
    description: "List of pending challenges",
    type: [ChallengeResponseDto],
  })
  async getPendingChallenges(@Request() req): Promise<ChallengeResponseDto[]> {
    return this.challengesService.getPendingChallenges(req.user.userId);
  }

  @Get("active")
  @ApiOperation({ summary: "Get active challenges (in progress)" })
  @ApiResponse({
    status: 200,
    description: "List of active challenges",
    type: [ChallengeResponseDto],
  })
  async getActiveChallenges(@Request() req): Promise<ChallengeResponseDto[]> {
    return this.challengesService.getActiveChallenges(req.user.userId);
  }

  @Get("stats")
  @ApiOperation({ summary: "Get challenge stats for current user" })
  @ApiResponse({
    status: 200,
    description: "Challenge statistics",
    type: ChallengeStatsDto,
  })
  async getStats(@Request() req): Promise<ChallengeStatsDto> {
    return this.challengesService.getChallengeStats(req.user.userId);
  }

  @Get("stats/:friendId")
  @ApiOperation({
    summary: "Get challenge stats between current user and a friend",
  })
  @ApiResponse({
    status: 200,
    description: "Challenge statistics with friend",
    type: ChallengeStatsDto,
  })
  async getStatsWith(
    @Request() req,
    @Param("friendId") friendId: string,
  ): Promise<ChallengeStatsDto> {
    return this.challengesService.getChallengeStatsBetweenUsers(
      req.user.userId,
      friendId,
    );
  }

  @Get(":id")
  @ApiOperation({ summary: "Get a specific challenge" })
  @ApiResponse({
    status: 200,
    description: "Challenge details",
    type: ChallengeResponseDto,
  })
  async getChallenge(
    @Request() req,
    @Param("id") id: string,
  ): Promise<ChallengeResponseDto> {
    return this.challengesService.getChallenge(req.user.userId, id);
  }

  @Post(":id/accept")
  @ApiOperation({ summary: "Accept a challenge" })
  @ApiResponse({
    status: 200,
    description: "Challenge accepted",
    type: ChallengeResponseDto,
  })
  async acceptChallenge(
    @Request() req,
    @Param("id") id: string,
  ): Promise<ChallengeResponseDto> {
    return this.challengesService.acceptChallenge(req.user.userId, id);
  }

  @Post(":id/decline")
  @ApiOperation({ summary: "Decline a challenge" })
  @ApiResponse({
    status: 200,
    description: "Challenge declined",
    type: ChallengeResponseDto,
  })
  async declineChallenge(
    @Request() req,
    @Param("id") id: string,
  ): Promise<ChallengeResponseDto> {
    return this.challengesService.declineChallenge(req.user.userId, id);
  }

  @Post(":id/cancel")
  @ApiOperation({ summary: "Cancel a challenge (challenger only)" })
  @ApiResponse({
    status: 200,
    description: "Challenge cancelled",
    type: ChallengeResponseDto,
  })
  async cancelChallenge(
    @Request() req,
    @Param("id") id: string,
  ): Promise<ChallengeResponseDto> {
    return this.challengesService.cancelChallenge(req.user.userId, id);
  }

  @Post("submit")
  @ApiOperation({ summary: "Submit challenge result" })
  @ApiResponse({
    status: 200,
    description: "Result submitted",
    type: ChallengeResponseDto,
  })
  async submitResult(
    @Request() req,
    @Body() dto: SubmitChallengeResultDto,
  ): Promise<ChallengeResponseDto> {
    return this.challengesService.submitResult(req.user.userId, dto);
  }
}
