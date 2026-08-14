import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// What a line of meal text turned into, and which reader produced it.
class MealTextReading {
  final MealTextParseResult result;

  /// True when a model read the line. Drives the review screen's marker, so
  /// the user can see which rows a machine interpreted — the confirmation
  /// step is only meaningful if you know what you are confirming.
  final bool usedModel;

  const MealTextReading(this.result, {required this.usedModel});
}

/// Decides whether a line is read by the model or the deterministic parser,
/// and always returns something either way.
///
/// The policy lives here rather than in the bloc so it can be tested without
/// a widget tree, and so the bloc keeps one collaborator instead of three.
///
/// Falling back rather than failing is the whole point. A missing key, a
/// disabled switch, no network, a rejected credential, a rate limit, a
/// changed API — every one of them lands the user on exactly the experience
/// they had before tier 1b existed, with no error to dismiss. The model is
/// an improvement to a working feature, never a dependency of it.
class ReadMealTextUseCase {
  static final _log = Logger('ReadMealTextUseCase');

  final AiCredentialStorage _credentials;

  /// Builds an interpreter around a key. A factory rather than an instance
  /// because the credential is read per call and should not be captured for
  /// the lifetime of a singleton.
  final MealTextInterpreter Function(String apiKey) _interpreterFactory;

  ReadMealTextUseCase(this._credentials, this._interpreterFactory);

  Future<MealTextReading> read(String input, {String? localeCode}) async {
    final parsed = parseMealText(input);

    if (!await _credentials.isEnabled()) {
      return MealTextReading(parsed, usedModel: false);
    }
    final apiKey = await _credentials.readApiKey();
    if (apiKey == null) {
      return MealTextReading(parsed, usedModel: false);
    }

    try {
      final interpreted = await _interpreterFactory(
        apiKey,
      ).interpret(input, localeCode: localeCode);

      // A model that found nothing is not better than a parser that found
      // something: `100g toast` is unambiguous, and an empty screen after a
      // network round trip is worse than the offline answer.
      if (interpreted.items.isEmpty && parsed.items.isNotEmpty) {
        return MealTextReading(parsed, usedModel: false);
      }
      return MealTextReading(interpreted, usedModel: true);
    } on MealTextInterpreterException catch (e) {
      // Logged without the input: the line the user typed is the one thing
      // in this flow that should not reach a log.
      _log.info('Interpreter unavailable, using the parser: ${e.reason}');
      return MealTextReading(parsed, usedModel: false);
    } catch (e, stackTrace) {
      // An interpreter that throws something unexpected is a bug, but it
      // must not cost the user their meal entry.
      _log.severe('Interpreter failed unexpectedly', e, stackTrace);
      return MealTextReading(parsed, usedModel: false);
    }
  }
}
