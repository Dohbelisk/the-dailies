import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  NotFoundException,
} from "@nestjs/common";
import { FriendsService } from "./friends.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { UsersService } from "../users/users.service";

@Controller("friends")
@UseGuards(JwtAuthGuard)
export class FriendsController {
  constructor(
    private readonly friendsService: FriendsService,
    private readonly usersService: UsersService,
  ) {}

  @Post("request")
  async sendFriendRequest(
    @Request() req,
    @Body() body: { receiverId: string },
  ) {
    return this.friendsService.sendFriendRequest(
      req.user.userId,
      body.receiverId,
    );
  }

  @Post("request/code")
  async sendFriendRequestByCode(
    @Request() req,
    @Body() body: { friendCode: string },
  ) {
    return this.friendsService.sendFriendRequestByCode(
      req.user.userId,
      body.friendCode,
    );
  }

  @Post("request/username")
  async sendFriendRequestByUsername(
    @Request() req,
    @Body() body: { username: string },
  ) {
    const users = await this.usersService.findByUsername(body.username);

    if (users.length === 0) {
      throw new NotFoundException("User not found");
    }

    // If multiple users found, return the list for the client to choose
    if (users.length > 1) {
      return { multiple: true, users };
    }

    // If exactly one user found, send the request
    const user = users[0] as any;
    return this.friendsService.sendFriendRequest(
      req.user.userId,
      user._id.toString(),
    );
  }

  @Get("requests/pending")
  async getPendingRequests(@Request() req) {
    return this.friendsService.getPendingRequests(req.user.userId);
  }

  @Get("requests/sent")
  async getSentRequests(@Request() req) {
    return this.friendsService.getSentRequests(req.user.userId);
  }

  @Post("requests/:id/accept")
  async acceptFriendRequest(@Request() req, @Param("id") requestId: string) {
    return this.friendsService.acceptFriendRequest(requestId, req.user.userId);
  }

  @Post("requests/:id/decline")
  async declineFriendRequest(@Request() req, @Param("id") requestId: string) {
    return this.friendsService.declineFriendRequest(requestId, req.user.userId);
  }

  @Get()
  async getFriends(@Request() req) {
    return this.friendsService.getFriends(req.user.userId);
  }

  @Delete(":friendId")
  async removeFriend(@Request() req, @Param("friendId") friendId: string) {
    await this.friendsService.removeFriend(req.user.userId, friendId);
    return { message: "Friend removed successfully" };
  }

  @Get("search")
  async searchUsers(@Query("username") username: string) {
    if (!username || username.trim().length === 0) {
      return [];
    }
    return this.usersService.findByUsername(username);
  }
}
