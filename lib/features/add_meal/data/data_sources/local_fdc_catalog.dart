import 'dart:convert';
import 'dart:io';

import 'package:opennutritracker/features/add_meal/data/data_sources/local_food_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';

/// One food of the local FoodData Central asset (`assets/fdc/fdc.json.gz`).
class FdcFood {
  final int fdcId;

  /// [SPConst.fdcFoundationSourceCode] or [SPConst.fdcSrLegacySourceCode].
  final String dataset;

  /// The English FDC description, e.g. "Apples, raw, with skin".
  final String name;

  /// Values per 100 g in app units, keyed by app field name; a missing key
  /// means FDC gives no value.
  final Map<String, double> values;

  const FdcFood({
    required this.fdcId,
    required this.dataset,
    required this.name,
    required this.values,
  });
}

/// The decoded FDC asset with an offline search on the English names.
class LocalFdcCatalog extends LocalFoodCatalog<FdcFood> {
  LocalFdcCatalog(super.foods)
    : super(nameOf: (food) => food.name, plainWords: const {'raw'});

  /// Decodes the gzip-compressed asset written by `tool/fdc/fdc_to_asset.py`.
  factory LocalFdcCatalog.decode(List<int> gzipBytes) {
    final json =
        jsonDecode(utf8.decode(gzip.decode(gzipBytes))) as Map<String, dynamic>;
    final fields = (json['fields'] as List).cast<String>();
    return LocalFdcCatalog([
      for (final row in json['foods'] as List)
        FdcFood(
          fdcId: (row as List)[0] as int,
          dataset: row[1] == 'f'
              ? SPConst.fdcFoundationSourceCode
              : SPConst.fdcSrLegacySourceCode,
          name: row[2] as String,
          values: {
            for (var i = 0; i < fields.length; i++)
              if ((row[3] as List)[i] != null)
                fields[i]: ((row[3] as List)[i] as num).toDouble(),
          },
        ),
    ]);
  }
}
