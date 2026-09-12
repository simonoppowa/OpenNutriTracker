# Weblate: what merges upstream into the working copy, and what "Repository outdated" means

Researched 2026-09-12 for the Hosted Weblate component `opennutritracker/app`
(component id 52968, vcs=git, branch=main, merge_style=rebase, push="").

Sources and pins used throughout:

- Docs: `https://docs.weblate.org/en/latest/...` — the page header reads "Weblate 2026.10 documentation" on 2026-09-12.
- Hosted Weblate version: `https://hosted.weblate.org/about/` shows `weblate-2026.9.1-81-g5f28605969`.
- Source: `github.com/WeblateOrg/weblate` branch `main` at commit `0195e965e6fc286098476a0d60faa8abe880ce38` (2026-09-12). Permalinks below use that SHA. Hosted runs 81 commits past 2026.9.1, so line numbers may differ slightly there; the code paths cited are long-standing.
- Local git evidence: Weblate's public export `https://hosted.weblate.org/git/opennutritracker/app/` fetched into the local clone (FETCH_HEAD only, no refs added).

## TL;DR

1. Weblate separates **fetch** (`git fetch origin +refs/heads/main:refs/remotes/origin/main`, updates only `origin/main`) from **update** (`do_update`: fetch, then commit pending changes if needed, then merge/rebase the working branch per Merge style, then re-parse files, then push if configured).
2. `AUTO_UPDATE` defaults to `"remote"` (= `False`): nightly **fetch only**, no merge. Only `"full"` (= `True`) merges nightly. Hosted Weblate's value is not published; its observed behaviour (nightly "Remote repository updated", working copy frozen at July 24, `origin/main` in the export current as of 2026-09-11) matches `"remote"`. Hosted Weblate is therefore not going to merge upstream on its own.
3. The only automatic path that runs a **full update** is a webhook: `POST https://hosted.weblate.org/hooks/github/`. It accepts JSON or form content type, uses only the `push` event, and only updates components whose `branch` equals the pushed branch (so pushes to `develop` never update the `main` component). **The GitHub repo currently has no webhook pointing at hosted.weblate.org** (only Codemagic and Crowdin hooks exist). A GitHub App is not needed for a `vcs=git` component; in fact App deliveries only match `github-app` components.
4. "Repository outdated" = `count_missing() > REPOSITORY_ALERT_THRESHOLD` (default 25), evaluated by a daily task; it is a plain `BaseAlert` (not an error). "Could not merge the repository" (`MergeFailure`) and "Could not push the repository" (`PushFailure`) are `ErrorAlert`s raised when a merge/rebase or push command fails; both are in `LOCKING_ALERTS`, and this component has `auto_lock_error=True`. Today the export is 283 commits behind and 23 ahead; the 23 local commits rebase cleanly onto current `origin/main` in a local dry run.
5. Merge style "Rebase" runs `git rebase [--gpg-sign=KEY] origin/main` on Weblate's local branch: the 23 Weblate commits are re-created on top of upstream (new SHAs) and re-signed with Hosted Weblate's GPG key `3C267921FD52C9FEE1F07A0AA3FAAA06E6569B4C`; authors are preserved. On failure Weblate runs `rebase --abort` (+ `reset --hard`), raises `MergeFailure`, and locks the component.
6. Pending (uncommitted) translations are database rows (`PendingUnitChange`), not dirty files. `do_update` holds the repository lock and commits them *before* the rebase when upstream touched translation files; Lazy commits docs list "A merge from upstream occurs" as a commit trigger. Pending work survives an update; the separate "Reset and reapply" action also keeps pending translations.

---

## 1. Fetching the remote vs updating the working branch

### Docs

- Repository maintenance table, "Update" row: "Fetches upstream changes, integrates them using the component's configured Merge style, and reconciles translation files."
  Source: https://docs.weblate.org/en/latest/admin/continuous.html#repository-maintenance
- Same table, "Update with rebase": "Fetches upstream changes and rebases local Weblate commits on top of upstream."
- Same table, "Update with merge": "Fetches upstream changes and integrates them with an explicit merge."
- "Repository actions started from this view are queued for background processing."
- "Operations that read repository content, such as updating, resetting, or rescanning, also reconcile translation files in Weblate."
- Ways to update (Updating repositories section): "Use Notification hooks ...", "Manually trigger update either in the repository management or using Weblate's REST API or Weblate Client", "Enable AUTO_UPDATE to automatically update all components on your Weblate instance", "Execute updategit".
  Source: https://docs.weblate.org/en/latest/admin/continuous.html#updating-repositories
