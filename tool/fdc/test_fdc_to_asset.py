"""Tests for fdc_to_asset.convert_foods: run with `python3 -m unittest`."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from fdc_to_asset import MAPPING, convert_foods  # noqa: E402


def nutrient(number, amount):
    return {"nutrient": {"number": number}, "amount": amount}


def food(fdc_id, description, *nutrients):
    return {"fdcId": fdc_id, "description": description, "foodNutrients": list(nutrients)}


def value(asset, food_index, field):
    return asset["foods"][food_index][3][asset["fields"].index(field)]


class ConvertFoodsTest(unittest.TestCase):
    def test_keeps_app_units_and_missing_values_null(self):
        asset = convert_foods(
            [],
            [food(1, "Apples, raw", nutrient("208", 52), nutrient("418", 0.1), nutrient("312", 0.027))],
        )

        self.assertEqual(asset["foods"][0][:3], [1, "s", "Apples, raw"])
        self.assertEqual(value(asset, 0, "energyKcal100"), 52)
        self.assertAlmostEqual(value(asset, 0, "vitaminB12100"), 0.1)
        self.assertAlmostEqual(value(asset, 0, "copper100"), 0.027)
        self.assertIsNone(value(asset, 0, "fat100"), "a missing nutrient is null, not 0")

    def test_takes_the_fallback_numbers_in_order(self):
        asset = convert_foods(
            [
                food(
                    2,
                    "Kale, raw",
                    nutrient("957", 40),
                    nutrient("958", 35),
                    nutrient("205.2", 4.4),
                    nutrient("269.3", 0.8),
                    nutrient("417", 62),
                )
            ],
            [food(3, "Kale, cooked", nutrient("208", 28), nutrient("435", 65), nutrient("417", 65.5))],
        )

        self.assertEqual(value(asset, 0, "energyKcal100"), 35, "Atwater specific before general")
        self.assertEqual(value(asset, 0, "carbohydrates100"), 4.4)
        self.assertEqual(value(asset, 0, "sugars100"), 0.8)
        self.assertEqual(value(asset, 0, "folate100"), 62)
        self.assertEqual(value(asset, 1, "folate100"), 65, "DFE before total folate")

    def test_marks_the_dataset_of_each_food(self):
        asset = convert_foods([food(4, "a", nutrient("208", 1))], [food(5, "b", nutrient("208", 1))])

        self.assertEqual([row[1] for row in asset["foods"]], ["f", "s"])

    def test_drops_empty_entries_and_foods_without_energy(self):
        asset = convert_foods(
            [None, food(6, "Beans, Dry, Red (0% moisture)", nutrient("203", 24)), food(7, "x", {"nutrient": None})],
            [food(8, "y", nutrient("208", None))],
        )

        self.assertEqual(asset["foods"], [])

    def test_drops_the_usda_program_note_from_names(self):
        asset = convert_foods(
            [],
            [food(9, "Apples, raw, with skin (Includes foods for USDA's Food Distribution Program)", nutrient("208", 52))],
        )

        self.assertEqual(asset["foods"][0][2], "Apples, raw, with skin")

    def test_lists_every_field(self):
        asset = convert_foods([], [])

        self.assertEqual(asset["fields"], [field for field, _ in MAPPING])
        self.assertIn("selenium100", asset["fields"])


if __name__ == "__main__":
    unittest.main()
