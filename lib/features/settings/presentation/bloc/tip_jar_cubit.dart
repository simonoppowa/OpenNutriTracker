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
  Map<TipSize, ProductDetails> _products = {};
  bool _buying = false;

  /// Bumped by every [load]; a load whose number is no longer current drops
  /// its result, so a slow, older query cannot replace a newer one.
  int _loadGeneration = 0;

  /// Bumped by every recorded tip; a flag read that started before the bump
  /// is stale and must not hide the tip just recorded.
  int _tipVersion = 0;

  /// The recovery in flight, shared by overlapping callers.
  Future<void>? _recovering;

  /// Purchase updates, handled one batch at a time in arrival order. The
  /// stream does not wait for a handler, so without this a recovery replay
  /// could consume a transaction its live update is still consuming.
  ///
  /// Null until the first update, so the chain is built in the listener's
  /// zone rather than wherever this cubit was constructed.
  Future<void>? _handling;

  /// Transactions this run has finished — consumed on Play, completed on
  /// the App Store. A later delivery of one (a replay, a duplicate update)
  /// is skipped, so it is neither consumed twice nor thanked twice. One that
  /// failed to finish stays out, so its next delivery retries it.
  final _finished = <String>{};

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
      (purchases) => _handling = (_handling ?? Future<void>.value())
          .then((_) => _onPurchases(purchases))
          .catchError(
            (Object _) => _log.warning('A purchase update was not handled'),
          ),
      onError: (Object _) =>
          _log.warning('The purchase stream reported an error'),
    );
    await _recoverOwnedTips();
  }

  /// Google Play only: asks for every tip still owned and consumes what
  /// comes back on the purchase stream.
  ///
  /// Run at start-up and again on every [load] — opening the page and Retry
  /// — rather than once per process. Play may be unreachable at start-up,
  /// and a consume can fail after a purchase; either way the owned tip would
  /// block buying that size again until the next restart, and the page is
  /// where the user would try. Querying owned purchases is answered by the
  /// Play Store app on the device, so repeating it is cheap.
  Future<void> _recoverOwnedTips() {
    if (!_store.needsConsume) return Future.value();
    return _recovering ??= () async {
      try {
        if (await _store.isAvailable()) await _store.restorePurchases();
      } catch (_) {
        _log.info('Could not check for unconsumed tips; the next load retries');
      } finally {
        _recovering = null;
      }
    }();
  }

  /// Loads the tips from the store. Fails on anything short of at least one
  /// tip: no network, nothing returned, or a build the store does not know
  /// (the develop flavour, a sideloaded or GitHub APK, TestFlight without
  /// sandbox setup).
  Future<void> load() async {
    final generation = ++_loadGeneration;
    bool current() => generation == _loadGeneration;

    final hasTipped = await _hasTipped();
    if (!current()) return;
    _emit(state.copyWith(status: TipJarStatus.loading, hasTipped: hasTipped));
    try {
      if (!await _store.isAvailable()) {
        if (current()) {
          _emit(state.copyWith(status: TipJarStatus.failed, tips: const []));
        }
        return;
      }
      unawaited(_recoverOwnedTips());
      final response = await _store.queryProductDetails(TipSize.productIds);
      if (!current()) return;
      final products = <TipSize, ProductDetails>{};
      final tips = <TipEntity>[];
      for (final product in response.productDetails) {
        final size = TipSize.fromProductId(product.id);
        if (size == null) continue;
        products[size] = product;
        tips.add(
          TipEntity(
            size: size,
            price: product.price,
            rawPrice: product.rawPrice,
          ),
        );
      }
      tips.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      _products = products;
      _emit(
        state.copyWith(
          status: tips.isEmpty ? TipJarStatus.failed : TipJarStatus.ready,
          tips: tips,
        ),
      );
    } catch (_) {
      if (!current()) return;
      _log.info('Could not load the tips from the store');
      _emit(state.copyWith(status: TipJarStatus.failed, tips: const []));
    }
  }

  /// Opens the store's purchase sheet for [tip]. The result arrives on the
  /// purchase stream, not here.
  ///
  /// Waits for any recovery and purchase update in hand first: a tip of
  /// this size may be owned and mid-consume, and Play refuses to sell an
  /// owned one (`ITEM_ALREADY_OWNED`) rather than open the sheet.
  Future<void> buy(TipEntity tip) async {
    final product = _products[tip.size];
    if (product == null || _buying) return;
    _buying = true;
    try {
      await _settled();
      if (!await _store.buyConsumable(product)) _tell(const TipFailed());
    } catch (_) {
      _log.info('The store did not open the purchase sheet');
      _tell(const TipFailed());
    } finally {
      _buying = false;
    }
  }

  /// Returns once no recovery or purchase update is being handled.
  ///
  /// `restorePurchases` returns after handing its answer to the purchase
  /// stream, which delivers it in a microtask. The zero-length timer runs
  /// after those, so by then the answer is queued on [_handling].
  Future<void> _settled() async {
    await _recovering;
    await Future<void>.delayed(Duration.zero);
    await _handling;
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
          final key = _transactionKey(purchase);
          if (key != null && _finished.contains(key)) continue;
          // Recorded before the transaction is finished: if the app dies in
          // between, the store delivers the purchase again, while a finished
          // transaction with no record would lose the tip for good.
          await _markTipped();
          if (await _finish(purchase) && key != null) _finished.add(key);
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
  /// acknowledged, which stops Play refunding it; the next load or start
  /// consumes it.
  ///
  /// Returns whether the transaction is done with: consumed on Play, or
  /// completed (or nothing to complete) on the App Store.
  Future<bool> _finish(PurchaseDetails purchase) async {
    if (_store.needsConsume) {
      try {
        if (await _store.consume(purchase)) return true;
      } catch (_) {
        // Falls through to the acknowledgement below.
      }
      _log.warning('Could not consume a tip; the next load or start retries');
      await _completeIfPending(purchase);
      return false;
    }
    return _completeIfPending(purchase);
  }

  /// Whether the purchase needed no completing or was completed.
  Future<bool> _completeIfPending(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return true;
    try {
      await _store.completePurchase(purchase);
      return true;
    } catch (_) {
      _log.warning('Could not complete a tip purchase');
      return false;
    }
  }

  /// One transaction's identity: the store's order or transaction ID, else
  /// its purchase token. Null when the store gave neither, which only
  /// happens for a failure with no purchase behind it.
  static String? _transactionKey(PurchaseDetails purchase) {
    final id = purchase.purchaseID;
    if (id != null && id.isNotEmpty) return id;
    final token = purchase.verificationData.serverVerificationData;
    return token.isEmpty ? null : token;
  }

  Future<void> _markTipped() async {
    _tipVersion++;
    _emit(state.copyWith(hasTipped: true));
    try {
      await _config.setHasLeftTip();
    } catch (_) {
      _log.warning('Could not save that a tip was left');
    }
  }

  /// The stored flag — unless a tip was recorded while it was being read.
  /// Then the read may predate the write, and the state already says true.
  /// (Keeping a stored false otherwise matters: Reset profile data clears
  /// the flag while this singleton still holds true.)
  Future<bool> _hasTipped() async {
    final version = _tipVersion;
    bool stored;
    try {
      stored = await _config.getHasLeftTip();
    } catch (_) {
      stored = false;
    }
    return version == _tipVersion ? stored : state.hasTipped;
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
