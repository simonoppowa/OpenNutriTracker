import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';

/// Points the **real** prober at a server the reader is running.
///
/// Skipped unless `PROBE_ENDPOINT` and `PROBE_MODEL` are set, so it costs CI
/// nothing and never tries to reach a machine that is not there:
///
/// ```
/// fvm flutter test test/live/own_server_probe_live_test.dart \
///   --dart-define=PROBE_ENDPOINT=http://192.168.1.5:11434 \
///   --dart-define=PROBE_MODEL=gemma4:latest
/// ```
///
/// This is the only place the probe's *verdicts* are checked against a real
/// model rather than against a canned reply. #735 turns on the claim that a
/// capability flag is not fitness, and a probe whose correctness rests
/// entirely on fakes would be making the same mistake one layer up.
///
/// It runs in `flutter test` rather than as a `tool/` script because the
/// prober reaches `AiSelection`, and everything holding that also holds
/// `flutter_secure_storage` — whose FFI a plain `dart run` cannot load. The
/// keystore is never called here; only compiled.
///
/// One gap, stated rather than hidden: `flutter_image_compress` is a platform
/// channel with no implementation under `flutter test`, so the probe photo is
/// supplied already-encoded rather than pushed through `MealPhotoEncoder`.
/// The bytes are the same bundled JPEG the app would start from, at full
/// size. A destination that accepts this and rejects the app's output would
/// have to be objecting to the resize, not the container.
void main() {
  const endpoint = String.fromEnvironment('PROBE_ENDPOINT');
  const model = String.fromEnvironment('PROBE_MODEL');

  test('the prober agrees with what the model actually does', () async {
    final photoBytes = await File(aiProbePhotoAsset).readAsBytes();
    final client = http.Client();
    addTearDown(client.close);

    final prober = AiEndpointProber(
      client,
      sampleImage: (format) async =>
          MealPhoto(bytes: photoBytes, mediaType: format.mediaType),
    );
    final selection = AiSelection(
      provider: AiProvider.ownServer,
      endpoint: '${endpoint.replaceAll(RegExp(r'/+$'), '')}/v1/chat/completions',
      modelId: model,
    );

    final started = DateTime.now();
    final text = await prober.probeText(selection, localeCode: 'en');
    final afterText = DateTime.now();
    final photo = await prober.probePhoto(selection, localeCode: 'en');
    final afterPhoto = DateTime.now();

    final result = AiEndpointProbe(text: text, photo: photo);
    // ignore: avoid_print
    print(
      '\nendpoint : $endpoint\n'
      'model    : $model\n'
      'photo    : $aiProbePhotoAsset (${(photoBytes.length / 1024).round()} KB)\n'
      'text     : ${text.name} in ${afterText.difference(started).inSeconds}s\n'
      'photo    : ${photo.name} in '
      '${afterPhoto.difference(afterText).inSeconds}s\n'
      'stored   : "${result.encode()}"\n'
      'camera   : ${photo == AiCapability.passed ? 'offered' : 'hidden'}',
    );

    // The endpoint was reachable, so neither verdict may be inconclusive —
    // that is the state reserved for a server that did not answer, and
    // recording it for one that did would hide a capability the user has.
    expect(
      text,
      isNot(AiCapability.unknown),
      reason: 'a reachable endpoint must produce a verdict for text',
    );
    expect(
      photo,
      isNot(AiCapability.unknown),
      reason: 'a reachable endpoint must produce a verdict for photos',
    );
  }, timeout: const Timeout(Duration(minutes: 6)), skip: endpoint.isEmpty || model.isEmpty
      ? 'set --dart-define=PROBE_ENDPOINT and PROBE_MODEL to run this'
      : false);
}
