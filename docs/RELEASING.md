# Releasing

A release is **a merge of `develop` into `main`**. There is no release script and no tag to push
by hand: pushing to `main` starts the pipeline, and the pipeline does the packaging, the store
uploads and the GitHub release itself.

That is worth stating first because most of this page is about the parts the pipeline *cannot* do —
the ones that are otherwise remembered, or not.

## What happens on its own

Everything below fires from `push` on `main`, so it needs no action beyond the merge.

| Job | What it does |
|---|---|
| `linux-checks`, `*-build`, `*-integration-tests` | the same gates every PR runs |
| `ios-package` / `android-package` | build the IPA, AAB and APK |
| `ios-deploy` / `android-deploy` | upload to **TestFlight** and the Play **`internal`** track |
| `github-release` | tag, attach the IPA/AAB/APK, and generate release notes from merged PRs |

Two properties are deliberate and worth knowing:

- **Both deploys wait for both packages.** `android-deploy` needs `ios-package` and vice versa, so
  a one-sided failure never publishes half a release or burns a Play `versionCode`.
- **Store metadata is not uploaded.** `skip_upload_metadata: true` on the Play lane, and the
  TestFlight `changelog` is commented out. Listing text and "what's new" are edited in the
  consoles, by a person.

After the GitHub release is *published*, `update-release-fingerprint.yml` extracts the signing
certificate's SHA-256 from the released APK and opens a **pull request into `develop`** updating
`docs/site/release-info.json`. It is a PR, not a push — it waits for someone to merge it.

And `deploy-site.yml` publishes GitHub Pages on any push to `main` touching `docs/site/**`, which
is how that merged fingerprint eventually reaches the site — on the *next* release, since the PR
lands on `develop`.

## Before opening the release PR

- [ ] **Bump `version:` in `pubspec.yaml`.** Both halves: the name (`2.0.2`) and the build number
      (`+61`). The build number must increase or Play rejects the upload. Nothing bumps it for you.
- [ ] **Decide the store "what's new" text.** It is not in this repo — `fastlane/metadata/android`
      carries a single stale `changelogs/12.txt` against a build number now far past it, so treat
      that directory as unused rather than as the source.
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

## After the pipeline finishes

- [ ] **Watch the run to a terminal state.** A run can fail *before creating any job* — GitHub
      reports `startup_failure`, and the check-runs read `cancelled` for jobs that never existed.
      Re-running is the fix; it is not a fault in the branch.
- [ ] **Promote the Android build.** The only Play lane is `internal`. Production promotion is
      manual in the Play Console.
- [ ] **Submit the iOS build.** The lane uploads to TestFlight; App Store submission is not
      automated.
- [ ] **Update the store listings** with the "what's new" text, since the pipeline uploads none.
- [ ] **Merge the release-fingerprint PR** into `develop`.

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

`main` and `develop` carry different workflow sets: `deploy-site.yml` and
`update-release-fingerprint.yml` exist **only on `main`**. That is why neither runs from a
`feature/**` branch, and why editing them requires a PR that reaches `main`.
