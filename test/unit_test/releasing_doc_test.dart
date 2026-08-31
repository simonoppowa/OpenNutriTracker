import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps [docs/RELEASING.md] pointing at things that exist.
///
/// It is a checklist, which is a document read once per release by someone
/// working through it in order — so a link that goes nowhere is found at the
/// worst possible moment, by the person least able to stop and investigate.
/// Nothing else checks it: the architecture page's test guards links *into*
/// that page, not this file's own.
///
/// Paths and anchors only. Whether a step is still the right step is a
/// judgement no test makes.
void main() {
  final doc = File('docs/RELEASING.md');
  final text = doc.readAsStringSync();

  String slug(String heading) => heading
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 -]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  final ownAnchors = {
    for (final m in RegExp(r'^#{1,6}\s+(.+)$', multiLine: true).allMatches(text))
      slug(m.group(1)!.trim()),
  };

  // Relative links, resolved from docs/. "../CONTRIBUTING.md" climbs out;
  // "ai-architecture.md" sits alongside.
  final relative = RegExp(
    r'\]\((?!https?:|#)([^)\s#]+)\)',
  ).allMatches(text).map((m) => m.group(1)!).toSet();

  final internal = RegExp(
    r'\]\(#([^)\s]+)\)',
  ).allMatches(text).map((m) => m.group(1)!).toSet();

  group('docs/RELEASING.md', () {
    test('the checklist is where this test thinks it is', () {
      expect(doc.existsSync(), isTrue);
      expect(text, contains('# Releasing'));
    });

    test('the link scan found something', () {
      // Without this the two checks below iterate an empty set and pass
      // while proving nothing — the same canary the architecture page's
      // test carries, for the same reason.
      expect(relative, isNotEmpty);
      expect(internal, isNotEmpty);
    });

    test('every file it links to exists', () {
      final missing = [
        for (final path in relative)
          if (!File('docs/$path').existsSync() &&
              !File(path.replaceFirst('../', '')).existsSync())
            path,
      ];
      expect(missing, isEmpty);
    });

    test('every heading it links to exists', () {
      // The hotfix section is cross-referenced from two places, so a
      // reworded heading breaks the step that stops a fix on `main` being
      // lost — quietly, in a document nobody re-reads between releases.
      final broken = [
        for (final anchor in internal)
          if (!ownAnchors.contains(anchor)) anchor,
      ];
      expect(broken, isEmpty);
    });
  });
}
