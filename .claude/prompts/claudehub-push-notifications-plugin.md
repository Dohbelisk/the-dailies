# ClaudeHub Push Notifications Plugin - Build Prompt

Paste this into a Claude Code session in the ClaudeHub repo (~/Development/Personal/claudehub-2):

---

Build a ClaudeHub plugin called "push-notifications" with sidebar label "Push" that provides a full push notification management dashboard for The Dailies app. The plugin should have 3 tabs:

## Tab 1: Send Notification

A form to compose and send push notifications:
- **Title** (text input)
- **Body** (textarea)
- **Target audience** selector:
  - All users
  - By tag (multi-select from registered tags - fetch from API)
  - By tag combination (AND/OR logic between multiple tags)
- **Send now** or **Schedule** toggle:
  - If scheduled: date/time picker
  - Option to make it **recurring** with cron-style interval (daily, weekly, custom)
- **Preview** section showing how the notification will appear on iOS/Android
- **Send / Schedule** button with confirmation dialog

The backend should call the existing The Dailies API endpoint for push notifications. If one doesn't exist yet, document what endpoint is needed:
- `POST /notifications/send` - send to all or filtered by tags
- `POST /notifications/schedule` - schedule one-time or recurring
- `GET /notifications/scheduled` - list scheduled notifications
- `DELETE /notifications/scheduled/:id` - cancel scheduled notification

## Tab 2: Scheduled

A list/table of all scheduled and recurring notifications:
- Title, body, target tags, scheduled time, recurrence pattern, status
- Actions: edit, cancel, pause/resume (for recurring)
- History of sent notifications with delivery stats (sent count, opened count if available)

## Tab 3: Dashboard

User stats and tag analytics:
- **Total registered users** (with growth chart if data available)
- **Active users** (daily/weekly/monthly)
- **Platform split** (iOS vs Android)
- **Subscription status** breakdown (free vs premium)
- **Tag registry**: table of all registered tags with:
  - Tag name
  - User count per tag
  - Percentage of total users
  - Sparkline of tag growth over time (if data available)
- **Notification history**: recent sends with open rates

## Implemented User Tags (FCM Topics)

The Dailies app registers these tags as FCM topic subscriptions via `NotificationTagService`. Tags are evaluated on app launch and after puzzle completion. The plugin dashboard should be able to target any of these topics.

### Broadcast
- `daily_puzzles` - all users (subscribed by default)

### Engagement Tags
- `streak_active` - user has an active daily streak
- `streak_broken` - had a streak before but it's currently broken (win-back target)
- `streak_never` - user has never built a streak
- `new_user` - installed within last 7 days
- `power_user` - 100+ total puzzles completed

### Subscription Tags
- `tier_free` / `tier_premium` - current subscription status

### Gameplay Tags
- `plays_{gameType}` - one tag per puzzle type completed at least 3 times (e.g. `plays_sudoku`, `plays_crossword`, `plays_word_forge`, `plays_killer_sudoku`, `plays_word_search`, `plays_nonogram`, `plays_number_target`, `plays_ball_sort`, `plays_pipes`, `plays_lights_out`, `plays_word_ladder`, `plays_connections`, `plays_mathora`)
- `favorite_{gameType}` - user's most-played puzzle type
- `puzzles_completed_10` / `puzzles_completed_50` / `puzzles_completed_100` / `puzzles_completed_500` - milestone tiers (highest applicable)

### Platform & Version Tags
- `platform_ios` / `platform_android`
- `version_{semver}` - current app version (e.g. `version_1_0_0` - dots replaced with underscores for topic compatibility)

### Time-Based Tags
- `plays_morning` (5am-12pm) / `plays_afternoon` (12pm-5pm) / `plays_evening` (5pm-9pm) / `plays_night` (9pm-5am) - last session time window

---

Use the ClaudeHub plugin development spec at ~/Development/Personal/claudehub-2/PLUGIN-DEVELOPMENT.md for manifest format, bridge API, and styling guidelines. The plugin should use the ClaudeHub API proxy bridge to communicate with The Dailies backend at the configured API URL. Style it consistently with existing ClaudeHub plugins.
