#!/usr/bin/env bash
# Tests for pod_install_with_targeted_fallback.sh.
#
# The fallback parser is the only piece of the iOS CI flow that decides
# *which* pods to update when Podfile.lock drifts. A regression in its
# regexes would silently degrade the targeted-update path back to a
# full `pod update`, which is exactly the behaviour we filed #369 to
# avoid. These tests pin each recognised CocoaPods error shape so that
# kind of regression surfaces here rather than on a real drift event
# in production.
#
# Each test case runs the script under control of a mocked `pod` shim
# that:
#   - emits a canned `pod install` failure
#   - records the arguments `pod update` is called with into a file
# The assertion is on the recorded arguments — empty file means
# `pod update` wasn't invoked, "<full>" means it was invoked with no
# arguments (the last-resort full-update fallback).

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sut="$script_dir/pod_install_with_targeted_fallback.sh"

tests_run=0
tests_failed=0

run_case() {
  local name="$1"
  local install_exit="$2"
  local install_output="$3"
  local expected="$4"

  local sandbox; sandbox="$(mktemp -d)"
  local mock_bin="$sandbox/bin"
  local update_log="$sandbox/update.log"
  local install_output_file="$sandbox/install_output.txt"
  mkdir -p "$mock_bin"
  printf '%s\n' "$install_output" > "$install_output_file"

  cat > "$mock_bin/pod" <<MOCK_EOF
#!/usr/bin/env bash
case "\$1" in
  install)
    cat "$install_output_file"
    exit $install_exit
    ;;
  update)
    shift
    if [ \$# -eq 0 ]; then
      echo "<full>" > "$update_log"
    else
      echo "\$*" > "$update_log"
    fi
    exit 0
    ;;
esac
MOCK_EOF
  chmod +x "$mock_bin/pod"

  PATH="$mock_bin:$PATH" "$sut" >/dev/null 2>&1 || true

  local actual="<not called>"
  if [ -f "$update_log" ]; then
    actual="$(cat "$update_log")"
  fi

  tests_run=$((tests_run + 1))
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $name"
  else
    tests_failed=$((tests_failed + 1))
    echo "FAIL: $name"
    echo "  expected: $expected"
    echo "  actual:   $actual"
  fi

  rm -rf "$sandbox"
}

run_case "successful pod install does not invoke update" \
  0 \
  'Pod installation complete!' \
  '<not called>'

run_case "compatible-versions form, top-level pod" \
  1 \
  '[!] CocoaPods could not find compatible versions for pod "flutter_local_notifications":' \
  'flutter_local_notifications'

run_case "compatible-versions form, subspec reduces to root pod" \
  1 \
  '[!] CocoaPods could not find compatible versions for pod "Sentry/HybridSDK":' \
  'Sentry'

run_case "missing-specification form" \
  1 \
  '[!] Unable to find a specification for `flutter_secure_storage`' \
  'flutter_secure_storage'

run_case "none-of-your-sources form, subspec reduces to root pod" \
  1 \
  'None of your spec sources contain a spec satisfying the dependency: `Sentry/HybridSDK (= 8.58.0)`.' \
  'Sentry'

run_case "multiple failures with duplicate subspec roots dedup" \
  1 \
  '[!] CocoaPods could not find compatible versions for pod "FooLib":
[!] CocoaPods could not find compatible versions for pod "BarLib/SubA":
[!] CocoaPods could not find compatible versions for pod "BarLib/SubB":' \
  'FooLib BarLib'

run_case "unparseable failure falls back to full pod update" \
  1 \
  '[!] some unfamiliar error shape from a future CocoaPods version' \
  '<full>'

run_case "compatible-versions and none-of-your-sources together still dedup" \
  1 \
  '[!] CocoaPods could not find compatible versions for pod "Sentry/HybridSDK":
None of your spec sources contain a spec satisfying the dependency: `Sentry/HybridSDK (= 8.58.0)`.' \
  'Sentry'

# The script under test runs *only* on the macOS runners, whose /bin/bash
# is 3.2, while these tests run on linux-checks under bash 5. That gap let
# a `declare -A` sit in the fallback path unnoticed until a CocoaPods CDN
# outage took that path for the first time and the script died with
# "declare: -A: invalid option".
#
# There is no bash 3.2 on the Linux runner to execute against, so this
# greps for the bash-4-only constructs instead. It is a lint, not an
# execution test, but it closes the gap that mattered: the parser tests
# above can never fail for a reason the target platform would.
tests_run=$((tests_run + 1))
# Comment lines are dropped, so the note explaining this rule does not
# trip it.
bash4_only=$(grep -nE \
  '(declare|local|typeset)[[:space:]]+-[A-Za-z]*A|mapfile|readarray|\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?(,,|\^\^)' \
  "$script_dir/pod_install_with_targeted_fallback.sh" \
  | grep -vE '^[0-9]+:[[:space:]]*#' || true)

if [ -n "$bash4_only" ]; then
  tests_failed=$((tests_failed + 1))
  echo "FAIL: bash 4+ construct in a script that runs on macOS bash 3.2:"
  echo "$bash4_only"
else
  echo "ok: no bash 4+ constructs in pod_install_with_targeted_fallback.sh"
fi

echo
echo "Tests run: $tests_run, failures: $tests_failed"
exit "$tests_failed"
