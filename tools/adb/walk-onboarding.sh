#!/usr/bin/env bash
# tools/adb/walk-onboarding.sh
#
# Walks the OpenNutriTracker onboarding flow using the ADB driver.
# Assumes the app is freshly installed (or app data cleared) and the
# onboarding intro page is visible.
#
# Source it from per-branch verifier scripts:
#   source "$(dirname "$0")/walk-onboarding.sh"
#   walk_onboarding   # leaves the app on the main Home tab
#
# Or run it standalone to verify the walker end-to-end:
#   DEVICE=<serial> bash tools/adb/walk-onboarding.sh
#
# Dummy data filled: female / default birthday / 170 cm / 65 kg /
# Active / Maintain weight.
# ---------------------------------------------------------------------------

__WO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$__WO_DIR/adb-driver.sh"

walk_onboarding() {
  echo "  walk_onboarding: waiting for intro page..."
  wait_for_id 'onboarding-checkbox-privacy' 20 || return 1

  echo "  page 0 — privacy + data collection"
  tap_id 'onboarding-checkbox-privacy' || return 1; sleep 0.3
  tap_id 'onboarding-checkbox-data'    || return 1; sleep 0.3
  tap_id 'onboarding-button'           || return 1; sleep 1

  echo "  page 1 — gender + birthday"
  wait_for_id 'onboarding-gender-genderFemale' 10 || return 1
  tap_id 'onboarding-gender-genderFemale' || return 1; sleep 0.5
  tap_id 'onboarding-birthday-field'      || return 1; sleep 1
  # Material DatePicker OK — check both text and content-desc (system vs Flutter dialog)
  _tap_text 'OK' || _tap_text 'Ok' || _tap_text 'ok' || return 1; sleep 0.8
  tap_id 'onboarding-button' || return 1; sleep 1

  echo "  page 2 — height + weight + optional target weight"
  wait_for_id 'onboarding-height-field' 10 || return 1
  enter_text_at 'onboarding-height-field' '170' || return 1; sleep 0.3
  enter_text_at 'onboarding-weight-field' '65'  || return 1; sleep 0.3
  press_back; sleep 0.5  # dismiss keyboard before scrolling
  # Target weight (#119) sits below the fold on shorter devices because
  # the page now scrolls. Swipe the content up so the field is visible
  # before tapping into it. The walker types an example value so the
  # verifier exercises the full happy path; leaving the field blank is
  # also a valid path through onboarding.
  adb -s "$DEVICE" shell input swipe 540 1600 540 800 300; sleep 0.4
  enter_text_at 'onboarding-target-weight-field' '63' || return 1; sleep 0.3
  press_back; sleep 0.5  # dismiss keyboard so NEXT button is reachable
  tap_id 'onboarding-button' || return 1; sleep 1

  echo "  page 3 — activity level"
  wait_for_id 'onboarding-activity-active' 10 || return 1
  tap_id 'onboarding-activity-active' || return 1; sleep 0.4
  tap_id 'onboarding-button'          || return 1; sleep 1

  echo "  page 4 — weight goal"
  wait_for_id 'onboarding-goal-maintain' 10 || return 1
  tap_id 'onboarding-goal-maintain' || return 1; sleep 0.4
  tap_id 'onboarding-button'        || return 1; sleep 1

  echo "  page 5 — overview, tapping START"
  wait_for_id 'onboarding-button' 10 || return 1
  tap_id 'onboarding-button' || return 1; sleep 3

  # Dismiss the first-launch disclaimer dialog if it appears.
  echo "  dismissing disclaimer dialog (if present)"
  for _ in 1 2 3; do
    if _tap_text 'OK'; then sleep 1; break; fi
    sleep 1
  done

  echo "  onboarding complete — waiting for main NavigationBar"
  wait_for_id 'nav-home' 15 || return 1
  echo "  ✓ landed on main screen"
}

# Run standalone for end-to-end verification.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -uo pipefail
  PACKAGE="${PACKAGE:-com.opennutritracker.ont.opennutritracker}"
  ACTIVITY="${ACTIVITY:-com.opennutritracker.ont.opennutritracker.MainActivity}"
  echo "=== Standalone onboarding walk — device: $DEVICE ==="
  adb -s "$DEVICE" shell pm clear "$PACKAGE" > /dev/null 2>&1 || true
  adb -s "$DEVICE" shell am start -n "$PACKAGE/$ACTIVITY" > /dev/null
  sleep 4
  walk_onboarding
  RC=$?
  if [[ $RC -eq 0 ]]; then
    echo "✓ walker completed onboarding successfully"
    screenshot /tmp/ont-onboarding-complete.png > /dev/null
    echo "screenshot: /tmp/ont-onboarding-complete.png"
  else
    echo "✗ walker failed — visible ids:"
    list_ids | sort -u
    screenshot /tmp/ont-onboarding-failed.png > /dev/null
    echo "screenshot: /tmp/ont-onboarding-failed.png"
  fi
  exit $RC
fi
