import { Controller, Post, Body, Get } from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import { IsString, IsArray, IsOptional, MinLength } from "class-validator";
import { DictionaryService } from "./dictionary.service";

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
}
