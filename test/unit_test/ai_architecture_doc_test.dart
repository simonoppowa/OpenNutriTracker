import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps [docs/ai-architecture.md] honest about the code it points at.
///
/// That page is written to be lifted onto the GitHub wiki once a release
/// ships the feature, and the wiki is a separate repository: no pull request
/// touches it, no reviewer reads it, and nothing runs against it. Once the
/// page is over there, this test is the only thing still watching it — so it
/// runs against the copy in this repository, where a rename can still be
/// caught in the diff that caused it.
///
/// **It checks paths and anchors, not prose.** A file that moved, a heading
/// that was reworded, a test that was renamed — those are the failures that
/// happen, and they are the ones that fail *quietly*, as a 404 nobody clicks.
/// A description that has drifted out of date is a real risk too and this
/// test does nothing about it; saying so is better than implying otherwise.
void main() {
  final doc = File('docs/ai-architecture.md');
  final text = doc.readAsStringSync();

  /// GitHub's heading slug: lowercased, punctuation dropped, spaces hyphened.
  String slug(String heading) => heading
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 -]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  Set<String> anchorsIn(String markdown) => {
    for (final match in RegExp(
      r'^#{1,6}\s+(.+)$',
      multiLine: true,
    ).allMatches(markdown))
      slug(match.group(1)!.trim()),
  };

  // Links that climb out of docs/ — every reference into lib/, test/ or the
  // README. Anything else on the page is an external URL and not ours to
  // keep working.
  final outward = RegExp(
    r'\]\(\.\./([^)\s#]+)(#[^)\s]*)?\)',
  ).allMatches(text).map((m) => (path: m.group(1)!, anchor: m.group(2)));

  // Links to a heading on the page itself — the table of contents, mostly.
  final internal = RegExp(
    r'\]\(#([^)\s]+)\)',
  ).allMatches(text).map((m) => m.group(1)!).toSet();

  group('docs/ai-architecture.md', () {
    test('the page is where this test thinks it is', () {
      // Every other expectation below reads as a pass against an empty
      // string, so the file has to be proven present before any of them
      // means anything.
      expect(doc.existsSync(), isTrue);
      expect(text, contains('# AI Meal Assistance'));
    });

    test('the link scan actually found links', () {
      // The canary. A regex that stops matching turns every check below into
      // a loop over nothing, and a loop over nothing passes. The floor is
      // deliberately well under the real count — this is here to catch a
      // scan that broke, not to police how many files the page cites.
      expect(
        outward.length,
        greaterThan(25),
        reason: 'the outward-link regex matched almost nothing, so the '
            'checks below are running over an empty list and passing '
            'vacuously — fix the scan, not the page',
      );
      expect(internal, isNotEmpty);
    });

    test('every file the page points at exists', () {
      final missing = [
        for (final link in outward)
          if (!File(link.path).existsSync()) link.path,
      ];
      expect(
        missing,
        isEmpty,
        reason: 'the page cites files that are no longer there. Either the '
            'code moved and the page needs updating, or the file was '
            'deleted and the section describing it is now fiction.',
      );
    });

    test('every heading the page links to exists', () {
      final own = anchorsIn(text);
      final broken = [
        for (final anchor in internal)
          if (!own.contains(anchor)) anchor,
      ];
      expect(
        broken,
        isEmpty,
        reason: 'a heading was reworded without its table-of-contents entry '
            'following it',
      );
    });

    test('the README still points at this page', () {
      // The other direction. Everything above keeps the page's outbound
      // links honest; this keeps the one link *into* it honest, because a
      // page nothing references is a page nobody reads and a rename would
      // cost it its only inbound link without failing anything.
      final readme = File('README.md').readAsStringSync();
      expect(
        readme,
        contains('](docs/ai-architecture.md)'),
        reason: 'the README no longer links to the architecture page, so the '
            'only route a reader has to it is gone',
      );
    });

    test('the release checklist still points at this page', () {
      // The other inbound link, and the one that carries the *instruction*
      // to publish this page to the wiki. If the page is renamed and the
      // checklist is not, the release step points at nothing — and a step
      // nobody can follow is how a page written for the wiki stays in the
      // repo forever.
      final releasing = File('docs/RELEASING.md').readAsStringSync();
      expect(
        releasing,
        contains('](ai-architecture.md)'),
        reason: 'docs/RELEASING.md no longer links to the architecture page, '
            'so the release step that publishes it has lost its target',
      );
    });

    test('every anchor into another document exists', () {
      final broken = <String>[];
      for (final link in outward) {
        final anchor = link.anchor;
        if (anchor == null || !link.path.endsWith('.md')) continue;
        final target = File(link.path);
        if (!target.existsSync()) continue; // already reported above
        if (!anchorsIn(target.readAsStringSync()).contains(anchor.substring(1))) {
          broken.add('${link.path}$anchor');
        }
      }
      expect(
        broken,
        isEmpty,
        reason: 'the page defers its privacy claims to a section of another '
            'document, and that section has been renamed — so the deferral '
            'now goes nowhere',
      );
    });
  });
}
