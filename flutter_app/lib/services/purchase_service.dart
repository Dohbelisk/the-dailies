import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'admob_service.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // Product ID from environment configuration
  // Must match the ID configured in App Store Connect / Google Play Console
  static String get premiumProductId => Environment.iapPremiumProductId;

  // SharedPreferences keys
  static const String _subscriptionActiveKey = 'subscription_active';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _trialUsedKey = 'trial_used';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final AdMobService _adMobService = AdMobService();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isAvailable = false;
  bool _isPurchasing = false;
  ProductDetails? _premiumProduct;
  DateTime? _subscriptionExpiry;
  bool _trialUsed = false;

  // Callbacks for UI updates
  Function()? onPurchaseSuccess;
  Function(String error)? onPurchaseError;
  Function()? onRestoreSuccess;

  bool get isAvailable => _isAvailable;
  bool get isPremium => _adMobService.isPremiumUser;
  bool get isPurchasing => _isPurchasing;
  ProductDetails? get premiumProduct => _premiumProduct;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  bool get trialUsed => _trialUsed;

  // Get the price string for display
  String get premiumPriceString => _premiumProduct?.price ?? '\$1.99/month';

  // Get subscription details for display
  String get subscriptionDetails {
    if (_premiumProduct != null) {
      return '${_premiumProduct!.price}/month';
    }
    return '\$1.99/month';
  }

  // Check if user can get free trial
  bool get canGetFreeTrial => !_trialUsed;

  // Trial duration display
  String get trialDuration => '3 days';

  /// Initialize the purchase service
  Future<void> initialize() async {
    // Check if IAP is available on this device
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      debugPrint('In-App Purchases not available on this device');
      // Still check if we have a local record of subscription
      await _checkLocalSubscriptionStatus();
      return;
    }

    // Listen for purchase updates
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    // Load product details
    await _loadProducts();

    // Check subscription status
    await _checkLocalSubscriptionStatus();

    // Load trial status
    await _loadTrialStatus();

    debugPrint('PurchaseService initialized. Available: $_isAvailable, Premium: $isPremium');
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails({premiumProductId});

      if (response.error != null) {
        debugPrint('Error loading products: ${response.error}');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
        // This is expected in development/testing
      }

      if (response.productDetails.isNotEmpty) {
        _premiumProduct = response.productDetails.first;
        debugPrint('Premium subscription loaded: ${_premiumProduct!.title} - ${_premiumProduct!.price}');
      }
    } catch (e) {
      debugPrint('Exception loading products: $e');
    }
  }

  /// Check local storage for subscription status
  Future<void> _checkLocalSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_subscriptionActiveKey) ?? false;
    final expiryTimestamp = prefs.getInt(_subscriptionExpiryKey);

    if (expiryTimestamp != null) {
      _subscriptionExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      // Check if subscription has expired
      if (_subscriptionExpiry!.isAfter(DateTime.now())) {
        if (!_adMobService.isPremiumUser) {
          await _adMobService.setPremiumStatus(true);
          debugPrint('Subscription status restored from local storage');
        }
      } else {
        // Subscription expired
        await _revokeSubscription();
        debugPrint('Subscription expired');
      }
    } else if (isActive && !_adMobService.isPremiumUser) {
      // Legacy check for older versions
      await _adMobService.setPremiumStatus(true);
    }
  }

  /// Load trial usage status
  Future<void> _loadTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _trialUsed = prefs.getBool(_trialUsedKey) ?? false;
  }

  /// Mark trial as used
  Future<void> _markTrialUsed() async {
    _trialUsed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trialUsedKey, true);
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  /// Process a single purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint('Processing purchase: ${purchase.productID} - ${purchase.status}');

    if (purchase.status == PurchaseStatus.pending) {
      _isPurchasing = true;
      debugPrint('Purchase pending...');
      return;
    }

    _isPurchasing = false;

    if (purchase.status == PurchaseStatus.error) {
      debugPrint('Purchase error: ${purchase.error}');
      onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed');

      // Complete the purchase to clear it from the queue
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status == PurchaseStatus.canceled) {
      debugPrint('Purchase canceled');

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {

      // Verify this is our premium product
      if (purchase.productID == premiumProductId) {
        // Mark trial as used since they subscribed
        await _markTrialUsed();

        // Grant subscription access
        await _grantSubscription();

        if (purchase.status == PurchaseStatus.restored) {
          onRestoreSuccess?.call();
        } else {
          onPurchaseSuccess?.call();
        }
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  /// Grant subscription access to the user
  Future<void> _grantSubscription() async {
    // Update AdMobService (which all other services check)
    await _adMobService.setPremiumStatus(true);

    // Set expiry to 30 days from now (will be refreshed on restore)
    _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));

    // Save locally as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionActiveKey, true);
    await prefs.setInt(_subscriptionExpiryKey, _subscriptionExpiry!.millisecondsSinceEpoch);

    debugPrint('Subscription granted! Expires: $_subscriptionExpiry');
  }

  /// Revoke subscription access
  Future<void> _revokeSubscription() async {
    await _adMobService.setPremiumStatus(false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionActiveKey, false);
    await prefs.remove(_subscriptionExpiryKey);

    _subscriptionExpiry = null;

    debugPrint('Subscription revoked');
  }

  /// Initiate a subscription purchase
  Future<bool> purchasePremium() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Store not available');
      return false;
    }

    if (_premiumProduct == null) {
      // Try to load products again
      await _loadProducts();

      if (_premiumProduct == null) {
        onPurchaseError?.call('Product not available');
        return false;
      }
    }

    if (_isPurchasing) {
      onPurchaseError?.call('Purchase already in progress');
      return false;
    }

    if (isPremium) {
      onPurchaseError?.call('Already subscribed');
      return false;
    }

    _isPurchasing = true;

    try {
      final purchaseParam = PurchaseParam(
        productDetails: _premiumProduct!,
      );

      // For subscriptions, we still use buyNonConsumable
      // The subscription nature is configured in the store (App Store Connect / Play Console)
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _isPurchasing = false;
        onPurchaseError?.call('Could not initiate purchase');
        return false;
      }

      return true;
    } catch (e) {
      _isPurchasing = false;
      onPurchaseError?.call('Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Store not available');
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Restore purchases initiated');
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      onPurchaseError?.call('Could not restore purchases: $e');
    }
  }

  /// Check if the product is available for purchase
  bool get canPurchase => _isAvailable && _premiumProduct != null && !isPremium && !_isPurchasing;

  /// Get purchase status for display
  String getPurchaseStatusText() {
    if (isPremium) return 'Premium Active';
    if (!_isAvailable) return 'Store Unavailable';
    if (_isPurchasing) return 'Processing...';
    if (_premiumProduct == null) return 'Loading...';
    return 'Subscribe to Premium';
  }

  /// Get subscription status details
  String getSubscriptionStatusDetails() {
    if (!isPremium) return '';
    if (_subscriptionExpiry != null) {
      final daysLeft = _subscriptionExpiry!.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        return 'Renews in $daysLeft days';
      }
    }
    return 'Active subscription';
  }

  /// Cleanup
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
