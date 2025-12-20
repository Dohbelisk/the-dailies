import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type DictionaryDocument = Dictionary & Document;

@Schema({ collection: 'dictionary' })
export class Dictionary {
  @Prop({ required: true, unique: true, index: true })
  word: string;

  @Prop({ required: true, index: true })
  length: number;

  @Prop({ type: [String], index: true })
  letters: string[]; // Sorted unique letters for quick lookup
}

export const DictionarySchema = SchemaFactory.createForClass(Dictionary);

// Create compound index for efficient Word Forge queries
DictionarySchema.index({ length: 1, letters: 1 });
