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

  /// GitHub's heading slug, as GitHub actually computes it: lowercased,
  /// punctuation dropped, and then every remaining space turned into a hyphen
  /// one at a time rather than a run at a time. Underscores are word
  /// characters and survive — which matters on a page whose headings name
  /// files like `meal_text_parser.dart`. Both details are confirmed against
  /// this repository's own rendered pages: the `food_summary` heading in
  /// docs/supabase-self-hosting.md is served with the id
  /// `food_summary--one-flat-row-per-food`, keeping the underscore and both
  /// hyphens the em dash left behind. A slug that dropped either would call a
  /// working link broken and a broken one fine.
  String slug(String heading) => heading
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}_ -]', unicode: true), '')
      .replaceAll(' ', '-');

  /// Fenced blocks, removed before anything is scanned. A link inside a fence
  /// is text on the rendered page and cannot be the 404 this test exists to
  /// catch, and this page quotes real source comments verbatim — so scanning
  /// one means failing the build over an accurate transcription. It also
  /// keeps a `# install` line in a shell block from registering as a heading.
  String withoutFences(String markdown) => markdown.replaceAll(
    RegExp(r'^(```|~~~)[^\n]*\n.*?^\1[^\n]*$', multiLine: true, dotAll: true),
    '',
  );

  /// The headings a link can land on. Repeated headings get a `-1` suffix on
  /// GitHub and this does not model that; no page it reads has one.
  Set<String> anchorsIn(String markdown) => {
    for (final match in RegExp(
      r'^#{1,6}\s+(.+)$',
      multiLine: true,
    ).allMatches(withoutFences(markdown)))
      slug(match.group(1)!),
  };

  /// Every link target, in each form that renders as a link. Reading only
  /// `](../path)` misses three that reach a reader just the same: a title
  /// after the target, an angle-bracketed target, and a reference definition
  /// on its own line. Missing them here is worse than it looks — the `sed` in
  /// docs/RELEASING.md that publishes this page rewrites `](../` and nothing
  /// else, so a form this scan does not catch is a form that arrives on the
  /// wiki unrewritten, as a dead link.
  Iterable<String> targetsIn(String markdown) sync* {
    final body = withoutFences(markdown);
    for (final match in RegExp(
      r'\]\(\s*<?([^)\s>]+)>?[^)]*\)',
    ).allMatches(body)) {
      yield match.group(1)!;
    }
    for (final match in RegExp(
      r'^ {0,3}\[[^\]]+\]:\s*<?([^\s>]+)>?',
      multiLine: true,
    ).allMatches(body)) {
      yield match.group(1)!;
    }
  }

  /// A target split into the file it names and the heading it jumps to.
  ({String path, String? anchor}) parts(String target) {
    final hash = target.indexOf('#');
    if (hash < 0) return (path: target, anchor: null);
    return (path: target.substring(0, hash), anchor: target.substring(hash));
  }

  /// Where a link written in docs/ lands, or null if it lands outside the
  /// repository. `File('../x')` resolves against the working directory rather
  /// than against docs/, so `](../../x)` was looked for *beside* the checkout
  /// — and on a machine that happens to have something of that name there, it
  /// is found and the link passes. GitHub serves it as a 404. A target
  /// starting `/` is the same failure by another route: a reader's browser
  /// resolves it against github.com, not against the repository.
  String? insideRepo(String linkPath) {
    if (linkPath.startsWith('/')) return null;
    final segments = <String>[];
    for (final segment in 'docs/$linkPath'.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (segments.isEmpty) return null;
        segments.removeLast();
      } else {
        segments.add(segment);
      }
    }
    return segments.join('/');
  }

  /// Somebody else's to keep working.
  bool isExternal(String linkPath) =>
      RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:|^//').hasMatch(linkPath);

  final targets = targetsIn(text).map(parts).toList();

  // Links into the repository — lib/, test/, the README, and a sibling page
  // in docs/, which a scan that recognised a link only by its `../` never saw.
  final outward = [
    for (final target in targets)
      if (target.path.isNotEmpty && !isExternal(target.path)) target,
  ];

  // Links to a heading on the page itself — the table of contents, mostly.
  final internal = {
    for (final target in targets)
      if (target.path.isEmpty && target.anchor != null)
        target.anchor!.substring(1),
  };

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
      // a loop over nothing, and a loop over nothing passes. The floors sit
      // just under the real counts — 49 outward links and 9 distinct anchors
      // as this is written — so that losing one *kind* of link fails too: the
      // code map alone is 24 rows, and a floor low enough to survive dropping
      // it is a floor that catches nothing. A page that genuinely sheds links
      // is an edit somebody made on purpose, and lowering these by hand is
      // part of it.
      expect(
        outward.length,
        greaterThan(40),
        reason: 'the outward-link scan lost links, so the checks below are '
            'running over a short list — or an empty one — and passing '
            'vacuously; fix the scan, not the page',
      );
      expect(
        internal.length,
        greaterThan(6),
        reason: 'the anchor scan lost links: the table of contents alone is '
            'nine entries',
      );
    });

    test('every file the page points at exists', () {
      final missing = <String>[];
      final escaping = <String>[];
      for (final link in outward) {
        final resolved = insideRepo(link.path);
        if (resolved == null) {
          escaping.add(link.path);
        } else if (!File(resolved).existsSync() &&
            !Directory(resolved).existsSync()) {
          missing.add(link.path);
        }
      }
      expect(
        escaping,
        isEmpty,
        reason: 'the page cites a path that leaves the repository. Whatever '
            'it finds on the machine running this, a reader gets a 404.',
      );
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
      // The README's links resolve from the repository root, so the target
      // is read as written — and read in every form, so that adding a title
      // to the link does not read as the link having been removed.
      final readme = File('README.md').readAsStringSync();
      expect(
        targetsIn(readme).map((target) => parts(target).path),
        contains('docs/ai-architecture.md'),
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
        targetsIn(releasing).map((target) => parts(target).path),
        contains('ai-architecture.md'),
        reason: 'docs/RELEASING.md no longer links to the architecture page, '
            'so the release step that publishes it has lost its target',
      );
    });

    test('every anchor into another document exists', () {
      final broken = <String>[];
      for (final link in outward) {
        final anchor = link.anchor;
        if (anchor == null || !link.path.endsWith('.md')) continue;
        final resolved = insideRepo(link.path);
        if (resolved == null) continue; // already reported above
        final target = File(resolved);
        if (!target.existsSync()) continue; // already reported above
        if (!anchorsIn(
          target.readAsStringSync(),
        ).contains(anchor.substring(1))) {
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
