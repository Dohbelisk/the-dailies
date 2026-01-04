import { Injectable, Logger } from "@nestjs/common";

export interface FeedbackPayload {
  feedbackId: string;
  type: string;
  message: string;
  email?: string;
  puzzleId?: string;
  gameType?: string;
  difficulty?: string;
  puzzleDate?: string;
  deviceInfo?: string;
  createdAt: string;
}

@Injectable()
export class GitHubService {
  private readonly logger = new Logger(GitHubService.name);
  private readonly owner: string;
  private readonly repo: string;
  private readonly token: string | undefined;

  constructor() {
    // Parse owner/repo from GITHUB_REPOSITORY env var (format: owner/repo)
    const repository = process.env.GITHUB_REPOSITORY || "";
    const [owner, repo] = repository.split("/");
    this.owner = owner || "";
    this.repo = repo || "";
    this.token = process.env.GITHUB_TOKEN;
  }

  private isConfigured(): boolean {
    return Boolean(this.owner && this.repo && this.token);
  }

  async createIssueFromFeedback(payload: FeedbackPayload): Promise<void> {
    if (!this.isConfigured()) {
      this.logger.warn(
        "GitHub integration not configured. Set GITHUB_REPOSITORY and GITHUB_TOKEN env vars to enable.",
      );
      return;
    }

    try {
      // Trigger repository_dispatch event
      const response = await fetch(
        `https://api.github.com/repos/${this.owner}/${this.repo}/dispatches`,
        {
          method: "POST",
          headers: {
            Accept: "application/vnd.github.v3+json",
            Authorization: `Bearer ${this.token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            event_type: "feedback-submitted",
            client_payload: payload,
          }),
        },
      );

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`GitHub API returned ${response.status}: ${errorText}`);
      }

      this.logger.log(
        `Triggered GitHub issue creation for feedback ${payload.feedbackId}`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to trigger GitHub issue creation: ${error.message}`,
      );
      // Don't throw - we don't want to fail the feedback submission
    }
  }
}
