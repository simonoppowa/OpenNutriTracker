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

Everything below fires from `push` on `main`, so it needs no action beyond the merge.

| Job | What it does |
|---|---|
| `linux-checks`, `*-build`, `*-integration-tests` | the same gates every PR runs |
| `ios-package` / `android-package` | build the IPA, AAB and APK |
| `ios-deploy` / `android-deploy` | upload to **TestFlight**, and *attempt* the Play **`internal`** track — see [the Android upload](#the-android-upload-usually-needs-a-hand) |
| `github-release` | tag, attach the IPA/AAB/APK, and generate release notes from merged PRs |

Two properties are deliberate and worth knowing:

- **Both deploys wait for both packages.** `android-deploy` needs `ios-package` and vice versa, so
  a one-sided failure never publishes half a release or burns a Play `versionCode`.
- **Store metadata is not uploaded.** `skip_upload_metadata: true` on the Play lane, and the
  TestFlight `changelog` is commented out. Listing text and "what's new" are edited in the
  consoles, by a person.

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
summary. When it says the upload needs doing by hand:

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
