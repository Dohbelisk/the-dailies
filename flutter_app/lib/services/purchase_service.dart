import 'dart:async';
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

  // SharedPreferences key for premium status backup
  static const String _premiumPurchasedKey = 'premium_purchased';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final AdMobService _adMobService = AdMobService();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isAvailable = false;
  bool _isPurchasing = false;
  ProductDetails? _premiumProduct;

  // Callbacks for UI updates
  Function()? onPurchaseSuccess;
  Function(String error)? onPurchaseError;
  Function()? onRestoreSuccess;

  bool get isAvailable => _isAvailable;
  bool get isPremium => _adMobService.isPremiumUser;
  bool get isPurchasing => _isPurchasing;
  ProductDetails? get premiumProduct => _premiumProduct;

  // Get the price string for display
  String get premiumPriceString => _premiumProduct?.price ?? '\$4.99';

  /// Initialize the purchase service
  Future<void> initialize() async {
    // Check if IAP is available on this device
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      print('In-App Purchases not available on this device');
      // Still check if we have a local record of premium purchase
      await _checkLocalPremiumStatus();
      return;
    }

    // Listen for purchase updates
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Load product details
    await _loadProducts();

    // Check for any pending purchases
    await _checkLocalPremiumStatus();

    print('PurchaseService initialized. Available: $_isAvailable, Premium: $isPremium');
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails({premiumProductId});

      if (response.error != null) {
        print('Error loading products: ${response.error}');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
        // This is expected in development/testing
      }

      if (response.productDetails.isNotEmpty) {
        _premiumProduct = response.productDetails.first;
        print('Premium product loaded: ${_premiumProduct!.title} - ${_premiumProduct!.price}');
      }
    } catch (e) {
      print('Exception loading products: $e');
    }
  }

  /// Check local storage for premium status (backup in case store is unavailable)
  Future<void> _checkLocalPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPurchased = prefs.getBool(_premiumPurchasedKey) ?? false;

    if (isPurchased && !_adMobService.isPremiumUser) {
      // Restore premium status from local backup
      await _adMobService.setPremiumStatus(true);
      print('Premium status restored from local storage');
    }
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  /// Process a single purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    print('Processing purchase: ${purchase.productID} - ${purchase.status}');

    if (purchase.status == PurchaseStatus.pending) {
      _isPurchasing = true;
      print('Purchase pending...');
      return;
    }

    _isPurchasing = false;

    if (purchase.status == PurchaseStatus.error) {
      print('Purchase error: ${purchase.error}');
      onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed');

      // Complete the purchase to clear it from the queue
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status == PurchaseStatus.canceled) {
      print('Purchase canceled');

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {

      // Verify this is our premium product
      if (purchase.productID == premiumProductId) {
        await _grantPremium();

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

  /// Grant premium status to the user
  Future<void> _grantPremium() async {
    // Update AdMobService (which all other services check)
    await _adMobService.setPremiumStatus(true);

    // Also save locally as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumPurchasedKey, true);

    print('Premium status granted!');
  }

  /// Initiate a premium purchase
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
      onPurchaseError?.call('Already premium');
      return false;
    }

    _isPurchasing = true;

    try {
      final purchaseParam = PurchaseParam(
        productDetails: _premiumProduct!,
      );

      // For non-consumable products, use buyNonConsumable
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
      print('Restore purchases initiated');
    } catch (e) {
      print('Restore purchases error: $e');
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
    return 'Upgrade to Premium';
  }

  /// Cleanup
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
