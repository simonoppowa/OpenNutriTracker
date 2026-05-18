#!/usr/bin/env python3
"""
Translate FDC food descriptions to German using Google Translate (no API key needed).

Prerequisites:
    pip install deep-translator

Usage:
    python3 translate_fdc_de.py \
        --input  /path/to/filtered/fdc_food_filtered.csv \
        --output /path/to/filtered/fdc_food_translated.csv

The output CSV contains all original columns plus a new 'description_de' column.
Already-translated rows are skipped when re-running (progress is saved after each batch).
"""

import argparse
import csv
import os
import sys
import time

BATCH_SIZE = 20


def translate_batch(translator, texts):
    results = []
    for text in texts:
        try:
            result = translator.translate(text)
            results.append(result or text)
        except Exception:
            results.append(text)  # fall back to English on error
        time.sleep(1.0)
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input",  required=True, help="fdc_food_filtered.csv")
    parser.add_argument("--output", required=True, help="fdc_food_translated.csv")
    args = parser.parse_args()

    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print("Install deep-translator first:  pip install deep-translator")
        sys.exit(1)

    translator = GoogleTranslator(source="en", target="de")

    # Load already-translated rows so we can resume after interruption
    done = {}
    if os.path.exists(args.output):
        with open(args.output, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                if row.get("description_de"):
                    done[row["fdc_id"]] = row["description_de"]
        print(f"Resuming — {len(done)} rows already translated.")

    # Read all input rows
    with open(args.input, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = list(reader.fieldnames) + ["description_de"]
        rows = list(reader)

    todo = [r for r in rows if r["fdc_id"] not in done]
    print(f"To translate: {len(todo)} rows (total {len(rows)})")

    # Translate in batches, save progress after each batch
    for i in range(0, len(todo), BATCH_SIZE):
        batch = todo[i : i + BATCH_SIZE]
        texts = [r["description"] for r in batch]
        try:
            translated = translate_batch(translator, texts)
        except Exception as e:
            print(f"Error at batch {i}: {e}")
            print("Saving progress and stopping — re-run to continue.")
            break
        for row, de in zip(batch, translated):
            done[row["fdc_id"]] = de or row["description"]

        # Save progress after every batch
        with open(args.output, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for row in rows:
                row["description_de"] = done.get(row["fdc_id"], "")
                writer.writerow(row)

        done_count = sum(1 for r in rows if done.get(r["fdc_id"]))
        print(f"  {done_count}/{len(rows)} translated…")
        time.sleep(0.5)

    translated_count = sum(1 for r in rows if done.get(r["fdc_id"]))
    print(f"Done. {translated_count}/{len(rows)} rows have German names → {args.output}")


if __name__ == "__main__":
    main()
