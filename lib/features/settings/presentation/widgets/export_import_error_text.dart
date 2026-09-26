import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The sentence the Export / Import dialogs show for a failed operation.
///
/// One string per reason, so a user picking the wrong file or saving to a
/// folder the app cannot write to is told which of the two happened
/// (#1103). Shared by the app-data and the custom-food-data dialogs.
String exportImportErrorText(S l10n, ExportImportFailureReason reason) {
  switch (reason) {
    case ExportImportFailureReason.unreadableOrWrongFormat:
      return l10n.exportImportErrorUnreadableLabel;
    case ExportImportFailureReason.writeFailed:
      return l10n.exportImportErrorWriteFailedLabel;
    case ExportImportFailureReason.unexpected:
      return l10n.exportImportErrorLabel;
    case ExportImportFailureReason.cancelled:
      // Never rendered: the bloc maps a cancel back to its initial state
      // and ExportImportError asserts against carrying this reason. The
      // generic label keeps the switch exhaustive without a string that
      // could not be shown.
      return l10n.exportImportErrorLabel;
  }
}
