import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_photo_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

class _MemoryStorage implements FlutterSecureStorage {
  /// Starts with the agreement already given.
  ///
  /// A stored credential is only usable once the user has agreed to what
  /// leaves the device (#836), so a store holding a key and no agreement is a
  /// state the app cannot reach. These tests arrange a working feature, which
  /// now means configured *and* agreed to.
  final store = <String, String>{'AiTermsAcceptedTag': 'true'};

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
  final Future<void>? waitUntilReleased;

  MealPhoto? sawPhoto;
  String? sawLocale;
  var calls = 0;
  final entered = Completer<void>();

  _FakeInterpreter({this.result, this.throws, this.waitUntilReleased});

  @override
  Future<MealTextParseResult> interpret(
    MealPhoto photo, {
    String? localeCode,
  }) async {
    calls++;
    sawPhoto = photo;
    sawLocale = localeCode;
    if (!entered.isCompleted) entered.complete();
    if (waitUntilReleased != null) await waitUntilReleased;
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
({
  ReadMealPhotoUseCase useCase,
  _FakeInterpreter interpreter,
  AiCredentialStorage credentials,
})
subject({
  String? apiKey,
  bool enabled = true,
  MealTextParseResult? result,
  Object? throws,
  AiEndpointProbe? probe,
  Future<void>? waitUntilReleased,
  bool ownServer = false,
}) {
  final storage = _MemoryStorage();
  final credentials = AiCredentialStorage(storage);
  if (apiKey != null) {
    storage.store['AiApiKeyTag'] = apiKey;
    storage.store['AiAssistEnabledTag'] = enabled ? 'true' : 'false';
  }
  // The one provider whose address the user supplies, and so the only one
  // where an endpoint can move under a request that is still out.
  if (ownServer) {
    storage.store['AiProviderTag'] = 'ownServer';
    storage.store['AiEndpointTag.ownServer'] =
        'http://192.168.1.5:11434/v1/chat/completions';
    storage.store['AiModelTag.ownServer'] = 'gemma3:4b';
    storage.store['AiAssistEnabledTag'] = enabled ? 'true' : 'false';
  }
  if (probe != null) {
    // Written straight into the slot the active provider reads, so a case
    // about retraction starts where a user with a passing check starts.
    storage.store[ownServer ? 'AiProbeTag.ownServer' : 'AiProbeTag.anthropic'] =
        probe.encode();
  }
  final interpreter = _FakeInterpreter(
    result: result,
    throws: throws,
    waitUntilReleased: waitUntilReleased,
  );
  return (
    useCase: ReadMealPhotoUseCase(credentials, (_) => interpreter),
    interpreter: interpreter,
    credentials: credentials,
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

    test(
      'a refused plaintext destination is not blamed on the model',
      () async {
        final s = subject(
          apiKey: 'k',
          throws: const MealInterpreterException(
            'plaintext to a public address',
            failure: MealInterpreterFailure.insecureDestination,
          ),
        );

        final reading = await s.useCase.read(_photo);

        expect(
          (reading as MealPhotoFailed).failure,
          MealPhotoFailure.insecureDestination,
        );
      },
    );

    group('a pass that has stopped being true (#782)', () {
      const passedBoth = AiEndpointProbe(
        text: AiCapability.passed,
        photo: AiCapability.passed,
      );

      test('an unsupported photo retracts the stored pass', () async {
        // A pass says photos worked once, and it can stop being true without
        // the user touching anything: pull a different model under the same
        // tag and the camera is still offered, still says photos work, and
        // fails on every photograph taken.
        final s = subject(
          apiKey: 'k',
          probe: passedBoth,
          throws: const MealInterpreterException(
            'this model cannot see',
            failure: MealInterpreterFailure.unsupported,
          ),
        );

        await s.useCase.read(_photo);

        expect((await s.credentials.readProbe()).photo, AiCapability.failed);
      });

      test('a replacement model does not inherit the old failure', () async {
        // The request owns the selection it started with. If settings move
        // while the model is answering, its eventual failure says nothing
        // about the replacement and must not refill the probe slot that the
        // model change cleared.
        final release = Completer<void>();
        final s = subject(
          apiKey: 'k',
          probe: passedBoth,
          waitUntilReleased: release.future,
          throws: const MealInterpreterException(
            'the old model cannot see',
            failure: MealInterpreterFailure.unsupported,
          ),
        );

        final reading = s.useCase.read(_photo);
        await s.interpreter.entered.future;
        await s.credentials.writeModel('replacement-model');
        release.complete();
        await reading;

        expect((await s.credentials.readProbe()).photo, AiCapability.unknown);
      });

      test('the same model on a different machine keeps its slot', () async {
        // The endpoint half of the pair, and why it is not redundant.
        // `writeEndpoint` clears the model when the address changes, so most
        // address changes read as model changes too — and a check watching
        // only the model would look sufficient. Re-pointing at another box
        // running the same tag, which is one `writeOwnServerConfiguration`,
        // leaves the model identical and moves only the address. The old
        // machine's failure would then hide the new machine's camera.
        final release = Completer<void>();
        final s = subject(
          ownServer: true,
          probe: passedBoth,
          waitUntilReleased: release.future,
          throws: const MealInterpreterException(
            'the old box cannot see',
            failure: MealInterpreterFailure.unsupported,
          ),
        );

        final reading = s.useCase.read(_photo);
        await s.interpreter.entered.future;
        await s.credentials.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.9:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        release.complete();
        await reading;

        expect(
          (await s.credentials.readProbe(provider: AiProvider.ownServer)).photo,
          AiCapability.unknown,
          reason: 'that verdict is about a machine the user has moved off',
        );
      });

      test('the text verdict is left where it stands', () async {
        // This photograph says nothing about whether a meal line still reads,
        // and the two are stored together — so a retraction that took the
        // text result with it would turn one fact into two losses.
        final s = subject(
          apiKey: 'k',
          probe: passedBoth,
          throws: const MealInterpreterException(
            'this model cannot see',
            failure: MealInterpreterFailure.unsupported,
          ),
        );

        await s.useCase.read(_photo);

        expect((await s.credentials.readProbe()).text, AiCapability.passed);
      });

      test('nothing else in the taxonomy retracts it', () async {
        // The narrowness is the whole design. Each of these says something
        // about the network, the load, the credential, the bill, the picture
        // or the address — and none of them about whether the model has eyes.
        // `insecureDestination` is the one this rule had to wait for: #790
        // separated it out precisely so a photo the app *refused to send*
        // could not be read as a model that cannot see.
        for (final failure in [
          MealInterpreterFailure.transient,
          MealInterpreterFailure.timeout,
          MealInterpreterFailure.auth,
          MealInterpreterFailure.billing,
          MealInterpreterFailure.rejected,
          MealInterpreterFailure.insecureDestination,
        ]) {
          final s = subject(
            apiKey: 'k',
            probe: passedBoth,
            throws: MealInterpreterException('nope', failure: failure),
          );

          await s.useCase.read(_photo);

          expect(
            (await s.credentials.readProbe()).photo,
            AiCapability.passed,
            reason: '$failure must not cost the user a working camera',
          );
        }
      });

      test('a fresh pass puts the camera back', () async {
        // The way out, and the reason `failed` is not a dead end: the dialog
        // reports per capability and offers the retry on the same surface.
        final s = subject(
          apiKey: 'k',
          probe: passedBoth,
          throws: const MealInterpreterException(
            'this model cannot see',
            failure: MealInterpreterFailure.unsupported,
          ),
        );
        await s.useCase.read(_photo);
        expect((await s.credentials.readProbe()).photo, AiCapability.failed);

        await s.credentials.writeProbe(passedBoth);

        expect((await s.credentials.readProbe()).photo, AiCapability.passed);
      });

      test('a photo that succeeds leaves the pass alone', () async {
        // Guard against a retraction that fires on the way through rather
        // than on the failure — the assertions above would all still pass.
        final s = subject(apiKey: 'k', probe: passedBoth, result: _oneItem);

        await s.useCase.read(_photo);

        expect((await s.credentials.readProbe()).photo, AiCapability.passed);
      });
    });

    test('a timeout folds into transient rather than crashing', () async {
      // #774 gave the taxonomy a `timeout` member for the text path. This
      // path deliberately did not gain a user-facing string for it: the only
      // configuration that reports a timeout that way is a server the user
      // runs, and that provider has no photo path at all — `_photoDestination`
      // is null for it, so the camera hides itself until #747 settles which
      // image formats a local runtime can decode.
      //
      // Pinned rather than left implicit because the arm is unreachable
      // today, which is exactly the kind of code that rots into a crash the
      // moment the camera is offered there.
      final s = subject(
        apiKey: 'k',
        throws: const MealInterpreterException(
          'request timed out',
          failure: MealInterpreterFailure.timeout,
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
        expect(
          (reading as MealPhotoFailed).failure,
          MealPhotoFailure.transient,
        );
      },
    );

    test('an unexpected throw never escapes the use case', () async {
      final s = subject(apiKey: 'k', throws: StateError('bug'));

      await expectLater(s.useCase.read(_photo), completes);
    });
  });
}
