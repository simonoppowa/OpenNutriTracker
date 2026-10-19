import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:opennutritracker/features/settings/domain/auto_backup_service.dart';

/// Kept alive for the app's lifetime once [startAutoBackup] ran.
AppLifecycleListener? _resumeListener;

/// Runs a due automatic backup now and every time the app comes back to the
/// foreground. iOS gives no reliable background time, so these are the
/// moments a backup can happen; [AutoBackupService.runIfDue] decides whether
/// one is due and never throws.
void startAutoBackup(AutoBackupService service) {
  unawaited(service.runIfDue());
  _resumeListener ??= AppLifecycleListener(
    onResume: () => unawaited(service.runIfDue()),
  );
}
