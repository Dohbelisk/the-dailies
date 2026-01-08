# Monetization System

Freemium model with AdMob advertising, token-based archive access, and in-app purchase subscriptions.

## AdMob Integration

| Ad Type | Trigger | Reward |
|---------|---------|--------|
| Rewarded video | Watch for hints | 3 hints |
| Rewarded video | Watch for tokens | 5 tokens |
| Interstitial | After puzzle completion | Every 2-3 games |

- Premium users skip all ads automatically
- GDPR consent tracked via `ConsentService`

## Token System

- 1 free token per day (resets at midnight)
- Token costs by difficulty:
  - Easy: 1 token
  - Medium: 2 tokens
  - Hard/Expert: 3 tokens
- Watch rewarded ads for 5 tokens
- Premium users have unlimited archive access

## Hint System

- 3 free hints per day
- Watch rewarded ads for 3 more hints
- Premium users have unlimited hints

## In-App Purchases

Handled by `PurchaseService` in Flutter app.

### Premium Subscription
- Type: Auto-renewable subscription (monthly)
- Product ID: `premium_monthly`
- Configured in App Store Connect
- Features:
  - Ad-free experience
  - Unlimited hints
  - Unlimited archive access

### Purchase Lifecycle
- States: pending, purchased, restored, error
- Local backup storage for premium status
- Restore purchases functionality available

## iOS Subscription Setup (App Store Connect)

1. Create subscription group in App Store Connect → Subscriptions
2. Add auto-renewable subscription with product ID `premium_monthly`
3. Set pricing (e.g., $4.99/month)
4. Configure introductory offer (e.g., 1 week free trial) in Subscription Prices → Introductory Offers
5. The Flutter app's `PurchaseService` handles all purchase flows automatically

## Revenue Model

### Free Tier
| Ad Type | Estimated CPM |
|---------|---------------|
| Banner | ~$0.50 |
| Interstitial | ~$3-5 |
| Rewarded | ~$10-15 |

### Premium Tier
- Monthly: $4.99/month
- Yearly: $39.99/year
- Benefits: Ad-free, unlimited hints, unlimited archive

## Configuration Files

- Android: `flutter_app/android/app/src/main/AndroidManifest.xml`
- iOS: `flutter_app/ios/Runner/Info.plist`
- Environment: `flutter_app/lib/config/environment.dart`

## Test Ad Units

**Important:** Test ad IDs must be replaced with production IDs before release.

See also:
- `MONETIZATION.md` - Revenue strategy details
- `ADS_IMPLEMENTATION.md` - AdMob technical guide
- `ARCHIVE_SYSTEM.md` - Token system guide
