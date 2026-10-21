import 'dart:convert';
import 'dart:io';

import 'package:opennutritracker/features/add_meal/data/data_sources/bls_synonyms.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_food_catalog.dart';

/// One food of the local BLS asset (`assets/bls/bls_4_0.json.gz`).
class BlsFood {
  final String code;
  final String nameDe;
  final String? nameEn;

  /// Values per 100 g in app units, keyed by app field name; a missing key
  /// means BLS gives no value.
  final Map<String, double> values;

  const BlsFood({
    required this.code,
    required this.nameDe,
    required this.nameEn,
    required this.values,
  });
}

/// The decoded BLS asset with an offline search on the German names.
class LocalBlsCatalog extends LocalFoodCatalog<BlsFood> {
  LocalBlsCatalog(super.foods)
    : super(
        nameOf: (food) => food.nameDe,
        synonyms: blsSynonyms,
        plainWords: const {'roh'},
      );

  /// Decodes the gzip-compressed asset written by `tool/bls/bls_to_asset.py`.
  factory LocalBlsCatalog.decode(List<int> gzipBytes) {
    final json =
        jsonDecode(utf8.decode(gzip.decode(gzipBytes))) as Map<String, dynamic>;
    final fields = (json['fields'] as List).cast<String>();
    return LocalBlsCatalog([
      for (final row in json['foods'] as List)
        BlsFood(
          code: (row as List)[0] as String,
          nameDe: row[1] as String,
          nameEn: row[2] as String?,
          values: {
            for (var i = 0; i < fields.length; i++)
              if ((row[3] as List)[i] != null)
                fields[i]: ((row[3] as List)[i] as num).toDouble(),
          },
        ),
    ]);
  }
}
