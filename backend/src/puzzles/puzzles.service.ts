import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { Puzzle, PuzzleDocument, GameType } from "./schemas/puzzle.schema";
import {
  CreatePuzzleDto,
  UpdatePuzzleDto,
  PuzzleQueryDto,
} from "./dto/puzzle.dto";

@Injectable()
export class PuzzlesService {
  constructor(
    @InjectModel(Puzzle.name) private puzzleModel: Model<PuzzleDocument>,
  ) {}

  async create(createPuzzleDto: CreatePuzzleDto): Promise<Puzzle> {
    const puzzle = new this.puzzleModel({
      ...createPuzzleDto,
      date: new Date(createPuzzleDto.date),
    });
    return puzzle.save();
  }

  async findAll(query: PuzzleQueryDto): Promise<Puzzle[]> {
    const filter: any = {};

    if (query.gameType) {
      filter.gameType = query.gameType;
    }

    if (query.difficulty) {
      filter.difficulty = query.difficulty;
    }

    if (query.isActive !== undefined) {
      filter.isActive = query.isActive;
    }

    if (query.startDate || query.endDate) {
      filter.date = {};
      if (query.startDate) {
        filter.date.$gte = new Date(query.startDate);
      }
      if (query.endDate) {
        filter.date.$lte = new Date(query.endDate);
      }
    }

    return this.puzzleModel.find(filter).sort({ date: -1 }).exec();
  }

  async findOne(id: string): Promise<Puzzle> {
    const puzzle = await this.puzzleModel.findById(id).exec();
    if (!puzzle) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }
    return puzzle;
  }

  async findTodaysPuzzles(): Promise<Puzzle[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return this.puzzleModel
      .find({
        date: { $gte: today, $lt: tomorrow },
        isActive: true,
      })
      .exec();
  }

  async findByTypeAndDate(gameType: GameType, date: string): Promise<Puzzle> {
    const targetDate = new Date(date);
    targetDate.setHours(0, 0, 0, 0);

    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);

    const puzzle = await this.puzzleModel
      .findOne({
        gameType,
        date: { $gte: targetDate, $lt: nextDay },
        isActive: true,
      })
      .exec();

    if (!puzzle) {
      throw new NotFoundException(`No ${gameType} puzzle found for ${date}`);
    }

    return puzzle;
  }

  async findByType(gameType: GameType): Promise<Puzzle[]> {
    return this.puzzleModel
      .find({ gameType, isActive: true })
      .sort({ date: -1 })
      .limit(30)
      .exec();
  }

  async update(id: string, updatePuzzleDto: UpdatePuzzleDto): Promise<Puzzle> {
    const updateData: any = { ...updatePuzzleDto };

    if (updatePuzzleDto.date) {
      updateData.date = new Date(updatePuzzleDto.date);
    }

    const puzzle = await this.puzzleModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .exec();

    if (!puzzle) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }

    return puzzle;
  }

  async remove(id: string): Promise<void> {
    const result = await this.puzzleModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }
  }

  async getStats(): Promise<any> {
    const stats = await this.puzzleModel.aggregate([
      {
        $group: {
          _id: "$gameType",
          count: { $sum: 1 },
          activeCount: {
            $sum: { $cond: ["$isActive", 1, 0] },
          },
        },
      },
    ]);

    const totalPuzzles = await this.puzzleModel.countDocuments();
    const todaysPuzzles = await this.findTodaysPuzzles();

    return {
      totalPuzzles,
      todaysPuzzlesCount: todaysPuzzles.length,
      byGameType: stats.reduce((acc, s) => {
        acc[s._id] = { total: s.count, active: s.activeCount };
        return acc;
      }, {}),
    };
  }

  // Bulk operations for admin
  async createMany(puzzles: CreatePuzzleDto[]): Promise<Puzzle[]> {
    const puzzleDocs = puzzles.map((p) => ({
      ...p,
      date: new Date(p.date),
      solution: p.solution || {},
    }));
    const created = await this.puzzleModel.insertMany(puzzleDocs);
    return created as Puzzle[];
  }

  async toggleActive(id: string): Promise<Puzzle> {
    const puzzle = await this.puzzleModel.findById(id);
    if (!puzzle) {
      throw new NotFoundException(`Puzzle with ID ${id} not found`);
    }
    puzzle.isActive = !puzzle.isActive;
    return puzzle.save();
  }
}
