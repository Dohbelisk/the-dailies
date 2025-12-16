# 📱 AdMob Advertising Implementation Guide

## Overview

The Dailies app now includes a complete advertising monetization system using Google AdMob. This implementation supports a freemium model with ad-supported free tier and premium subscription option.

## What Was Implemented

### 1. AdMob Service (`flutter_app/lib/services/admob_service.dart`)

A singleton service that manages all ad operations:

**Features:**
- Banner ads (320x50)
- Interstitial ads (full screen)
- Rewarded video ads
- Premium user detection (automatically skips ads)
- Ad performance tracking
- Automatic ad pre-loading

**Key Methods:**
```dart
await AdMobService().initialize()           // Initialize AdMob SDK
await loadBannerAd()                        // Load banner ad
await showInterstitialAd()                  // Show interstitial (respects frequency)
await loadAndShowRewardedAd(onRewarded: (reward) {}) // Show rewarded video
await setPremiumStatus(bool isPremium)      // Update premium status
```

### 2. Hint Service (`flutter_app/lib/services/hint_service.dart`)

Manages hint availability and rewarded video ads:

**Features:**
- 3 free hints per day for free users
- Daily hint reset at midnight
- Watch rewarded video ads to get 3 more hints
- Premium users get unlimited hints
- Persistent hint count storage

**Key Methods:**
```dart
await HintService().initialize()            // Load hint count from storage
await useHint()                             // Use one hint (returns true if available)
await watchAdForHints()                     // Show rewarded ad for hints
int availableHints                          // Get current hint count
bool isPremium                              // Check premium status
```

### 3. Ad Placements

#### Banner Ads
**Location:** Bottom of home screen
**File:** `flutter_app/lib/screens/home_screen.dart`
**Behavior:**
- Always visible on home screen
- Positioned at bottom using Stack/Positioned
- Automatically disposed when leaving screen
- Hidden for premium users

#### Interstitial Ads
**Location:** After puzzle completion
**File:** `flutter_app/lib/screens/game_screen.dart`
**Behavior:**
- Shows after completion dialog is dismissed
- Frequency control: Every 2-3 completed puzzles
- Automatic pre-loading of next ad
- Never shown to premium users

#### Rewarded Video Ads
**Location:** Hint system in Sudoku/Killer Sudoku games
**File:** `flutter_app/lib/screens/game_screen.dart`
**Behavior:**
- Triggered when user runs out of hints
- Shows dialog offering to watch video for 3 hints
- Rewards granted after video completion
- Premium users skip this (unlimited hints)

### 4. Platform Configuration

#### Android (`flutter_app/android/app/src/main/AndroidManifest.xml`)
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

#### iOS (`flutter_app/ios/Runner/Info.plist`)
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
<key>SKAdNetworkItems</key>
<array>
    <!-- 22 SKAdNetwork identifiers added for attribution -->
</array>
```

### 5. Dependencies (`flutter_app/pubspec.yaml`)
```yaml
dependencies:
  google_mobile_ads: ^5.1.0
  in_app_purchase: ^3.2.0
  shared_preferences: ^2.2.2  # For hint count persistence
