#!/usr/bin/env bash
# Run `pod install --repo-update`. If it fails because Podfile.lock has
# stale constraints, fall back to `pod update` — but limit the update to
# the failing pod(s) when we can identify them from CocoaPods' output,
# rather than re-resolving every pod.
#
# The previous shape ran a blanket `pod update` on any failure, which
# meant a single drifting dependency could quietly bump twelve other
# pods up to new minor versions and ride those into the next release
# without anyone having intentionally changed them. Tracked in #369.
#
# The script self-locates so it works no matter where it's invoked
# from: `cd "$(dirname "$0")/../../ios"` puts us in the iOS project
# directory before anything else runs.
#
# Adding a new error pattern: extend the `extract_pods` function below
# and add a matching test case to test_pod_install_with_targeted_fallback.sh.
# The test script runs in CI on linux-checks so a regression in the
# parser surfaces on the next PR rather than the next constraint drift.

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ios_dir="$(cd "$script_dir/../../ios" && pwd)"
cd "$ios_dir"

log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT

# `set +e` around the install so we can branch on the exit status rather
# than letting `set -e` short-circuit us before we get to parse the log.
set +e
pod install --repo-update 2>&1 | tee "$log_file"
install_status=${PIPESTATUS[0]}
set -e

if [ "$install_status" -eq 0 ]; then
  exit 0
fi

# CocoaPods has a few different error shapes when constraints drift.
# These three cover the cases this project has actually hit:
#
#   [!] CocoaPods could not find compatible versions for pod "FooName":
#   [!] Unable to find a specification for `FooName`
#   None of your spec sources contain a spec satisfying the dependency: `FooName (= 1.2.3)`.
#
# Either form may name a subspec like `Sentry/HybridSDK`; `pod update`
# operates on root pods, so we strip the subspec suffix below.
extract_pods() {
  {
    grep -oE 'compatible versions for pod "[^"]+"' "$log_file" \
      | sed -E 's/.*"([^"]+)".*/\1/'
    grep -oE "Unable to find a specification for [\`'][^\`']+" "$log_file" \
      | sed -E "s/.*specification for [\`']//"
    grep -oE "satisfying the dependency: \`[^[:space:]\`]+" "$log_file" \
      | sed -E "s/^satisfying the dependency: \`//"
  } || true
}

parsed_pods=()
while IFS= read -r line; do
  [ -n "$line" ] && parsed_pods+=("$line")
done < <(extract_pods)

declare -A seen=()
root_pods=()
for pod in "${parsed_pods[@]:-}"; do
  root="${pod%%/*}"
  [ -z "$root" ] && continue
  if [ -z "${seen[$root]:-}" ]; then
    seen[$root]=1
    root_pods+=("$root")
  fi
done

if [ "${#root_pods[@]}" -gt 0 ]; then
  echo "::warning::Podfile.lock has stale constraints on: ${root_pods[*]} — regenerating those pods only"
  pod update "${root_pods[@]}"
else
  echo "::warning::Podfile.lock has stale constraints (couldn't identify which pod from CocoaPods output) — falling back to a full pod update"
  pod update
fi
