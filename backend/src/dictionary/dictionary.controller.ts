import {
  Controller,
  Post,
  Body,
  Get,
  Patch,
  Delete,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiQuery } from "@nestjs/swagger";
import {
  IsString,
  IsArray,
  IsOptional,
  MinLength,
  ValidateNested,
  ArrayMinSize,
} from "class-validator";
import { Type } from "class-transformer";
import { DictionaryService } from "./dictionary.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { AdminGuard } from "../auth/guards/admin.guard";

class ValidateWordDto {
  @IsString()
  @MinLength(1)
  word: string;
}

class ValidateWordsDto {
  @IsArray()
  @IsString({ each: true })
  words: string[];
}

class ValidateWordForPuzzleDto {
  @IsString()
  @MinLength(1)
  word: string;

  @IsArray()
  @IsString({ each: true })
  letters: string[];

  @IsString()
  @MinLength(1)
  centerLetter: string;

  @IsOptional()
  minLength?: number;
}

class UpdateClueDto {
  @IsString()
  clue: string;
}

class AddWordDto {
  @IsString()
  @MinLength(4)
  word: string;

  @IsOptional()
  @IsString()
  clue?: string;
}

class BulkAddWordsDto {
  @IsArray()
  @IsString({ each: true })
  words: string[];
}

class WordClueItem {
  @IsString()
  word: string;

  @IsString()
  clue: string;
}

class BulkUpdateCluesDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => WordClueItem)
  clues: WordClueItem[];
}

@ApiTags("dictionary")
@Controller("dictionary")
export class DictionaryController {
  constructor(private readonly dictionaryService: DictionaryService) {}

  @Post("validate")
  @ApiOperation({ summary: "Check if a word exists in the dictionary" })
  async validateWord(@Body() dto: ValidateWordDto) {
    const valid = await this.dictionaryService.isValidWord(dto.word);
    return { word: dto.word.toUpperCase(), valid };
  }

  @Post("validate-many")
  @ApiOperation({ summary: "Check if multiple words exist in the dictionary" })
  async validateWords(@Body() dto: ValidateWordsDto) {
    return this.dictionaryService.validateWords(dto.words);
  }

  @Post("validate-for-puzzle")
  @ApiOperation({ summary: "Validate a word for a Word Forge puzzle" })
  async validateWordForPuzzle(@Body() dto: ValidateWordForPuzzleDto) {
    return this.dictionaryService.isValidWordForPuzzle(
      dto.word,
      dto.letters,
      dto.centerLetter,
      dto.minLength || 4,
    );
  }

  @Get("count")
  @ApiOperation({ summary: "Get total word count in dictionary" })
  async getWordCount() {
    const count = await this.dictionaryService.getWordCount();
    return { count };
  }

  @Get("status")
  @ApiOperation({ summary: "Get dictionary status" })
  async getStatus() {
    const count = await this.dictionaryService.getWordCount();
    return {
      loaded: count > 0,
      wordCount: count,
      minWordLength: 4,
    };
  }

  // ============ Admin Endpoints ============

  @Get()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({
    summary: "List dictionary words with pagination and filters",
  })
  @ApiQuery({ name: "page", required: false, type: Number })
  @ApiQuery({ name: "limit", required: false, type: Number })
  @ApiQuery({ name: "search", required: false, type: String })
  @ApiQuery({ name: "length", required: false, type: Number })
  @ApiQuery({ name: "startsWith", required: false, type: String })
  @ApiQuery({ name: "hasClue", required: false, type: Boolean })
  async findAll(
    @Query("page") page?: string,
    @Query("limit") limit?: string,
    @Query("search") search?: string,
    @Query("length") length?: string,
    @Query("startsWith") startsWith?: string,
    @Query("hasClue") hasClue?: string,
  ) {
    return this.dictionaryService.findAll({
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 50,
      search,
      length: length ? parseInt(length, 10) : undefined,
      startsWith: startsWith?.toUpperCase(),
      hasClue:
        hasClue === "true" ? true : hasClue === "false" ? false : undefined,
    });
  }

  @Get("word/:word")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: "Get a single dictionary word" })
  async findByWord(@Param("word") word: string) {
    return this.dictionaryService.findByWord(word.toUpperCase());
  }

  @Patch("word/:word")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: "Update a word's clue" })
  async updateClue(@Param("word") word: string, @Body() dto: UpdateClueDto) {
    return this.dictionaryService.updateClue(word.toUpperCase(), dto.clue);
  }

  @Delete("word/:word")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: "Delete a word from the dictionary" })
  async deleteWord(@Param("word") word: string) {
    return this.dictionaryService.deleteWord(word.toUpperCase());
  }

  @Post("word")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: "Add a word to the dictionary" })
  async addWord(@Body() dto: AddWordDto) {
    const word = await this.dictionaryService.addWord(dto.word);
    if (dto.clue) {
      await this.dictionaryService.updateClue(dto.word, dto.clue);
    }
    return word;
  }

  @Post("words/bulk")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: "Bulk add words to the dictionary" })
  async bulkAddWords(@Body() dto: BulkAddWordsDto) {
    const count = await this.dictionaryService.bulkAddWords(dto.words);
    return { added: count };
  }

  @Patch("words/bulk-clues")
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: "Bulk update clues for multiple words" })
  async bulkUpdateClues(@Body() dto: BulkUpdateCluesDto) {
    return this.dictionaryService.updateCluesBulk(dto.clues);
  }
}