- REST API: `POST /api/components/(project)/(component)/repository/` with "operation (string) – Operation to perform: one of push, pull, commit, reset, cleanup".
  Source: https://docs.weblate.org/en/latest/api.html#post--api-components-(string-project)-(string-component)-repository-

### Source

- Fetch only — `GitRepository.update_remote()`:
  `refspec = f"+refs/heads/{branch}:refs/remotes/origin/{branch}"` then `["fetch", "--no-tags", "origin", refspec]`, with the comment "# Update existing branch only, not changing depth".
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/vcs/git.py#L1637-L1647
- `Component.update_remote_branch()` ("""Pull from remote repository.""") wraps that fetch, records `ActionEvents.REMOTE_UPDATE` ("Remote repository updated" in the change log) when `origin/<branch>` moved, adds `UpdateFailure` on error, and deletes it on success. It never touches the working branch.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/models/component.py#L2774-L2860
- Full update — `Component.do_update()`:
  "# Hold lock all time here to avoid somebody writing between commit and merge/rebase." → `update_remote_branch()` → `repo_needs_merge()` → `if self.needs_commit_upstream(): self.commit_pending("update", user, skip_push=True)` → `update_branch(method=...)` → `finish_update()` (create_translations + `push_if_needed`).
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/models/component.py#L2938-L3004
- `repo_needs_merge()` = `count_repo_missing > 0`; `count_missing()` = `len(log_revisions("..origin/<branch>"))`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/models/component.py#L6207-L6209
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/vcs/base.py#L1324-L1328

### Evidence in the public export (fetched 2026-09-12)

`git ls-remote https://hosted.weblate.org/git/opennutritracker/app/`:

```
afbad294feb6a6882fb04f863da545758a108cca  refs/heads/main            <- Weblate's working branch
012223c434c31eecdf07114720336b730662f55e  refs/remotes/origin/main   <- Weblate's fetched upstream ref
```

`012223c4` is the current tip of `simonoppowa/OpenNutriTracker` `main` (2026-09-11, "chore(store): bring the store assets ... (#1147)"). So the nightly fetch works; the working branch simply is never merged/rebased. `git merge-base` of the two is `294debe6` (2026-07-23). `git rev-list --count afbad294..origin/main` = **283** (count_missing); `origin/main..afbad294` = **23** (count_outgoing, all `chore(l10n): ...` commits, 2026-08-03 to 2026-09-08).

## 2. AUTO_UPDATE and Hosted Weblate

### Docs (https://docs.weblate.org/en/latest/admin/config.html#auto-update)

- "Updates all repositories on a daily basis."
- "Every hour, Weblate queues updates for repositories whose component ID modulo 24 matches the current UTC hour."
- `"none"`: "No daily updates."
- `"remote"` also `False`: "Fetch remote changes without merging them into the working copy. This is the default; False does not disable daily updates."
- `"full"` also `True`: "Fetch remote changes and merge them into the working copy."
- Hint: "Useful if you are not using Notification hooks to update Weblate repositories automatically."
- Continuous localization page: "By default, Weblate automatically fetches remote repositories daily to improve performance when merging changes later. Updates are distributed throughout the day. Set AUTO_UPDATE to "full" to also merge remote changes into the working copy."
  https://docs.weblate.org/en/latest/admin/continuous.html#automatically-updating-repositories-daily

### Source

- `settings_example.py`: `AUTO_UPDATE = False` (i.e. remote-only).
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/settings_example.py#L998
- Periodic task: `sender.add_periodic_task(3600, update_remotes.s(), name="update-remotes")`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/tasks.py#L1896
- `update_remotes()` docstring: """Queue updates of all remote branches (without attempt to merge).""" — selects `hourmod = id % 24 == now.hour` and calls `perform_update.delay("Component", component_id, auto=True)`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/tasks.py#L902-L916
- `execute_legacy_update()`: full `do_update` only when `isinstance(obj, Project) or settings.AUTO_UPDATE in {"full", True} or not auto`; otherwise `obj.update_remote_branch(user=...)` (fetch only).
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/tasks.py#L145-L170

### Hosted Weblate specifically

- Hosted's `AUTO_UPDATE` value is **not published**. `github.com/WeblateOrg/hosted` ("Hosted Weblate customizations") contains no settings module with `AUTO_UPDATE` (checked the tree at `main` on 2026-09-12).
- Circumstantial evidence that Hosted runs the default `"remote"`:
  - Component id 52968; `52968 % 24 == 0`, so the daily fetch is queued during 00:00–00:59 UTC. The nightly "Remote repository updated" at 02:51 (local CEST = 00:51 UTC) fits that hour exactly.
  - The export's `refs/remotes/origin/main` is current (2026-09-11) while `refs/heads/main` is a July-24 snapshot plus Weblate's own commits. That is precisely what `"remote"` produces and what `"full"` could not.
