import 'dart:io' show Platform;

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/health_package_service.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';
import 'package:opennutritracker/core/data/data_source/health/noop_health_service.dart';

final _log = Logger('HealthServiceFactory');

/// Resolves the [HealthService] this build should use, once, at startup.
///
/// Mirrors how [NotificationService] resolves its platform implementation:
/// probe, and on anything unexpected fall back to a service that reports
/// itself unavailable. A health plugin that cannot initialise must never be
/// able to stop the app from launching.
Future<HealthService> createHealthService() async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return const NoopHealthService();
  }
  try {
    return await HealthPackageService.create();
  } catch (error, stackTrace) {
    _log.severe(
      'Health plugin failed to initialise; workout import disabled '
      'for this session',
      error,
      stackTrace,
    );
    return const NoopHealthService();
  }
}
