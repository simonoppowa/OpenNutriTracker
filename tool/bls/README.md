# Local BLS asset

`assets/bls/bls_4_0.json.gz` holds the Bundeslebensmittelschlüssel 4.0
(© Max Rubner-Institut, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/))
in the shape the app reads offline: per food the BLS code, the German and
English name and the nutrients per 100 g in the app's units. Missing values
are `null`, never `0`. The asset is a modified version of the BLS (units
converted, cut to 38 nutrient fields), and the in-app credits say so, as
CC BY 4.0 requires.

Regenerate after a new BLS release:

1. Download the data zip from <https://blsdb.de/download> and unpack it.
2. From the repo root:

   ```sh
   uv run tool/bls/bls_to_asset.py path/to/BLS_4_0_Daten_2025_DE.xlsx assets/bls/bls_4_0.json.gz
   ```

3. Run `python3 -m unittest discover -s tool/bls` and `flutter test test/unit_test/bls_asset_test.dart`.

The component mapping (BLS code → app field, unit factor) is `MAPPING` in
`bls_to_asset.py`. It extends the mapping of the OpenNutriTracker backend
(`scripts/bls/bls_to_ont_csv.py`) with vitamin E, K, B1, B2, B5, biotin,
folate, iodine, copper, manganese, salt, water, alcohol, omega-3 and omega-6.
BLS 4.0 has no selenium column.

Size: about 0.7 MB compressed, 2 MB as JSON.
