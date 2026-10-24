import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('SafeUrlLauncher');

/// Opens [url] (in an external app unless [mode] says otherwise) and reports
/// whether that worked.
///
/// `launchUrl` throws a [PlatformException] when no app can handle the link
/// (`ACTIVITY_NOT_FOUND` on Android) or the string is not a URL the platform
/// accepts (`argument_error` on iOS). Both are failures to open, not crashes,
/// so they come back as `false` for the caller to show feedback on.
Future<bool> tryLaunchExternalUrl(
  String url, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    _log.warning('Not a valid URL, not opening it: $url');
    return false;
  }
  try {
    return await launchUrl(uri, mode: mode);
  } on PlatformException catch (e) {
    _log.warning('Could not open $url: ${e.code} ${e.message}');
    return false;
  }
}
