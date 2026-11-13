import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/features/settings/data/tip_store.dart';

/// A [TipStore] whose answers each test sets, and which records every call
/// the tip jar makes.
class FakeTipStore implements TipStore {
  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  @override
  bool needsConsume = false;

  /// What [queryProductDetails] returns; null makes it throw.
  List<ProductDetails>? products = tipProducts();

  /// Completes [queryProductDetails] only when completed, when set.
  Completer<void>? queryGate;

  /// Per-call answers, taken in order before [queryGate] and [products]:
  /// a gate to wait on (or null) and the products (null throws).
  final queryScript = <(Completer<void>?, List<ProductDetails>?)>[];
  bool buyResult = true;
  bool buyThrows = false;
  bool consumeResult = true;
  bool consumeThrows = false;
  bool restoreThrows = false;

  /// Holds [consume] in flight until completed, when set.
  Completer<void>? consumeGate;

  /// Per-call gates for [consume], taken in order before [consumeGate].
  final consumeGates = <Completer<void>>[];

  /// Holds [restorePurchases] until completed, when set; then it delivers
  /// [restoreEmits] on the purchase stream, as Play does.
  Completer<void>? restoreGate;
  List<PurchaseDetails> restoreEmits = const [];

  /// Store calls in order: `consume`, `complete`, `buy`, `restore`.
  final calls = <String>[];

  int queryCalls = 0;
  int restoreCalls = 0;
  final bought = <ProductDetails>[];
  final consumed = <PurchaseDetails>[];
  final completed = <PurchaseDetails>[];

  /// Delivers [purchases] the way the store would.
  void emit(List<PurchaseDetails> purchases) => _purchases.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queryCalls++;
    var gate = queryGate;
    var found = products;
    if (queryScript.isNotEmpty) (gate, found) = queryScript.removeAt(0);
    await gate?.future;
    if (found == null) throw StateError('store unreachable');
    return ProductDetailsResponse(
      productDetails: found.where((p) => ids.contains(p.id)).toList(),
      notFoundIDs: [
        for (final id in ids)
          if (!found.any((p) => p.id == id)) id,
      ],
    );
  }

  @override
  Future<bool> buyConsumable(ProductDetails product) async {
    calls.add('buy');
    bought.add(product);
    if (buyThrows) throw StateError('sheet failed');
    return buyResult;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    calls.add('complete');
    completed.add(purchase);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    calls.add('restore');
    await restoreGate?.future;
    if (restoreThrows) throw StateError('billing unavailable');
    if (restoreEmits.isNotEmpty) emit(restoreEmits);
  }

  @override
  Future<bool> consume(PurchaseDetails purchase) async {
    calls.add('consume');
    consumed.add(purchase);
    await (consumeGates.isNotEmpty ? consumeGates.removeAt(0) : consumeGate)
        ?.future;
    if (consumeThrows) throw StateError('consume failed');
    return consumeResult;
  }

  Future<void> dispose() => _purchases.close();
}

/// Store products for the three tips, listed most expensive first so a test
/// sees the jar sort them.
List<ProductDetails> tipProducts({Set<String>? only}) => [
  _product('tip_large', '€9.99', 9.99),
  _product('tip_small', '€1.99', 1.99),
  _product('tip_medium', '€4.99', 4.99),
].where((p) => only == null || only.contains(p.id)).toList();

ProductDetails _product(String id, String price, double rawPrice) =>
    ProductDetails(
      id: id,
      title: id,
      description: id,
      price: price,
      rawPrice: rawPrice,
      currencyCode: 'EUR',
    );

PurchaseDetails tipPurchase(
  String productId,
  PurchaseStatus status, {
  bool pendingComplete = true,
  String? id,
}) => PurchaseDetails(
  purchaseID: id ?? 'order-$productId',
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: 'token-$productId',
    source: 'test',
  ),
  transactionDate: null,
  status: status,
)..pendingCompletePurchase = pendingComplete;

/// Only the two calls the tip jar makes; anything else fails the test.
class FakeTipConfig extends Fake implements ConfigRepository {
  bool hasLeftTip;
  int writes = 0;

  /// Makes [setHasLeftTip] throw, as a failing Hive write would.
  bool writeThrows = false;

  /// Holds [setHasLeftTip] in flight until completed, when set.
  Completer<void>? writeGate;

  /// Holds [getHasLeftTip]'s answer, read when it was called, until
  /// completed — a read that started before a write.
  Completer<void>? readGate;

  FakeTipConfig({this.hasLeftTip = false});

  @override
  Future<bool> getHasLeftTip() async {
    final value = hasLeftTip;
    await readGate?.future;
    return value;
  }

  @override
  Future<void> setHasLeftTip() async {
    writes++;
    await writeGate?.future;
    if (writeThrows) throw StateError('disk full');
    hasLeftTip = true;
  }
}
