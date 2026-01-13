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
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { PuzzlesService } from "./puzzles.service";
import {
  CreatePuzzleDto,
  UpdatePuzzleDto,
  PuzzleQueryDto,
  UpdatePuzzleStatusDto,
} from "./dto/puzzle.dto";
import { GameType } from "./schemas/puzzle.schema";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { AdminGuard } from "../auth/guards/admin.guard";

@ApiTags("puzzles")
@Controller("puzzles")
export class PuzzlesController {
  constructor(private readonly puzzlesService: PuzzlesService) {}

  // Public endpoints

  @Get("today")
  @ApiOperation({
    summary: "Get all puzzles for today (based on SAST timezone)",
  })
  @ApiResponse({ status: 200, description: "Returns today's puzzles" })
  findTodaysPuzzles() {
    return this.puzzlesService.findTodaysPuzzles();
  }

  @Get("type/:gameType")
  @ApiOperation({ summary: "Get puzzles by game type" })
  findByType(@Param("gameType") gameType: GameType) {
    return this.puzzlesService.findByType(gameType);
  }

  @Get("type/:gameType/date/:date")
  @ApiOperation({ summary: "Get puzzle by type and date" })
  findByTypeAndDate(
    @Param("gameType") gameType: GameType,
    @Param("date") date: string,
  ) {
    return this.puzzlesService.findByTypeAndDate(gameType, date);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get a puzzle by ID" })
  findOne(@Param("id") id: string) {
    return this.puzzlesService.findOne(id);
  }

  // Admin endpoints

  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Create a new puzzle (Admin only)" })
  @ApiResponse({ status: 201, description: "Puzzle created successfully" })
  create(@Body() createPuzzleDto: CreatePuzzleDto) {
    return this.puzzlesService.create(createPuzzleDto);
  }

  @Post("bulk")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Create multiple puzzles (Admin only)" })
  createMany(@Body() puzzles: CreatePuzzleDto[]) {
    return this.puzzlesService.createMany(puzzles);
  }

  @Get()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Get all puzzles with filters (Admin only)" })
  findAll(@Query() query: PuzzleQueryDto) {
    return this.puzzlesService.findAll(query);
  }

  @Get("admin/stats")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Get puzzle statistics (Admin only)" })
  getStats() {
    return this.puzzlesService.getStats();
  }

  @Patch(":id")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Update a puzzle (Admin only)" })
  update(@Param("id") id: string, @Body() updatePuzzleDto: UpdatePuzzleDto) {
    return this.puzzlesService.update(id, updatePuzzleDto);
  }

  @Patch(":id/toggle-active")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      "Toggle puzzle active status (Admin only) - DEPRECATED, use /status instead",
  })
  toggleActive(@Param("id") id: string) {
    return this.puzzlesService.toggleActive(id);
  }

  @Patch(":id/status")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: "Update puzzle status with validation (Admin only)",
  })
  @ApiResponse({ status: 200, description: "Status updated successfully" })
  @ApiResponse({
    status: 400,
    description: "Validation failed - puzzle cannot be activated",
  })
  updateStatus(@Param("id") id: string, @Body() dto: UpdatePuzzleStatusDto) {
    return this.puzzlesService.updateStatus(id, dto.status);
  }

  @Delete(":id")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Delete a puzzle (Admin only)" })
  remove(@Param("id") id: string) {
    return this.puzzlesService.remove(id);
  }
}
