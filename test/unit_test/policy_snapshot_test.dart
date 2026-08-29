import 'package:flutter_test/flutter_test.dart';

import '../../tool/policy_snapshot.dart';

/// The drift guard for the two published policy documents (#887, #888).
///
/// Fixtures rather than the network: the real check runs in CI against the live
/// API, and a unit test that depended on a third party would fail for reasons
/// that have nothing to do with this code.
///
/// The shapes below are taken from the live documents on 2026-08-27 — the
/// `iub-purpose-<n>` / `iub-service-<n>` classes, the two spellings of the
/// last-updated line, and the German document's named entities are all real.
String _document({
  required String lastUpdatedLine,
  required List<(String purpose, int services)> groups,
  List<String> hosts = const [],
  String ownerHeading = 'Owner and Data Controller',
  String contactLine = 'Owner contact email: someone@example.invalid',
  List<String> ownerLines = const [
    'A Maintainer',
    '1 Example Street',
    '12345 Town',
  ],
}) {
  final buffer = StringBuffer()
    ..writeln('<h1>Privacy Policy of OpenNutriTracker</h1>')
    ..writeln('<p>$lastUpdatedLine</p>')
    ..writeln('<h2>$ownerHeading</h2>')
    ..writeln('<p>${ownerLines.join('<br/>')}</p>')
    ..writeln('<p>$contactLine</p>');

  for (final (purpose, services) in groups) {
    buffer.writeln('<h3 class="iub-purpose iub-purpose-$purpose">Group</h3>');
    for (var i = 0; i < services; i++) {
      buffer.writeln(
        '<h4 class="iub-service iub-service-${purpose}0$i">A service</h4>',
      );
    }
  }
  for (final host in hosts) {
    buffer.writeln('<p><a href="https://$host/path">link</a></p>');
  }
  return buffer.toString();
}

