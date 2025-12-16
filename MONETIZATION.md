# The Dailies - Monetization Strategy

## Overview

The Dailies uses a **freemium model** with voluntary rewarded ads and an optional one-time premium purchase.

## Monetization Tiers

### Free Tier (Ad-Supported)
**Features:**
- Access to all daily puzzles
- Unlimited gameplay
- Basic statistics
- Limited hints (3 free per day)
- Limited archive access (requires tokens)

**Ads (100% Voluntary - User Choice):**
- Rewarded video ads for extra hints (3 hints per video)
- Rewarded video ads for tokens (5 tokens per video, used for archive access)
- Rewarded video ads for retries when out of mistakes

**Expected Revenue:** $0.30 - $1.50 per user per month (via rewarded ads only)

---

### Premium Tier (One-Time Purchase)
**Price:** $4.99 (one-time, lifetime access)

**Features:**
- **Unlimited Hints** - Get help whenever you need (no ads required)
- **Unlimited Archive Access** - Play any past puzzle without tokens
- **Unlimited Retries** - Never lose progress when you run out of mistakes
- **Support Development** - Help keep the app updated

**Premium Value Drivers:**
1. Skip all reward video ads - instant access to hints, retries, and archives
2. No token economy - unlimited archive access
3. No daily limits on hints or retries
4. One-time payment, no recurring charges

---

## Ad Placement Strategy

### Rewarded Video Ads (100% User-Initiated - No Forced Ads)

All ads are completely voluntary. Users choose when and if they want to watch ads in exchange for in-game benefits.

#### 1. Hint Rewards
**Location:** Hint button prompt (Sudoku/Killer Sudoku)
**Frequency:** User choice (when hints run out)
**Type:** AdMob Rewarded Video
**Reward:** 3 extra hints
**Revenue:** ~$10-15 CPM

**Implementation:**
```dart
// Show when:
// - User has 0 hints left
// - User taps hint button
// Reward: +3 hints
// Skip if: Premium user (unlimited hints)
```

#### 2. Token Rewards (Archive System)
**Location:** Archive screen, puzzle unlock prompts
**Frequency:** User choice (when tokens run out)
**Type:** AdMob Rewarded Video
**Reward:** 5 tokens
**Revenue:** ~$10-15 CPM

**Implementation:**
```dart
// Show when:
// - User wants to play archive puzzle but lacks tokens
// - User taps "Get Tokens" → "Watch Video"
// Reward: +5 tokens
// Skip if: Premium user (unlimited archive access)
```

#### 3. Retry Rewards (Mistake Recovery)
**Location:** Game over prompt when user runs out of mistakes
**Frequency:** User choice (when mistakes limit reached)
**Type:** AdMob Rewarded Video
**Reward:** Continue playing with mistakes reset
**Revenue:** ~$10-15 CPM

**Implementation:**
```dart
// Show when:
// - User runs out of allowed mistakes
// - Game over dialog appears
// - User taps "Watch Ad to Continue"
// Reward: Reset mistakes counter, continue puzzle
// Skip if: Premium user (unlimited retries)
```

---

## Revenue Projections

**Note:** All ad revenue is from voluntary rewarded video ads only. No forced ads means better user experience.

### Conservative Estimate (1,000 DAU)

**Free Users (85% - 850 users):**
- Rewarded ads for hints: 50 views/day × $0.012 = $0.60/day
- Rewarded ads for tokens: 80 views/day × $0.012 = $0.96/day
- Rewarded ads for retries: 30 views/day × $0.012 = $0.36/day
- **Subtotal:** $1.92/day = **$57.60/month**

**Premium Purchases (15% conversion over time):**
- ~150 purchases × $4.99 = **$748.50** (one-time)
- Ongoing: New user conversions

**Monthly Ad Revenue:** ~$58
**Initial Premium Revenue:** ~$750 (then ongoing from new users)

---

### Optimistic Estimate (10,000 DAU)

**Free Users (80% - 8,000 users):**
- Rewarded ads for hints: 800 views/day × $0.015 = $12/day
- Rewarded ads for tokens: 1,200 views/day × $0.015 = $18/day
- Rewarded ads for retries: 500 views/day × $0.015 = $7.50/day
- **Subtotal:** $37.50/day = **$1,125/month**

**Premium Purchases (20% conversion):**
- ~2,000 purchases × $4.99 = **$9,980** (one-time)

**Key Insight:** One-time purchases are simpler for users (no recurring charges to worry about) and can drive higher conversion rates than subscriptions for casual games.

---

## Ad Configuration

### AdMob Setup
```yaml
# Android
android/app/build.gradle:
  - Add AdMob App ID in AndroidManifest.xml

# iOS
ios/Runner/Info.plist:
  - Add GADApplicationIdentifier
  - Add SKAdNetworkIdentifier items
```

### Test Ad Unit IDs (Development)
```dart
// Rewarded Video (used for hints, tokens, retries)
Android: ca-app-pub-3940256099942544/5224354917
iOS: ca-app-pub-3940256099942544/1712485313
```

### Production Ad Unit IDs
```dart
// Replace with your actual AdMob rewarded video ID
// Get from: https://apps.admob.com
// Only need ONE rewarded video ad unit (used for all three purposes)
```

---

## In-App Purchase Products

### Premium Upgrade (One-Time)
```dart
Product ID: premium_upgrade
Price: $4.99
Type: Non-consumable (permanent unlock)
Platform: iOS App Store / Google Play Store
```

**What Premium Unlocks:**
- Unlimited hints (bypass 3/day limit)
- Unlimited archive access (bypass token system)
- Unlimited retries (bypass mistake limits)
- No ads shown (reward ad options hidden)

---

## User Flow

