# 📚 Archive & Token System Implementation

## Overview

The Dailies app now includes a comprehensive archive system that allows users to play puzzles from previous days using a token-based economy. This creates an additional monetization opportunity through rewarded video ads while providing value to users.

## How It Works

### For Free Users

**Daily Access:**
- Can play all of today's puzzles for free
- Get 1 free token every day (at midnight)
- Watch rewarded video ads to earn 5 tokens per video
- Spend tokens to unlock archive puzzles:
  - Easy difficulty: 1 token
  - Medium difficulty: 2 tokens
  - Hard/Expert difficulty: 3 tokens

**Archive Access Flow:**
1. Tap "Archive" button on home screen
2. Browse puzzles from previous days
3. Select a puzzle to play
4. If insufficient tokens → Prompted to watch ad or go premium
5. If sufficient tokens → Tokens deducted, puzzle unlocked
6. Play the puzzle normally

### For Premium Users

- **Unlimited archive access** (no tokens needed)
- All ads removed (including token reward ads)
- Can play any puzzle from any day instantly
- Premium badge displayed instead of token count

## Implementation Details

### 1. Token Service (`flutter_app/lib/services/token_service.dart`)

A singleton service managing the token economy:

**Features:**
- Token balance persistence using SharedPreferences
- Daily free token distribution
- Rewarded video ad integration for token earning
- Token cost calculation based on difficulty
- Premium user detection

**Key Methods:**
```dart
await TokenService().initialize()                     // Initialize and award daily token
int availableTokens                                   // Get current token balance
bool isPremium                                        // Check premium status

// Check access
bool canAccessPuzzle(String difficulty, {bool isTodaysPuzzle})

// Spend tokens
await spendTokens(String difficulty)                  // Returns true if successful

// Earn tokens
await watchAdForTokens()                              // Show rewarded ad for 5 tokens
await addTokens(int count)                            // Add tokens manually

// Token costs
TokenService.getTokenCost(String difficulty)          // Returns 1/2/3 for easy/medium/hard

// Daily token info
await getNextDailyTokenTime()                         // Returns "Next token in 5h 23m"
```

### 2. Archive Screen (`flutter_app/lib/screens/archive_screen.dart`)

Full-featured archive UI with date navigation and puzzle browsing:

**Features:**
- Date picker (swipe left/right to change dates)
- Grid view of all puzzles for selected date
- Locked state for puzzles requiring tokens
- Token cost badges on puzzle cards
- "Get Tokens" dialog with multiple options:
  - Watch video ad → Get 5 tokens
  - Daily free token countdown
  - Go Premium option
- Premium users see all puzzles unlocked

**UI Components:**
- Date navigation with arrow buttons
- Token cost info banner
- Locked overlay on inaccessible puzzles
- Token balance display in app bar

### 3. Token Balance Widget (`flutter_app/lib/widgets/token_balance_widget.dart`)

Reusable widget displaying token count or premium status:

**Free Users:**
- Shows token icon + count
- Displays "X tokens" label
- Tappable to navigate to archive

**Premium Users:**
- Shows golden "Premium" badge
- Gradient background with glow effect
- Premium icon

### 4. Integration Points

#### Home Screen (`flutter_app/lib/screens/home_screen.dart`)
- Token balance widget in header (top-left)
- Archive button in header (history icon)
- Both navigate to ArchiveScreen

#### Game Service (`flutter_app/lib/services/game_service.dart`)
- Added `getPuzzleByDate(GameType type, String dateStr)` method
- Parses YYYY-MM-DD date strings
- Fetches puzzles from backend by date

#### Puzzle Card (`flutter_app/lib/widgets/puzzle_card.dart`)
- New `isLocked` parameter
- Locked overlay with lock icon
- Semi-transparent black overlay when locked

## Token Economy Design

### Token Sources

| Source | Tokens | Frequency | Notes |
|--------|--------|-----------|-------|
| Daily Login | 1 | Once per day | Resets at midnight |
| Rewarded Video Ad | 5 | Unlimited | ~30-second video |
| Premium Subscription | ∞ | N/A | No tokens needed |

### Token Costs

| Difficulty | Cost | Rationale |
|-----------|------|-----------|
| Easy | 1 token | Low barrier, encourages engagement |
| Medium | 2 tokens | Balanced cost for mid-tier content |
| Hard | 3 tokens | Premium content, higher value |
| Expert | 3 tokens | Same as hard |

