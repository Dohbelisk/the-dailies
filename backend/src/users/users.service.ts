import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument, UserRole } from './schemas/user.schema';

export class CreateUserDto {
  email: string;
  password: string;
  username?: string;
  role?: UserRole;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const existingUser = await this.userModel.findOne({ email: createUserDto.email });
    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);
    const friendCode = await this.generateUniqueFriendCode();

    const user = new this.userModel({
      ...createUserDto,
      password: hashedPassword,
      friendCode,
    });

    return user.save();
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email }).exec();
  }

  async findById(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id).exec();
  }

  async findAll(): Promise<User[]> {
    return this.userModel.find().select('-password').exec();
  }

  async validatePassword(user: UserDocument, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.password);
  }

  async updateRole(userId: string, role: UserRole): Promise<User> {
    const user = await this.userModel.findByIdAndUpdate(
      userId,
      { role },
      { new: true },
    ).select('-password');

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async createAdminUser(email: string, password: string): Promise<User> {
    return this.create({
      email,
      password,
      username: 'Admin',
      role: UserRole.ADMIN,
    });
  }

  async generateUniqueFriendCode(): Promise<string> {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous chars
    let friendCode: string;
    let isUnique = false;

    while (!isUnique) {
      friendCode = '';
      for (let i = 0; i < 8; i++) {
        friendCode += characters.charAt(Math.floor(Math.random() * characters.length));
      }

      const existingUser = await this.userModel.findOne({ friendCode }).exec();
      if (!existingUser) {
        isUnique = true;
      }
    }

    return friendCode;
  }

  async findByFriendCode(friendCode: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ friendCode }).exec();
  }

  async findByUsername(username: string): Promise<User[]> {
    return this.userModel
      .find({ username: { $regex: username, $options: 'i' } })
      .select('-password')
      .limit(20)
      .exec();
  }
}
