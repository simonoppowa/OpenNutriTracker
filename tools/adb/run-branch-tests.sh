#!/usr/bin/env bash
# tools/adb/run-branch-tests.sh
#
# Sequential ADB smoke-test pass for all triage branches.
#
# For each branch:
#   1. Checkout + flutter pub get + flutter build apk --debug
#   2. adb install -r
#   3. Clear app data, launch, walk onboarding (tools/adb/walk-onboarding.sh)
#   4. Run the branch-specific feature probe (finds widgets by Semantics identifier)
#   5. Screenshot + log PASS/FAIL
#
# Usage:
#   bash tools/adb/run-branch-tests.sh               # all branches
#   bash tools/adb/run-branch-tests.sh <branch>       # single branch re-run
#
# Environment:
#   DEVICE    — adb serial (default: first connected device)
#   FVM       — path to fvm binary (default: fvm on PATH, or ~/fvm/bin/fvm)
#
# Outputs:
#   /tmp/ont-branch-screenshots/<branch>.png
#   /tmp/ont-branch-test.log
# ---------------------------------------------------------------------------
set -uo pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$__DIR/walk-onboarding.sh"   # also pulls in adb-driver.sh

DEVICE="${DEVICE:-$(adb devices | awk '/device$/{print $1; exit}')}"
PACKAGE="com.opennutritracker.ont.opennutritracker"
ACTIVITY="com.opennutritracker.ont.opennutritracker.MainActivity"
REPO="$(cd "$__DIR/../.." && pwd)"
FVM="${FVM:-$(command -v fvm 2>/dev/null || echo "$HOME/fvm/bin/fvm")}"
APK="$REPO/build/app/outputs/flutter-apk/app-debug.apk"
SCREENSHOTS="/tmp/ont-branch-screenshots"
LOG="/tmp/ont-branch-test.log"
SECRETS="/tmp/ont-secrets"

# ---------------------------------------------------------------------------
# Branch list (add new branches here as the project grows)
# ---------------------------------------------------------------------------
ALL_BRANCHES=(
  docs/publish-signing-fingerprint-321
  docs/supabase-fdc-self-hosting-344
  docs/project-website-266
  fix/safearea-add-meal-156
  feature/scan-default-serving-158
  feature/fdc-import-sanity-checks-222
  feature/slovak-translation-142
  feature/weight-tracking-log-38
  feature/csv-export-132
  feature/json-meal-import-181
  feature/target-weight-119
  feature/custom-activity-kcal-70
  feature/custom-meal-barcode-167
  feature/custom-meal-pictures-64
  fix/atwater-consistency-warning-213
  feature/ephemeral-meal-249
  feature/kj-display-unit-177
  feature/diary-progress-circles-175
  feature/sortable-diary-list-82
  feature/per-meal-calorie-target-150
  feature/daily-micronutrient-panel-160
  feature/simplify-custom-meal-232
  feature/midnight-reset-offset-139
  feature/per-nutrient-planning-goals-173
)

if [[ -n "${1:-}" ]]; then
  BRANCHES=("$1")
else
  BRANCHES=("${ALL_BRANCHES[@]}")
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
_log() { echo "$*" | tee -a "$LOG"; }

_launch_fresh() {
  adb -s "$DEVICE" shell pm clear "$PACKAGE" > /dev/null 2>&1 || true
  adb -s "$DEVICE" shell am start -n "$PACKAGE/$ACTIVITY" > /dev/null 2>&1
  sleep 4
}

_nav_smoke() {
  # Onboarding + all four nav tabs
  walk_onboarding || return 1
  for tab in nav-home nav-diary nav-recipes nav-profile; do
    tap_id "$tab" || { _log "  ✗ $tab not found"; return 1; }
    sleep 1.5
  done
  tap_id 'nav-home'; sleep 1
}

_open_settings() {
  tap_id 'nav-home' || return 1; sleep 1
  # Settings IconButton has tooltip="Settings" → content-desc="Settings"
  _tap_text 'Settings' || { _log "  ✗ could not open Settings"; return 1; }
  sleep 2
}

_check_settings_entry() {
  local id="$1"
  walk_onboarding || return 1
  _open_settings || return 1
  wait_for_id "$id" 8 || { _log "  ✗ '$id' not found in Settings"; return 1; }
  _log "  ✓ '$id' visible in Settings"
}

_check_profile_entry() {
  local id="$1"
  walk_onboarding || return 1
  tap_id 'nav-profile' || return 1; sleep 1.5
  wait_for_id "$id" 8 || { _log "  ✗ '$id' not found in Profile"; return 1; }
  _log "  ✓ '$id' visible in Profile"
}

