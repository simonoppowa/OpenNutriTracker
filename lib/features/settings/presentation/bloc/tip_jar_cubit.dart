import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/features/settings/data/tip_store.dart';
import 'package:opennutritracker/features/settings/domain/entity/tip_entity.dart';

enum TipJarStatus { loading, failed, ready }

class TipJarState extends Equatable {
  final TipJarStatus status;

  /// The tips the store returned, cheapest first. Only the ones that loaded:
  /// a partial answer shows what it has.
  final List<TipEntity> tips;

  /// Whether a tip has gone through on this device. Shows a line of text and
  /// nothing else — anything more would be an unlock (#1534).
  final bool hasTipped;

  const TipJarState({
    this.status = TipJarStatus.loading,
    this.tips = const [],
    this.hasTipped = false,
  });

  TipJarState copyWith({
    TipJarStatus? status,
    List<TipEntity>? tips,
    bool? hasTipped,
  }) => TipJarState(
    status: status ?? this.status,
    tips: tips ?? this.tips,
    hasTipped: hasTipped ?? this.hasTipped,
  );

  @override
  List<Object?> get props => [status, tips, hasTipped];
}

/// Something the Support page tells the user once, rather than state it
/// keeps showing.
sealed class TipOutcome {
  const TipOutcome();
}

class TipThanked extends TipOutcome {
  final TipEntity tip;

  const TipThanked(this.tip);
}

/// The store took the order but the payment has not cleared (Play's
/// pending purchases). No thanks yet: it may never go through.
class TipPending extends TipOutcome {
  const TipPending();
}

class TipFailed extends TipOutcome {
  const TipFailed();
}

/// The Support page's tip jar: three consumable tips that unlock nothing
/// (#1534).
///
/// A singleton started at app launch ([start]) rather than a per-screen bloc,
/// because purchases do not wait for the screen: a transaction left
/// unfinished by an earlier run, or a pending Play payment that clears later,
/// arrives on the purchase stream whenever it likes and still has to be
/// finished, or the store refunds it.
///
/// Purchase details never reach the log or Sentry: the log lines below carry
/// fixed text only.
class TipJarCubit extends Cubit<TipJarState> {
  final _log = Logger('TipJarCubit');
  final TipStore _store;
  final ConfigRepository _config;

  final _outcomes = StreamController<TipOutcome>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  final Map<TipSize, ProductDetails> _products = {};
  bool _buying = false;

  TipJarCubit(this._store, this._config) : super(const TipJarState());

  Stream<TipOutcome> get outcomes => _outcomes.stream;

  /// Listens for purchases for the rest of the app's life and, on Google
  /// Play, consumes any tip an earlier run left unconsumed.
  ///
  /// The plugin's own auto-consume only knows purchases started in the
  /// current process, so a tip that completes after a restart (a pending
  /// payment, or the app killed mid-purchase) would otherwise stay owned:
  /// the user could not buy it again, and Play refunds it after three days.
  Future<void> start() async {
    if (_purchases != null) return;
    _purchases = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object _) =>
          _log.warning('The purchase stream reported an error'),
    );
    if (!_store.needsConsume) return;
    try {
      if (await _store.isAvailable()) await _store.restorePurchases();
    } catch (_) {
      _log.info('Could not check for unconsumed tips; the next start retries');
    }
  }

  /// Loads the tips from the store. Fails on anything short of at least one
  /// tip: no network, nothing returned, or a build the store does not know
  /// (the develop flavour, a sideloaded or GitHub APK, TestFlight without
  /// sandbox setup).
  Future<void> load() async {
    _emit(
      state.copyWith(
        status: TipJarStatus.loading,
        hasTipped: await _hasTipped(),
      ),
    );
    try {
      if (!await _store.isAvailable()) {
        _emit(state.copyWith(status: TipJarStatus.failed, tips: const []));
        return;
      }
      final response = await _store.queryProductDetails(TipSize.productIds);
      _products.clear();
      final tips = <TipEntity>[];
      for (final product in response.productDetails) {
        final size = TipSize.fromProductId(product.id);
        if (size == null) continue;
        _products[size] = product;
        tips.add(
          TipEntity(
            size: size,
            price: product.price,
            rawPrice: product.rawPrice,
          ),
        );
      }
      tips.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      _emit(
        state.copyWith(
          status: tips.isEmpty ? TipJarStatus.failed : TipJarStatus.ready,
          tips: tips,
        ),
      );
    } catch (_) {
      _log.info('Could not load the tips from the store');
      _emit(state.copyWith(status: TipJarStatus.failed, tips: const []));
    }
  }

  /// Opens the store's purchase sheet for [tip]. The result arrives on the
  /// purchase stream, not here.
  Future<void> buy(TipEntity tip) async {
    final product = _products[tip.size];
    if (product == null || _buying) return;
    _buying = true;
    try {
      if (!await _store.buyConsumable(product)) _tell(const TipFailed());
    } catch (_) {
      _log.info('The store did not open the purchase sheet');
      _tell(const TipFailed());
    } finally {
      _buying = false;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final size = TipSize.fromProductId(purchase.productID);
      // Play reports a failed or cancelled purchase that has no purchase
      // behind it with an empty product ID; anything else that is not a tip
      // is not this jar's.
      if (size == null && purchase.productID.isNotEmpty) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _tell(const TipPending());
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (size == null) continue;
          await _finish(purchase);
          await _markTipped();
          final tip = state.tips.firstWhereOrNull((t) => t.size == size);
          // A restored tip is one an earlier run left unconsumed, found at
          // start-up: the user is not on the page, so no dialog.
          if (purchase.status == PurchaseStatus.purchased && tip != null) {
            _tell(TipThanked(tip));
          }
        case PurchaseStatus.error:
          await _completeIfPending(purchase);
          _log.info('A tip purchase failed');
          _tell(const TipFailed());
        case PurchaseStatus.canceled:
          await _completeIfPending(purchase);
      }
    }
  }

  /// Consumes the tip on Google Play, so it can be bought again, or finishes
  /// the transaction on the App Store.
  ///
  /// A Play consume also acknowledges the purchase, so a consumed tip needs
  /// no [TipStore.completePurchase]. One that fails to consume is still
  /// acknowledged, which stops Play refunding it; the next start consumes it.
  Future<void> _finish(PurchaseDetails purchase) async {
    if (_store.needsConsume) {
      try {
        if (await _store.consume(purchase)) return;
      } catch (_) {
        // Falls through to the acknowledgement below.
      }
      _log.warning('Could not consume a tip; the next start retries');
    }
    await _completeIfPending(purchase);
  }

  Future<void> _completeIfPending(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _store.completePurchase(purchase);
    } catch (_) {
      _log.warning('Could not complete a tip purchase');
    }
  }

  Future<void> _markTipped() async {
    _emit(state.copyWith(hasTipped: true));
    try {
      await _config.setHasLeftTip();
    } catch (_) {
      _log.warning('Could not save that a tip was left');
    }
  }

  Future<bool> _hasTipped() async {
    try {
      return await _config.getHasLeftTip();
    } catch (_) {
      return false;
    }
  }

  void _tell(TipOutcome outcome) {
    if (!_outcomes.isClosed) _outcomes.add(outcome);
  }

  void _emit(TipJarState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() async {
    await _purchases?.cancel();
    await _outcomes.close();
    return super.close();
  }
}
