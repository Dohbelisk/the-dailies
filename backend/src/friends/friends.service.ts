import {
  Injectable,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { Friend, FriendDocument } from "./schemas/friend.schema";
import {
  FriendRequest,
  FriendRequestDocument,
  RequestStatus,
} from "./schemas/friend-request.schema";
import { UsersService } from "../users/users.service";

@Injectable()
export class FriendsService {
  constructor(
    @InjectModel(Friend.name) private friendModel: Model<FriendDocument>,
    @InjectModel(FriendRequest.name)
    private friendRequestModel: Model<FriendRequestDocument>,
    private usersService: UsersService,
  ) {}

  async sendFriendRequest(
    senderId: string,
    receiverId: string,
  ): Promise<FriendRequest> {
    // Validate users exist
    const sender = await this.usersService.findById(senderId);
    const receiver = await this.usersService.findById(receiverId);

    if (!sender || !receiver) {
      throw new NotFoundException("User not found");
    }

    if (senderId === receiverId) {
      throw new BadRequestException("Cannot send friend request to yourself");
    }

    // Check if already friends
    const existingFriendship = await this.friendModel
      .findOne({
        $or: [
          {
            userId: new Types.ObjectId(senderId),
            friendId: new Types.ObjectId(receiverId),
          },
          {
            userId: new Types.ObjectId(receiverId),
            friendId: new Types.ObjectId(senderId),
          },
        ],
      })
      .exec();

    if (existingFriendship) {
      throw new ConflictException("Already friends with this user");
    }

    // Check for existing pending request
    const existingRequest = await this.friendRequestModel
      .findOne({
        $or: [
          {
            senderId: new Types.ObjectId(senderId),
            receiverId: new Types.ObjectId(receiverId),
            status: RequestStatus.PENDING,
          },
          {
            senderId: new Types.ObjectId(receiverId),
            receiverId: new Types.ObjectId(senderId),
            status: RequestStatus.PENDING,
          },
        ],
      })
      .exec();

    if (existingRequest) {
      throw new ConflictException("Friend request already exists");
    }

    const friendRequest = new this.friendRequestModel({
      senderId: new Types.ObjectId(senderId),
      receiverId: new Types.ObjectId(receiverId),
      status: RequestStatus.PENDING,
    });

    return friendRequest.save();
  }

  async sendFriendRequestByCode(
    senderId: string,
    friendCode: string,
  ): Promise<FriendRequest> {
    const receiver = await this.usersService.findByFriendCode(friendCode);

    if (!receiver) {
      throw new NotFoundException("User with this friend code not found");
    }

    return this.sendFriendRequest(senderId, receiver._id.toString());
  }

  async acceptFriendRequest(
    requestId: string,
    userId: string,
  ): Promise<Friend> {
    const request = await this.friendRequestModel.findById(requestId).exec();

    if (!request) {
      throw new NotFoundException("Friend request not found");
    }

    if (request.receiverId.toString() !== userId) {
      throw new BadRequestException("Not authorized to accept this request");
    }

    if (request.status !== RequestStatus.PENDING) {
      throw new BadRequestException("Request already processed");
    }

    // Update request status
    request.status = RequestStatus.ACCEPTED;
    await request.save();

    // Create bidirectional friendship
    const friendship1 = new this.friendModel({
      userId: request.senderId,
      friendId: request.receiverId,
      friendsSince: new Date(),
    });

    const friendship2 = new this.friendModel({
      userId: request.receiverId,
      friendId: request.senderId,
      friendsSince: new Date(),
    });

    await Promise.all([friendship1.save(), friendship2.save()]);

    return friendship1;
  }

  async declineFriendRequest(
    requestId: string,
    userId: string,
  ): Promise<FriendRequest> {
    const request = await this.friendRequestModel.findById(requestId).exec();

    if (!request) {
      throw new NotFoundException("Friend request not found");
    }

    if (request.receiverId.toString() !== userId) {
      throw new BadRequestException("Not authorized to decline this request");
    }

    if (request.status !== RequestStatus.PENDING) {
      throw new BadRequestException("Request already processed");
    }

    request.status = RequestStatus.DECLINED;
    return request.save();
  }

  async getFriends(userId: string): Promise<any[]> {
    const friendships = await this.friendModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate("friendId", "-password")
      .exec();

    return friendships.map((f) => ({
      id: f._id,
      user: f.friendId,
      friendsSince: f.friendsSince,
    }));
  }

  async getPendingRequests(userId: string): Promise<any[]> {
    const requests = await this.friendRequestModel
      .find({
        receiverId: new Types.ObjectId(userId),
        status: RequestStatus.PENDING,
      })
      .populate("senderId", "-password")
      .exec();

    return requests.map((r: any) => ({
      id: r._id,
      sender: r.senderId,
      createdAt: r.createdAt,
    }));
  }

  async getSentRequests(userId: string): Promise<any[]> {
    const requests = await this.friendRequestModel
      .find({
        senderId: new Types.ObjectId(userId),
        status: RequestStatus.PENDING,
      })
      .populate("receiverId", "-password")
      .exec();

    return requests.map((r: any) => ({
      id: r._id,
      receiver: r.receiverId,
      createdAt: r.createdAt,
    }));
  }

  async removeFriend(userId: string, friendId: string): Promise<void> {
    // Remove both directions of the friendship
    await this.friendModel
      .deleteMany({
        $or: [
          {
            userId: new Types.ObjectId(userId),
            friendId: new Types.ObjectId(friendId),
          },
          {
            userId: new Types.ObjectId(friendId),
            friendId: new Types.ObjectId(userId),
          },
        ],
      })
      .exec();
  }

  /**
   * Check if two users are friends
   */
  async areFriends(userId1: string, userId2: string): Promise<boolean> {
    const friendship = await this.friendModel
      .findOne({
        $or: [
          {
            userId: new Types.ObjectId(userId1),
            friendId: new Types.ObjectId(userId2),
          },
          {
            userId: new Types.ObjectId(userId2),
            friendId: new Types.ObjectId(userId1),
          },
        ],
      })
      .exec();

    return !!friendship;
  }
}
