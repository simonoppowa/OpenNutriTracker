"""Tests for bls_to_asset.convert_rows: run with `python3 -m unittest`."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from bls_to_asset import MAPPING, convert_rows, parse_amount  # noqa: E402

HEADER = [
    "BLS Code",
    "Lebensmittelbezeichnung",
    "Food name",
    "ENERCC Energie (Kilokalorien) [kcal/100g]",
    "VITAA Vitamin A, Retinol-Aktivitäts-Äquivalent (RAE) [µg/100g]",
    "VITA Vitamin A, Retinol-Äquivalent (RE) [µg/100g]",
    "VITB6 Vitamin B6 [µg/100g]",
    "CU Kupfer [µg/100g]",
]


def value(asset, food_index, field):
    return asset["foods"][food_index][3][asset["fields"].index(field)]


class ConvertRowsTest(unittest.TestCase):
    def test_converts_units_and_keeps_missing_values_null(self):
        asset = convert_rows(
            HEADER,
            [["C133000", "Hafer Flocken", "Oat flakes", 348, None, 2, 98, 409.61]],
        )

        self.assertEqual(asset["foods"][0][:3], ["C133000", "Hafer Flocken", "Oat flakes"])
        self.assertEqual(value(asset, 0, "energyKcal100"), 348)
        self.assertAlmostEqual(value(asset, 0, "vitaminB6100"), 0.098)
        self.assertAlmostEqual(value(asset, 0, "copper100"), 0.40961)
        self.assertIsNone(value(asset, 0, "fat100"), "no FAT column means null, not 0")

    def test_vitamin_a_takes_only_rae(self):
        asset = convert_rows(HEADER, [["X1", "a", "a", 1, None, 7, None, None]])

        self.assertIsNone(value(asset, 0, "vitaminA100"), "RE is no stand-in for RAE")
        self.assertIsNone(value(asset, 0, "vitaminB6100"))

    def test_skips_rows_without_code_and_lists_every_field(self):
        asset = convert_rows(HEADER, [[None, "x", "x", 1, 1, 1, 1, 1]])

        self.assertEqual(asset["foods"], [])
        self.assertEqual(len(asset["fields"]), len(MAPPING))

    def test_parse_amount(self):
        self.assertEqual(parse_amount("1,5"), 1.5)
        self.assertIsNone(parse_amount("-"))
        self.assertIsNone(parse_amount(""))
        self.assertEqual(parse_amount(3), 3.0)


if __name__ == "__main__":
    unittest.main()
