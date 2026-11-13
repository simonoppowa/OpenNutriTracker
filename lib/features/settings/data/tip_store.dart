import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// The store calls the tip jar makes, behind one seam so the plugin never
/// loads under `flutter test` and the purchase handling can be tested with a
/// fake.
abstract class TipStore {
  /// Every purchase update, including ones left unfinished by an earlier run
  /// of the app.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Whether this device can reach the platform store at all.
  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);

  /// Opens the store's purchase sheet. The outcome arrives on
  /// [purchaseStream].
  Future<bool> buyConsumable(ProductDetails product);

  Future<void> completePurchase(PurchaseDetails purchase);

  /// Re-delivers owned purchases on [purchaseStream] as
  /// [PurchaseStatus.restored]. On Android that is every tip not yet
  /// consumed.
  Future<void> restorePurchases();

  /// Whether purchases have to be consumed by the app (Google Play) before
  /// the same tip can be bought again.
  bool get needsConsume;

  /// Consumes [purchase] on Google Play, and reports whether Play confirmed
  /// it. Never called where [needsConsume] is false.
  Future<bool> consume(PurchaseDetails purchase);
}

/// [TipStore] on the `in_app_purchase` plugin: StoreKit 2 on iOS, Play
/// Billing on Android.
class InAppPurchaseTipStore implements TipStore {
  InAppPurchase get _iap => InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream.map(
    (purchases) => [for (final purchase in purchases) withPlayState(purchase)],
  );

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);

  /// On Android the tip jar consumes every tip itself (see [consume]), so the
  /// plugin's own auto-consume is off there: it only remembers purchases
  /// started in the current process, and one consume path for all tips is
  /// simpler than two that overlap. StoreKit requires `autoConsume: true`.
  @override
  Future<bool> buyConsumable(ProductDetails product) => _iap.buyConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
    autoConsume: !needsConsume,
  );

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  bool get needsConsume => Platform.isAndroid;

  @override
  Future<bool> consume(PurchaseDetails purchase) async {
    final result = await _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .consumePurchase(purchase);
    return result.responseCode == BillingResponse.ok;
  }
}

/// The Android plugin marks everything `restorePurchases` returns as
/// restored, including a purchase whose payment is still pending (a cash
/// payment, say). That one cannot be consumed yet, so it is reported as
/// pending instead; it arrives again as purchased once the payment clears.
@visibleForTesting
PurchaseDetails withPlayState(PurchaseDetails purchase) {
  if (purchase is GooglePlayPurchaseDetails &&
      purchase.status == PurchaseStatus.restored &&
      purchase.billingClientPurchase.purchaseState !=
          PurchaseStateWrapper.purchased) {
    purchase.status = PurchaseStatus.pending;
  }
  return purchase;
}