- Conclusion: **Hosted Weblate only fetches on a schedule. It merges/rebases the working copy only when (a) a webhook arrives, (b) someone triggers Update in Repository maintenance / REST API / wlc, or (c) a push-related code path calls `do_update`/`update_branch` (e.g. `do_push` when the repo needs merge and pushes to the same location).**

## 3. The GitHub webhook

### Docs (https://docs.weblate.org/en/latest/admin/code-hosting.html#github-notifications)

- "The Payload URL consists of your Weblate URL appended by /hooks/github/, for example for the Hosted Weblate service, this is https://hosted.weblate.org/hooks/github/."
- "You can leave other values at default settings. Weblate can handle both content types and consumes just the push event."
- "If you are not using a GitHub App, add the Weblate webhook in the repository settings (Webhooks) to receive notifications on every push to a GitHub repository"
- On the App: "If you are using Hosted Weblate, use the Hosted Weblate app from Weblate's Connect GitHub account flow. It uses GitHub App webhooks, so you do not need to configure a separate Webhook in GitHub." — but: "Components using the GitHub (via Weblate GitHub app) VCS backend are matched only through this dedicated endpoint. All generic forge webhook endpoints exclude them from matching and response diagnostics, including /hooks/github/."
- "The Hosted Weblate legacy app is kept for existing webhook-only setups. Its deliveries use the generic GitHub webhook URL and are authenticated using a separate webhook secret configured by the Hosted Weblate operator."
- Matching: "Forge webhooks update components whose Source code repository exactly matches a repository URL from the payload (HTTPS or SSH as reported by the forge, plus common variants such as a trailing slash)." and "Changed in version 2026.9: Host and path suffix fallback matching was removed."
  https://docs.weblate.org/en/latest/admin/continuous.html#matching-webhook-targets
- API: "POST /hooks/github/ — Special hook for handling GitHub notifications and automatically updating matching components." Diagnostics: "branch_matches — Number of repository matches whose configured branch matches the payload."; "When an update event completes target matching but schedules no update, the response uses HTTP status code 202"; "Ping and ignored events return HTTP status code 201".
  https://docs.weblate.org/en/latest/api.html#notification-hooks
- `ENABLE_HOOKS`: "Whether to turn on anonymous remote hooks." https://docs.weblate.org/en/latest/admin/config.html#enable-hooks — and per project "Enable hooks" (API field `enable_hooks`); `https://hosted.weblate.org/api/projects/opennutritracker/` returns `"enable_hooks": true`.
- `GITHUB_LEGACY_APP_WEBHOOK_SECRET` (Added in 2026.8): "App webhook deliveries to the generic URL are rejected when this setting is empty or their X-Hub-Signature-256 does not match. Ordinary repository webhooks are unaffected."
  https://docs.weblate.org/en/latest/admin/config.html#github-legacy-app-webhook-secret

### Source (weblate/trans/views/hooks.py)