```

## User Experience Flow

### Free User Flow

1. **Open App**
   - See banner ad at bottom of home screen

2. **Play Puzzle**
   - Complete puzzle
   - View completion dialog
   - After dismissing: Interstitial ad shows (every 2-3 games)

3. **Use Hints**
   - Start with 3 free hints per day
   - When hints run out: Dialog offers to watch video for 3 more
   - Watch 30-second video → Get 3 hints
   - Can watch multiple times

4. **Next Day**
   - Hints reset to 3 free hints
   - Cycle continues

### Premium User Flow

1. **Subscribe to Premium** (not yet implemented)
   - All ads disappear
   - Unlimited hints
   - No prompts or interruptions

## Revenue Model

### Free Tier (Ad-Supported)
- **Banner Ads:** ~$0.50 CPM
- **Interstitial Ads:** ~$3-5 CPM
- **Rewarded Ads:** ~$10-15 CPM
- **Expected:** $0.50 - $2.00 per user per month

### Premium Tier (Subscription)
- **Price:** $4.99/month or $39.99/year
- **Features:** Ad-free, unlimited hints, premium themes
- **Expected:** $4.99 per user per month

See `MONETIZATION.md` for detailed revenue projections.

## Testing

### Test Ad Units (Currently Active)

**DO NOT** use these in production - they won't generate revenue!

**Android:**
```dart
Banner:       ca-app-pub-3940256099942544/6300978111
Interstitial: ca-app-pub-3940256099942544/1033173712
Rewarded:     ca-app-pub-3940256099942544/5224354917
```

**iOS:**
```dart
Banner:       ca-app-pub-3940256099942544/2934735716
Interstitial: ca-app-pub-3940256099942544/4411468910
Rewarded:     ca-app-pub-3940256099942544/1712485313
```

### How to Test

1. **Run the app:**
   ```bash
   cd flutter_app
   flutter run
   ```

2. **Test Banner Ad:**
   - Open home screen
   - Verify banner appears at bottom
   - Should load within 1-2 seconds

3. **Test Interstitial Ad:**
   - Complete 2 puzzles
   - On 2nd or 3rd completion, interstitial should show
   - Verify ad dismisses properly

4. **Test Rewarded Video Ad:**
   - Play Sudoku/Killer Sudoku
   - Use all 3 free hints
   - Tap hint button again
   - Dialog should offer to watch video
   - Watch video → Verify 3 hints added

## Production Deployment

### ⚠️ CRITICAL: Replace Test Ad IDs

Before releasing, you MUST:

1. **Create AdMob Account**
   - Go to https://apps.admob.com
   - Create new app
   - Create 3 ad units: Banner, Interstitial, Rewarded

2. **Update Ad Unit IDs**
   - Edit `flutter_app/lib/services/admob_service.dart`
   - Replace lines 11-21 with your production IDs:
   ```dart
   static const String _bannerAdUnitId = Platform.isAndroid
       ? 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY' // Your Android ID
       : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your iOS ID
   ```

3. **Update App IDs**
   - **Android:** `flutter_app/android/app/src/main/AndroidManifest.xml` line 36
   - **iOS:** `flutter_app/ios/Runner/Info.plist` line 50

4. **Test with Production IDs**
   - Use AdMob test devices to avoid policy violations
   - Add your device ID in AdMob settings
   - Verify ads load correctly

## Performance Optimizations

### Current Optimizations

1. **Ad Pre-loading**
   - Interstitial ads pre-loaded after previous one dismisses
   - Minimizes wait time for users

2. **Frequency Capping**
   - Interstitials: Max 1 per 2-3 games
   - Prevents user annoyance
   - Maintains engagement

3. **Graceful Degradation**
   - If ads fail to load, game continues normally
   - Error messages logged (not shown to user)
   - Premium users never see loading attempts

4. **Memory Management**
   - Ads properly disposed when screens unmount
   - No memory leaks

## Analytics & Metrics

### Current Tracking

The AdMobService tracks:
- Banner impressions
- Interstitial impressions
- Rewarded video impressions

**Access metrics:**
```dart
Map<String, int> stats = AdMobService().getAdStats();
// Returns: { bannerImpressions, interstitialImpressions, rewardedImpressions }
```

### Recommended Metrics to Add

1. **Ad Revenue**
   - Track eCPM (effective cost per mille)
   - Monitor by ad type

2. **User Engagement**
   - Rewarded video completion rate
   - Interstitial skip rate

3. **Conversion Tracking**
   - Free to premium conversion rate
   - Impact of ad frequency on retention

## Troubleshooting

### Common Issues

**1. Ads not loading**
- ✅ Check internet connection
- ✅ Verify ad unit IDs are correct
- ✅ Ensure AdMob account is active
- ✅ Check AdMob dashboard for fill rates

**2. Blank banner space**
- ✅ Banner ad may be loading
- ✅ Check console for error messages
- ✅ Verify AdMob initialization completed

**3. Rewarded video doesn't grant reward**
- ✅ Ensure video plays to completion
- ✅ Check `onUserEarnedReward` callback
- ✅ Verify HintService.addHints() is called

**4. Premium users seeing ads**
- ✅ Check `_isPremiumUser` flag in AdMobService
- ✅ Verify SharedPreferences has 'is_premium' = true
- ✅ Call `AdMobService().setPremiumStatus(true)`

### Debug Logging

Check Flutter console for these messages:
```
✅ AdMob initialized successfully
✅ Banner ad loaded
✅ Interstitial ad loaded
✅ Rewarded ad loaded
📖 Interstitial ad showed
🎁 User earned reward: 3
⏭️  Skipping interstitial ad (counter: 1)
```

## Privacy & Compliance

### Required Before Production

1. **Privacy Policy**
   - Disclose ad data collection
   - Link in app settings
   - Include AdMob's data usage

2. **GDPR Compliance (EU Users)**
   - Implement consent dialog
   - Use UMP SDK (User Messaging Platform)
   - Allow opt-out of personalized ads

3. **COPPA Compliance**
   - App is 13+ (puzzle games)
   - No data collection from children
   - Age gate on first launch

4. **App Store Listings**
   - Declare ad usage in App Store Connect
   - Mark "Contains Ads" in Play Console

## Files Modified/Created

### Created Files
- ✅ `flutter_app/lib/services/admob_service.dart` (260 lines)
- ✅ `flutter_app/lib/services/hint_service.dart` (85 lines)
- ✅ `MONETIZATION.md` (432 lines)
- ✅ `ADS_IMPLEMENTATION.md` (this file)

### Modified Files
- ✅ `flutter_app/pubspec.yaml` - Added dependencies
- ✅ `flutter_app/lib/main.dart` - Initialize services
- ✅ `flutter_app/lib/screens/home_screen.dart` - Banner ad integration
- ✅ `flutter_app/lib/screens/game_screen.dart` - Interstitial & rewarded ads
- ✅ `flutter_app/android/app/src/main/AndroidManifest.xml` - AdMob app ID
- ✅ `flutter_app/ios/Runner/Info.plist` - AdMob app ID & SKAdNetwork

## Next Steps

1. **Implement In-App Purchases** (Premium subscriptions)
   - Create SubscriptionService
   - Add monthly/annual plans
   - Integrate with App Store/Play Store

2. **Backend Integration**
   - Add subscription schema
   - Create subscription endpoints
   - Handle App Store/Play Store webhooks

3. **Revenue Analytics**
   - Build admin dashboard
   - Track ad revenue by type
   - Monitor conversion rates

4. **Production Launch**
   - Replace test ad IDs
   - Add privacy policy
   - Implement GDPR consent
   - Submit to stores

## Support Resources

- [AdMob Documentation](https://developers.google.com/admob)
- [Flutter AdMob Plugin](https://pub.dev/packages/google_mobile_ads)
- [AdMob Policy](https://support.google.com/admob/answer/6128543)
- [In-App Purchase Guide](https://pub.dev/packages/in_app_purchase)

---

**Implementation Date:** 2025-12-14
**Implementation Status:** ✅ Complete (Ad System)
**Next Priority:** In-App Purchase Subscriptions
