import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_text_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

class _MemoryStorage implements FlutterSecureStorage {
  final store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns a canned reading, or throws. Records what it was asked.
class _FakeInterpreter implements MealTextInterpreter {
  final MealTextParseResult? result;
  final Object? throws;

  String? sawInput;
  String? sawLocale;
  var calls = 0;

  _FakeInterpreter({this.result, this.throws});

  @override
  Future<MealTextParseResult> interpret(
    String input, {
    String? localeCode,
  }) async {
    calls++;
    sawInput = input;
    sawLocale = localeCode;
    if (throws != null) throw throws!;
    return result!;
  }
}

void main() {
  late _MemoryStorage backing;
  late AiCredentialStorage credentials;

  setUp(() {
    backing = _MemoryStorage();
    credentials = AiCredentialStorage(backing);
  });

  ReadMealTextUseCase useCaseWith(_FakeInterpreter interpreter) =>
      ReadMealTextUseCase(credentials, (_) => interpreter);

  group('with no key configured', () {
    test('uses the parser and never builds an interpreter', () async {
      final interpreter = _FakeInterpreter(
        result: const MealTextParseResult(items: [], errors: []),
      );

      final reading = await useCaseWith(interpreter).read('100g toast');

      expect(reading.usedModel, isFalse);
      expect(reading.result.items.single.query, 'toast');
      expect(interpreter.calls, 0);
    });
  });

  group('with a key but the switch off', () {
    test('uses the parser', () async {
      await credentials.writeApiKey('sk-test');
      await credentials.setEnabled(false);
      final interpreter = _FakeInterpreter(
        result: const MealTextParseResult(items: [], errors: []),
      );

      final reading = await useCaseWith(interpreter).read('100g toast');

      expect(reading.usedModel, isFalse);
      expect(interpreter.calls, 0);
    });
  });

  group('with the feature on', () {
    setUp(() async => credentials.writeApiKey('sk-test'));

    test('uses the model and says so', () async {
      final interpreter = _FakeInterpreter(
        result: const MealTextParseResult(
          items: [ParsedMealItem(query: 'chicken caesar salad')],
          errors: [],
        ),
      );

      final reading = await useCaseWith(
        interpreter,
      ).read('I had a chicken caesar salad', localeCode: 'de');

      expect(reading.usedModel, isTrue);
      expect(reading.result.items.single.query, 'chicken caesar salad');
      expect(interpreter.sawInput, 'I had a chicken caesar salad');
      expect(interpreter.sawLocale, 'de');
    });

    test('falls back to the parser when the provider fails', () async {
      // The model is an improvement to a working feature, never a
      // dependency of it: no network must land the user exactly where tier 0
      // left them, with nothing to dismiss.
      final interpreter = _FakeInterpreter(
        throws: const MealInterpreterException('request failed'),
      );

      final reading = await useCaseWith(interpreter).read('100g toast');

      expect(reading.usedModel, isFalse);
      expect(reading.result.items.single.query, 'toast');
      expect(reading.result.items.single.quantity, 100);
    });

    test('falls back when the key is rejected', () async {
      final interpreter = _FakeInterpreter(
        throws: const MealInterpreterException('unauthorized', statusCode: 401),
      );

      final reading = await useCaseWith(interpreter).read('100g toast');

      expect(reading.usedModel, isFalse);
      expect(reading.result.items, hasLength(1));
      // ...and says why. On a Pixel 6 a mistyped key produced a plausible
      // screen of parser rows with no indication at all, discoverable only
      // in `adb logcat`, while every request still made the round trip.
      expect(reading.modelFailure, MealTextModelFailure.auth);
    });

    test('reports a model nothing can serve', () async {
      final interpreter = _FakeInterpreter(
        throws: const MealInterpreterException('no endpoints', statusCode: 404),
      );

      final reading = await useCaseWith(interpreter).read('100g toast');

      expect(reading.result.items, hasLength(1));
      expect(reading.modelFailure, MealTextModelFailure.unsupported);
    });

    test('stays quiet about failures that may fix themselves', () async {
      // The notice is only worth anything if it is rare. A dropped
      // connection resolves on its own, and a banner that fires for those is
      // one people learn to scroll past — which would cost it the value it
      // has for a wrong key.
      for (final e in const [
        MealInterpreterException('timeout'),
        MealInterpreterException('rate limited', statusCode: 429),
        MealInterpreterException('server error', statusCode: 503),
        MealInterpreterException('bad request', statusCode: 400),
      ]) {
        final reading = await useCaseWith(
          _FakeInterpreter(throws: e),
        ).read('100g toast');

        expect(reading.result.items, hasLength(1), reason: '$e');
        expect(reading.modelFailure, isNull, reason: '$e');
      }
    });

    test('says nothing when the model answered', () async {
      final reading = await useCaseWith(
        _FakeInterpreter(
          result: const MealTextParseResult(items: [], errors: []),
        ),
      ).read('100g toast');

      expect(reading.usedModel, isTrue);
      expect(reading.modelFailure, isNull);
    });

    test(
      'falls back when the interpreter throws something unexpected',
      () async {
        // A bug in the interpreter must not cost the user their meal entry.
        final interpreter = _FakeInterpreter(throws: StateError('boom'));

        final reading = await useCaseWith(interpreter).read('100g toast');

        expect(reading.usedModel, isFalse);
        expect(reading.result.items.single.query, 'toast');
      },
    );

    test('an empty answer is trusted, not overridden by the parser', () async {
      // Found on a Pixel 6: "meine Steuererklärung und ein Tacker" made the
      // model correctly return nothing, and the old rule replaced that with
      // the parser — which turns any sentence into a query and produced a
      // cheese-roll match the user had to skip. An empty list is a judgment
      // the model was asked to make.
      final interpreter = _FakeInterpreter(
        result: const MealTextParseResult(items: [], errors: []),
      );

      final reading = await useCaseWith(
        interpreter,
      ).read('my tax return and a stapler');

      expect(reading.result.items, isEmpty);
      expect(reading.usedModel, isTrue);
    });

    test('a failure still falls back, unlike an empty answer', () async {
      // The distinction the old rule missed: a model that could not answer
      // is not a model that answered "nothing".
      final interpreter = _FakeInterpreter(
        throws: const MealInterpreterException('request failed'),
      );

      final reading = await useCaseWith(interpreter).read('100g toast');

      expect(reading.usedModel, isFalse);
      expect(reading.result.items.single.query, 'toast');
    });

    test('reads text the parser cannot segment at all', () async {
      // #623: a language with no spaces between words. The deterministic
      // parser cannot express a count here without per-locale word lists,
      // which #600 refused; a model needs none.
      final interpreter = _FakeInterpreter(
        result: const MealTextParseResult(
          items: [
            ParsedMealItem(query: '鸡蛋', quantity: 2),
            ParsedMealItem(query: '牛奶', quantity: 200, unit: 'ml'),
          ],
          errors: [],
        ),
      );

      final reading = await useCaseWith(
        interpreter,
      ).read('2个鸡蛋，200ml牛奶', localeCode: 'zh');

      expect(reading.usedModel, isTrue);
      expect(reading.result.items, hasLength(2));
      expect(reading.result.items[0].quantity, 2);
    });
  });
}
