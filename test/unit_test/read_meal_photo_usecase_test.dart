import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_photo_usecase.dart';
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
class _FakeInterpreter implements MealPhotoInterpreter {
  final MealTextParseResult? result;
  final Object? throws;

  MealPhoto? sawPhoto;
  String? sawLocale;
  var calls = 0;

  _FakeInterpreter({this.result, this.throws});

  @override
  Future<MealTextParseResult> interpret(
    MealPhoto photo, {
    String? localeCode,
  }) async {
    calls++;
    sawPhoto = photo;
    sawLocale = localeCode;
    if (throws != null) throw throws!;
    return result!;
  }
}

final _photo = MealPhoto(
  bytes: Uint8List.fromList([1, 2, 3]),
  mediaType: 'image/webp',
);

const _oneItem = MealTextParseResult(
  items: [ParsedMealItem(query: 'egg', quantity: 2)],
  errors: [],
);

/// A use case over storage that already holds [apiKey], or nothing.
({ReadMealPhotoUseCase useCase, _FakeInterpreter interpreter}) subject({
  String? apiKey,
  bool enabled = true,
  MealTextParseResult? result,
  Object? throws,
}) {
  final storage = _MemoryStorage();
  final credentials = AiCredentialStorage(storage);
  if (apiKey != null) {
    storage.store['AiApiKeyTag'] = apiKey;
    storage.store['AiAssistEnabledTag'] = enabled ? 'true' : 'false';
  }
  final interpreter = _FakeInterpreter(result: result, throws: throws);
  return (
    useCase: ReadMealPhotoUseCase(credentials, (_) => interpreter),
    interpreter: interpreter,
  );
}

void main() {
  group('without a usable credential', () {
    test('no key stored reports unavailable', () async {
      final s = subject();

      expect(await s.useCase.read(_photo), isA<MealPhotoUnavailable>());
      expect(s.interpreter.calls, 0);
    });

    test('a key the user switched off reports unavailable', () async {
      final s = subject(apiKey: 'k', enabled: false, result: _oneItem);

      expect(await s.useCase.read(_photo), isA<MealPhotoUnavailable>());
      expect(
        s.interpreter.calls,
        0,
        reason: 'a paused feature must not reach the network',
      );
    });

    test('unavailable is not reported as a failure', () async {
      // The two want opposite words in front of the user: one is a setting
      // they can change, the other is something that went wrong.
      final s = subject();

      expect(await s.useCase.read(_photo), isNot(isA<MealPhotoFailed>()));
    });
  });

  group('with the feature on', () {
    test('passes the photo and the locale through', () async {
      final s = subject(apiKey: 'k', result: _oneItem);

      final reading = await s.useCase.read(_photo, localeCode: 'de');

      expect(reading, isA<MealPhotoRead>());
      expect((reading as MealPhotoRead).result.items.single.query, 'egg');
      expect(s.interpreter.sawPhoto, same(_photo));
      expect(s.interpreter.sawLocale, 'de');
    });

    test('an empty answer is a reading, not a failure', () async {
      // The model looked and found no food. Same rule the text path settled
      // on in #647 — overriding an answer is not the same as handling a
      // failure to answer.
      final s = subject(
        apiKey: 'k',
        result: const MealTextParseResult(items: [], errors: []),
      );

      final reading = await s.useCase.read(_photo);

      expect(reading, isA<MealPhotoRead>());
      expect((reading as MealPhotoRead).result.items, isEmpty);
    });

    test('a rejected key is reported as an auth failure', () async {
      final s = subject(
        apiKey: 'k',
        throws: const MealInterpreterException(
          'nope',
          failure: MealInterpreterFailure.auth,
          statusCode: 401,
        ),
      );

      final reading = await s.useCase.read(_photo);

      expect(reading, isA<MealPhotoFailed>());
      expect((reading as MealPhotoFailed).failure, MealPhotoFailure.auth);
    });

    test('an exhausted credit is reported as billing, not auth', () async {
      final s = subject(
        apiKey: 'k',
        throws: const MealInterpreterException(
          'no credit',
          failure: MealInterpreterFailure.billing,
          statusCode: 402,
        ),
      );

      final reading = await s.useCase.read(_photo);

      expect(reading, isA<MealPhotoFailed>());
      expect((reading as MealPhotoFailed).failure, MealPhotoFailure.billing);
    });

    test('a refused image is not offered as retryable', () async {
      // Found by running a corpus of real photographs: a JPEG carrying Adobe
      // APP14 markers is refused with a 400 every single time, while the same
      // picture re-encoded goes through. "Check your connection and try
      // again" is advice that can never work here; "try another photo" can.
      final s = subject(
        apiKey: 'k',
        throws: const MealInterpreterException(
          'bad image',
          failure: MealInterpreterFailure.rejected,
          statusCode: 400,
        ),
      );

      final reading = await s.useCase.read(_photo);

      expect(
        (reading as MealPhotoFailed).failure,
        MealPhotoFailure.rejectedImage,
      );
    });

    test('a server error is not reported as an auth failure', () async {
      final s = subject(
        apiKey: 'k',
        throws: const MealInterpreterException(
          'boom',
          failure: MealInterpreterFailure.transient,
          statusCode: 503,
        ),
      );

      final reading = await s.useCase.read(_photo);

      expect((reading as MealPhotoFailed).failure, MealPhotoFailure.transient);
    });

    test('a network failure with no status is not an auth failure', () async {
      final s = subject(
        apiKey: 'k',
        throws: const MealInterpreterException('request failed'),
      );

      final reading = await s.useCase.read(_photo);

      expect((reading as MealPhotoFailed).failure, MealPhotoFailure.transient);
    });

    test(
      'an unexpected throw does not send the user to check their key',
      () async {
        // A bug in the interpreter is not the user's credential being wrong,
        // and telling them it is sends them to fix the one thing that works.
        final s = subject(apiKey: 'k', throws: StateError('bug'));

        final reading = await s.useCase.read(_photo);

        expect(reading, isA<MealPhotoFailed>());
        expect((reading as MealPhotoFailed).failure, MealPhotoFailure.transient);
      },
    );

    test('an unexpected throw never escapes the use case', () async {
      final s = subject(apiKey: 'k', throws: StateError('bug'));

      await expectLater(s.useCase.read(_photo), completes);
    });
  });
}
