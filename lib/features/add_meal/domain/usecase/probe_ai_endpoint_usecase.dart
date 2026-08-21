import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/data/meal_items_api_factory.dart';
import 'package:opennutritracker/features/add_meal/data/model_meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/data/model_meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_photo_encoder.dart';
import 'package:path_provider/path_provider.dart';

/// A meal line to probe a text endpoint with.
///
/// English, in every locale, and deliberately so. The pass bar is
/// **structural** — did a parseable tool call come back with at least one
/// item — and nothing about it depends on the language, because the model
/// answers in the user's language whatever it was asked in. Localizing this
/// would add nine strings to test a property that has nothing to do with
/// words.
///
/// Two foods rather than one, so a model that collapses everything into a
/// single row is still a pass while a model that returns nothing is not.
const aiProbeMealLine = 'two eggs and a slice of toast';

/// The bundled photograph a photo probe is run against.
///
/// A sliced loaf on a board: one unambiguous food, filling the frame, no
/// composed dish to argue about. The other demo photos include a tempura
/// rice bowl and a bowl of yoghurt with garnish scattered around it, either
/// of which would make a *correct* answer look like a wrong one.
///
/// Already shipped for Try Demo and declared in `pubspec.yaml`, so probing
/// costs no app size.
const aiProbePhotoAsset = 'assets/demo/meals/1552056413-b8b5eed0170b.jpg';

/// Runs the two setup-time probes against an endpoint and reports what it
/// found. **Stores nothing** — see [AiCredentialStorage.writeProbe] for that.
///
/// Split from the storage because deciding and remembering are different
/// jobs, and because it lets the whole thing be pointed at a real server
/// without a keystore in the way: `own_server_probe_live_test.dart` does
/// exactly that. A probe whose own verdicts have only ever been checked
/// against a fake is a probe that has never been tested.
///
/// Every request goes through [mealItemsApiFor] and the shipping
/// interpreters, so what is measured is the path the user's meals will take —
/// the same prompts, the same schema, the same forcing mode, the same image
/// encoder. A probe built from its own request would be testing a second
/// implementation that nothing else uses.
class AiEndpointProber {
  static final _log = Logger('AiEndpointProber');

  final http.Client _client;

  /// Produces the image to probe with, already encoded for the destination.
  /// Injected because the default reaches the asset bundle and a temporary
  /// directory, neither of which exists outside a Flutter app.
  final Future<MealPhoto?> Function(MealPhotoFormat format) _sampleImage;

  AiEndpointProber(
    this._client, {
    Future<MealPhoto?> Function(MealPhotoFormat format)? sampleImage,
  }) : _sampleImage = sampleImage ?? loadProbePhoto;

  /// Asks [selection]'s endpoint for a meal line and for a photograph, and
  /// reports what each produced.
  ///
  /// Sequential rather than concurrent. A local runtime serves one request at
  /// a time against one loaded model, so firing both at once would queue them
  /// anyway — and it would make the first call, the one that pays for the
  /// cold model load, indistinguishable from the second in the timings.
  Future<AiEndpointProbe> probe(
    AiSelection selection, {
    String? localeCode,
  }) async {
    final text = await probeText(selection, localeCode: localeCode);
    final photo = await probePhoto(selection, localeCode: localeCode);
    return AiEndpointProbe(text: text, photo: photo);
  }

  Future<AiCapability> probeText(
    AiSelection selection, {
    String? localeCode,
  }) async {
    try {
      final result = await ModelMealTextInterpreter(
        _apiFor(selection),
      ).interpret(aiProbeMealLine, localeCode: localeCode);
      return _verdictFor(result.items.length, 'text');
    } on MealInterpreterException catch (e) {
      return _verdictForFailure(e, 'text');
    } catch (e, stackTrace) {
      // A probe must never take a settings screen down with it.
      _log.severe('Text probe failed unexpectedly', e, stackTrace);
      return AiCapability.unknown;
    }
  }

