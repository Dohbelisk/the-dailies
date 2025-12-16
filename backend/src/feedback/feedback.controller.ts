import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { FeedbackService } from './feedback.service';
import { CreateFeedbackDto, UpdateFeedbackDto, FeedbackQueryDto } from './dto/feedback.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@ApiTags('feedback')
@Controller('feedback')
export class FeedbackController {
  constructor(private readonly feedbackService: FeedbackService) {}

  // Public endpoint - no auth required (anonymous feedback allowed)
  @Post()
  @ApiOperation({ summary: 'Submit feedback (anonymous allowed)' })
  @ApiResponse({ status: 201, description: 'Feedback submitted successfully' })
  create(@Body() createFeedbackDto: CreateFeedbackDto) {
    return this.feedbackService.create(createFeedbackDto);
  }

  // Admin endpoints below

  @Get()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all feedback with filters (Admin only)' })
  @ApiResponse({ status: 200, description: 'Returns list of feedback' })
  findAll(@Query() query: FeedbackQueryDto) {
    return this.feedbackService.findAll(query);
  }

  @Get('stats')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get feedback statistics (Admin only)' })
  @ApiResponse({ status: 200, description: 'Returns feedback statistics' })
  getStats() {
    return this.feedbackService.getStats();
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get feedback by ID (Admin only)' })
  @ApiResponse({ status: 200, description: 'Returns the feedback item' })
  @ApiResponse({ status: 404, description: 'Feedback not found' })
  findOne(@Param('id') id: string) {
    return this.feedbackService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update feedback status/notes (Admin only)' })
  @ApiResponse({ status: 200, description: 'Feedback updated successfully' })
  @ApiResponse({ status: 404, description: 'Feedback not found' })
  update(@Param('id') id: string, @Body() updateFeedbackDto: UpdateFeedbackDto) {
    return this.feedbackService.update(id, updateFeedbackDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete feedback (Admin only)' })
  @ApiResponse({ status: 200, description: 'Feedback deleted successfully' })
  @ApiResponse({ status: 404, description: 'Feedback not found' })
  remove(@Param('id') id: string) {
    return this.feedbackService.remove(id);
  }
}
