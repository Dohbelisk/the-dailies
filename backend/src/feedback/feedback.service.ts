import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import {
  Feedback,
  FeedbackDocument,
  FeedbackStatus,
} from "./schemas/feedback.schema";
import {
  CreateFeedbackDto,
  UpdateFeedbackDto,
  FeedbackQueryDto,
  FeedbackStatsDto,
} from "./dto/feedback.dto";
import { EmailService } from "../email/email.service";

@Injectable()
export class FeedbackService {
  constructor(
    @InjectModel(Feedback.name) private feedbackModel: Model<FeedbackDocument>,
    private readonly emailService: EmailService,
  ) {}

  async create(createFeedbackDto: CreateFeedbackDto): Promise<Feedback> {
    const feedback = new this.feedbackModel(createFeedbackDto);
    const saved = await feedback.save();

    // Send email notification asynchronously (don't await to not block response)
    this.emailService
      .sendFeedbackNotification({
        _id: saved._id.toString(),
        type: saved.type,
        message: saved.message,
        email: saved.email,
        puzzleId: saved.puzzleId,
        gameType: saved.gameType,
        difficulty: saved.difficulty,
        puzzleDate: saved.puzzleDate,
        deviceInfo: saved.deviceInfo,
        createdAt: (saved as any).createdAt,
      })
      .catch((error) => {
        console.error("Failed to send feedback notification:", error);
      });

    return saved;
  }

  async findAll(query: FeedbackQueryDto): Promise<Feedback[]> {
    const filter: any = {};

    if (query.type) {
      filter.type = query.type;
    }

    if (query.status) {
      filter.status = query.status;
    }

    if (query.puzzleId) {
      filter.puzzleId = query.puzzleId;
    }

    if (query.startDate || query.endDate) {
      filter.createdAt = {};
      if (query.startDate) {
        filter.createdAt.$gte = new Date(query.startDate);
      }
      if (query.endDate) {
        filter.createdAt.$lte = new Date(query.endDate);
      }
    }

    return this.feedbackModel.find(filter).sort({ createdAt: -1 }).exec();
  }

  async findOne(id: string): Promise<Feedback> {
    const feedback = await this.feedbackModel.findById(id).exec();
    if (!feedback) {
      throw new NotFoundException(`Feedback with ID ${id} not found`);
    }
    return feedback;
  }

  async update(
    id: string,
    updateFeedbackDto: UpdateFeedbackDto,
  ): Promise<Feedback> {
    const feedback = await this.feedbackModel
      .findByIdAndUpdate(id, updateFeedbackDto, { new: true })
      .exec();
    if (!feedback) {
      throw new NotFoundException(`Feedback with ID ${id} not found`);
    }
    return feedback;
  }

  async remove(id: string): Promise<void> {
    const result = await this.feedbackModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Feedback with ID ${id} not found`);
    }
  }

  async getStats(): Promise<FeedbackStatsDto> {
    const [total, byTypeResult, byStatusResult, newCount] = await Promise.all([
      this.feedbackModel.countDocuments().exec(),
      this.feedbackModel
        .aggregate([{ $group: { _id: "$type", count: { $sum: 1 } } }])
        .exec(),
      this.feedbackModel
        .aggregate([{ $group: { _id: "$status", count: { $sum: 1 } } }])
        .exec(),
      this.feedbackModel.countDocuments({ status: FeedbackStatus.NEW }).exec(),
    ]);

    const byType: Record<string, number> = {};
    byTypeResult.forEach((item: { _id: string; count: number }) => {
      byType[item._id] = item.count;
    });

    const byStatus: Record<string, number> = {};
    byStatusResult.forEach((item: { _id: string; count: number }) => {
      byStatus[item._id] = item.count;
    });

    return {
      total,
      byType,
      byStatus,
      newCount,
    };
  }
}
