# Releasing

A release is **a merge of `develop` into `main`**. There is no release script, and no tag to push
by hand: pushing to `main` starts the pipeline, and the pipeline does the packaging, the store
uploads and the GitHub release itself.

A **hotfix merged straight to `main`** starts the same pipeline, which is why it is a legitimate
thing to do — and why it needs [its own step afterwards](#hotfixes-and-the-way-back-to-develop),
because nothing carries it back.

That is worth stating first because most of this page is about the parts the pipeline *cannot* do —
the ones that are otherwise remembered, or not.

## What happens on its own

Everything below fires from `push` on `main`. **It does not run to completion unattended** — the
jobs holding store credentials pause for an approval, see [Environments](#environments-and-the-approval-pause).

| Job | What it does |
|---|---|
| `linux-checks`, `*-build`, `*-integration-tests` | the same gates every PR runs |
| `ios-package` / `android-package` | build the IPA, AAB and APK |
| `ios-deploy` / `android-deploy` | upload to **TestFlight**, and *attempt* the Play **`internal`** track — see [the Android upload](#the-android-upload-usually-needs-a-hand) |
| `github-release` | tag, attach the IPA/AAB/APK, and generate release notes from merged PRs |
| `release-summary` | last job; asserts the run produced what `release-gate` promised, and says so on the run page |

Two properties are deliberate and worth knowing:

- **Both deploys wait for both packages.** `android-deploy` needs `ios-package` and vice versa, so
  a one-sided failure never publishes half a release or burns a Play `versionCode`.
- **Store metadata is not uploaded.** `skip_upload_metadata: true` on the Play lane, and the
  TestFlight `changelog` is commented out. Listing text and "what's new" are edited in the
  consoles, by a person.

### Environments and the approval pause

Three deployment environments, split by which **credentials** a job holds rather than by what it
is called. All three are pinned to `main` by a deployment branch policy, which is a guard
independent of the `if:` expressions — the expression is the mechanism that has already failed
here once, when a `workflow_dispatch` from a topic branch cut a real tag.

| Environment | Jobs | Protection |
| :-- | :-- | :-- |
| `release-build` | `android-package` | branch policy |
| `release-ship` | `ios-package`, `ios-deploy`, `android-deploy` | branch policy **and an approval** |
| `release-publish` | `github-release` | branch policy |

**A release stops and waits for you.** The `release-ship` jobs sit in *Review pending deployments*
until approved, so a merge to `main` does not finish on its own. Approving is the decision point:
those jobs can consume a Play `versionCode` and a TestFlight build number, and neither is
refundable.

Declining is a real option and behaves sanely — a rejected job reports `failure`, so
`github-release` (which needs both deploys green) never runs, and no build number is spent.
`release-summary` will fail the run and say the build can be retried as it stands, which it can.

`ios-package` is on `release-ship` and `android-package` is not, though both only package:
`fastlane ios build` runs `match`, which authenticates to App Store Connect, so iOS packaging
holds store credentials where Android packaging holds only a local keystore.

### The Android upload usually needs a hand

`android-deploy` **attempts** the Play upload and, for now, is expected to fail on one specific
error. Since 2.1.0 the bundle declares `android.permission.health.*`, and the Play Publishing API
rejects health-permission bundles with *"You must let us know whether your app includes any health
features"* regardless of the declaration — a known upstream defect
([#942](https://github.com/simonoppowa/OpenNutriTracker/issues/942),
[fastlane#22204](https://github.com/fastlane/fastlane/issues/22204) closed unfixed,
[fastlane#27960](https://github.com/fastlane/fastlane/issues/27960) reopened, and reproduced from a
different toolchain in [expo/eas-cli#3275](https://github.com/expo/eas-cli/issues/3275)). The same
bundle uploaded by hand through the console is asked no health question and goes through.

The step tolerates that one error and nothing else: it emits a `::warning::` and writes the
recovery steps into the run's **step summary**. So the job going green is not the signal — read the
summary. `release-summary` repeats it at the end of the run in its own words, and does so whatever
colour `android-deploy` ended up, because the ledger step after the upload can fail on its own.
When either says the upload needs doing by hand:

1. Download the `android-aab` artifact from the run. (A full release also attaches the AAB to the
   GitHub release; a build-only bump creates no release, so the run artifact is the only copy —
   and it expires after 90 days.)
2. Play Console → Internal testing → **Create new release**, and drop the AAB in.
3. **Read the warnings on the review step before publishing.** That is the only place Play reports
   them, and a failing API upload never gets far enough to return them — which is how the minSdk
   regression in [#959](https://github.com/simonoppowa/OpenNutriTracker/issues/959) went unnoticed
   for eight days.

This step starts passing on its own once Google fixes the API; nothing here needs changing then.

## Before opening the release PR

- [ ] **Bump `version:` in `pubspec.yaml`.** The build number (`+63`) must increase or the
      pipeline refuses to deploy — `release-gate` reads it and Play rejects a reused versionCode.
      Nothing bumps it for you.

      **Bumping the build number alone is a supported release.** `2.2.0+63` → `2.2.0+64` ships to
      TestFlight and Play under the same version name. On that path `github-release` is **skipped
      on purpose**, because `v2.2.0` already exists and re-running it would delete the published
      release's assets and replace them with binaries from another commit. A skipped
      `github-release` there is expected, not the #1008 skip bug — the run is green and
      `release-gate`'s step summary says which of the two happened. The consequence: a build-only
      bump publishes no GitHub release, so its IPA and AAB exist only as run artifacts, for 90
      days. Bump the name as well when the build should have a durable public download.

      **Bumping the name without the build fails the gate**, by design: `2.3.0+63` is refused with
      an error naming both fixes. So does a build number that goes backwards — this repo's history
      contains `1.3.1+51` and `1.4.0+51`, the same versionCode twice.
- [ ] **Write the store "what's new" text** into
      `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt` — `63.txt` for build 63. The
      directory also holds a stale `12.txt` from the F-Droid era; ignore that one. The pipeline does
      **not** upload it (`skip_upload_metadata: true`), so this file is the record, and the text
      still has to be pasted into the consoles by hand.
- [ ] **Check the Play data-safety declaration still matches what the app does.** Any release that
      adds or changes a network destination changes this answer. It is the one item here whose
      failure mode is the app being pulled rather than a bad release.
- [ ] **Confirm no unreleased-feature documentation is public** — see the doc steps below.

## The release PR

- [ ] Open **one** batched `develop → main` PR. `main` takes release merges only
      ([CONTRIBUTING.md](../CONTRIBUTING.md)).
- [ ] Confirm the checks are **registered**, not just absent. A PR that gets no checks still reports
      mergeable, and silence looks exactly like success.
- [ ] Merge. From here the pipeline runs; do not tag by hand.
- [ ] Confirm `develop` is not missing anything `main` already has — see
      [Hotfixes](#hotfixes-and-the-way-back-to-develop). A hotfix that never came back is invisible
      at this point, and shipping without it is the whole cost.

## After the pipeline finishes

- [ ] **Watch the run to a terminal state.** A run can fail *before creating any job* — GitHub
      reports `startup_failure`, and the check-runs read `cancelled` for jobs that never existed.
      Re-running is the fix; it is not a fault in the branch.
- [ ] **If you have to re-run after a deploy job failed, use "Re-run failed jobs" — never "Re-run
      all jobs".** The former reuses `release-gate`'s cached answer. The latter recomputes it, and
      by then the deploy jobs have recorded the build as spent, so the gate correctly answers "do
      not deploy" and the release is stranded mid-flight with no way forward but a build bump.
- [ ] **Know what the pipeline records.** Each deploy job pushes a `deployed/<build-number>` tag on
      success — that is the ledger `release-gate` reads, and the one thing this workflow pushes
      besides a release tag. It records what a store **consumed**, not what it **published**: with
      the #942 tolerance `android-deploy` exits 0 on a rejected upload and still marks the build
      spent. So a build you never hand-uploaded still needs a bump before you can retry it.
- [ ] **Get the Android build onto `internal`.** Check the run's step summary first: if the API
      upload hit [#942](https://github.com/simonoppowa/OpenNutriTracker/issues/942), the track is
      still empty and the AAB needs uploading by hand. Production promotion is manual either way.
- [ ] **Submit the iOS build.** The lane uploads to TestFlight; App Store submission is not
      automated.
- [ ] **Update the store listings** with the "what's new" text, since the pipeline uploads none.
- [ ] **Read `release-summary`.** It is the last job, it runs whatever happened upstream, and it
      asserts the artifact rather than the colour: that every deploy job the gate promised actually
      succeeded, and that the tag the gate promised is on the remote. A run where it is green and
      says *"Nothing was due to ship from this push"* shipped nothing **on purpose**; a run where it
      is red shipped less than it promised, whatever the jobs above it say. It exists because two
      consecutive releases were lost behind a green run
      ([#1012](https://github.com/simonoppowa/OpenNutriTracker/issues/1012)).

## Store declarations

These declarations sit in three different places, which is the whole reason they drift apart:

- **In the app bundle.** The iOS purpose strings in `Info.plist`, and the privacy manifest. They
  ship with a build and are entered nowhere — they are right when the code is right, and App
  Review reads them straight out of the bundle.
- **Repo text that a human copies into a console.** The Play listing, and only that.
- **Console only, with no repo copy at all.** Play's Health apps declaration, and the App Store
  Connect App Privacy record — which has to agree with the privacy manifest, with nothing
  anywhere checking that it does.

All of them were corrected for 2.2.0 in
[#990](https://github.com/simonoppowa/OpenNutriTracker/issues/990).
[`test/unit_test/store_declarations_test.dart`](../test/unit_test/store_declarations_test.dart)
pins the repo half so a later edit cannot quietly undo one; the console half is the checklist
below, and nothing but this page will remind you.

- [ ] **Paste `fastlane/metadata/android/en-US/full_description.txt` into the Play listing.**
      `upload_to_play_store` runs with `skip_upload_metadata: true`, so the pipeline never touches
      the listing and the file and the live description agree only if someone copies it across.
      The file is held under Play's 4000-character cap by a test; the Console gives no warning
      until it refuses the text.
- [ ] **Keep the "not a medical device" sentence in the listing.** Google's
      [Health Content and Services](https://support.google.com/googleplay/android-developer/answer/12261419)
      policy requires that exact wording *in the app description* for a health-and-fitness app that
      is not a declared medical device, plus a reminder to consult a healthcare professional. Both
      are the last line of `full_description.txt`.
- [ ] **Answer Play's Health apps declaration.** Required for all developers under the same policy,
      with nutrition tracking as a declarable feature.
- [ ] **Make the App Store Connect App Privacy record agree with
      [`ios/Runner/PrivacyInfo.xcprivacy`](../ios/Runner/PrivacyInfo.xcprivacy).** They are two
      separate artifacts with no link between them, so they agree only by hand — and Apple
      validates the manifest on the way in: *"App Store Connect rejects app submissions that
      include invalid privacy manifest files."* What the manifest declares today, and what the
      questionnaire therefore has to say:

      | Data type | Linked to user | Tracking | Purpose |
      | :-- | :-- | :-- | :-- |
      | Photos or Videos | No | No | App Functionality |
      | Other User Content | No | No | App Functionality |
      | Crash Data, Performance Data, Other Diagnostic Data | No | No | App Functionality |

      The first two exist only because of AI meal assistance. Food search terms, HealthKit
      workouts and locally-attached meal photos are deliberately absent; the manifest says why,
      beside each one.

The table is what the AI path made necessary, not a statement that the record is complete. Three
things behind it are open rather than answered, and none blocks a release:
[#816](https://github.com/simonoppowa/OpenNutriTracker/issues/816) on whether a server the user
runs counts as collection for Play's Data safety form; the Apple twin of it noted in the privacy
manifest; and [#938](https://github.com/simonoppowa/OpenNutriTracker/issues/938) on the coarse
location the Supabase gateway derives from the caller's IP, whose research concludes both stores
want it declared and which no manifest entry covers yet. That research sits on the unmerged
`research/store-declarations` branch; `docs/ai-legal-constraints.md` carries the rest.

## Hotfixes, and the way back to `develop`

A fix urgent enough to skip the batch can go straight to `main`. Nothing brings it back down, so
the next release — cut from `develop` — quietly ships without it.

This has already happened once. [#879](https://github.com/simonoppowa/OpenNutriTracker/pull/879)
landed on `main` and left `develop` without the setting that keeps the application log, food search
terms included, out of Sentry breadcrumbs; it was backported in
[#893](https://github.com/simonoppowa/OpenNutriTracker/pull/893) only because someone went looking.
The failure mode is silence: no check fails, and the fix simply is not there.

- [ ] **After merging anything directly to `main`, open a backport PR into `develop`** in the same
      sitting. It is not done until that PR is merged too.

**Cherry-pick the commits. Do not merge `main` into `develop`.** With a squash-merge flow the two
branches share only an old merge base — the previous release — and `main` carries each release as a
single squashed commit of everything `develop` had at the time. A merge weighs that against
`develop`'s individual commits plus everything added since, which conflicts across the whole
release and can revert newer work where git cannot tell the two apart. `git cherry-pick -x <sha>`
keeps authorship and records where it came from.

```bash
git log --oneline origin/develop..origin/main    # what main has that develop does not
```

**Most of what that command prints is expected and must not be backported.** Release commits are
absent from `develop` *by construction* under squash merging, so they accumulate there forever.
Before backporting anything, check whether its content is already present — a file that exists on
both branches, or a paragraph already corrected — rather than trusting the commit list. Only two of
the four entries it printed in August 2026 were real gaps.

## Documentation

The step this page exists for. These have no automation at all, and nothing fails if they are
skipped — which is exactly why they get skipped.

- [ ] **Publish [`docs/ai-architecture.md`](ai-architecture.md) to the wiki**, if this is the first
      release shipping AI meal assistance. It was written as a wiki page and staged in the repo
      deliberately: until a build ships the feature, a public page describing the app sending food
      photos to a model reads as an undeclared transfer rather than as documentation that ran ahead.

      The conversion is a copy and one `sed`:

      ```bash
      sed -E 's#\]\(\.\./#](https://github.com/simonoppowa/OpenNutriTracker/blob/main/#g' docs/ai-architecture.md > /path/to/wiki/AI-Meal-Assistance.md
      ```

      Then add its row to the wiki's `Home.md` page table, and check the Mermaid blocks render —
      they are certain in repo Markdown and unverified on this wiki.

- [ ] **Reduce the repo copy to a pointer** once the page is live, so there is one authoritative
      copy rather than two that agree today.
- [ ] **Check the README's privacy section still describes the shipped build.** It holds the
      falsifiable claims — destinations, retention, the Experimental exit criteria — and it is the
      first thing an auditor reads.

## Notes

Store credentials, signing keys and the Play service account live in repository secrets and are
consumed by the workflow; none of them need touching for an ordinary release.

`main` and `develop` carry slightly different workflow sets, and the difference runs the other way
than you might expect: `develop` has `ios-integration-attempt.yml`, which `main` does not. Both
carry `default_workflow.yml`, `add-issues-to-projects.yml` and `policy-snapshot.yml`.

There is no site-publishing or signing-fingerprint workflow any more. `deploy-site.yml`,
`update-release-fingerprint.yml` and the whole `docs/site/` tree were removed with the project
website in [#786](https://github.com/simonoppowa/OpenNutriTracker/pull/786); nothing extracts a
signing fingerprint and nothing opens a PR after a release.