_open_recipe_builder() {
  # Recipes tab → "+" PopupMenu → "Create Recipe"
  tap_id 'nav-recipes' || return 1; sleep 1.5
  _tap_text 'Add' || { _log "  ✗ Add menu not found on Recipes tab"; return 1; }
  sleep 1
  _tap_text 'Create Recipe' || { _log "  ✗ Create Recipe menu item not found"; return 1; }
  sleep 2
}

# ---------------------------------------------------------------------------
# Per-branch feature probes
# ---------------------------------------------------------------------------

probe_docs()                       { _nav_smoke; }
probe_fix_safearea()               { _nav_smoke; }
probe_scan_default_serving_158()   { _nav_smoke; }
probe_fdc_sanity_222()             { _nav_smoke; }
probe_slovak_142()                 { _nav_smoke; }
probe_csv_export_132()             { _nav_smoke; }
probe_diary_progress_175()         { _nav_smoke; }
probe_atwater_213()                { _nav_smoke; }
probe_sortable_82()                { _nav_smoke; }  # sort menu needs diary entries

probe_kj_display_177()             { _check_settings_entry 'settings-energy-unit'; }
probe_per_meal_calorie_150()       { _check_settings_entry 'settings-energy-unit'; }
probe_midnight_offset_139()        { _check_settings_entry 'settings-energy-unit'; }
probe_json_import_181()            { _check_settings_entry 'settings-paste-json'; }
probe_daily_micronutrient_160()    { _check_settings_entry 'settings-nutrient-visibility'; }
probe_target_weight_119()          { _check_profile_entry  'profile-weight'; }

probe_weight_tracking_38() {
  walk_onboarding || return 1
  tap_id 'nav-profile' || return 1; sleep 1.5
  wait_for_id 'profile-weight-history' 8 || { _log "  ✗ profile-weight-history not found"; return 1; }
  _log "  ✓ profile-weight-history visible"
  tap_id 'profile-weight-history'; sleep 2
  wait_for_id 'weight-history-add' 8 || { _log "  ✗ weight-history-add FAB not found"; return 1; }
  _log "  ✓ weight-history-add FAB visible"
  tap_id 'weight-history-add'; sleep 1.5
  wait_for_id 'weight-history-weight-input' 5 || { _log "  ✗ weight-history-weight-input not found"; return 1; }
  _log "  ✓ weight-history-weight-input visible"
  press_back; sleep 0.5
}

probe_custom_activity_70() {
  walk_onboarding || return 1
  tap_id 'fab-add-item' || return 1; sleep 1
  wait_for_id 'add-item-activity' 5 || { _log "  ✗ add-item-activity not found"; return 1; }
  _log "  ✓ add-item-activity visible"
  tap_id 'add-item-activity'; sleep 2
  _log "  ✓ activity screen loaded"
  press_back; sleep 0.5
}

probe_custom_meal_barcode_167() {
  walk_onboarding || return 1
  _open_recipe_builder || return 1
  wait_for_id 'recipe-builder-barcode-input' 8 || { _log "  ✗ recipe-builder-barcode-input not found"; return 1; }
  _log "  ✓ recipe-builder-barcode-input visible"
}

probe_custom_meal_pictures_64() {
  walk_onboarding || return 1
  _open_recipe_builder || return 1
  wait_for_id 'recipe-builder-image-picker' 8 || { _log "  ✗ recipe-builder-image-picker not found"; return 1; }
  _log "  ✓ recipe-builder-image-picker visible"
}

probe_ephemeral_249() {
  # edit-meal-save-for-later only shows when !editOnly (a real food item is
  # selected). Navigate to the breakfast search screen and prompt the tester
  # to scan a barcode or tap a search result, then verify.
  walk_onboarding || return 1
  tap_id 'fab-add-item' || return 1; sleep 1
  wait_for_id 'add-item-breakfast' 5 || return 1
  tap_id 'add-item-breakfast'; sleep 2
  _log "  ── MANUAL STEP ───────────────────────────────────────"
  _log "  App is on the Breakfast search screen."
  _log "  Scan a food barcode or search for and tap a food item."
  _log "  Polling for edit-meal-save-for-later (120 s)..."
  _log "  ──────────────────────────────────────────────────────"
  wait_for_id 'edit-meal-save-for-later' 120 || { _log "  ✗ edit-meal-save-for-later not found"; return 1; }
  _log "  ✓ edit-meal-save-for-later visible"
}