### First Launch (New User)
1. Play first puzzle (no forced ads, completely ad-free until they choose)
2. After completion: Brief premium benefits mention
3. Continue as free user → Can optionally watch ads for rewards

### Free User Flow
1. Open app → No ads, clean interface
2. Play puzzle → No forced interruptions
3. Complete puzzle → No ads
4. Run out of hints → Prompt: "Watch ad for 3 hints" or "Go Premium ($4.99)"
5. Want to play archive → Prompt: "Watch ad for 5 tokens" or "Go Premium"
6. Run out of mistakes → Prompt: "Watch ad to retry" or "Go Premium"
7. User is always in control - they choose if/when to watch ads

### Premium User Flow
1. Purchase premium → Unlock all features permanently
2. No ads available (all ad options replaced with instant access)
3. Unlimited hints, retries, and archive access
4. Purchase syncs across devices via App Store/Play Store

---

## Privacy & Compliance

### GDPR (Europe)
- Implement consent dialog for ads
- Allow users to opt-out of personalized ads
- Privacy policy link in settings

### COPPA (Children's Privacy)
- App is 13+ (puzzle games are educational)
- No data collection from children

### App Store Requirements
- Clear description of premium features
- Restore purchases functionality
- No misleading purchase prompts

---

## Analytics Tracking

### Key Metrics
- Rewarded ad impressions
- Rewarded ad completion rate
- Ad revenue (eCPM)
- Premium conversion rate
- Average revenue per user (ARPU)

---

## Implementation Checklist

### Flutter App
- [x] Add google_mobile_ads package
- [x] Configure AdMob app IDs (Android & iOS)
- [x] Create AdMobService (rewarded video only)
- [x] Implement rewarded video ads for hints
- [x] Implement rewarded video ads for archive tokens
- [x] Create HintService (3 free hints/day, watch ad for 3 more)
- [x] Create TokenService (daily free token, watch ad for 5 more)
- [ ] Implement retry system with rewarded video ads
- [x] Add in_app_purchase package
- [ ] Create PurchaseService (one-time IAP)
- [ ] Add premium feature gates
- [ ] Add restore purchases
- [ ] Add premium purchase UI in settings

### Backend
- [ ] Add isPremium field to User schema (optional - can be client-only)
- [ ] Add analytics tracking endpoints (optional)

### Legal
- [ ] Create privacy policy
- [ ] Create terms of service
- [ ] Implement GDPR consent

---

## Testing Strategy

### Ad Testing
1. Use test ad units in development
2. Verify ads load correctly
3. Test rewarded ad rewards are granted
4. Test premium user ad blocking

### Purchase Testing
1. Use sandbox environment (App Store/Play Store)
2. Test purchase flow
3. Test restore purchases
4. Verify premium status persists
5. Test premium features unlock correctly

---

## Best Practices

### Ad Quality (Rewarded Ads Only)
- Only show ads when user explicitly chooses to watch
- Never interrupt gameplay with forced ads
- Clearly communicate the reward before showing ad
- Respect user's premium status (no ad options for premium users)
- Make sure rewards are granted reliably

### User Experience
- Prioritize user choice and control
- Make premium value clear without aggressive prompts
- One-time purchase = no recurring worry for users
- Reward loyal users with daily free tokens/hints
- Never punish free users - ads should feel like opportunities

### Revenue Optimization
- Track rewarded ad completion rates
- Test different reward amounts
- Consider regional pricing for premium
- Offer occasional sales/promotions

---

## Support & Resources

- [AdMob Documentation](https://developers.google.com/admob)
- [App Store In-App Purchase](https://developer.apple.com/in-app-purchase/)
- [Google Play Billing](https://developer.android.com/google/play/billing)
- [Flutter google_mobile_ads](https://pub.dev/packages/google_mobile_ads)
- [Flutter in_app_purchase](https://pub.dev/packages/in_app_purchase)

---

## Production Configuration

Before releasing to production, you MUST replace the test ad unit IDs with your production IDs:

### Files to Update:

1. **flutter_app/lib/services/admob_service.dart**
   - Replace test IDs with your AdMob production IDs
   - Get production IDs from: https://apps.admob.com

2. **flutter_app/android/app/src/main/AndroidManifest.xml**
   - Replace test app ID: `ca-app-pub-3940256099942544~3347511713`

3. **flutter_app/ios/Runner/Info.plist**
   - Replace test app ID: `ca-app-pub-3940256099942544~1458002511`

**WARNING:** Test ads will NOT generate revenue. You MUST use production IDs for real earnings.

---

## Implementation Status

### Completed
**Advertising System (Voluntary Only):**
- AdMob integration (Android & iOS)
- Rewarded video ads for hints (3 hints per video)
- Hint management system (3 free/day, watch ad for 3 more)
- Premium user detection (unlimited hints, no ads needed)

**Archive & Token System:**
- Token economy implementation
- Archive screen with date navigation
- Token balance widget
- Daily free token distribution (1 per day)
- Rewarded video ads for tokens (5 tokens per video)
- Token costs by difficulty (Easy: 1, Medium: 2, Hard: 3)
- Premium unlimited archive access

### Pending
- [ ] PurchaseService for one-time premium IAP
- [ ] Premium purchase UI (settings screen)
- [ ] Restore purchases functionality
- [ ] Retry system with rewarded video ads
- [ ] Production ad unit IDs
- [ ] Privacy policy & terms of service
- [ ] GDPR consent dialog

---

**Next Steps:**
1. Create PurchaseService for one-time premium purchase
2. Add premium upgrade UI to settings screen
3. Implement retry system with rewarded video ads
4. Test all flows on device
5. Replace test ad IDs with production IDs
6. Add privacy policy and GDPR compliance