- Content type: `extract_request_data()` uses the body as JSON when media type is `application/json`, otherwise reads the form field `payload` (GitHub's `application/x-www-form-urlencoded` mode).
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/views/hooks.py#L308-L317
- Event: `github_hook_helper` reads `x-github-event`; `if event != "push": return None` (→ 201 "Hook working"). Signature verification applies only when the payload contains `installation` (legacy App).
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/views/hooks.py#L857-L882
- Repo URL candidates come from the payload's `clone_url, git_url, ssh_url, svn_url, html_url, url` plus the `.git`-stripped variants — so `https://github.com/simonoppowa/OpenNutriTracker.git` matches.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/views/hooks.py#L806-L840
- Branch filter: `all_components = repo_components.filter(branch=branch)` where `branch = ref` without `refs/heads/`; then `enabled_components = all_components.filter(project__enable_hooks=True)`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/views/hooks.py#L1234-L1243
- What a hook does: `perform_update.delay("Component", obj.pk, user_id=user.id)` — `auto` defaults to False, so this is the **full** `do_update` (fetch + merge/rebase + parse + push_if_needed), not a fetch.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/views/hooks.py#L1265
- App deliveries: `github_integration_hook_helper` returns `component_vcs="github-app"` and `get_hook_components` filters `components.filter(vcs=component_vcs)`; the generic endpoint sets `exclude_component_vcs=["github-app"]`. A `vcs=git` component (ours) is only reachable through `/hooks/github/`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/views/hooks.py#L925-L965

### State of the upstream repository (checked with `gh api repos/simonoppowa/OpenNutriTracker/hooks`, 2026-09-12)

Two webhooks exist: `https://api.codemagic.io/hooks/...` (create, pull_request, push) and `https://crowdin.com/hooks/github` (pull_request, push). **There is no webhook to `hosted.weblate.org`.** Whether the Hosted Weblate GitHub App is installed on the account could not be listed with the current token (403 on `user/installations`), but it would not matter for this component (see above).

Practical answer: add a repository webhook with Payload URL `https://hosted.weblate.org/hooks/github/`, content type `application/json` (form also works), event `push` only, no secret needed (Weblate does not verify signatures for ordinary repository webhooks). Every push to `main` will then run a full update; pushes to `develop` are ignored by the `branch=main` component.

## 4. The alerts, precisely

Docs are vague: https://docs.weblate.org/en/latest/devel/alerts.html lists "Merge, update, or push failures in the repository" and "Repository containing too many outgoing or missing commits", and says "Problem alerts cannot be ignored, but will disappear once the underlying problem has been fixed." The threshold: "REPOSITORY_ALERT_THRESHOLD — Threshold for triggering an alert for outdated repositories, or ones that contain too many changes. Defaults to 25."
https://docs.weblate.org/en/latest/admin/config.html#repository-alert-threshold

Source definitions (weblate/trans/alerts/vcs.py, permalink base https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/alerts/vcs.py):

| Alert name | verbose text | base class | raised when | cleared when |
|---|---|---|---|---|
| `RepositoryOutdated` (L434-441) | "Repository outdated." | `RepositoryAlert(BaseAlert)` — informational, not an error, `doc_anchor="update-vcs"` | `repository_alerts` daily task: `if component.repository.count_missing() > threshold: component.add_alert("RepositoryOutdated")` (tasks.py L1033-1054, scheduled `crontab(hour=3, minute=45)` L1902) | same task when `count_missing() <= threshold`; `do_update` when nothing to merge (component.py L2970-2971); `update_branch` after a successful merge/rebase (L4299-4300); `do_push` after success (L3292-3293) |
| `RepositoryChanges` (L445-451) | "Repository has changes." | `RepositoryAlert`, `dismissible = True` | same task: `count_outgoing() > threshold` | `do_update`/`push_if_needed` when `not repo_needs_push()` |
| `MergeFailure` (L287-295) | "Could not merge the repository." | `RepositoryErrorAlert(ErrorAlert)`, `doc_page="faq"`, `doc_anchor="merge"` | `update_branch` when `repository.rebase()`/`merge()` raises `RepositoryError` (component.py L4275-4288: logs FAILED_REBASE/FAILED_MERGE, `add_alert("MergeFailure")` at L4283, then `method_func(abort=True)` at L4288); also when `count_missing()` itself errors (L6165-6171) or `repository_alerts` cannot check status (tasks.py L1038-1042) | `update_branch` success; `do_update` when nothing to merge; `do_push` success |
| `UpdateFailure` (L399-406) | "Could not update the repository." | `BaseGitFailure(RepositoryErrorAlert)` | `update_remote_branch` when the **fetch** fails (component.py L2819-2821) | next successful fetch (L2841) |
| `PushFailure` (L373-396) | "Could not push the repository." | `BaseGitFailure` | `push_if_needed` push error (L3161-3163); `repo_needs_push` / `count_outgoing` errors (L6211-6226) | successful push (L3165-3166); `update_branch` success when nothing to push |

Locking: `LOCKING_ALERTS = {"MergeFailure", "UpdateFailure", "PushFailure", "ParseError", "RepositoryOperationFailure"}` (component.py L225-231); `_add_alert` does `if created and self.effective_auto_lock_error and alert in LOCKING_ALERTS: self.do_lock(... lock=True, auto=True)`. The component API reports `"auto_lock_error": true`, so a failed rebase would lock translators out until the error clears (docs: "The component will be automatically unlocked once there are no repository errors left." https://docs.weblate.org/en/latest/admin/projects.html#component-lock-error). `RepositoryOutdated` is **not** a locking alert and not an error — it is purely "you are > 25 commits behind origin/<branch>".

Rebase-specific hint inside `BaseGitFailure.get_analysis`: when the diagnosis is `branch_behind`, Weblate suggests force push only if `vcs == "git" and merge_style == "rebase" and bool(push_branch) and not GitForcePush` (vcs.py L340-346) — irrelevant here because `push=""`.

For this component today: `count_missing = 283 > 25` → "Repository outdated" is expected and correct; `count_outgoing = 23 <= 25` → no "Repository has changes" alert (yet; two more Weblate commits would trigger it).

## 5. Merge style "rebase" with local commits

### Docs (https://docs.weblate.org/en/latest/admin/projects.html#component-merge-style)

- "Rebase — Rebases Weblate commits on top of upstream repository on update. This provides clean history without extra merge commits."
- "Rebasing can cause you trouble in case of complicated merges, so carefully consider whether or not you want to enable them."
- "You might need to turn on force pushing in Version control parameters, especially when pushing to a different branch."
- Conflict warning: "Weblate can have new local commits after you merge earlier Weblate commits upstream. ... Git is then sometimes no longer able to identify upstream changes as matching the Weblate ones and refuses to perform a rebase." and "Squash merging Weblate changes makes this harder to recover from."
  https://docs.weblate.org/en/latest/admin/continuous.html#avoiding-merge-conflicts-by-focusing-on-git-operations
- FAQ: "If you resolve the conflict in a pull request, merge it with a regular merge commit. Do not squash merge it."
  https://docs.weblate.org/en/latest/faq.html#how-to-fix-merge-conflicts-in-translations

### Source

- `GitRepository.rebase()`: `cmd = ["rebase"]; cmd.extend(self.get_gpg_sign_args()); cmd.append(self.get_remote_branch_name())` → literally `git rebase [--gpg-sign=<key>] origin/main`, run with env `WEBLATE_MERGE_SKIP=1`. Abort path: `rebase --abort` if `rebase-apply`/`rebase-merge` exists, then `reset --hard` if the tree is dirty.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/vcs/git.py#L1220-L1232
- `get_gpg_sign_args()`: `[f"--gpg-sign={sign_key}"]` when `WEBLATE_GPG_IDENTITY` yields a key, else `[]`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/vcs/git.py#L1322-L1326
- `update_branch()`: `if method == "rebase": method_func = self.repository.rebase; error_msg = gettext("Could not rebase local branch onto remote branch %s.")`; on success records `ActionEvents.REBASE` with `previous_head`/`new_head`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/models/component.py#L4220-L4320
- Note in `do_update`: `if not needs_merge and method != "rebase": ... return True` — an explicit "Update with rebase" always runs the rebase even when nothing is missing.

### Does Weblate sign/rewrite commits on rebase?

- Rewriting: yes by git semantics — rebase "Transplant[s] a series of commits onto a different starting point" producing `A'--B'--C'` (https://git-scm.com/docs/git-rebase, DESCRIPTION). Weblate's 23 local commits get new SHAs; author name/email/date are preserved by `git rebase`, the committer becomes Weblate's configured identity ("Hosted Weblate", as already seen on `afbad294`).
- Signing: Hosted Weblate signs everything. https://hosted.weblate.org/keys/ — "All commits made with Weblate are signed with the GPG key 3C267921FD52C9FEE1F07A0AA3FAAA06E6569B4C, for which the corresponding public key is found below." `git log --format=%GK afbad294` in the local fetch shows key id `A3FAAA06E6569B4C` (the long-id suffix of that key). Because `rebase` is invoked with `--gpg-sign=<key>` (git docs: "--gpg-sign[=<keyid>] GPG-sign commits."), the rebased commits are re-signed by the same key.
- Docs: "All commits can be signed by the GnuPG key of the Weblate instance. Turn on WEBLATE_GPG_IDENTITY." https://docs.weblate.org/en/latest/admin/optionals.html#signing-git-commits-with-gnupg

### Will the rebase succeed here?

Local dry run (detached worktree in the scratchpad, `git rebase origin/main` from `afbad294`): "Successfully rebased and updated detached HEAD." — 23/23 commits applied, no conflicts. Reason: the Weblate commits only add `lib/l10n/intl_{es,fr,hu,pt_BR,ru,sv}.arb`, and none of those paths exist on `origin/main` (which has cs, de, en, it, pl, sk, tr, uk, zh). After the rebase Weblate re-parses all files against the new `intl_en.arb` (1036 strings), so the six new ARBs will show many untranslated strings but no conflict.

Caveat on `push=""` + `push_on_commit=True`: docs say "To actually enable pushing Repository push URL has to be configured as well." (https://docs.weblate.org/en/latest/admin/projects.html#component-push-on-commit). Nothing is pushed; the 23 commits only exist in Weblate's export until someone pulls them from `https://hosted.weblate.org/git/opennutritracker/app/` or a push URL is set.

## 6. Pending (uncommitted) translations across an update; Lazy commits

### Docs (https://docs.weblate.org/en/latest/admin/continuous.html#lazy-commits)

- "The behaviour of Weblate is to group commits from the same author into one commit if possible."
- Commit triggers: "Somebody else changes an already changed string." / "A merge from upstream occurs." / "An explicit commit is requested." / "A file download is requested." / "Change is older than period defined as Age of changes to commit on Component configuration."
- Age of changes to commit: "Sets how old (in hours) changes have to be before they are committed by background task or the commit_pending management command. All changes in a component are committed once there is at least one change older than this period." (component has `commit_pending_age: 24`; `COMMIT_PENDING_HOURS` is the default: "Number of hours between committing pending changes by way of the background task.")
  https://docs.weblate.org/en/latest/admin/projects.html#component-commit-pending-age
- Reset and reapply: "The Reset and reapply operation keeps pending translations from Weblate while resetting the local repository state to match upstream." — "If neither of these conditions is met, Weblate keeps the pending changes in its database and reports a recovery error".
  https://docs.weblate.org/en/latest/admin/continuous.html#reset-and-reapply-recovery-behavior

### Source

- Pending changes are DB rows: `count_pending_units` uses `PendingUnitChange.objects.for_component(...)`; `commit_pending()` iterates `PendingUnitChange.objects.for_component(self, apply_filters=True, include_linked=True)` and writes them to files/commits under the repository lock.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/models/component.py#L3913-L3960
- `do_update` commits pending changes before merging only if upstream changed files that the component uses: `needs_commit_upstream()` — """Inspect changed files in the upstream repository to see if any of them would trigger parsing of translation files. In case there is none, the repository can be merged without committing pending changes."""
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/models/component.py#L2921-L2936
- The whole of `do_update` runs inside `with self.repository.lock:` ("Hold lock all time here to avoid somebody writing between commit and merge/rebase."), so a translator cannot slip a write in between the commit and the rebase.
- Background committer: `commit_pending` periodic task every 3600 s (`sender.add_periodic_task(3600, commit_pending.s(), name="commit-pending")`, tasks.py L1895) finds "committable components" by age and calls `component.queue_commit_pending("commit_pending")`.
  https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/tasks.py#L620-L637

Net effect for us: whatever translators have typed but Weblate has not yet committed is safe across an Update — it is either committed first (if upstream touched `lib/l10n/*.arb`, which it did) or stays in the database and is written on the next commit trigger. Nothing is lost by triggering Update, Update with rebase, or Reset and reapply; only "Reset and discard" throws pending work away ("Resets Weblate's local repository to upstream, discards pending Weblate changes").

## Open questions

1. Hosted Weblate's actual `AUTO_UPDATE` value is not documented anywhere public; "remote" is inferred from the default, the source, and the observed change log / export refs. A maintainer statement would settle it.
2. Why the alert is timestamped 2026-09-02: by commit date, `294debe6..origin/main` was already 181 commits on 2026-08-30 and 208 on 2026-09-01, far past the threshold of 25, so the Sep-2 timestamp is not "the day it crossed 25". `Alert.timestamp` is `auto_now_add`, so it reflects when the alert row was created; a prior row could have been deleted by an intermediate `do_update`/`update_branch` success path or the daily task, or the component/alerts could have been reset. Not determinable from public data.
3. Whether the Hosted Weblate GitHub App is installed on `simonoppowa` could not be checked (`gh api user/installations` needs an App-authorized token). Irrelevant for a `vcs=git` component, relevant only if the component is migrated to "GitHub (via Weblate GitHub app)".
4. Celery `crontab(hour=3, minute=45)` for `repository_alerts` — timezone (UTC vs instance TZ) was not verified; it only affects when the alert row is refreshed, not its meaning.
5. Hosted runs `2026.9.1-81-g5f28605969`, the source read is `main@0195e965`. No behavioural differences were spotted in the cited paths, but line numbers are for `main`.

## Verification

Fact-checked 2026-09-12 by re-fetching every cited source: docs pages pulled with curl and converted to text (header reads "Weblate 2026.10 documentation"), Weblate source downloaded from raw.githubusercontent.com at `0195e965e6fc286098476a0d60faa8abe880ce38`, Hosted Weblate pages/API via curl, GitHub hooks via `gh api`, and the git export cloned into the scratchpad (`verify/wl2`) with its `refs/remotes/origin/main` fetched so the counts run on the same object graph Weblate has.

### Verdicts

| # | Claim (short) | Verdict | Notes |
|---|---|---|---|
| 1 | "Update" row: fetch + integrate per Merge style + reconcile | supported | Exact text in the Repository maintenance table. |
| 2 | "Update with rebase" row | supported | Exact text. |
| 3 | `update_remote()` is a plain fetch into `refs/remotes/origin/<branch>` | supported | Code is at git.py L1644-1652 at this SHA (cited L1637-1647 is a few lines early); refspec and `fetch --no-tags origin` are there. |
| 4 | `do_update` lock → fetch → commit pending if upstream touched files → `update_branch` → `finish_update` | supported | L2938-3004; `finish_update` docstring "Parse and push a repository after a successful pull." |
| 5 | `AUTO_UPDATE` default `"remote"`/`False` fetch-only; `"full"`/`True` merges | supported | Exact text at config.html#auto-update. |
| 6 | Component id modulo 24 = UTC hour | supported | Exact text. |
| 7 | Default is daily fetch; `"full"` merges | supported | Exact text at continuous.html#automatically-updating-repositories-daily. |
| 8 | `update_remotes` docstring "(without attempt to merge)", `auto=True` | supported | tasks.py L902-916. |
| 9 | Full `do_update` only for Project / `AUTO_UPDATE in {"full", True}` / `not auto` | supported | The branch is in `execute_legacy_update` (L145-170), which `perform_update` (L194+) calls; `auto` defaults to `False`. |
| 10 | `settings_example.py` `AUTO_UPDATE = False` | supported | L998. |
| 11 | Hosted runs `weblate-2026.9.1-81-g5f28605969` | supported | Present on /about/. |
| 12 | Hosted `AUTO_UPDATE` unpublished; export `origin/main` current; matches `"remote"` | supported (inference) | `refs/remotes/origin/main = 012223c4` confirmed; GitHub code search for `AUTO_UPDATE` in WeblateOrg/hosted returns 0 hits; component changes API shows "Remote repository updated" at `02:51+02:00` (= 00:51 UTC, and `52968 % 24 == 0`) on 09-08, 09-11, 09-12 with no rebase/merge events. Still circumstantial. |
| 13 | Payload URL `https://hosted.weblate.org/hooks/github/` | supported | Exact text (it sits under the "App webhook URL" sub-heading of the GitHub notifications section). |
| 14 | Both content types; only push event | supported | Exact text. |
| 15 | JSON body used directly, else form field `payload` | supported | hooks.py L308-317. |
| 16 | Non-push events ignored; signature only when payload has `installation` | supported | hooks.py L857-882. |
| 17 | Filter `branch=branch` + `project__enable_hooks=True`; `perform_update.delay(...)` without `auto` | supported | hooks.py L1234-1265. |
| 18 | Exact URL match; suffix fallback removed in 2026.9 | supported | Exact "Changed in version 2026.9" note. |
| 19 | GitHub App not required; App-backend components matched only via dedicated endpoint | supported | Exact text; the page adds that *legacy* App deliveries to the generic endpoint "can match only components using a non-App VCS backend". |
| 20 | Component API fields (git, repo, push "", main, rebase, auto_lock_error true) | supported | All fields re-read from the API; project `enable_hooks: true` too. |
| 21 | No hosted.weblate.org webhook on the GitHub repo | supported | `gh api` lists only Codemagic (id 395497214) and Crowdin (id 539635059). Note the cited URL returns 401 unauthenticated; it needs a token. |
| 22 | `repository_alerts` sets/clears `RepositoryOutdated` on `count_missing() > threshold` | supported | tasks.py L1033-1054. |
| 23 | `REPOSITORY_ALERT_THRESHOLD` defaults to 25 | supported | Exact text. |
| 24 | `RepositoryOutdated` is an *informational* `RepositoryAlert` (not `ErrorAlert`) | **not supported** | Class hierarchy is right (`RepositoryAlert(BaseAlert)` vs `RepositoryErrorAlert(ErrorAlert)`), but `BaseAlert.severity = AlertSeverity.ERROR` (alerts/base.py L40) and `RepositoryOutdated` does not override it (only `GitHubAppMigration` sets `INFO`, vcs.py L84); it is also `dismissible = False`. The docs distinguish "Problem alerts" (cannot be ignored) from "Information and warning alerts" (dismissible) — this one is a problem alert. Corrected: `RepositoryOutdated` is a non-dismissible ERROR-severity `RepositoryAlert` without an error payload; `MergeFailure`/`PushFailure`/`UpdateFailure` are `ErrorAlert` subclasses that additionally carry the git error text and are in `LOCKING_ALERTS`. |
| 25 | `MergeFailure` raised in `update_branch`, then `method_func(abort=True)` | supported | component.py L4284 / L4288. |
| 26 | `UpdateFailure` on fetch failure; `PushFailure` on push / needs-push failure | supported | L2819-2821; L3161-3163; L6187; L6225. |
| 27 | `LOCKING_ALERTS` and auto-lock | supported | L225-231; `_add_alert` L4584 `if created and self.effective_auto_lock_error and alert in LOCKING_ALERTS: self.do_lock(...)`. |
| 28 | Lock on error docs | supported, wrong anchor | Text is exact; the anchor is `#component-auto-lock-error` (alias `#lock-on-error`), not `#component-lock-error`. |
| 29 | Export is 283 behind, 23 ahead, merge base 294debe6 (2026-07-23) | **not supported as stated** | 23 ahead and merge base `294debe6` (2026-07-23) confirmed. 283 is what a *full-history* clone gives (`git rev-list --count afbad294..origin/main` in the project repo). Weblate's repository is a shallow clone whose `.git/shallow` is exactly `294debe6` (the export serves it shallow; `VCS_CLONE_DEPTH` defaults to shallow), so `HEAD` has only 24 reachable commits. On that graph the very command `count_missing()` runs — `git log --format=format:%H ..origin/main --` — returns **1388**, because develop-lineage commits reachable from `origin/main` are not reachable from the truncated `HEAD`. Corrected: Weblate counts 1388 missing / 23 outgoing; either number is > 25, so "Repository outdated" fires and "Repository has changes" does not. This also invalidates the day-by-day "181 on 08-30 / 208 on 09-01" reasoning in open question 2. |
| 30 | Merge style Rebase docs incl. force push note | supported | Exact text. |
| 31 | `git rebase [--gpg-sign=<key>] origin/<branch>`; abort = `rebase --abort` + `reset --hard` | supported | git.py L1230-1242 at this SHA (cited L1220-1232 slightly early). |
| 32 | Hosted signs with `3C267921FD52C9FEE1F07A0AA3FAAA06E6569B4C` | supported | Exact text on /keys/. |
| 33 | git rebase transplants / creates new commits; `--gpg-sign` signs | supported | "Transplant a series of commits onto a different starting point." and the `A'--B'--C'` example; `--gpg-sign[=<keyid>]` "GPG-sign commits." |
| 34 | Rebase conflicts after upstream merges / squash | supported | Exact sentence. |
| 35 | Dry-run rebase applies 23/23, no conflicts, six new ARBs absent upstream | supported | Reproduced on Weblate's own shallow graph (`wl2`, detached at `afbad294`, `git rebase refs/wl/origin-main`): "Successfully rebased and updated detached HEAD.", 23 commits on top, added `intl_{es,fr,hu,pt_BR,ru,sv}.arb`, no modified files; upstream `lib/l10n/` has only cs, de, en, it, pl, sk, tr, uk, zh. |
| 36 | Push on commit needs a push URL | supported | Exact text. |
| 37 | Lazy commits triggers incl. "A merge from upstream occurs." | supported | Exact list. |
| 38 | Age of changes to commit | supported | Exact text. |
| 39 | Pending changes are `PendingUnitChange` rows; `commit_pending` under lock | supported | L3913-3960; `self.repository.lock.reacquire()` per translation. |
| 40 | `do_update` commits pending only when `needs_commit_upstream()` | supported | Docstring at L2921-2936. |
| 41 | Reset and reapply keeps pending; Reset and discard drops them | supported | Exact text in both the recovery section and the maintenance table. |
| 42 | REST `operation` one of push, pull, commit, reset, cleanup | supported | Exact text at the component repository endpoint. |
| 43 | Periodic tasks: `commit_pending` and `update_remotes` hourly, `repository_alerts` `crontab(hour=3, minute=45)` | supported (wording) | tasks.py L1893-1903. The webhook is not a periodic task; it is a view that queues `perform_update`. |

### Corrections to carry into the text above

- Section 1 / 4 / open question 2: replace "283 (count_missing)" with "1388 as Weblate counts it on its shallow clone (283 in a full-history clone)". The shallow boundary is `294debe6`, i.e. the commit Weblate cloned at on 2026-07-23.
- Section 4 table: `RepositoryOutdated` is severity ERROR (default), not informational; it is simply not an `ErrorAlert` (no git error payload) and not locking.
- Section 4: Lock on error anchor is `admin/projects.html#component-auto-lock-error`.

### Still unsourced

- Hosted Weblate's actual `AUTO_UPDATE` value (only inferred from default + change log + export refs).
- Whether the shallow clone's inflated `count_missing` is what Hosted's UI shows in the alert (the alert row stores no count).
- Celery timezone for `crontab(hour=3, minute=45)` on Hosted (the observed 00:51 UTC fetch fits the UTC-hour scheduler, but the alert cron was not observed).
- Committer identity after rebase (stated in section 5 as "Hosted Weblate"; git docs do not say this and it was not checked against a rebased Weblate commit).
