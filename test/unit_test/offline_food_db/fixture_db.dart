import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// `foods_fixture.sqlite.gz`: twelve foods built by the backend's
/// `scripts/shared/build_sqlite.py` from its `testdata/sqlite` CSVs with the
/// German portion review applied. Its expectations were checked against the
/// Postgres functions loaded with the same rows. Rebuild with:
///
///     python3 scripts/shared/build_sqlite.py \
///       --csv-dir scripts/shared/testdata/sqlite/usda \
///                 scripts/shared/testdata/sqlite/nordic \
///       --review scripts/shared/testdata/sqlite/review/portions_de.csv \
///       --output /tmp/fixture/foods.sqlite --page-size 4096 --no-attribution
final fixtureGz = File('test/fixture/offline_food_db/foods_fixture.sqlite.gz');

/// The fixture unpacked into [dir], as a path.
String unpackFixture(Directory dir) {
  final path = '${dir.path}/foods.sqlite';
  File(path).writeAsBytesSync(gzip.decode(fixtureGz.readAsBytesSync()));
  return path;
}

Database openFixture(Directory dir) =>
    sqlite3.open(unpackFixture(dir), mode: OpenMode.readOnly);