  Future<AiCapability> probePhoto(
    AiSelection selection, {
    String? localeCode,
  }) async {
    final MealPhoto? photo;
    try {
      photo = await _sampleImage(
        MealPhotoFormat.forProvider(selection.provider),
      );
    } catch (e, stackTrace) {
      _log.severe('Could not prepare the probe photo', e, stackTrace);
      return AiCapability.unknown;
    }
    // Nothing was sent, so nothing was learned. Not a failure of the
    // endpoint, and recording one would blame a server for the app's own
    // missing encoder.
    if (photo == null) return AiCapability.unknown;

    try {
      final result = await ModelMealPhotoInterpreter(
        _apiFor(selection),
      ).interpret(photo, localeCode: localeCode);
      return _verdictFor(result.items.length, 'photo');
    } on MealInterpreterException catch (e) {
      return _verdictForFailure(e, 'photo');
    } catch (e, stackTrace) {
      _log.severe('Photo probe failed unexpectedly', e, stackTrace);
      return AiCapability.unknown;
    }
  }

  MealItemsApi _apiFor(AiSelection selection) =>
      mealItemsApiFor(_client, selection, timeout: aiEndpointProbeTimeout);

  /// **At least one item**, not merely a well-formed reply.
  ///
  /// An empty list is a legitimate answer to a real meal — the model looked
  /// and found no food — but it is not a legitimate answer to *this* input,
  /// which is two named foods and a photograph of a loaf of bread. Zero here
  /// is the failure the project has already measured: `openai/gpt-5.4-nano`
  /// advertised every capability, accepted food-bearing photographs, and
  /// returned nothing for all of them. A bar of "it replied" would have
  /// passed it.
  AiCapability _verdictFor(int items, String probe) {
    _log.info('$probe probe returned $items item(s)');
    return items == 0 ? AiCapability.failed : AiCapability.passed;
  }

  /// Only failures that say something durable about the destination become a
  /// verdict. Everything else stays [AiCapability.unknown] — the endpoint may
  /// be perfectly capable and merely asleep, and a wrong `failed` hides a
  /// working feature until the user finds the retry.
  AiCapability _verdictForFailure(MealInterpreterException e, String probe) {
    _log.info('$probe probe failed: ${e.reason} (${e.failure.name})');
    return switch (e.failure) {
      // The model will not call the tool, or nothing behind this address can
      // serve this kind of request. True again tomorrow. On Ollama, which
      // has no `tool_choice` field at all, this is the *expected* way a
      // weak model fails rather than a rare one (#733).
      MealInterpreterFailure.unsupported => AiCapability.failed,
      // The request itself was refused — on the photo probe, that is the
      // image. Also true again tomorrow, with the same picture.
      MealInterpreterFailure.rejected => AiCapability.failed,
      // Neither says anything about capability. A user's own server should
      // not be answering either of these, and if it does, the thing to fix
      // is not the model.
      MealInterpreterFailure.auth ||
      MealInterpreterFailure.billing => AiCapability.unknown,
      // Asleep, loading, rate limited, or a reply that did not parse. The
      // whole reason `unknown` exists.
      MealInterpreterFailure.transient => AiCapability.unknown,
    };
  }
}

/// Loads the bundled probe photograph and runs it through the **real**
/// encoder, so a probe exercises the image pipeline rather than a stand-in.
///
/// The encoder takes a path because the thing it normally encodes is a file
/// the picker wrote, so the asset is spilled to a temporary file first and
/// then discarded by the same call that reads it — the identical treatment a
/// user's own photograph gets, and for the identical reason (#758's
/// disclosure says the app keeps no copy).
Future<MealPhoto?> loadProbePhoto(MealPhotoFormat format) async {
  final bytes = (await rootBundle.load(aiProbePhotoAsset)).buffer
      .asUint8List();
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/ai_probe_sample.jpg');
  await file.writeAsBytes(bytes, flush: true);
  return MealPhotoEncoder.encodeAndDiscardSource(file.path, format: format);
}
