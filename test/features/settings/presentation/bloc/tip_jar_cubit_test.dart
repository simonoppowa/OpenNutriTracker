import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:opennutritracker/features/settings/data/tip_store.dart';
import 'package:opennutritracker/features/settings/domain/entity/tip_entity.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/tip_jar_cubit.dart';

import '../../../../helpers/fake_tip_store.dart';

/// Logs when the tip jar records a tip, to check it does so first.
class _OrderConfig extends FakeTipConfig {
  final List<String> order;

  _OrderConfig(this.order);

  @override
  Future<void> setHasLeftTip() async {
    order.add('record');
    await super.setHasLeftTip();
  }
}

/// [FakeTipStore] that logs when a purchase is consumed.
class _OrderStore implements TipStore {
  final FakeTipStore inner;
  final List<String> order;

  _OrderStore(this.inner, this.order);

  @override
  bool get needsConsume => true;

  @override
  Future<bool> consume(PurchaseDetails purchase) async {
    order.add('consume');
    return true;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => inner.purchaseStream;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      inner.queryProductDetails(ids);

  @override
  Future<bool> buyConsumable(ProductDetails product) =>
      inner.buyConsumable(product);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      inner.completePurchase(purchase);

  @override
  Future<void> restorePurchases() => inner.restorePurchases();
}

void main() {
  late FakeTipStore store;
  late FakeTipConfig config;
  late TipJarCubit jar;
  late List<TipOutcome> outcomes;

  setUp(() {
    store = FakeTipStore();
    config = FakeTipConfig();
    jar = TipJarCubit(store, config);
    outcomes = [];
    jar.outcomes.listen(outcomes.add);
  });

  tearDown(() async {
    await jar.close();
    await store.dispose();
  });

  /// Lets the purchase handler's awaits run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('load', () {
    test('sorts the tips cheapest first, with the store prices', () async {
      await jar.load();

      expect(jar.state.status, TipJarStatus.ready);
      expect(jar.state.tips.map((t) => t.size), [
        TipSize.small,
        TipSize.medium,
        TipSize.large,
      ]);
      expect(jar.state.tips.map((t) => t.price), ['€1.99', '€4.99', '€9.99']);
    });

    test('shows only the tips that loaded', () async {
      store.products = tipProducts(only: {'tip_medium'});

      await jar.load();

      expect(jar.state.status, TipJarStatus.ready);
      expect(jar.state.tips.single.size, TipSize.medium);
    });

    test('fails when the store is unavailable', () async {
      store.available = false;

      await jar.load();

      expect(jar.state.status, TipJarStatus.failed);
      expect(store.queryCalls, 0);
    });

    test('fails when the store knows none of the tips', () async {
      store.products = [];

      await jar.load();

      expect(jar.state.status, TipJarStatus.failed);
      expect(jar.state.tips, isEmpty);
    });

    test('fails when the query throws', () async {
      store.products = null;

      await jar.load();

      expect(jar.state.status, TipJarStatus.failed);
    });

    test('a slow older load cannot replace a newer result', () async {
      final slow = Completer<void>();
      store.queryScript
        ..add((slow, null)) // the first visit: slow, then fails
        ..add((null, tipProducts())); // the second: answers at once

      final first = jar.load();
      await settle(); // the first visit's query is now in flight
      expect(store.queryCalls, 1);
      await jar.load();
      expect(jar.state.status, TipJarStatus.ready);

      slow.complete();
      await first;

      expect(jar.state.status, TipJarStatus.ready);
      expect(jar.state.tips, hasLength(3));
      await jar.buy(jar.state.tips.first);
      expect(store.bought.single.id, 'tip_small');
    });

    test('a slow older success cannot replace a newer one either', () async {
      final slow = Completer<void>();
      store.queryScript
        ..add((slow, tipProducts(only: {'tip_small'})))
        ..add((null, tipProducts()));

      final first = jar.load();
      await settle(); // the first visit's query is now in flight
      expect(store.queryCalls, 1);
      await jar.load();
      slow.complete();
      await first;

      expect(jar.state.tips, hasLength(3));
    });

    test('a tip recorded while the flag is being read is not hidden', () async {
      await jar.start();
      await jar.load();
      config.readGate = Completer<void>();

      final reload = jar.load(); // reads false, held at the gate
      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();
      expect(jar.state.hasTipped, isTrue);

      config.readGate!.complete();
      await reload;

      expect(jar.state.hasTipped, isTrue);
    });

    test('a cleared flag is read back even when the state still says '
        'tipped (Reset profile data)', () async {
      await jar.start();
      await jar.load();
      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();
      expect(jar.state.hasTipped, isTrue);

      config.hasLeftTip = false;
      await jar.load();

      expect(jar.state.hasTipped, isFalse);
    });

    test('a tip whose record fails to save is still finished, still shown, '
        'and saved by the next load', () async {
      await jar.start();
      await jar.load();
      config.writeThrows = true;
      final purchase = tipPurchase('tip_small', PurchaseStatus.purchased);

      store.emit([purchase]);
      await settle();

      // Finished regardless: holding it back risks a Play refund and blocks
      // buying that size again.
      expect(store.completed, [purchase]);
      expect(jar.state.hasTipped, isTrue);
      expect(config.hasLeftTip, isFalse);
      expect(outcomes.single, isA<TipThanked>());

      // Still failing: the line stays for this run.
      await jar.load();
      expect(jar.state.hasTipped, isTrue);
      expect(config.writes, 2);

      config.writeThrows = false;
      await jar.load();
      expect(config.hasLeftTip, isTrue);
      expect(config.writes, 3);

      // Saved: later loads read it back and stop writing.
      await jar.load();
      expect(jar.state.hasTipped, isTrue);
      expect(config.writes, 3);
    });

    test('Reset profile data drops a save still waiting for its retry: '
        'reopening does not bring the line back', () async {
      await jar.start();
      await jar.load();
      config.writeThrows = true;
      final purchase = tipPurchase('tip_small', PurchaseStatus.purchased);
      store.emit([purchase]);
      await settle();
      expect(store.completed, [purchase]);
      expect(jar.state.hasTipped, isTrue);

      // What DeleteAllUserDataUsecase does: the hook, then the cleared flag.
      jar.forgetTip();
      config.hasLeftTip = false;
      expect(jar.state.hasTipped, isFalse);

      config.writeThrows = false;
      await jar.load(); // reopening the page

      expect(jar.state.hasTipped, isFalse);
      expect(config.hasLeftTip, isFalse);
      expect(config.writes, 1); // only the failed one
    });

    test('a save that fails after Reset does not re-arm the retry', () async {
      await jar.start();
      await jar.load();
      config.writeGate = Completer<void>();
      final purchase = tipPurchase('tip_small', PurchaseStatus.purchased);
      store.emit([purchase]);
      await settle(); // the save is now in flight

      jar.forgetTip(); // Reset profile data
      config.hasLeftTip = false;
      config.writeThrows = true;
      config.writeGate!.complete(); // the old save fails, late
      await settle();

      expect(store.completed, [purchase]);
      config.writeThrows = false;
      await jar.load(); // reopening the page

      expect(jar.state.hasTipped, isFalse);
      expect(config.hasLeftTip, isFalse);
      expect(config.writes, 1);
    });

    test('reads whether a tip was left', () async {
      config.hasLeftTip = true;

      await jar.load();

      expect(jar.state.hasTipped, isTrue);
    });
  });

  group('buy', () {
    test('opens the sheet for the tip', () async {
      await jar.load();

      await jar.buy(jar.state.tips.first);

      expect(store.bought.single.id, 'tip_small');
      expect(outcomes, isEmpty);
    });

    test('reports a sheet that did not open', () async {
      await jar.load();
      store.buyResult = false;

      await jar.buy(jar.state.tips.first);
      await settle();

      expect(outcomes.single, isA<TipFailed>());
    });

    test('reports a sheet that threw', () async {
      await jar.load();
      store.buyThrows = true;

      await jar.buy(jar.state.tips.first);
      await settle();

      expect(outcomes.single, isA<TipFailed>());
    });
  });

  group('purchase updates on the App Store', () {
    setUp(() async {
      await jar.start();
      await jar.load();
    });

    test('a purchase is finished, remembered and thanked', () async {
      final purchase = tipPurchase('tip_medium', PurchaseStatus.purchased);

      store.emit([purchase]);
      await settle();

      expect(store.completed, [purchase]);
      expect(store.consumed, isEmpty);
      expect(jar.state.hasTipped, isTrue);
      expect(config.writes, 1);
      final thanked = outcomes.single as TipThanked;
      expect(thanked.tip.size, TipSize.medium);
      expect(thanked.tip.price, '€4.99');
    });

    test('a pending purchase is not thanked or remembered', () async {
      store.emit([tipPurchase('tip_small', PurchaseStatus.pending)]);
      await settle();

      expect(outcomes.single, isA<TipPending>());
      expect(jar.state.hasTipped, isFalse);
      expect(config.writes, 0);
      expect(store.completed, isEmpty);
    });

    test('an error is reported and its transaction finished', () async {
      final purchase = tipPurchase('tip_small', PurchaseStatus.error);

      store.emit([purchase]);
      await settle();

      expect(outcomes.single, isA<TipFailed>());
      expect(store.completed, [purchase]);
      expect(jar.state.hasTipped, isFalse);
    });

    test('a cancel says nothing', () async {
      store.emit([
        tipPurchase(
          'tip_small',
          PurchaseStatus.canceled,
          pendingComplete: false,
        ),
      ]);
      await settle();

      expect(outcomes, isEmpty);
      expect(store.completed, isEmpty);
      expect(jar.state.hasTipped, isFalse);
    });

    test('a product that is not a tip is left alone', () async {
      store.emit([tipPurchase('pro_upgrade', PurchaseStatus.purchased)]);
      await settle();

      expect(outcomes, isEmpty);
      expect(store.completed, isEmpty);
      expect(jar.state.hasTipped, isFalse);
    });

    test('start does not restore: consumables are not restorable', () {
      expect(store.restoreCalls, 0);
    });
  });

  group('purchase updates on Google Play', () {
    setUp(() {
      store.needsConsume = true;
    });

    test('start consumes tips an earlier run left unconsumed', () async {
      await jar.start();
      expect(store.restoreCalls, 1);

      final leftover = tipPurchase('tip_large', PurchaseStatus.restored);
      store.emit([leftover]);
      await settle();

      expect(store.consumed, [leftover]);
      // Consuming acknowledges too; a second acknowledge would fail.
      expect(store.completed, isEmpty);
      expect(jar.state.hasTipped, isTrue);
      // Found at start-up, away from the page: no dialog.
      expect(outcomes, isEmpty);
    });

    test('start skips the restore when Play is unreachable', () async {
      store.available = false;

      await jar.start();

      expect(store.restoreCalls, 0);
    });

    test('Play unreachable at start: the next load recovers the leftover '
        'tip', () async {
      store.available = false;
      await jar.start();
      expect(store.restoreCalls, 0);

      store.available = true;
      await jar.load();
      await settle();
      expect(store.restoreCalls, 1);

      final leftover = tipPurchase('tip_medium', PurchaseStatus.restored);
      store.emit([leftover]);
      await settle();

      expect(store.consumed, [leftover]);
      expect(jar.state.hasTipped, isTrue);
    });

    test('Retry repeats the recovery', () async {
      await jar.start();
      await jar.load();
      await jar.load();
      await settle();

      expect(store.restoreCalls, 3);
    });

    test(
      'buy waits for an owned tip of that size to finish consuming',
      () async {
        await jar.start();
        await jar.load();
        store.consumeGate = Completer<void>();
        store.emit([tipPurchase('tip_small', PurchaseStatus.restored)]);
        await settle(); // the consume is now in flight

        final buying = jar.buy(jar.state.tips.first);
        await settle();
        expect(store.bought, isEmpty);

        store.consumeGate!.complete();
        await buying;

        expect(store.calls, ['restore', 'restore', 'consume', 'buy']);
      },
    );

    test('buy waits for a recovery still asking Play, and for what it '
        'returns', () async {
      await jar.start();
      store.restoreGate = Completer<void>();
      store.restoreEmits = [tipPurchase('tip_small', PurchaseStatus.restored)];
      await jar.load(); // recovery starts and is held

      final buying = jar.buy(jar.state.tips.first);
      await settle();
      expect(store.bought, isEmpty);

      store.restoreGate!.complete();
      await buying;

      expect(store.calls.sublist(store.calls.length - 2), ['consume', 'buy']);
    });

    test('a replay while the live update is consuming is skipped: one '
        'consume, one thank-you', () async {
      await jar.start();
      await jar.load();
      store.consumeGate = Completer<void>();

      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();
      store.emit([tipPurchase('tip_small', PurchaseStatus.restored)]);
      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();
      store.consumeGate!.complete();
      await settle();

      expect(store.consumed, hasLength(1));
      expect(store.completed, isEmpty);
      expect(outcomes.whereType<TipThanked>(), hasLength(1));
    });

    test('a tip that failed to consume is retried by its replay', () async {
      await jar.start();
      store.consumeResult = false;
      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();

      store.consumeResult = true;
      store.emit([tipPurchase('tip_small', PurchaseStatus.restored)]);
      await settle();

      expect(store.consumed, hasLength(2));
    });

    test('two tips of the same size are two transactions', () async {
      await jar.start();
      await jar.load();

      store.emit([
        tipPurchase('tip_small', PurchaseStatus.purchased, id: 'GPA.1'),
      ]);
      store.emit([
        tipPurchase('tip_small', PurchaseStatus.purchased, id: 'GPA.2'),
      ]);
      await settle();

      expect(store.consumed, hasLength(2));
      expect(outcomes.whereType<TipThanked>(), hasLength(2));
    });

    test('a tip is recorded before its transaction is finished', () async {
      await jar.start();
      final order = <String>[];
      final recording = _OrderConfig(order);
      final ordered = TipJarCubit(_OrderStore(store, order), recording);
      addTearDown(ordered.close);
      await ordered.start();

      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();

      expect(order, ['record', 'consume']);
    });

    test('a restore that throws does not break start', () async {
      store.restoreThrows = true;

      await jar.start();
      await jar.load();
      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();

      expect(store.consumed, hasLength(1));
    });

    test('start listens only once', () async {
      await jar.start();
      await jar.start();
      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await settle();

      expect(store.consumed, hasLength(1));
      expect(store.restoreCalls, 1);
    });

    test('a purchase is consumed and thanked', () async {
      await jar.start();
      await jar.load();
      final purchase = tipPurchase('tip_small', PurchaseStatus.purchased);

      store.emit([purchase]);
      await settle();

      expect(store.consumed, [purchase]);
      expect(store.completed, isEmpty);
      expect(outcomes.single, isA<TipThanked>());
    });

    test('a tip that fails to consume is acknowledged, so Play does not '
        'refund it, and still counts', () async {
      await jar.start();
      store.consumeResult = false;
      final purchase = tipPurchase('tip_small', PurchaseStatus.purchased);

      store.emit([purchase]);
      await settle();

      expect(store.completed, [purchase]);
      expect(jar.state.hasTipped, isTrue);
    });

    test('a consume that throws falls back to the acknowledgement', () async {
      await jar.start();
      store.consumeThrows = true;
      final purchase = tipPurchase('tip_small', PurchaseStatus.purchased);

      store.emit([purchase]);
      await settle();

      expect(store.completed, [purchase]);
    });

    test('a pending purchase is not consumed', () async {
      await jar.start();

      store.emit([tipPurchase('tip_small', PurchaseStatus.pending)]);
      await settle();

      expect(store.consumed, isEmpty);
      expect(outcomes.single, isA<TipPending>());
    });

    test('a failure with no purchase behind it is still reported', () async {
      await jar.start();

      store.emit([
        tipPurchase('', PurchaseStatus.error, pendingComplete: false),
        tipPurchase('', PurchaseStatus.canceled, pendingComplete: false),
      ]);
      await settle();

      expect(outcomes.single, isA<TipFailed>());
      expect(store.completed, isEmpty);
    });
  });

  group('withPlayState', () {
    GooglePlayPurchaseDetails restored(PurchaseStateWrapper state) {
      final details = GooglePlayPurchaseDetails.fromPurchase(
        PurchaseWrapper(
          orderId: 'order',
          packageName: 'com.opennutritracker.ont.opennutritracker',
          purchaseTime: 0,
          purchaseToken: 'token',
          signature: 'signature',
          products: const ['tip_small'],
          isAutoRenewing: false,
          originalJson: '{}',
          isAcknowledged: false,
          purchaseState: state,
        ),
      ).single;
      return details..status = PurchaseStatus.restored;
    }

    test('a restored tip still awaiting payment reads as pending', () {
      expect(
        withPlayState(restored(PurchaseStateWrapper.pending)).status,
        PurchaseStatus.pending,
      );
    });

    test('a restored tip that was paid stays restored', () {
      expect(
        withPlayState(restored(PurchaseStateWrapper.purchased)).status,
        PurchaseStatus.restored,
      );
    });

    test('anything else passes through', () {
      final purchase = tipPurchase('tip_small', PurchaseStatus.restored);
      expect(withPlayState(purchase).status, PurchaseStatus.restored);
    });
  });
}
