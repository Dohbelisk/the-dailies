import { Controller, Post, Body, UseGuards, Get } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import {
  IsString,
  IsOptional,
  IsNumber,
  Min,
  Max,
  IsArray,
  ArrayMinSize,
  ArrayMaxSize,
} from "class-validator";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { AdminGuard } from "../auth/guards/admin.guard";
import { AiService, CrosswordWord, ConnectionsCategory } from "./ai.service";

class GenerateCrosswordWordsDto {
  @IsString()
  theme: string;

  @IsOptional()
  @IsNumber()
  @Min(3)
  @Max(20)
  count?: number;

  @IsOptional()
  @IsNumber()
  @Min(2)
  @Max(8)
  minLength?: number;

  @IsOptional()
  @IsNumber()
  @Min(4)
  @Max(15)
  maxLength?: number;
}

class GenerateConnectionsDto {
  @IsOptional()
  @IsString()
  theme?: string;
}

class GenerateWordCluesDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @IsString({ each: true })
  words: string[];
}

@ApiTags("ai")
@Controller("ai")
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth()
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Get("status")
  @ApiOperation({ summary: "Check if AI service is available" })
  getStatus() {
    return {
      available: this.aiService.isAvailable(),
    };
  }

  @Post("crossword-words")
  @ApiOperation({ summary: "Generate crossword words and clues for a theme" })
  async generateCrosswordWords(
    @Body() dto: GenerateCrosswordWordsDto,
  ): Promise<{ theme: string; words: CrosswordWord[] }> {
    const words = await this.aiService.generateCrosswordWords(
      dto.theme,
      dto.count || 10,
      dto.minLength || 3,
      dto.maxLength || 12,
    );

    return {
      theme: dto.theme,
      words,
    };
  }

  @Post("connections")
  @ApiOperation({
    summary: "Generate a complete Connections puzzle with 4 categories",
  })
  async generateConnections(
    @Body() dto: GenerateConnectionsDto,
  ): Promise<{ theme?: string; categories: ConnectionsCategory[] }> {
    const categories = await this.aiService.generateConnections(dto.theme);

    return {
      theme: dto.theme,
      categories,
    };
  }

  @Post("word-clues")
  @ApiOperation({
    summary: "Generate dictionary clues for a list of words",
  })
  async generateWordClues(
    @Body() dto: GenerateWordCluesDto,
  ): Promise<{ clues: { word: string; clue: string }[] }> {
    const clues = await this.aiService.generateWordClues(dto.words);

    return {
      clues,
    };
  }
}
