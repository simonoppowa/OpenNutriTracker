# Install dependencies
install:
  flutter pub get

# Build OpenNutriTracker
build:
  dart run build_runner build

# Format dart code (excludes lib/generated/ — gitignored gen-l10n output with its own style)
format *OPTIONS:
  dart format {{OPTIONS}} ./lib/core ./lib/features ./lib/l10n ./test

# Generate localizations from lib/l10n/*.arb into lib/generated/ (gitignored)
gen_l10n:
  flutter gen-l10n

# Generate, then fail if any locale is missing a key.
#
# `flutter gen-l10n` exits 0 on a missing translation: it records the key in
# l10n_untranslated.json (gitignored, per untranslated-messages-file in
# l10n.yaml) and the string falls back to English at runtime. Nothing else
# catches that — analyze and the tests only see the generated getter, which
# exists either way — so a key added to intl_en.arb alone ships as English in
# the other eight locales without a single red check.
check_l10n: gen_l10n
  #!/usr/bin/env bash
  set -euo pipefail
  if [ ! -f l10n_untranslated.json ]; then
    echo "l10n_untranslated.json not found — check untranslated-messages-file in l10n.yaml" >&2
    exit 1
  fi
  if [ "$(tr -d '[:space:]' < l10n_untranslated.json)" != "{}" ]; then
    echo "Locales are missing keys:" >&2
    cat l10n_untranslated.json >&2
    echo "Add each key to every lib/l10n/intl_*.arb, then re-run." >&2
    exit 1
  fi
  echo "All locales complete."

# Guard AGENTS.md against Codex's silent instruction-file truncation.
#
# Codex reads AGENTS.md on the PR review path and truncates instruction
# content at 32 KiB (32768 bytes) — keeping the head, dropping the tail, with
# no warning anywhere a human looks. Nothing else catches it: the review still
# runs, still posts findings, and simply never sees the rules past the cut.
# The budget is cumulative across every AGENTS.md in the tree, so a nested
# file buys no headroom.
check_agents_md:
  #!/usr/bin/env bash
  set -euo pipefail
  limit=31000          # deliberate margin under 32768
  head_limit=12000     # Code Review Rules must sit well inside the head
  size=$(wc -c < AGENTS.md)
  if [ "$size" -gt "$limit" ]; then
    echo "AGENTS.md is ${size} bytes, over the ${limit}-byte guard." >&2
    echo "Codex truncates at 32768 and says nothing. Trim a section or move" >&2
    echo "device/authoring prose out (e.g. to tools/adb/README.md)." >&2
    exit 1
  fi
  offset=$(grep -b -m1 '^## Code Review Rules$' AGENTS.md | cut -d: -f1) || true
  if [ -z "${offset:-}" ]; then
    echo "AGENTS.md has no '## Code Review Rules' heading — Codex review reads it." >&2
    exit 1
  fi
  if [ "$offset" -gt "$head_limit" ]; then
    echo "'## Code Review Rules' starts at byte ${offset}; keep it under ${head_limit}." >&2
    echo "Truncation drops the tail, so the review rules must stay near the top." >&2
    exit 1
  fi
  echo "AGENTS.md ${size}/${limit} bytes; Code Review Rules at byte ${offset}."

# Run tests
test:
  flutter test

# Run CI checks
ci: check_agents_md install (format "--set-exit-if-changed") check_l10n build && test
  flutter analyze

create_emulator:
  fvm flutter emulators --create --name flutter_emulator

start_emulator:
  fvm flutter emulators --launch flutter_emulator

dev:
  fvm flutter run --flavor develop

# Run with the active profile wiped and reseeded with demo data (skips onboarding)
dev_seed:
  fvm flutter run --flavor develop -t lib/dev/main_dev.dart