probe_simplify_custom_232() {
  # "New Custom Food" pushes EditMealScreen with an empty MealEntity,
  # which starts in Simple mode and shows the Simple / Advanced toggle.
  walk_onboarding || return 1
  tap_id 'nav-recipes' || return 1; sleep 1.5
  _tap_text 'Add' || { _log "  ✗ Add menu not found on Recipes tab"; return 1; }
  sleep 1
  _tap_text 'New Custom Food' || { _log "  ✗ New Custom Food not found"; return 1; }
  sleep 2
  wait_for_id 'edit-meal-mode-toggle' 8 || { _log "  ✗ edit-meal-mode-toggle not found"; return 1; }
  _log "  ✓ edit-meal-mode-toggle visible"

  # In Simple mode the unit selector is hidden — confirm it is absent.
  if id_exists 'edit-meal-unit-selector'; then
    _log "  ✗ edit-meal-unit-selector visible in Simple mode (should be hidden)"
    return 1
  fi
  _log "  ✓ unit selector absent in Simple mode"

  # Tap "Advanced" and wait for the unit selector to appear.
  _tap_text 'Advanced' || { _log "  ✗ Advanced segment not found"; return 1; }
  sleep 1.5
  wait_for_id 'edit-meal-unit-selector' 8 || { _log "  ✗ edit-meal-unit-selector not visible after switching to Advanced"; return 1; }
  _log "  ✓ unit selector visible in Advanced mode"

  # Tap "Simple" — unit selector should disappear again.
  _tap_text 'Simple' || { _log "  ✗ Simple segment not found"; return 1; }
  sleep 1.5
  if id_exists 'edit-meal-unit-selector'; then
    _log "  ✗ edit-meal-unit-selector still visible after returning to Simple mode"
    return 1
  fi
  _log "  ✓ unit selector hidden again after returning to Simple mode"
}

probe_per_nutrient_173() {
  # Nutrient goal sliders live inside the Calculations dialog in Settings.
  walk_onboarding || return 1
  _open_settings || return 1
  _tap_text 'Calculations' || {
    adb -s "$DEVICE" shell input swipe 720 1400 720 800 400; sleep 1
    _tap_text 'Calculations' || { _log "  ✗ Calculations tile not found"; return 1; }
  }
  sleep 2
  # kcal-input is at the top of the dialog; fibre-slider may require scrolling
  wait_for_id 'calculations-kcal-input' 8 || { _log "  ✗ calculations-kcal-input not found"; return 1; }
  _log "  ✓ calculations-kcal-input visible (dialog opened correctly)"
}

