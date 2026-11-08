/// Returns [raw] as a trimmed, percent-encoded absolute http(s) URL, or null
/// when it can't be one.
///
/// iOS refuses to launch anything `NSURL` can't parse, which surfaces as
/// `PlatformException(argument_error, Unable to parse URL)`. Open Food Facts
/// product URLs carry localized, non-ASCII slugs and users can import arbitrary
/// strings, so a stored meal URL is only trusted after passing through here.
/// Callers treat null as "no per-item page" and fall back to the source's
/// website.
String? normalizeWebUrl(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  // Uri encodes spaces and non-ASCII path/query characters on parse and
  // leaves existing %XX escapes alone, so the result is safe to re-normalize.
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  // A host with an escape in it (spaces, non-ASCII) is not one NSURL accepts.
  if (uri.host.isEmpty || uri.host.contains('%')) return null;
  return uri.toString();
}
