import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// A model failure the user can act on, and which will not fix itself.
///
/// **Transient failures are deliberately absent.** A dropped connection or a
/// rate limit resolves on its own, and a notice that fires for those becomes
/// noise people learn to ignore — which would cost it the value it has for
/// the two that never resolve on their own. Silence is the right answer to a
/// blip and the wrong answer to a wrong key.
enum MealTextModelFailure {
  /// The provider rejected the credential. Permanent until the key changes.
  ///
  /// Found on a Pixel 6: a mistyped key produced a plausible screen of
  /// parser rows and no indication whatsoever, discoverable only in
  /// `adb logcat`. Every request still made the round trip.
  auth,

  /// Nothing can serve the configured model. Permanent until it changes.
  unsupported,

  /// The account cannot pay. Announced rather than swallowed: the parser
  /// still produced the rows, but this one is actionable and will not clear
  /// on its own, so saying nothing means the model silently stays off.
  billing,

  /// The server was given the full budget and still did not answer.
  ///
  /// Belongs here, beside three permanent failures, because of *which*
  /// budget. Only a server the user runs classifies a timeout this way, and
  /// only after 120 seconds — six times what a hosted API gets. A cold model
  /// load does not reach that; hardware that cannot serve the chosen model
  /// does, and will again tomorrow, which is exactly the "will not fix
  /// itself" test this enum applies.
  ///
  /// The alternative was silence, and #774 is what silence looked like: the
  /// user waits, the model is never mentioned again, and rows appear that
  /// look no different from rows the model produced.
  timeout,
  /// The app refused to send: plaintext, to an address that is not private.
  ///
  /// The most important one in this list to say out loud, because it is the
  /// only failure here the *app* caused. Silence would mean a user whose
  /// server is at `http://` on the open internet gets parser rows forever
  /// and never learns their configuration is one the app will not honour.
  insecureDestination,
}

/// What a line of meal text turned into, and which reader produced it.
class MealTextReading {
  final MealTextParseResult result;

  /// True when a model read the line. Drives the review screen's marker, so
  /// the user can see which rows a machine interpreted — the confirmation
  /// step is only meaningful if you know what you are confirming.
  final bool usedModel;

  /// Set when the model was asked and could not answer for a reason worth
  /// reporting. Null covers both "it answered" and "it failed in a way that
  /// may well work next time".
  ///
  /// The rows are the parser's either way: this reports *why the better
  /// reader was not used*, and never withholds a result.
  final MealTextModelFailure? modelFailure;

  const MealTextReading(
    this.result, {
    required this.usedModel,
    this.modelFailure,
  });
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
  final MealTextInterpreter Function(AiSelection selection) _interpreterFactory;

  ReadMealTextUseCase(this._credentials, this._interpreterFactory);

  Future<MealTextReading> read(String input, {String? localeCode}) async {
    final parsed = parseMealText(input);

    final selection = await _credentials.readSelection();
    if (selection == null) {
      return MealTextReading(parsed, usedModel: false);
    }

    try {
      final interpreted = await _interpreterFactory(
        selection,
      ).interpret(input, localeCode: localeCode);

      // An empty list is an *answer*, not a failure: the model was asked to
      // find food and reported there is none. Overriding it with the parser
      // discards that judgment, and the parser will happily turn any
      // sentence into a query — on a Pixel 6, "meine Steuererklärung und
      // ein Tacker" came back as a cheese-roll match the user had to skip.
      //
      // The fallback below is for a model that could not answer. This is a
      // model that did.
      return MealTextReading(interpreted, usedModel: true);
    } on MealInterpreterException catch (e) {
      // Logged without the input: the line the user typed is the one thing
      // in this flow that should not reach a log.
      _log.info('Interpreter unavailable, using the parser: ${e.reason}');
      // The rows are the parser's regardless. What changes is whether the
      // user is told why the model did not produce them — and that is worth
      // saying exactly when saying it again tomorrow would not help.
      return MealTextReading(
        parsed,
        usedModel: false,
        modelFailure: switch (e.failure) {
          MealInterpreterFailure.auth => MealTextModelFailure.auth,
          MealInterpreterFailure.unsupported =>
            MealTextModelFailure.unsupported,
          MealInterpreterFailure.billing => MealTextModelFailure.billing,
          MealInterpreterFailure.timeout => MealTextModelFailure.timeout,
          MealInterpreterFailure.insecureDestination =>
            MealTextModelFailure.insecureDestination,
          // Silent by design: the parser already produced the rows, and a
          // notice that would say the same thing tomorrow is not worth
          // interrupting for.
          MealInterpreterFailure.rejected ||
          MealInterpreterFailure.transient => null,
        },
      );
    } catch (e, stackTrace) {
      // An interpreter that throws something unexpected is a bug, but it
      // must not cost the user their meal entry.
      _log.severe('Interpreter failed unexpectedly', e, stackTrace);
      return MealTextReading(parsed, usedModel: false);
    }
  }
}
