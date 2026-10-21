# Local FoodData Central asset

`assets/fdc/fdc.json.gz` holds the Foundation Foods and SR Legacy datasets of
USDA FoodData Central (public domain,
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)) in the shape
the app reads offline (#80): per food the FDC id, the dataset (`f`
Foundation, `s` SR Legacy), the English description and the nutrients per
100 g in the app's units. Missing values are `null`, never `0`. Foods without
an energy value are left out (mostly Foundation's dried beans "0% moisture"),
and the note "(Includes foods for USDA's Food Distribution Program)" is cut
from the names. The in-app credits name the source.

The app searches it on the English names only. Both datasets have their own
switch in Settings → Food databases and start off; they are meant for the
gaps the BLS and Open Food Facts leave.

Regenerate after a new FDC release:

1. Download the JSON zips of "Foundation Foods" and "SR Legacy" from
   <https://fdc.nal.usda.gov/download-datasets> and unpack them.
2. From the repo root:

   ```sh
   uv run tool/fdc/fdc_to_asset.py \
     path/to/FoodData_Central_foundation_food_json_2026-04-30.json \
     path/to/FoodData_Central_sr_legacy_food_json_2018-04.json \
     assets/fdc/fdc.json.gz
   ```

3. Run `python3 -m unittest discover -s tool/fdc` and
   `flutter test test/features/add_meal/data/data_sources/local_fdc_food_data_source_test.dart`.

The nutrient mapping (app field → FDC nutrient numbers in priority order) is
`MAPPING` in `fdc_to_asset.py`. FDC already uses the app's units. Foundation
Foods often lack energy 208 and use Atwater energy (958, then 957),
carbohydrate by summation (205.2) and "Sugars, Total" (269.3) instead; folate
takes DFE (435) before total folate (417).

Current build: Foundation Foods 2026-04-30 and SR Legacy 2018-04, 8,114
foods (321 Foundation, 7,793 SR Legacy), about 0.55 MB compressed, 1.9 MB
as JSON.
