import { Controller, Get, Post, Body, Param, Query, Headers } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiHeader } from '@nestjs/swagger';
import { ScoresService, CreateScoreDto } from './scores.service';

@ApiTags('scores')
@Controller('scores')
export class ScoresController {
  constructor(private readonly scoresService: ScoresService) {}

  @Post()
  @ApiOperation({ summary: 'Submit a score' })
  @ApiHeader({ name: 'x-device-id', description: 'Device identifier', required: false })
  create(
    @Body() createScoreDto: CreateScoreDto,
    @Headers('x-device-id') deviceId?: string,
  ) {
    return this.scoresService.create({
      ...createScoreDto,
      deviceId: deviceId || createScoreDto.deviceId,
    });
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get user statistics' })
  @ApiHeader({ name: 'x-device-id', description: 'Device identifier', required: false })
  getStats(
    @Query('userId') userId?: string,
    @Headers('x-device-id') deviceId?: string,
  ) {
    return this.scoresService.getUserStats(userId, deviceId);
  }

  @Get('puzzle/:puzzleId')
  @ApiOperation({ summary: 'Get scores for a puzzle' })
  findByPuzzle(@Param('puzzleId') puzzleId: string) {
    return this.scoresService.findByPuzzle(puzzleId);
  }

  @Get('leaderboard/:puzzleId')
  @ApiOperation({ summary: 'Get leaderboard for a puzzle' })
  getLeaderboard(
    @Param('puzzleId') puzzleId: string,
    @Query('limit') limit?: number,
  ) {
    return this.scoresService.getLeaderboard(puzzleId, limit);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get scores for a user' })
  findByUser(@Param('userId') userId: string) {
    return this.scoresService.findByUser(userId);
  }

  @Get('device/:deviceId')
  @ApiOperation({ summary: 'Get scores for a device' })
  findByDevice(@Param('deviceId') deviceId: string) {
    return this.scoresService.findByDevice(deviceId);
  }
}
