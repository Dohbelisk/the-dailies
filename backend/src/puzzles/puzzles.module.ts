import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PuzzlesService } from './puzzles.service';
import { PuzzlesController } from './puzzles.controller';
import { GenerateController } from './generate.controller';
import { Puzzle, PuzzleSchema } from './schemas/puzzle.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Puzzle.name, schema: PuzzleSchema }]),
  ],
  controllers: [PuzzlesController, GenerateController],
  providers: [PuzzlesService],
  exports: [PuzzlesService],
})
export class PuzzlesModule {}
