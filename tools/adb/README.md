# ADB test tooling

Reusable scripts for driving the app on a real device or emulator, plus the
uiautomator gotchas that make coordinate-based taps land where you expect.

Moved out of `AGENTS.md` because none of it is checkable from a diff — it is
device-driver operating guidance, and `AGENTS.md` is read by PR review agents
under a hard size limit. See the `## Code Review Rules` section there.

### Flutter widgets on Android use `content-desc`, not `text`

When inspecting the uiautomator dump, the visible text of Flutter widgets is reported under `content-desc`, not `text`. System dialogs (DatePicker, AlertDialog) use `text`. Test drivers that find widgets by visible label must check both.

### Form fields drift between taps

Flutter `TextField` / `TextFormField` widgets all report screen-wide `bounds` in the uiautomator dump (the `container: true` gotcha applied to every form input). Tapping a field by hard-coded coordinates from an earlier dump only works once — the moment the keyboard pops up, every layout in the form shifts, and the next tap lands on the wrong row.

The `adb-driver.sh` helpers `tap_field_by_hint`, `enter_text_in_field`, and `fill_fields_by_hint` re-dump the UI before every tap and locate the field by its placeholder `hint` attribute (uiautomator dumps the TextField's placeholder there even when there's no `Semantics(identifier:)` on the field). They also hide the keyboard between fields so the next field's hit target is calculated against the post-IME layout, not the pre-IME one.

Use them for any custom-meal / recipe / onboarding flow that fills more than one input:

```bash
source tools/adb/adb-driver.sh
fill_fields_by_hint \
  'Meal name'     'Greek%syoghurt' \
  'Energy (kcal)' '100' \
  'Carbohydrates' '4' \
  'Fat'           '5' \
  'Protein'       '10'
```

Pass `clear` as a third argument to `enter_text_in_field` when overwriting an existing value:

```bash
enter_text_in_field 'Protein' '10' clear
```

### ADB test tooling

Reusable ADB scripts live in `tools/adb/`:

| Script | Purpose |
|--------|---------|
| `adb-driver.sh` | Core driver library: `tap_id`, `wait_for_id`, `enter_text_at`, `_tap_text`, `screenshot`, `list_ids`, plus form-field helpers `tap_field_by_hint`, `enter_text_in_field`, `fill_fields_by_hint`, `clear_focused_field`, `hide_keyboard`. Source from any test script. |
| `walk-onboarding.sh` | Walks the 7-page onboarding flow, lands the app on the main screen. Exports `walk_onboarding()`. Run standalone or source it. |
| `run-branch-tests.sh` | Sequential smoke-test runner for all triage branches: builds a debug APK, installs it, walks onboarding, and runs a branch-specific probe. Produces a pass/fail summary and per-branch screenshots. |

Usage:

```bash
# Source the driver in a one-off script
source tools/adb/adb-driver.sh
wait_for_id 'nav-home' 15 && echo "on main screen"

# Walk onboarding standalone (clears app data first)
DEVICE=1C151FDEE003YJ bash tools/adb/walk-onboarding.sh

# Run the full branch test pass (unattended, ~90 min)
DEVICE=1C151FDEE003YJ bash tools/adb/run-branch-tests.sh
```

`DEVICE` defaults to the first device returned by `adb devices` when not set.
