// Fetches both published privacy-policy documents, writes a readable snapshot
// of each into the repository, and compares their structure.
//
// Two jobs in one script, because they need the same fetch:
//
//  1. **The change record.** iubenda keeps no version history and offers no
//     "tell me what changed" view (#871). Committing the rendered text gives
//     git's history as a substitute, which is what #887 settled on when it
//     decided what is owed to users who acknowledged an older policy.
//
//  2. **The drift guard.** Every clause this project wrote is a *custom*
//     clause, and custom clauses do not propagate between languages in
//     iubenda (#871) — #888 caught exactly that in the wild, with the German
//     document left behind. A check that needs no discipline beats one that
//     relies on someone remembering.
//
// The API returns the *rendered document*, not the configuration
// (verified in #871), so every comparison here has to be derived from HTML.
// What makes that tractable is that some of the markup is language-independent:
//
//  * `iub-purpose-<n>` ids come from iubenda's fixed taxonomy and are
//    identical in both documents. Measured 2026-08-27: {16, 25, 30, 42, 46, 61}
//    in both.
//  * `iub-service-<n>` ids are **not** — they are minted per language
//    (13427280 vs 13427279 and so on), so they cannot be a comparison key.
//    The service *count per purpose* can be, and is.
//  * The set of linked hosts is language-independent, but see the note on
//    `hostDifferences` for why it only warns.
//
// Usage:
//   dart run tool/policy_snapshot.dart            # write snapshots, check
//   dart run tool/policy_snapshot.dart --check    # check only, write nothing

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// The two published documents. Both are rendered from configurations in the
/// same iubenda project; see `URLConst.privacyPolicyFor` for which locale is
/// sent to which.
const policyDocuments = <String, String>{'en': '53501884', 'de': '53922100'};

/// Where the snapshots live. One file per language, plain text, so a git diff
/// reads like a diff of the policy rather than of HTML.
const snapshotDirectory = 'docs/privacy-policy';

Future<void> main(List<String> args) async {
  final checkOnly = args.contains('--check');
  final documents = <String, String>{};

  for (final entry in policyDocuments.entries) {
    stdout.writeln('Fetching ${entry.key} (${entry.value})…');
    documents[entry.key] = await fetchPolicy(entry.value);
  }

  if (!checkOnly) {
    Directory(snapshotDirectory).createSync(recursive: true);
    for (final entry in documents.entries) {
      final file = File('$snapshotDirectory/${entry.key}.txt');
      file.writeAsStringSync(redactPostalAddress(htmlToText(entry.value)));
      stdout.writeln('Wrote ${file.path}');
    }
  }

  final report = comparePolicies(documents['en']!, documents['de']!);
  stdout.writeln('\n$report');

  if (report.failures.isNotEmpty) {
    stderr.writeln(
      'The two documents disagree on something the maintainer controls. '
      'Every clause in this policy is custom, and custom clauses do not '
      'propagate between languages — see #888.',
    );
    exit(1);
  }
}

/// The rendered document for [publicId], as HTML.
///
/// `no-markup` of the three documented endpoints: it keeps the heading
/// structure the comparison needs while dropping iubenda's presentational
/// wrapper, so the snapshot diffs are about words rather than styling.
Future<String> fetchPolicy(String publicId) async {
  final url = Uri.https(
    'www.iubenda.com',
    '/api/privacy-policy/$publicId/no-markup',
  );
  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw StateError('$url returned HTTP ${response.statusCode}');
  }

  final body = jsonDecode(utf8.decode(response.bodyBytes));
  if (body is! Map || body['success'] != true) {
    // The documented failure is a plan downgrade: "To access this privacy
    // policy via API, convert it to Pro". Worth failing loudly, because it
    // silently ends the change record.
    throw StateError(
      '$url reported failure: ${body is Map ? body['error'] : body}',
    );
  }

  final content = body['content'];
  if (content is! String || content.isEmpty) {
    throw StateError('$url returned no content');
  }
  return content;
}

/// A readable, diffable rendering of [html].
///
/// Not a general HTML converter — it only has to be stable, so that a diff
/// between two snapshots shows editorial changes and nothing else.
String htmlToText(String html) {
  var text = html
      .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      // A blank line before each block element, so headings and paragraphs
      // stay separate lines and a one-clause edit stays a one-hunk diff.
      .replaceAll(
        RegExp(r'<(h[1-6]|p|div|li|tr)[^>]*>', caseSensitive: false),
        '\n\n',
      )
      .replaceAll(RegExp(r'<[^>]+>'), '');

  text = _unescapeEntities(text);

  final lines = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .toList();

  final out = <String>[];
  for (final line in lines) {
    if (line.isEmpty && (out.isEmpty || out.last.isEmpty)) continue;
    out.add(line);
  }
  return '${out.join('\n').trim()}\n';
}