### Economic Balance

**Example User Journey (7 days):**

**Light User:**
- Day 1-7: Play today's puzzles (free)
- Total tokens earned: 7 free + 0 video = 7 tokens
- Can play: ~5 archive easy puzzles or 2 medium + 1 easy

**Engaged User:**
- Day 1-7: Play today's puzzles + 1 archive puzzle/day
- Watches 1 video per day for tokens
- Total tokens: 7 free + 35 video = 42 tokens
- Can play: ~14 archive puzzles (mix of difficulties)

**Ad Revenue Impact:**
- Engaged users watching 7 videos/week
- Rewarded video CPM: ~$10-15
- Revenue: ~$0.07-0.10 per user per week
- **Projected:** $0.30-0.40 per engaged user per month

## User Experience Flow

### Scenario 1: Free User with Tokens

```
1. Tap "Archive" on home screen
2. See token balance: "5 tokens"
3. Browse to yesterday's date
4. Select Medium Sudoku (costs 2 tokens)
5. Prompt: "This costs 2 tokens. You have 5."
6. Confirm → 2 tokens deducted → Play puzzle
7. Token balance now: "3 tokens"
```

### Scenario 2: Free User without Tokens

```
1. Tap "Archive" on home screen
2. See token balance: "0 tokens"
3. Select Hard Crossword (costs 3 tokens)
4. Dialog: "Tokens Required - You need 3 tokens"
5. Tap "Get Tokens"
6. Options displayed:
   - Watch Video (Get 5 tokens) ← Tap this
   - Daily Token (Next in 8h 42m)
   - Go Premium (Unlimited access)
7. Watch 30-second video
8. Success: "You got 5 tokens!"
9. Token balance now: "5 tokens"
10. Can now unlock and play the puzzle
```

### Scenario 3: Premium User

```
1. Tap "Archive" on home screen
2. See "Premium" badge (no token count)
3. Browse to any date
4. All puzzles show unlocked
5. Tap any puzzle → Instant access
6. No tokens deducted, no prompts
```

## Revenue Model

### Token-Based Revenue (Rewarded Ads)

**Conservative Estimate (1,000 DAU):**
- 20% of users engage with archive (200 users)
- Average 1 video per active user per day
- 200 video views/day × 30 days = 6,000 views/month
- Rewarded video eCPM: $12
- **Monthly revenue:** 6,000 ÷ 1,000 × $12 = **$72**

**Optimistic Estimate (10,000 DAU):**
- 30% engage with archive (3,000 users)
- Average 2 videos per active user per day
- 6,000 video views/day × 30 days = 180,000 views/month
- Rewarded video eCPM: $15
- **Monthly revenue:** 180,000 ÷ 1,000 × $15 = **$2,700**

### Premium Conversion Driver

The token system serves as a **conversion funnel** to premium:

1. **Awareness:** Users see locked archive puzzles
2. **Trial:** Watch ad, get tokens, try archive puzzles
3. **Engagement:** Enjoy older puzzles, want more
4. **Friction:** Run out of tokens, need to watch more ads
5. **Conversion:** Choose unlimited access via premium subscription

**Expected Conversion Impact:**
- Archive feature increases premium awareness by ~30%
- Estimated premium conversion uplift: +5-10%
- If 20% of users become premium → 22-24% with archive
- Additional premium revenue: ~$50-200/month per 1,000 DAU

## Testing

### Manual Testing Checklist

**Token Service:**
- [ ] Daily token awarded on first launch of the day
- [ ] Token count persists across app restarts
- [ ] Rewarded video ad shows and awards 5 tokens
- [ ] Token costs calculated correctly (easy=1, medium=2, hard=3)
- [ ] Premium users bypass token requirements

**Archive Screen:**
- [ ] Date navigation works (left/right arrows)
- [ ] Can't navigate to future dates or today
- [ ] Puzzles load for selected date
- [ ] Locked puzzles show lock icon
- [ ] Token cost badges display correctly
- [ ] "Get Tokens" dialog appears when tapping locked puzzle

**Game Access:**
- [ ] Today's puzzles are always free
- [ ] Archive puzzles deduct tokens on play
- [ ] Premium users access all puzzles without token deduction
- [ ] Insufficient tokens shows appropriate error

**Integration:**
- [ ] Token balance displays on home screen
- [ ] Archive button navigates to archive screen
- [ ] Token count updates after watching ad
- [ ] Token count updates after playing archive puzzle