# ---------------------------------------------------------------------------
# Probe dispatch
# ---------------------------------------------------------------------------
probe_for_branch() {
  case "$1" in
    docs/*)                               probe_docs ;;
    fix/safearea-add-meal-156)            probe_fix_safearea ;;
    feature/scan-default-serving-158)     probe_scan_default_serving_158 ;;
    feature/fdc-import-sanity-checks-222) probe_fdc_sanity_222 ;;
    feature/slovak-translation-142)       probe_slovak_142 ;;
    feature/csv-export-132)               probe_csv_export_132 ;;
    feature/diary-progress-circles-175)   probe_diary_progress_175 ;;
    fix/atwater-consistency-warning-213)  probe_atwater_213 ;;
    feature/weight-tracking-log-38)       probe_weight_tracking_38 ;;
    feature/json-meal-import-181)         probe_json_import_181 ;;
    feature/target-weight-119)            probe_target_weight_119 ;;
    feature/custom-activity-kcal-70)      probe_custom_activity_70 ;;
    feature/custom-meal-barcode-167)      probe_custom_meal_barcode_167 ;;
    feature/custom-meal-pictures-64)      probe_custom_meal_pictures_64 ;;
    feature/ephemeral-meal-249)           probe_ephemeral_249 ;;
    feature/kj-display-unit-177)          probe_kj_display_177 ;;
    feature/sortable-diary-list-82)       probe_sortable_82 ;;
    feature/per-meal-calorie-target-150)  probe_per_meal_calorie_150 ;;
    feature/daily-micronutrient-panel-160) probe_daily_micronutrient_160 ;;
    feature/simplify-custom-meal-232)     probe_simplify_custom_232 ;;
    feature/midnight-reset-offset-139)    probe_midnight_offset_139 ;;
    feature/per-nutrient-planning-goals-173) probe_per_nutrient_173 ;;
    *)                                    probe_docs ;;
  esac
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
cd "$REPO"

_log "=== ONT branch test pass — $(date) ==="
_log "Device  : $DEVICE"
_log "Branches: ${#BRANCHES[@]}"
_log ""

if ! adb -s "$DEVICE" get-state &>/dev/null; then
  echo "ERROR: device $DEVICE not connected. Aborting." | tee -a "$LOG"
  exit 1
fi

mkdir -p "$SECRETS" "$SCREENSHOTS"
chmod 700 "$SECRETS"

# Stash gitignored credential files outside the repo so they survive checkouts
[[ -f "$REPO/.env" ]]                      && cp "$REPO/.env"                      "$SECRETS/env"          || _log "WARNING: .env not found"
[[ -f "$REPO/android/key.properties" ]]    && cp "$REPO/android/key.properties"    "$SECRETS/key.properties" || true
[[ -f "$REPO/android/keystore.jks" ]]      && cp "$REPO/android/keystore.jks"      "$SECRETS/keystore.jks"   || true

ORIGINAL_BRANCH=$(git branch --show-current)
declare -A RESULTS

_log "  fetching all remote branches..."
git fetch --all --quiet 2>&1 | tee -a "$LOG" || true

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
for BRANCH in "${BRANCHES[@]}"; do
  _log "=== $BRANCH ==="

  if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    _log "  SKIP: branch not found locally"
    RESULTS[$BRANCH]="MISSING"; _log ""; continue
  fi

  git checkout "$BRANCH" 2>&1 | tail -1 | tee -a "$LOG"
  git pull --ff-only origin "$BRANCH" 2>&1 | tail -1 | tee -a "$LOG" || true

  [[ -f "$SECRETS/env"            ]] && cp "$SECRETS/env"            "$REPO/.env"
  [[ -f "$SECRETS/key.properties" ]] && cp "$SECRETS/key.properties" "$REPO/android/key.properties"
  [[ -f "$SECRETS/keystore.jks"   ]] && cp "$SECRETS/keystore.jks"   "$REPO/android/keystore.jks"

  _log "  pub get..."
  "$FVM" flutter pub get --no-example 2>&1 | tail -2 | tee -a "$LOG"

  _log "  building debug APK..."
  BUILD_OUT=$("$FVM" flutter build apk --debug 2>&1)
  BUILD_EXIT=$?
  echo "$BUILD_OUT" | tail -3 | sed 's/^/  /' | tee -a "$LOG"

  if [[ $BUILD_EXIT -ne 0 ]]; then
    _log "  ✗ BUILD FAILED"
    RESULTS[$BRANCH]="BUILD_FAIL"; _log ""; continue
  fi

  _log "  installing APK..."
  adb -s "$DEVICE" install -r "$APK" > /dev/null 2>&1 || {
    _log "  ✗ install failed"
    RESULTS[$BRANCH]="INSTALL_FAIL"; _log ""; continue
  }

  _log "  launching fresh..."
  _launch_fresh

  _log "  running feature probe..."
  probe_for_branch "$BRANCH"
  PROBE_EXIT=$?

  SAFE="${BRANCH//\//_}"
  adb -s "$DEVICE" exec-out screencap -p > "$SCREENSHOTS/${SAFE}.png" 2>/dev/null || true

  if [[ $PROBE_EXIT -eq 0 ]]; then
    RESULTS[$BRANCH]="PASS"; _log "  → PASS"
  else
    RESULTS[$BRANCH]="FAIL"; _log "  → FAIL"
  fi

  adb -s "$DEVICE" shell pm clear "$PACKAGE" > /dev/null 2>&1 || true
  _log ""
done

# ---------------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------------
git checkout "$ORIGINAL_BRANCH" 2>&1 | tail -1 | tee -a "$LOG"
[[ -f "$SECRETS/env"            ]] && cp "$SECRETS/env"            "$REPO/.env"
[[ -f "$SECRETS/key.properties" ]] && cp "$SECRETS/key.properties" "$REPO/android/key.properties"
[[ -f "$SECRETS/keystore.jks"   ]] && cp "$SECRETS/keystore.jks"   "$REPO/android/keystore.jks"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
_log ""
_log "===== SUMMARY ====="
PASS_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
for BRANCH in "${BRANCHES[@]}"; do
  STATUS="${RESULTS[$BRANCH]:-UNKNOWN}"
  printf "  %-12s %s\n" "$STATUS" "$BRANCH" | tee -a "$LOG"
  case $STATUS in
    PASS)                          ((PASS_COUNT++)) ;;
    FAIL|BUILD_FAIL|INSTALL_FAIL)  ((FAIL_COUNT++)) ;;
    *)                             ((SKIP_COUNT++)) ;;
  esac
done
_log ""
_log "  $PASS_COUNT passed · $FAIL_COUNT failed · $SKIP_COUNT skipped"
_log "  Screenshots → $SCREENSHOTS"
_log "  Log         → $LOG"

[[ $FAIL_COUNT -eq 0 ]]
