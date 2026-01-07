import { Injectable, UnauthorizedException } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import * as admin from "firebase-admin";
import { UsersService } from "../users/users.service";
import { UserDocument } from "../users/schemas/user.schema";

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async validateUser(
    email: string,
    password: string,
  ): Promise<UserDocument | null> {
    const user = await this.usersService.findByEmail(email);
    if (user && (await this.usersService.validatePassword(user, password))) {
      return user;
    }
    return null;
  }

  async login(user: UserDocument) {
    const payload = {
      email: user.email,
      sub: user._id,
      role: user.role,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user._id,
        email: user.email,
        username: user.username,
        role: user.role,
        friendCode: user.friendCode,
        profilePicture: user.profilePicture,
        authProvider: user.authProvider,
      },
    };
  }

  async register(email: string, password: string, username?: string) {
    const user = await this.usersService.create({
      email,
      password,
      username,
    });

    return this.login(user as UserDocument);
  }

  async validateToken(token: string) {
    try {
      return this.jwtService.verify(token);
    } catch {
      throw new UnauthorizedException("Invalid token");
    }
  }

  async googleSignIn(idToken: string) {
    try {
      // Verify the Google ID token using Firebase Admin
      const decodedToken = await admin.auth().verifyIdToken(idToken);

      const { uid, email, name, picture } = decodedToken;

      if (!email) {
        throw new UnauthorizedException("Google account has no email");
      }

      // Check if user exists by googleId
      let user = await this.usersService.findByGoogleId(uid);

      if (!user) {
        // Check if email already exists (link accounts)
        user = await this.usersService.findByEmail(email);

        if (user) {
          // Link Google to existing account
          user = await this.usersService.linkGoogleAccount(
            user._id.toString(),
            uid,
            picture,
          );
        } else {
          // Create new user from Google
          user = await this.usersService.createFromGoogle({
            email,
            googleId: uid,
            username: name || email.split("@")[0],
            profilePicture: picture,
          });
        }
      }

      // Return JWT (same as regular login)
      return this.login(user);
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException(
        "Invalid Google token: " + (error.message || "Unknown error"),
      );
    }
  }
}