String _unescapeEntities(String input) {
  const named = <String, String>{
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
    // The German document arrives with its umlauts as named entities.
    '&auml;': 'ä', '&ouml;': 'ö', '&uuml;': 'ü',
    '&Auml;': 'Ä', '&Ouml;': 'Ö', '&Uuml;': 'Ü',
    '&szlig;': 'ß',
    '&eacute;': 'é', '&egrave;': 'è', '&agrave;': 'à', '&ccedil;': 'ç',
    '&laquo;': '«', '&raquo;': '»', '&bdquo;': '„', '&ldquo;': '“',
    '&rdquo;': '”', '&lsquo;': '‘', '&rsquo;': '’', '&sbquo;': '‚',
  };
  var out = input;
  named.forEach((entity, char) => out = out.replaceAll(entity, char));
  return out.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) => String.fromCharCode(int.parse(m.group(1)!)),
  );
}

/// Headings that open the owner block, and the contact lines that close it.
/// Both languages, because the snapshot is taken of both.
const _ownerHeadings = [
  'Owner and Data Controller',
  'Anbieter und Verantwortlicher',
];
const _ownerContactPrefixes = [
  'Owner contact email',
  'E-Mail-Adresse des Anbieters',
];

/// Marker left in place of the owner's postal address.
const postalAddressPlaceholder = '[postal address — see the published policy]';

/// Replaces the owner's postal address with [postalAddressPlaceholder].
///
/// The address is on the published page already, so this is not hiding it. It
/// keeps a maintainer's home address out of a public repository's *permanent*
/// history, which is a different and much longer-lived thing than a page that
/// can be edited. #886 also recorded a preference for a c/o or service address
/// over the residential one, and nothing here should quietly outrun that.
///
/// Structural rather than a search for the address itself: the address must not
/// be written down in this repository, which is the whole point, so it cannot
/// be the thing matched on. The owner block runs from a known heading to the
/// contact-email line, and everything between the name and that line is the
/// address.
///
/// **Throws when the block cannot be recognised.** A silent no-op here would
/// mean an iubenda wording change quietly commits the address, so the failure
/// mode is a loud one.
String redactPostalAddress(String text) {
  final lines = text.split('\n');
  final headingIndex = lines.indexWhere(
    (line) => _ownerHeadings.contains(line.trim()),
  );
  if (headingIndex < 0) {
    throw StateError(
      'Owner block not found — refusing to write a snapshot that may carry a '
      'postal address. Headings looked for: $_ownerHeadings',
    );
  }

  final contactIndex = lines.indexWhere(
    (line) => _ownerContactPrefixes.any((p) => line.trim().startsWith(p)),
    headingIndex,
  );
  if (contactIndex < 0) {
    throw StateError(
      'Owner contact line not found after the owner heading — refusing to '
      'write a snapshot that may carry a postal address.',
    );
  }

  // Between the heading and the contact line: a blank, the name, then the
  // address lines. Keep the name, replace the rest.
  final body = <String>[];
  for (var i = headingIndex + 1; i < contactIndex; i++) {
    if (lines[i].trim().isNotEmpty) body.add(lines[i]);
  }
  if (body.isEmpty) return text;

  return [
    ...lines.sublist(0, headingIndex + 1),
    '',
    body.first,
    if (body.length > 1) postalAddressPlaceholder,
    '',
    ...lines.sublist(contactIndex),
  ].join('\n');
}

/// Purpose ids, from iubenda's fixed taxonomy. Identical in both documents,
/// which is what makes them usable as a comparison key.
Set<String> purposeIds(String html) => RegExp(
  r'iub-purpose-(\d+)',
).allMatches(html).map((m) => m.group(1)!).toSet();

/// How many service entries sit under each purpose, keyed by purpose id.
///
/// Counts rather than ids: `iub-service-<n>` is minted per language, so the
/// ids differ between the documents even when they describe the same service.
/// A count is the strongest language-independent claim available — it catches
/// a service declared in one language and not the other, which is #888.
Map<String, int> serviceCountsByPurpose(String html) {
  final counts = <String, int>{};
  String? current;
  for (final match in RegExp(
    r'iub-purpose-(\d+)|iub-service-(\d+)',
  ).allMatches(html)) {
    final purpose = match.group(1);
    if (purpose != null) {
      current = purpose;
      counts.putIfAbsent(current, () => 0);
    } else if (current != null) {
      counts[current] = counts[current]! + 1;
    }
  }
  return counts;
}

/// Hosts the document links out to.
Set<String> linkedHosts(String html) => RegExp(
  r'href="https?://([^/"]+)',
).allMatches(html).map((m) => m.group(1)!).toSet();

