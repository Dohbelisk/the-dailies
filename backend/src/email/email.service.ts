import { Injectable } from "@nestjs/common";
import { MailerService } from "@nestjs-modules/mailer";
import { ConfigService } from "@nestjs/config";

@Injectable()
export class EmailService {
  private readonly feedbackEmail: string;

  constructor(
    private readonly mailerService: MailerService,
    private readonly configService: ConfigService,
  ) {
    this.feedbackEmail =
      this.configService.get<string>("FEEDBACK_EMAIL") ||
      "wayne@steedman.co.za";
  }

  async sendFeedbackNotification(feedback: {
    _id: string;
    type: string;
    message: string;
    email?: string;
    puzzleId?: string;
    gameType?: string;
    difficulty?: string;
    puzzleDate?: Date;
    deviceInfo?: string;
    createdAt?: Date;
  }): Promise<void> {
    const subject = `[The Dailies] New ${this.formatFeedbackType(feedback.type)} Received`;

    const gameContext = feedback.puzzleId
      ? `
Game Context:
- Puzzle ID: ${feedback.puzzleId}
- Game Type: ${feedback.gameType || "N/A"}
- Difficulty: ${feedback.difficulty || "N/A"}
- Puzzle Date: ${feedback.puzzleDate ? new Date(feedback.puzzleDate).toLocaleDateString() : "N/A"}`
      : "";

    const replyInfo = feedback.email
      ? `\nUser provided email for follow-up: ${feedback.email}`
      : "\nNo contact email provided (anonymous submission)";

    const text = `
New feedback submitted:

Type: ${this.formatFeedbackType(feedback.type)}
${gameContext}

Message:
${feedback.message}
${replyInfo}

Device Info: ${feedback.deviceInfo || "Not provided"}

---
Submitted: ${feedback.createdAt ? new Date(feedback.createdAt).toISOString() : new Date().toISOString()}
Feedback ID: ${feedback._id}
    `.trim();

    try {
      await this.mailerService.sendMail({
        to: this.feedbackEmail,
        subject,
        text,
      });
    } catch (error) {
      console.error("Failed to send feedback notification email:", error);
      // Don't throw - we don't want email failure to break feedback submission
    }
  }

  private formatFeedbackType(type: string): string {
    const mapping: Record<string, string> = {
      bug_report: "Bug Report",
      new_game_suggestion: "New Game Type Suggestion",
      puzzle_suggestion: "New Puzzle Suggestion",
      puzzle_mistake: "Puzzle Mistake Report",
      general: "General Feedback",
    };
    return mapping[type] || type;
  }
}
