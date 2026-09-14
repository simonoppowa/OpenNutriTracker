/// Why an export or import did not complete.
///
/// Carried by [ExportImportFailure] from the use cases up to the
/// `ExportImportBloc`, which puts it on `ExportImportError` so the dialog
/// can say something more useful than "error" and a bug report can name
/// the class of failure (#1103).
enum ExportImportFailureReason {
  /// The user dismissed the file picker. Not an error: the bloc maps this
  /// back to its initial state instead of showing it.
  cancelled,

  /// The picked file could not be read, is not a zip, or is a zip without
  /// the entries an OpenNutriTracker backup carries — a `.csv` handed to
  /// the JSON importer, for example, or a DBO whose JSON no longer parses.
  unreadableOrWrongFormat,

  /// The save dialog returned a location, but the bytes did not land there
  /// (or the write itself threw).
  writeFailed,

  /// Anything the use cases did not classify. The log carries the details.
  unexpected,
}

/// An export or import failure with a [reason] the UI can act on.
///
/// The use cases throw this at the boundaries they understand (the file
/// picker, reading and decoding the archive, saving the export). Anything
/// else propagates as-is and the bloc files it under
/// [ExportImportFailureReason.unexpected] — so an unclassified exception
/// still surfaces with its stack trace instead of vanishing.
class ExportImportFailure implements Exception {
  final ExportImportFailureReason reason;
  final String message;

  /// The exception this failure wraps, when it reclassifies one. The
  /// original stack trace is preserved on the rethrow itself (see
  /// [guard]), so only the object needs carrying here.
  final Object? cause;

  const ExportImportFailure(this.reason, this.message, {this.cause});

  /// Runs [action] and rethrows anything it throws as an
  /// [ExportImportFailure] with [reason], keeping the original stack trace.
  ///
  /// A failure that already carries a reason passes through untouched, so
  /// nesting guards does not blur a specific classification into a broad
  /// one.
  static Future<T> guard<T>(
    ExportImportFailureReason reason,
    String context,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on ExportImportFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ExportImportFailure(reason, '$context: $error', cause: error),
        stackTrace,
      );
    }
  }

  /// Synchronous counterpart of [guard].
  static T guardSync<T>(
    ExportImportFailureReason reason,
    String context,
    T Function() action,
  ) {
    try {
      return action();
    } on ExportImportFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ExportImportFailure(reason, '$context: $error', cause: error),
        stackTrace,
      );
    }
  }

  @override
  String toString() => 'ExportImportFailure(${reason.name}): $message';
}
