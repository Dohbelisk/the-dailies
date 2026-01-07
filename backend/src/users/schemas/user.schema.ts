import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";
import { ApiProperty } from "@nestjs/swagger";

export type UserDocument = User & Document;

export enum UserRole {
  USER = "user",
  ADMIN = "admin",
}

export enum AuthProvider {
  LOCAL = "local",
  GOOGLE = "google",
  BOTH = "both",
}

@Schema({ timestamps: true })
export class User {
  @ApiProperty()
  @Prop({ required: true, unique: true })
  email: string;

  @ApiProperty()
  @Prop({ required: false })
  password?: string;

  @ApiProperty()
  @Prop()
  username: string;

  @ApiProperty()
  @Prop({ unique: true, sparse: true })
  friendCode: string;

  @ApiProperty({ enum: UserRole })
  @Prop({ type: String, enum: UserRole, default: UserRole.USER })
  role: UserRole;

  @ApiProperty()
  @Prop({ default: true })
  isActive: boolean;

  @ApiProperty()
  @Prop({ unique: true, sparse: true })
  googleId?: string;

  @ApiProperty()
  @Prop()
  profilePicture?: string;

  @ApiProperty({ enum: AuthProvider })
  @Prop({ type: String, enum: AuthProvider, default: AuthProvider.LOCAL })
  authProvider: AuthProvider;
}

export const UserSchema = SchemaFactory.createForClass(User);