void main() {
  group('structure extracted from the rendered document', () {
    test('purpose ids come out of the taxonomy classes', () {
      final html = _document(
        lastUpdatedLine: 'Latest update: August 27, 2026',
        groups: const [('16', 1), ('46', 2)],
      );

      expect(purposeIds(html), {'16', '46'});
    });

    test('services are counted per purpose, not in total', () {
      // A total would miss a service moving between groups, and it is the
      // per-group count that says "this language is missing an entry".
      final html = _document(
        lastUpdatedLine: 'Latest update: August 27, 2026',
        groups: const [('16', 1), ('46', 2), ('61', 2)],
      );

      expect(serviceCountsByPurpose(html), {'16': 1, '46': 2, '61': 2});
    });

    test('a purpose with no services still appears, with a count of zero', () {
      final html = _document(
        lastUpdatedLine: 'Latest update: August 27, 2026',
        groups: const [('16', 0)],
      );

      expect(serviceCountsByPurpose(html), {'16': 0});
    });
  });

  group('the last-updated date, in both languages', () {
    test('reads the English format', () {
      expect(
        lastUpdated('<p>Latest update: August 27, 2026</p>'),
        '2026-08-27',
      );
    });

    test('reads the German format, which orders it differently', () {
      expect(
        lastUpdated('<p>Letzte Aktualisierung: 27. August 2026</p>'),
        '2026-08-27',
      );
    });

    test('reads a German month name that is not spelled as in English', () {
      expect(
        lastUpdated('<p>Letzte Aktualisierung: 3. März 2026</p>'),
        '2026-03-03',
      );
      expect(lastUpdated('<p>Latest update: March 3, 2026</p>'), '2026-03-03');
    });

    test('returns null rather than guessing when the line is missing', () {
      expect(lastUpdated('<p>Nothing to see</p>'), isNull);
    });
  });

  group('comparing the two documents', () {
    String en({
      String updated = 'Latest update: August 27, 2026',
      List<(String, int)> groups = const [('16', 1), ('46', 2)],
      List<String> hosts = const ['example.invalid'],
    }) => _document(lastUpdatedLine: updated, groups: groups, hosts: hosts);

    String de({
      String updated = 'Letzte Aktualisierung: 27. August 2026',
      List<(String, int)> groups = const [('16', 1), ('46', 2)],
      List<String> hosts = const ['example.invalid'],
    }) => _document(
      lastUpdatedLine: updated,
      groups: groups,
      hosts: hosts,
      ownerHeading: 'Anbieter und Verantwortlicher',
      contactLine: 'E-Mail-Adresse des Anbieters: someone@example.invalid',
    );

    test('two documents in step pass', () {
      final report = comparePolicies(en(), de());

      expect(report.failures, isEmpty);
    });

    test('a clause reaching only one language fails', () {
      // #888's failure, exactly: a custom clause added in English and never
      // translated. Custom clauses do not propagate in iubenda.
      final report = comparePolicies(
        en(groups: const [('16', 1), ('46', 3)]),
        de(groups: const [('16', 1), ('46', 2)]),
      );

      expect(report.failures, hasLength(1));
      expect(report.failures.single, contains('purpose 46'));
    });

    test('a whole service group missing in one language fails', () {
      final report = comparePolicies(
        en(groups: const [('16', 1), ('46', 2), ('61', 1)]),
        de(groups: const [('16', 1), ('46', 2)]),
      );

      expect(report.failures, isNotEmpty);
      expect(report.failures.first, contains('61'));
    });

    test('one document edited without the other fails', () {
      // The most direct signal there is: the documents disagree about when
      // they were last touched.
      final report = comparePolicies(
        en(updated: 'Latest update: August 27, 2026'),
        de(updated: 'Letzte Aktualisierung: 1. August 2026'),
      );

      expect(report.failures, hasLength(1));
      expect(report.failures.single, contains('2026-08-01'));
    });

    test(
      'a differing link only warns, because iubenda differs from itself',
      () {
        // Measured 2026-08-27: the English App Store Connect section links
        // support.apple.com for opt-out guidance and the German one omits the
        // sentence. That is the vendor's own template, so failing a build over
        // it would be a check nobody can satisfy.
        final report = comparePolicies(
          en(hosts: const ['example.invalid', 'support.apple.com']),
          de(hosts: const ['example.invalid']),
        );

        expect(report.failures, isEmpty);
        expect(report.warnings, hasLength(1));
        expect(report.warnings.single, contains('support.apple.com'));
      },
    );
  });

  group('the postal address never reaches the snapshot', () {
    test('the address is replaced and the name kept', () {
      final text = htmlToText(
        _document(
          lastUpdatedLine: 'Latest update: August 27, 2026',
          groups: const [('16', 1)],
        ),
      );

      final redacted = redactPostalAddress(text);

      expect(redacted, contains('A Maintainer'));
      expect(redacted, contains(postalAddressPlaceholder));
      expect(redacted, isNot(contains('1 Example Street')));
      expect(redacted, isNot(contains('12345 Town')));
      expect(redacted, contains('someone@example.invalid'));
    });

    test('works on the German document, whose headings differ', () {
      final text = htmlToText(
        _document(
          lastUpdatedLine: 'Letzte Aktualisierung: 27. August 2026',
          groups: const [('16', 1)],
          ownerHeading: 'Anbieter und Verantwortlicher',
          contactLine: 'E-Mail-Adresse des Anbieters: someone@example.invalid',
        ),
      );

      final redacted = redactPostalAddress(text);

      expect(redacted, isNot(contains('1 Example Street')));
      expect(redacted, contains(postalAddressPlaceholder));
    });

    test('an owner block with only a name is left alone', () {
      // If #886's preference lands and the address goes, there is nothing to
      // redact and no placeholder should appear.
      final text = htmlToText(
        _document(
          lastUpdatedLine: 'Latest update: August 27, 2026',
          groups: const [('16', 1)],
          ownerLines: const ['A Maintainer'],
        ),
      );

      final redacted = redactPostalAddress(text);

      expect(redacted, contains('A Maintainer'));
      expect(redacted, isNot(contains(postalAddressPlaceholder)));
    });

    test('an unrecognisable owner block throws rather than leaking', () {
      // The address cannot be searched for — it must not be written down in
      // this repository, which is the point — so recognition is structural.
      // If iubenda reworded the heading, a silent no-op would commit the
      // address on the next run.
      expect(
        () => redactPostalAddress('Some other document\n\nwith no owner block'),
        throwsStateError,
      );
    });
  });
}
