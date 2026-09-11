// The prompt text as it actually ran, read back out of the sources so the
// report cannot drift from the code. The system prompts are private
// constants of the interpreters, which is right for the app and awkward for
// a report; reading the file is the honest alternative to a second copy.

import 'dart:io';

class PromptsAsRun {
  final String textSystemPrompt;
  final String photoSystemPrompt;
  final String schemaPortionDescription;

  const PromptsAsRun({
    required this.textSystemPrompt,
    required this.photoSystemPrompt,
    required this.schemaPortionDescription,
  });
}

PromptsAsRun readPromptsAsRun() {
  final root = _packageRoot();
  String read(String path) => File('$root/$path').readAsStringSync();

  final text = _tripleQuoted(
    read('lib/features/add_meal/data/model_meal_text_interpreter.dart'),
  );
  final photo = _tripleQuoted(
    read('lib/features/add_meal/data/model_meal_photo_interpreter.dart'),
  );
  final schema = _portionDescription(
    read('lib/features/add_meal/domain/meal_items_api.dart'),
  );
  return PromptsAsRun(
    textSystemPrompt: text,
    photoSystemPrompt: photo,
    schemaPortionDescription: schema,
  );
}

String _packageRoot() {
  if (File('pubspec.yaml').existsSync()) return Directory.current.path;
  // `dart run tool/x.dart` from elsewhere: the script sits in tool/.
  final script = File.fromUri(Platform.script);
  return script.parent.parent.path;
}

String _tripleQuoted(String source) {
  final m = RegExp(
    r"static const _systemPrompt = '''\n(.*?)''';",
    dotAll: true,
  ).firstMatch(source);
  if (m == null) throw StateError('no _systemPrompt in source');
  return m.group(1)!;
}

String _portionDescription(String source) {
  final m = RegExp(
    r"'portion': \{\s*'type': 'string',\s*'description':\s*((?:'(?:[^'\\]|\\.)*'\s*)+),",
    dotAll: true,
  ).firstMatch(source);
  if (m == null) throw StateError('no portion description in schema');
  final literals = RegExp(r"'((?:[^'\\]|\\.)*)'").allMatches(m.group(1)!);
  return literals.map((l) => l.group(1)!.replaceAll(r"\'", "'")).join();
}

/// The bullet of [prompt] that starts with `- [start]`, joined onto one
/// line for quoting in a report.
String promptBullet(String prompt, String start) {
  final lines = prompt.split('\n');
  final from = lines.indexWhere((l) => l.startsWith('- $start'));
  if (from < 0) return '(bullet not found)';
  final out = <String>[lines[from]];
  for (var i = from + 1; i < lines.length && lines[i].startsWith('  '); i++) {
    out.add(lines[i].trim());
  }
  return out.join(' ');
}