/// Month names in the two languages the documents are published in, lowercased.
const _monthNames = <String, int>{
  'january': 1,
  'februar': 2,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
  'januar': 1,
  'märz': 3,
  'mai': 5,
  'juni': 6,
  'juli': 7,
  'oktober': 10,
  'dezember': 12,
};

/// The document's own "last updated" date, as `yyyy-mm-dd`, or null when it
/// cannot be parsed.
///
/// The single most direct signal for #888's failure: one document edited and
/// the other left behind. The two languages format it differently — *Latest
/// update: August 27, 2026* against *Letzte Aktualisierung: 27. August 2026* —
/// so both shapes are parsed rather than compared as strings.
String? lastUpdated(String html) {
  final text = htmlToText(html);
  final match = RegExp(
    r'(?:Latest update|Letzte Aktualisierung)\s*:\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;

  final value = match.group(1)!.trim();
  final year = RegExp(r'\b(\d{4})\b').firstMatch(value)?.group(1);
  final day = RegExp(r'\b(\d{1,2})\b').firstMatch(value)?.group(1);
  final monthWord = RegExp(
    r'\b([A-Za-zÄÖÜäöüß]+)\b',
  ).firstMatch(value)?.group(1);
  if (year == null || day == null || monthWord == null) return null;

  final month = _monthNames[monthWord.toLowerCase()];
  if (month == null) return null;

  final dd = day.padLeft(2, '0');
  final mm = month.toString().padLeft(2, '0');
  return '$year-$mm-$dd';
}

/// What the comparison found. Failures fail the build; warnings only report.
class PolicyComparison {
  final List<String> failures;
  final List<String> warnings;
  final List<String> notes;

  PolicyComparison(this.failures, this.warnings, this.notes);

  @override
  String toString() => [
    ...notes.map((n) => '  $n'),
    ...warnings.map((w) => 'WARN  $w'),
    ...failures.map((f) => 'FAIL  $f'),
    failures.isEmpty
        ? 'Both documents agree on everything checked.'
        : '${failures.length} divergence(s).',
  ].join('\n');
}

/// Compares the two rendered documents.
///
/// Only things the maintainer can actually fix are failures. iubenda's own
/// template text differs between its languages in places — measured
/// 2026-08-27, the English App Store Connect section links
/// `support.apple.com` for opt-out guidance and the German one omits the whole
/// sentence — and failing a build over a vendor's translation would be a check
/// nobody can satisfy. Those surface as warnings, and the committed snapshots
/// are what make them reviewable.
PolicyComparison comparePolicies(String enHtml, String deHtml) {
  final failures = <String>[];
  final warnings = <String>[];
  final notes = <String>[];

  final enPurposes = purposeIds(enHtml);
  final dePurposes = purposeIds(deHtml);
  notes.add('purposes: ${enPurposes.length} en, ${dePurposes.length} de');
  if (enPurposes.length != dePurposes.length ||
      !enPurposes.containsAll(dePurposes)) {
    failures.add(
      'purpose sets differ — en only: ${_sorted(enPurposes.difference(dePurposes))}, '
      'de only: ${_sorted(dePurposes.difference(enPurposes))}',
    );
  }

  final enServices = serviceCountsByPurpose(enHtml);
  final deServices = serviceCountsByPurpose(deHtml);
  notes.add('services: ${_total(enServices)} en, ${_total(deServices)} de');
  for (final purpose in {...enServices.keys, ...deServices.keys}) {
    final en = enServices[purpose] ?? 0;
    final de = deServices[purpose] ?? 0;
    if (en != de) {
      failures.add(
        'purpose $purpose declares $en service(s) in English and $de in German',
      );
    }
  }

  final enUpdated = lastUpdated(enHtml);
  final deUpdated = lastUpdated(deHtml);
  notes.add(
    'last updated: ${enUpdated ?? "unparsed"} en, ${deUpdated ?? "unparsed"} de',
  );
  if (enUpdated == null || deUpdated == null) {
    warnings.add(
      'could not parse a last-updated date from both documents; the date '
      'wording or format may have changed',
    );
  } else if (enUpdated != deUpdated) {
    failures.add(
      'last updated $enUpdated in English but $deUpdated in German — one '
      'document was edited without the other',
    );
  }

  final hostDifferences = linkedHosts(enHtml)
      .difference(linkedHosts(deHtml))
      .union(linkedHosts(deHtml).difference(linkedHosts(enHtml)));
  if (hostDifferences.isNotEmpty) {
    warnings.add(
      'linked hosts differ: ${_sorted(hostDifferences)} — check whether this is '
      'iubenda template text or a clause of ours that only reached one language',
    );
  }

  return PolicyComparison(failures, warnings, notes);
}

String _sorted(Set<String> values) => (values.toList()..sort()).join(', ');

int _total(Map<String, int> counts) =>
    counts.values.fold(0, (sum, value) => sum + value);
