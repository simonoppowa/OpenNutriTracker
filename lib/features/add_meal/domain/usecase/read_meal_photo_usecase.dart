import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// What reading a photo produced.
///
/// Sealed so the caller has to handle all three, and so "the feature is off"
/// cannot be confused with "the call failed". They look similar from the
/// bloc and want opposite words in front of the user: one is a setting they
/// can change, the other is a thing that went wrong.
sealed class MealPhotoReadResult {
  const MealPhotoReadResult();
}

/// The model answered. An empty [result] is a legitimate answer — it looked
/// and found no food — not a failure, exactly as on the text path (#647).
final class MealPhotoRead extends MealPhotoReadResult {
  final MealTextParseResult result;

  const MealPhotoRead(this.result);
}

/// No key stored, or the user has switched the feature off. The screen only
/// offers the camera when a key is enabled, so this is the narrow race where
/// the setting changed while the screen was open — worth handling, not worth
/// an alarming message.
final class MealPhotoUnavailable extends MealPhotoReadResult {
  const MealPhotoUnavailable();
}

/// Why a call failed, in the flavours the user can act on.
enum MealPhotoFailure {
  /// The account cannot pay — no credit, or a spend cap reached. Neither
  /// "try again later" nor "check your key" is true of it, and both send the
  /// user somewhere that cannot help.
  billing,

  /// The provider rejected the credential. Told apart from a transient
  /// failure because "try again later" is the wrong advice for a wrong key,
  /// and following it forever is a bad afternoon.
  auth,

  /// The provider refused this image. A corpus run found real photographs
  /// that are rejected on every attempt but succeed once re-encoded, so the
  /// useful advice is "try another photo", not "try again".
  rejectedImage,

  /// Nothing on the other end can read an image for this configuration —
  /// the chosen model has no vision, or no provider of it will honour a
  /// forced tool call. Kept apart from [transient] because retrying is
  /// hopeless and the fix is in settings, not in the network.
  unsupported,

  /// Network, rate limit, provider error. Worth another attempt.
  transient,
}

/// The call failed.
final class MealPhotoFailed extends MealPhotoReadResult {
  final MealPhotoFailure failure;

  const MealPhotoFailed(this.failure);
}

/// Reads a meal photo, when the user has asked for that.
///
/// The sibling of [ReadMealTextUseCase], with the opposite failure policy and
/// for a good reason. Text always has the deterministic parser underneath, so
/// a failed model call there is invisible: the user gets the experience they
/// had before tier 1b existed. A photo has nothing underneath it. There is no
/// offline way to turn a picture into food names, so a failure here is a real
/// dead end and the honest thing is to say so rather than to silently produce
/// nothing and let the screen look broken.
class ReadMealPhotoUseCase {
  static final _log = Logger('ReadMealPhotoUseCase');

  final AiCredentialStorage _credentials;

  /// Builds an interpreter around a key. A factory rather than an instance
  /// because the credential is read per call and should not be captured for
  /// the lifetime of a singleton.
  final MealPhotoInterpreter Function(AiSelection selection)
  _interpreterFactory;

  ReadMealPhotoUseCase(this._credentials, this._interpreterFactory);

  Future<MealPhotoReadResult> read(
    MealPhoto photo, {
    String? localeCode,
  }) async {
    final selection = await _credentials.readSelection();
    if (selection == null) {
      return const MealPhotoUnavailable();
    }

    try {
      final result = await _interpreterFactory(
        selection,
      ).interpret(photo, localeCode: localeCode);
      return MealPhotoRead(result);
    } on MealInterpreterException catch (e) {
      _log.info('Photo interpreter failed: ${e.reason}');
      return MealPhotoFailed(switch (e.failure) {
        MealInterpreterFailure.auth => MealPhotoFailure.auth,
        MealInterpreterFailure.rejected => MealPhotoFailure.rejectedImage,
        MealInterpreterFailure.unsupported => MealPhotoFailure.unsupported,
        MealInterpreterFailure.billing => MealPhotoFailure.billing,
        // Unreachable today, and deliberately not given a member of its own.
        // A server the user runs is the only configuration that reports a
        // timeout as its own kind of failure, and that provider has no photo
        // path at all — `_photoDestination` is null for it, so the camera
        // hides itself (#747 is where the image-format question is settled).
        // Folding it in here keeps the honest "try again" rather than adding
        // a user-facing string no build can currently show.
        MealInterpreterFailure.timeout ||
        MealInterpreterFailure.transient => MealPhotoFailure.transient,
      });
    } catch (e, stackTrace) {
      // An interpreter that throws something unexpected is a bug. Report it
      // as a transient failure rather than as a rejected key — telling the
      // user to check a credential that is fine sends them to fix the one
      // thing that is not broken.
      _log.severe('Photo interpreter failed unexpectedly', e, stackTrace);
      return const MealPhotoFailed(MealPhotoFailure.transient);
    }
  }
}
