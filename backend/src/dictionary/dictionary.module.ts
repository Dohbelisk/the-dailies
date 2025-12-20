import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DictionaryController } from './dictionary.controller';
import { DictionaryService } from './dictionary.service';
import { Dictionary, DictionarySchema } from './schemas/dictionary.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Dictionary.name, schema: DictionarySchema },
    ]),
  ],
  controllers: [DictionaryController],
  providers: [DictionaryService],
  exports: [DictionaryService],
})
export class DictionaryModule {}
