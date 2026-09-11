// Command-line options shared by the two portion harnesses (#1160), and the
// only code that touches a secret.
//
// Keys and the backend credentials are read at run time from files whose
// *paths* were given on the command line. Nothing here returns a secret as
// a value the caller might print: a provider key is handed on as a closure,
// the way `meal_items_api_factory.dart` hands one to the clients, and the
// backend pair is wrapped in [SupabaseAccess], whose `toString` says nothing.

import 'dart:io';

import 'providers.dart';

/// The default `.env` — the main checkout's, which is gitignored there.
const defaultEnvPath = '/home/simon/Documents/OpenNutriTracker/.env';

/// What both tools take. `--keys` may be absent in a dry run, where no
/// provider is called.
class MeasurementOptions {
  final Directory? keysDir;
  final String envPath;
  final Directory outDir;
  final List<Provider> providers;
  final int count;
  final bool dryRun;

  const MeasurementOptions({
    required this.keysDir,
    required this.envPath,
    required this.outDir,
    required this.providers,
    required this.count,
    required this.dryRun,
  });
}

/// Parses `--keys DIR --env PATH --out DIR --providers a,b,c --count N
/// --dry-run`. Exits 64 on a usage error, the way the old harness did.
MeasurementOptions parseOptions(
  List<String> args, {
  required String tool,
  required int defaultCount,
}) {
  String? keys;
  var env = defaultEnvPath;
  String? out;
  var providers = Provider.values.toList();
  var count = defaultCount;
  var dryRun = false;

  String next(int i, String flag) {
    if (i + 1 >= args.length) usage(tool, 'missing value for $flag');
    return args[i + 1];
  }

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--keys':
        keys = next(i, '--keys');
        i++;
      case '--env':
        env = next(i, '--env');
        i++;
      case '--out':
        out = next(i, '--out');
        i++;
      case '--providers':
        providers = [
          for (final name in next(i, '--providers').split(','))
            Provider.values.firstWhere(
              (p) => p.name == name.trim(),
              orElse: () => usage(tool, 'unknown provider "$name"'),
            ),
        ];
        i++;
      case '--count':
        count =
            int.tryParse(next(i, '--count')) ??
            usage(tool, '--count takes an integer');
        i++;
      case '--dry-run':
        dryRun = true;
      case '--help' || '-h':
        usage(tool, null);
      default:
        usage(tool, 'unexpected argument "${args[i]}"');
    }
  }

  if (out == null) usage(tool, '--out is required');
  if (count <= 0) usage(tool, '--count must be positive');
  if (!dryRun && keys == null) {
    usage(tool, '--keys is required unless --dry-run');
  }

  return MeasurementOptions(
    keysDir: keys == null ? null : Directory(keys),
    envPath: env,
    outDir: Directory(out),
    providers: providers,
    count: count,
    dryRun: dryRun,
  );
}

Never usage(String tool, String? error) {
  if (error != null) stderr.writeln('error: $error');
  stderr.writeln(
    'usage: dart run tool/$tool --out <dir> [--keys <dir>] '
    '[--env <path>] [--providers anthropic,openrouter,openai] '
    '[--count N] [--dry-run]\n'
    '  --keys      directory holding files named anthropic, openrouter, '
    'openai; a missing file skips that provider\n'
    '  --env       file with SUPABASE_PROJECT_URL and '
    'SUPABASE_PROJECT_ANON_KEY (default $defaultEnvPath)\n'
    '  --dry-run   a fake provider answers; only the read-only backend '
    'RPCs are called',
  );
  exit(64);
}

/// A closure that reads the key file for [provider] when called, or null when
/// there is no such file. Read at call time, never held in a field, and
/// never returned as a string to anything that formats output.
String Function()? keyReaderFor(Directory? keysDir, Provider provider) {
  if (keysDir == null) return null;
  final file = File('${keysDir.path}${Platform.pathSeparator}${provider.name}');
  if (!file.existsSync()) return null;
  return () {
    final key = file.readAsStringSync().trim();
    if (key.isEmpty) {
      throw StateError('key file for ${provider.name} is empty');
    }
    return key;
  };
}

/// The two values the backend needs. Deliberately not printable.
class SupabaseAccess {
  final Uri projectUrl;
  final String Function() anonKey;

  const SupabaseAccess._(this.projectUrl, this.anonKey);

  @override
  String toString() => 'SupabaseAccess(${projectUrl.host})';
}

/// Reads `SUPABASE_PROJECT_URL` and `SUPABASE_PROJECT_ANON_KEY` from a
/// `KEY=VALUE` file. Exits when either is missing rather than falling back
/// to anything, because a wrong backend would measure the wrong tables.
SupabaseAccess readSupabaseAccess(String envPath) {
  final file = File(envPath);
  if (!file.existsSync()) {
    stderr.writeln('env file not found: $envPath');
    exit(66);
  }
  final values = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[line.substring(0, eq).trim()] = value;
  }
  final url = values['SUPABASE_PROJECT_URL'];
  final key = values['SUPABASE_PROJECT_ANON_KEY'];
  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    stderr.writeln(
      'env file lacks SUPABASE_PROJECT_URL or SUPABASE_PROJECT_ANON_KEY',
    );
    exit(65);
  }
  return SupabaseAccess._(Uri.parse(url), () => key);
}
