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
# The budget is cumulative along the chain that applies to a path — the root
# file plus every scoped one above that path — so a nested file buys no
# headroom for the directory it sits in.
check_agents_md:
  #!/usr/bin/env bash
  set -euo pipefail
  limit=31000          # deliberate margin under 32768
  head_limit=12000     # Code Review Rules must sit well inside the head
  # The budget is cumulative along a path, not across the tree. Codex reads
  # the root file plus the scoped ones above the reviewed path, so a
  # `subdir/AGENTS.md` spends the same 32768 as the root one — but a sibling
  # `other/AGENTS.md` never applies to that same path and must not be charged
  # against it. Measuring only the root left this green while a real chain
  # was over; summing every tracked file would fail on a total no single
  # review ever reads. So: the worst root-to-leaf chain.
  #
  # Two pathspecs rather than a `*AGENTS.md` suffix glob, which would also
  # match a tracked `NOTAGENTS.md` that Codex never reads.
  agents=$(git ls-files 'AGENTS.md' '*/AGENTS.md')
  if [ -z "$agents" ]; then
    echo "No AGENTS.md is tracked; this guard has nothing to measure." >&2
    exit 1
  fi
  declare -A bytes_of
  while IFS= read -r f; do
    bytes_of["$f"]=$(wc -c < "$f")
  done <<< "$agents"
  # For each file, the chain that reaches it: itself plus every AGENTS.md in
  # an ancestor directory. `${f%AGENTS.md}` is that file's directory prefix
  # ("" at the root), so an ancestor is one whose prefix this one starts with.
  worst=0
  worst_chain=""
  while IFS= read -r f; do
    dir="${f%AGENTS.md}"
    chain_size=0
    chain=""
    while IFS= read -r g; do
      gdir="${g%AGENTS.md}"
      if [ "${dir:0:${#gdir}}" = "$gdir" ]; then
        chain_size=$((chain_size + ${bytes_of["$g"]}))
        chain="${chain}  ${bytes_of["$g"]} ${g}"$'\n'
      fi
    done <<< "$agents"
    if [ "$chain_size" -gt "$worst" ]; then
      worst=$chain_size
      worst_chain=$chain
    fi
  done <<< "$agents"
  if [ "$worst" -gt "$limit" ]; then
    echo "An AGENTS.md chain totals ${worst} bytes, over the ${limit}-byte guard:" >&2
    printf '%s' "$worst_chain" >&2
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
  count=$(printf '%s\n' "$agents" | wc -l)
  echo "${count} AGENTS.md file(s), worst chain ${worst}/${limit} bytes; Code Review Rules at byte ${offset}."

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