### Automated Testing (TODO)

```dart
test('TokenService awards daily token', () async {
  // Test daily token logic
});

test('TokenService calculates costs correctly', () {
  expect(TokenService.getTokenCost('easy'), 1);
  expect(TokenService.getTokenCost('medium'), 2);
  expect(TokenService.getTokenCost('hard'), 3);
});

test('Premium users bypass token requirements', () {
  // Mock premium status, verify canAccessPuzzle returns true
});
```

## Known Limitations & Future Improvements

### Current Limitations

1. **No Bulk Purchase:** Users can only earn tokens via videos or daily bonus
2. **No Token Expiry:** Tokens never expire (could encourage hoarding)
3. **Fixed Costs:** Token prices don't adjust based on puzzle age
4. **No Gifting:** Can't share or gift tokens to friends

### Planned Improvements

1. **Token Packs (IAP):**
   - 50 tokens: $0.99
   - 150 tokens: $1.99
   - 500 tokens: $4.99

2. **Dynamic Pricing:**
   - Older puzzles cost fewer tokens
   - Recent puzzles (1-7 days) cost more
   - Gradually decrease cost over time

3. **Bonus Events:**
   - "Double Token Weekends"
   - "Free Archive Friday" (all archive puzzles free for 24h)
   - Login streaks reward bonus tokens

4. **Social Features:**
   - Share tokens with friends
   - "Gift a Puzzle" feature
   - Token leaderboards

5. **Token Bundles:**
   - Themed puzzle packs (e.g., "Week of Hard Sudoku: 15 tokens")
   - Subscription-style bundles (monthly token allowance)

## Analytics & Metrics to Track

### Key Performance Indicators (KPIs)

1. **Token Engagement:**
   - % of users who earn tokens from videos
   - Average tokens earned per user per day
   - Average tokens spent per user per day
   - Token balance distribution histogram

2. **Archive Usage:**
   - % of users who visit archive
   - Average puzzles played from archive per user
   - Most popular archive dates/puzzles
   - Conversion rate: archive visitor → token earner

3. **Ad Performance:**
   - Rewarded video completion rate
   - Average videos watched per user
   - eCPM for rewarded videos
   - Total revenue from token ads

4. **Conversion Metrics:**
   - Archive visitor → Premium conversion rate
   - Token earner → Premium conversion rate
   - Days from first archive visit to premium upgrade

### Recommended Analytics Events

```dart
// Log these events for tracking
analyticsService.logEvent('archive_opened');
analyticsService.logEvent('token_earned_video', {tokens: 5});
analyticsService.logEvent('token_earned_daily', {tokens: 1});
analyticsService.logEvent('token_spent', {cost: 2, difficulty: 'medium'});
analyticsService.logEvent('archive_puzzle_locked_shown');
analyticsService.logEvent('get_tokens_dialog_shown');
analyticsService.logEvent('premium_upgrade_from_archive');
```

## Files Created/Modified

### Created Files
- ✅ `flutter_app/lib/services/token_service.dart` (148 lines)
- ✅ `flutter_app/lib/screens/archive_screen.dart` (524 lines)
- ✅ `flutter_app/lib/widgets/token_balance_widget.dart` (107 lines)
- ✅ `ARCHIVE_SYSTEM.md` (this file)

### Modified Files
- ✅ `flutter_app/lib/main.dart` - Initialize TokenService
- ✅ `flutter_app/lib/screens/home_screen.dart` - Add archive button and token display
- ✅ `flutter_app/lib/services/game_service.dart` - Add getPuzzleByDate method
- ✅ `flutter_app/lib/widgets/puzzle_card.dart` - Add isLocked state

## Summary

The archive and token system provides:

✅ **Additional Revenue Stream** - Rewarded video ads for tokens
✅ **Premium Conversion Driver** - Friction point encouraging subscriptions
✅ **User Engagement** - Access to unlimited puzzle content
✅ **Fair Free Tier** - Daily free token + ability to watch ads
✅ **Premium Value Prop** - Unlimited archive access differentiates paid tier

**Next Steps:**
1. Test the full flow on a device
2. Monitor token earning/spending metrics
3. A/B test token costs and rewards
4. Add token purchase IAPs
5. Implement dynamic pricing based on puzzle age

---

**Implementation Date:** 2025-12-14
**Status:** ✅ Complete
**Next Priority:** In-App Purchase for Token Packs & Premium Subscription
