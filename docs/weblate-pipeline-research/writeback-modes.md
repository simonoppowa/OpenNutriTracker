# Hosted Weblate → GitHub write-back modes

Researched 2026-09-12. Docs pinned to `https://docs.weblate.org/en/latest/` (page footer: "Weblate 2026.10").
Hosted Weblate itself reports `weblate-2026.9.1-81-g5f28605969` on https://hosted.weblate.org/about/, so the
2026.9 "Version control parameters" (`create_merge_request`, `merge_request_automerge`, …) are live there.
Weblate source quoted at commit `0195e965e6fc286098476a0d60faa8abe880ce38` (main HEAD today).

## TL;DR for this repo

| Mode | What Hosted Weblate does | What the repo owner must do | Fits our branch protection? |
|---|---|---|---|
| (a) Direct SSH push | Pushes commits as the `weblate` GitHub user over SSH to *Repository push URL*, to *Push branch* (or the tracked branch if empty) | Invite `weblate` as a collaborator with **write**; set *Repository push URL* = `git@github.com:simonoppowa/OpenNutriTracker.git`; optionally set *Push branch* | Only with *Push branch* set to an unprotected branch. `main` has "require PR" (admins exempt, no bypass list possible on a personal repo), so a direct push to `main` by a write collaborator is rejected. |
| (b) VCS = "GitHub pull request" (legacy, token-based) | Forks the repo into `github.com/weblate/<repo>`, force-pushes branch `weblate-<project>-<component>`, opens a PR against the tracked branch as user `weblate`; a subsequent push updates the open PR; after merge the next push opens a new PR | For a public repo: **nothing** (fork + PR needs no access). With *Push branch* set: `weblate` needs write access (pushes to upstream branch over SSH) | Yes. PR base is always the component's *Repository branch* (`main` today). |
| (c) Hosted Weblate GitHub App | VCS backend "GitHub (via Weblate GitHub app)"; installation token for clone, push of translation branch, PR creation, webhooks | Install https://github.com/apps/hosted-weblate on the `simonoppowa` account, grant it the repo, connect it from the Weblate **workspace**, import/migrate the component | Yes (PR flow). Requires the Weblate project to be in a workspace. |
| (d) HTTPS push URL with a PAT | Plain git push over HTTPS with `https://user:token@github.com/...` | Repo owner mints a PAT and embeds it in *Repository push URL* | Docs frame this as self-hosted; same protected-branch caveats as (a). |

Current state of the `app` component: `vcs=git`, `push=""`, `push_on_commit=true`, `commit_pending_age=24`.
Because the push URL is empty, `push_if_needed()` logs "skipped push: upstream not configured" — commits
accumulate in Weblate's local clone (visible at https://hosted.weblate.org/git/opennutritracker/app/) and nothing
is written back. The `weblate` user is **not** a collaborator on `simonoppowa/OpenNutriTracker` (collaborators:
erikpt, TomAFrench, simonoppowa, jordan-lee-code — `gh api repos/simonoppowa/OpenNutriTracker/collaborators`).

---

## (a) Plain git push over SSH

### Where Hosted Weblate publishes its SSH public key

- https://hosted.weblate.org/keys/ (behind an Anubis JS challenge; opened in a browser) shows two keys:
  - `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDS37LXHx0G1k76wjelsEC8V7lbfeUGtxo/… weblate@web`
  - `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINl+lWmTpBBkj1B5lE/uhYI6Y3sy4WQ7CiCzwqrCSRfa Hosted Weblate`
  - Page text: "The corresponding public key is found below, you can use it to grant Weblate access to a repository."
  - Also lists egress IPs (88.198.184.85, 116.203.108.97, 162.55.191.230 + three IPv6) and the commit-signing GPG key
    `3C267921FD52C9FEE1F07A0AA3FAAA06E6569B4C`: "All commits made with Weblate are signed with the GPG key".
- Docs (https://docs.weblate.org/en/latest/vcs.html#weblate-ssh-key): "The Weblate public key is visible to all users browsing the About page."
  and "Weblate now generates both RSA and Ed25519 SSH keys. Using Ed25519 is recommended for new setups."

### Deploy key vs. collaborator — why deploy-key setup is NOT the documented path on Hosted Weblate

- The RSA key shown on hosted.weblate.org/keys/ is attached to the GitHub user `weblate`: it appears verbatim in
  https://github.com/weblate.keys. (The Ed25519 key from the keys page does **not** appear there — see open questions.)
- GitHub refuses to attach one key twice: https://docs.github.com/en/authentication/troubleshooting-ssh/error-key-already-in-use
  — "This error occurs when you try to add a key that's already been added to another account or repository."
  And https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys —
  "Deploy keys only grant access to a single repository." / "A deploy key with write access lets a deployment push to the repository."
- Weblate docs therefore say: https://docs.weblate.org/en/latest/vcs.html#ssh-repositories — "On GitHub, each key can only be used once".
- Hosted-specific instruction (https://docs.weblate.org/en/latest/vcs.html#accessing-repositories-from-hosted-weblate):
  - "Hosted Weblate has a dedicated push user (with the username weblate, e-mail hosted@weblate.org, and a name or profile description Weblate push user)."
  - "read-only is okay for cloning, write is required for pushing"
  - "The weblate user on GitHub accepts invitations automatically within five minutes when you intentionally use direct SSH access there."
  - "you can configure Source code repository and Repository push URL using the SSH protocol, for example git@example.com:group/project.git."
- GitHub user record (`gh api users/weblate`): login `weblate`, name "Weblate (bot)", bio "I'm user pushing changes from Hosted Weblate. See @WeblateOrg for our code.", type User, 1922 public repos (forks).
- Note on personal repos: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys —
  "Only organizations can restrict machine users to read-only access. Personal repositories always grant collaborators read/write access."
  So inviting `weblate` to this personal repo necessarily grants write.

### "Repository push URL" and "Push branch" fields

- https://docs.weblate.org/en/latest/admin/projects.html#component-push — "Repository URL used for pushing. The behavior of this depends on Version control system".
- https://docs.weblate.org/en/latest/admin/projects.html#component-push-branch — "Branch for pushing changes, leave empty to use Repository branch."
- Options table, https://docs.weblate.org/en/latest/admin/code-hosting.html#pushing-changes-from-weblate:
  - "Push directly | Git | SSH URL | empty"
  - "Push to separate branch | Git | SSH URL | Branch name"
- Rebase + separate branch needs force push: https://docs.weblate.org/en/latest/admin/projects.html#component-merge-style —
  "You might need to turn on force pushing in Version control parameters, especially when pushing to a different branch."
  Parameter `git_force_push` (https://docs.weblate.org/en/latest/vcs.html#list-of-version-control-parameters):
  "Overwrite the remote branch instead of refusing to push non-fast-forward changes."
- Source confirms the separate-branch force semantics for the PR backends too
  (https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/vcs/git.py, `GitMergeRequestBase.push`):
  "Weblate owns the dedicated push branch and rebases it, so it has to be forced."

---

## (b) VCS = "GitHub pull request" (legacy token integration)

Docs: https://docs.weblate.org/en/latest/admin/code-hosting.html#github-pull-requests

- What it is: "pushing translation changes as pull requests, instead of pushing directly to the repository".
- Credentials are **server-side** (`GITHUB_CREDENTIALS`), not per component. On Hosted Weblate that is the `weblate` GitHub user
  (docs example at https://docs.weblate.org/en/latest/admin/config.html#github-credentials literally uses `"username": "weblate"`).
  Token needs: "To clone, push and create pull requests, the read and write access to Contents and Pull requests is required."
  and "If Weblate should fork private repositories, the token might also need administration access."
- Fork-vs-branch: https://docs.weblate.org/en/latest/admin/code-hosting.html#ssh-with-a-dedicated-user (Note) —
  "if not set, the project is forked and changes are pushed through a fork." / "If set, changes are pushed to the upstream repository and the chosen branch."
- Options table rows:
  - "GitHub pull request from fork | GitHub pull requests | empty | empty"
  - "GitHub pull request from branch | GitHub pull requests | SSH URL [1] | Branch name" with footnote
    "Can be empty in case Source code repository supports pushing."
- New in 2026.9 (https://docs.weblate.org/en/latest/vcs.html#list-of-version-control-parameters, "Added in version 2026.9."):
  - `create_merge_request` — "When turned off, Weblate pushes to the translated branch directly, which requires write access to it."
  - `merge_request_automerge` — "Turn on GitHub auto-merge for pull requests created by Weblate, so that they are merged once the required checks pass."
  - `merge_request_merge_method` — "Method used when merging pull requests automatically. The repository has to allow it."

### Mechanics from source (git.py at commit 0195e965e6fc)

- Fork branch name: `return f"weblate-{self.component.project.slug}-{self.component.slug}"` → for us `weblate-opennutritracker-app`.
- Fork is used only when *Push branch* is empty or equals the tracked branch: `return not branch or branch == self.branch` (`should_use_fork`).
- Push to fork is always forced: `"push", "--force", credentials["username"], f"{local_branch}:{fork_branch}"` (`push_to_fork`).
- With server-side credentials the fork push goes over **SSH** (`push_scheme = "ssh"` in `get_credentials`; `if credentials["push_scheme"] == "ssh": push_url = ssh_url` in `configure_fork_remote`) — i.e. the `weblate` user's SSH key.
- PR creation: `"head": head, "base": origin_branch` where `origin_branch` is the component's tracked branch — the PR **always targets Repository branch**.
- Re-push while a PR is open: GitHub answers "A pull request already exists"; Weblate ignores it —
  `if "A pull request already exists" in error_text:` … `return`. So the open PR is updated in place by the force push; no second PR.
- After the PR is merged, the next push opens a fresh PR from the same head (real-world evidence: kando-menu/kando PRs #1497, #1518, #1521, #1538,
  all `head = weblate:weblate-kando-core`, author `weblate`, `maintainer_can_modify: true`, `head.repo.fork: true`).
- Fork branch-mode example without fork: Fabito02/ChromaLeon#90, `head = Fabito02:translations`, author `weblate` (Push branch set on upstream).
- Fork hygiene: `configure_fork_features` — "This function disables Actions to prevent unnecessary CI runs."
- `GitMergeRequestBase.needs_push_url = False` → `can_push()` is true even with an empty push URL (`return self.has_push_configuration() or not self.repository_class.needs_push_url`).

### Pull request message template

- Field: https://docs.weblate.org/en/latest/admin/projects.html#component-pull-message — "The built-in defaults follow Conventional Commits and include Weblate links where available."
- Setting: https://docs.weblate.org/en/latest/admin/config.html#default-pull-message — "Configures the default title and message for pull requests."
- Current default (https://github.com/WeblateOrg/weblate/blob/0195e965e6fc286098476a0d60faa8abe880ce38/weblate/trans/defaults.py):
  ```
  DEFAULT_PULL_MESSAGE = """chore(l10n): update translations

  Translations updated in [{{ site_title }}]({{ site_url }}) for [{{ project_name }}/{{ component_name }}]({{ url }}).
  ...
  ![Weblate translation status]({{widget_url}})
  """
  ```
  First line = PR title, rest = body (`get_merge_message`: `return lines[0], "\n".join(lines[1:]).strip()`).
- PRs opened by Hosted Weblate today are still titled "Translations update from Hosted Weblate" (kando#1538, ChromaLeon#90, InstallerX-Revived#829) — the deployed 2026.9.1 default or per-component overrides differ from main's template. Set `pull_message` explicitly if the title matters for our commitlint/CI.

---

## (c) Hosted Weblate GitHub App (recommended by the docs)

Docs: https://docs.weblate.org/en/latest/admin/code-hosting.html#hosted-weblate-github-app

- "Use the Connect GitHub account flow, install the App on the GitHub user or organization that owns your repositories"
- "The App-backed workflow uses GitHub installation access tokens for cloning, pushing translation branches, creating pull requests, and receiving incoming notifications."
- "You do not need to invite the Hosted Weblate weblate GitHub user or configure a separate repository webhook for components imported this way."
- "Use the Hosted Weblate weblate GitHub user only when you intentionally configure direct SSH pushes outside the GitHub App workflow"
- Backend name: "Components imported through the GitHub App flow use the dedicated GitHub (via Weblate GitHub app) VCS backend."
- Workspace requirement (https://docs.weblate.org/en/latest/admin/code-hosting.html#connecting-a-workspace):
  "Projects that are not in a workspace cannot connect a GitHub account through the GitHub App."
- Migration of an existing Git component (https://docs.weblate.org/en/latest/admin/code-hosting.html#migrating-existing-components):
  "Weblate reports an informational diagnostic for Git and GitHub pull request components that can be migrated to a registered Weblate GitHub App."
  and it "removes separate push URLs because the App authenticates pushes to the source repository."
- The App itself (`gh api apps/hosted-weblate`): slug `hosted-weblate`, owner `WeblateOrg`, created 2026-06-26, permissions
  `contents: write, metadata: read, organization_administration: read, pull_requests: write, workflows: write`, events `["push"]`.
  Matches the docs' manifest list: "Contents and Pull requests read/write, Metadata read-only, Organization administration read-only, Workflows read/write".
- A separate `hosted-weblate-legacy` app exists (contents write, metadata read; events push, repository) — webhook-only per docs
  ("The Hosted Weblate legacy app is kept for existing webhook-only setups.").
- Same `create_merge_request` / auto-merge parameters apply (`github-app` is listed for all three parameters).

## (d) HTTPS with a personal access token in the push URL

- https://docs.weblate.org/en/latest/admin/code-hosting.html#https-with-personal-access-token —
  "Include the token in your repository URL: https://username:token@github.com/owner/repo.git." / "The token needs read access for cloning and write access for pushing."
- https://docs.weblate.org/en/latest/vcs.html#https-repositories — Weblate "will strip this info when the URL is shown to users".
- The docs put this under self-hosted guidance; nothing technical prevents it on Hosted, but it means handing a PAT with `contents:write` to a third-party service and every push is authored by the token owner's identity for protection purposes.

---

## When does a push / PR actually happen? ("Push on commit" × "Age of changes to commit")

1. Edits are **not** committed immediately — Lazy commits (https://docs.weblate.org/en/latest/admin/continuous.html#lazy-commits):
   "The behaviour of Weblate is to group commits from the same author into one commit if possible." A commit happens when any of:
   "Somebody else changes an already changed string." / "A merge from upstream occurs." / "An explicit commit is requested." /
   "A file download is requested." / "Change is older than period defined as Age of changes to commit on Component configuration."
2. *Age of changes to commit* (https://docs.weblate.org/en/latest/admin/projects.html#component-commit-pending-age):
   "All changes in a component are committed once there is at least one change older than this period." Default 24 h
   (`DEFAULT_COMMIT_PENDING_HOURS = 24` in defaults.py; our component uses 24). The sweep runs hourly:
   `sender.add_periodic_task(3600, commit_pending.s(), name="commit-pending")` (tasks.py).
3. *Push on commit* (https://docs.weblate.org/en/latest/admin/projects.html#component-push-on-commit):
   "When enabled, the push is initiated once Weblate commits changes to its underlying repository (see Lazy commits)." and
   "To actually enable pushing Repository push URL has to be configured as well." Default on: "this is enabled by default"
   (code-hosting.html) / `DEFAULT_PUSH_ON_COMMIT = True`.
4. Source chain: `Component.commit_pending()` ends with `if not skip_push: self.push_if_needed()`; `push_if_needed` bails with
   "skipped push: push on commit disabled" or "skipped push: upstream not configured" (`can_push()` false) or when nothing is outgoing.
   For PR backends `needs_push_url = False`, so the push (fork + PR) fires without a push URL.
5. Net effect: with push_on_commit=true and age=24 h, a translation lands upstream (as a push or PR) roughly 24–25 h after the
   first pending edit unless one of the other commit triggers fires earlier. Setting *Push on commit* off means pushes only happen
   manually ("push manually under Repository maintenance or using the API via wlc push").
6. *Lock on error* (https://docs.weblate.org/en/latest/admin/projects.html#component-lock-on-error): "Locks the component (and linked components, see Weblate internal URLs) upon the first failed push or merge into its upstream repository, or pull from it."

## "Push branch" with the PR integration

Supported: the options table has "GitHub pull request from branch | GitHub pull requests | SSH URL [1] | Branch name", and the setup overview says
"Optionally set Push branch when Weblate should push to a branch in the upstream repository instead of using a fork where supported."
Consequences from source: the fork is skipped (`should_use_fork` false), the push to that upstream branch is forced, and the PR is opened
from `<branch>` into the component's *Repository branch*. Write access to the upstream is required for that push (SSH as `weblate`, or the App).

## Branch protection / required reviews

- Weblate docs (https://docs.weblate.org/en/latest/admin/continuous.html#protected-branches): "you can configure it to use pull requests and perform actual review on the translations" —
  "An alternative approach is to waive this limitation for the Weblate push user."
- GitHub (https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches):
  - "Actors may only be added to bypass lists when the repository belongs to an organization." → on a **personal** repo like ours there is no way to whitelist `weblate` or the App past "require PR".
  - "By default, the restrictions of a branch protection rule don't apply to people with admin permissions to the repository"
  - "People, teams, and apps that have permission to push to a protected branch will still need to create a pull request when pull requests are required."
- This repo today (`gh api repos/simonoppowa/OpenNutriTracker/branches/{main,develop}/protection`, `…/rulesets`):
  - `main`: required PR reviews with `required_approving_review_count: 0`, `enforce_admins: false`, `restrictions: null`, no bypass allowances.
  - `develop`: required PR reviews, `required_approving_review_count: 1`.
  - Ruleset "Copilot automatic code review" (active) on `refs/heads/main`, `refs/heads/develop`, `refs/heads/release/**` with rules `deletion`, `non_fast_forward`, `copilot_code_review`; `bypass_actors: []`.
  - Therefore: direct SSH push to `main` by a `weblate` write collaborator is rejected; a PR (fork or branch mode) works; a dedicated push branch (e.g. `weblate` / `l10n/weblate`) is outside the ruleset so force-push is allowed there. Auto-merge on `main` would need only the merge-queue-less "require PR" to be satisfied (0 approvals), but on `develop` a human approval is needed.

## Open questions

1. The Ed25519 key shown on https://hosted.weblate.org/keys/ is **not** in https://github.com/weblate.keys (only the RSA `weblate@web` key is). Whether that Ed25519 key is attached to another GitHub account, unused, or usable as a deploy key could not be determined without the private key; do not rely on adding it as a deploy key.
2. Whether the `opennutritracker` Weblate project already sits in a workspace (prerequisite for the GitHub App flow) — requires a logged-in Weblate admin view; not visible publicly.
3. Hosted Weblate's PR title today is "Translations update from Hosted Weblate", not main's `chore(l10n): update translations`; unclear whether that is the deployed 2026.9.1 default or a per-component template. Set `pull_message` explicitly.
4. Does the "GitHub pull request" VCS on Hosted Weblate, when *Push branch* is set, need `weblate` invited as a collaborator (SSH push) or does Hosted Weblate's token push over HTTPS? Source says configured credentials force `push_scheme = "ssh"` for the fork remote; for the `origin` push it uses the component's push URL, which the docs table says should be an SSH URL. Verify in practice before relying on HTTPS.
5. No primary source found stating a hard limit on how often the hourly `commit_pending` sweep is scheduled on Hosted Weblate specifically (the 3600 s value is from the upstream source, not a Hosted-specific statement).

## Verification

Fact-checked 2026-09-12 by re-fetching every cited source (docs.weblate.org pages via curl, Weblate source via
raw.githubusercontent.com at commit `0195e965e6fc` — confirmed to exist, committed 2026-09-12T12:19Z — GitHub docs via curl,
hosted.weblate.org `/keys/` and `/about/` in a browser because Anubis returns 403 to curl/WebFetch, kando PRs and the
GitHub App via `gh api`).

### Verdicts

| # | Claim (short) | Verdict | Notes |
|---|---|---|---|
| 1 | Dedicated push user `weblate` / hosted@weblate.org; write needed for pushing | supported | Verbatim on vcs.html#accessing-repositories-from-hosted-weblate. The section now leads with "use the Hosted Weblate app … whenever possible" and frames the SSH user as "for direct SSH access outside the GitHub App workflow, and for Bitbucket, Codeberg, and GitLab". |
| 2 | `weblate` accepts GitHub invitations within five minutes | supported | Verbatim, same section. |
| 3 | /keys/ publishes RSA + Ed25519 keys, egress IPs, GPG key | supported | Seen in browser: both keys, 3 IPv4 + 3 IPv6, GPG `3C267921FD52C9FEE1F07A0AA3FAAA06E6569B4C`. |
| 4 | RSA key is on github.com/weblate.keys; the Hosted Ed25519 key is not | supported, with a correction | The RSA key matches byte-for-byte. `weblate.keys` lists **8** keys (7 RSA + 1 Ed25519 `…IFOT4xbZ6FFz…`), not "only the RSA weblate@web key". The Hosted Ed25519 key `…INl+lWmT…` is indeed absent, but a *different* Ed25519 key is attached to the user. |
| 5 | "On GitHub, each key can only be used once" → cannot double as deploy key | supported | Verbatim Warning in vcs.html#ssh-repositories. |
| 6 | GitHub rejects reused keys; deploy keys are single-repo | supported | Both sentences on the error-key-already-in-use page ("Once a key has been attached to one repository as a deploy key, it cannot be used on another repository."). |
| 7 | Personal repos always grant collaborators read/write | supported | Verbatim under "Cons of machine users" on managing-deploy-keys. |
| 8 | Push branch: empty = Repository branch | supported | Verbatim projects.html#component-push-branch. |
| 9 | Git push modes table rows | supported | Table on code-hosting.html#pushing-changes-from-weblate. |
| 10 | Rebase + different branch may need `git_force_push` | supported | Verbatim under Merge style → Rebase. |
| 11 | GitHub PR VCS = thin layer over GitHub API; GITHUB_CREDENTIALS | supported | Verbatim code-hosting.html#github-pull-requests. |
| 12 | GITHUB_CREDENTIALS example uses `weblate`; Contents + Pull requests r/w; admin for private forks | supported | Verbatim config.html#github-credentials. Also notes fine-grained tokens cannot fork outside the org. |
| 13 | Empty Push branch → fork; set → upstream branch | supported | The Note lives in the first `#ssh-with-a-dedicated-user` section (GitHub). |
| 14 | "GitHub pull request from branch" row with SSH URL [1] | supported | Footnote [1]: "Can be empty in case Source code repository supports pushing." |
| 15 | `create_merge_request` (2026.9) off → direct push needing write | supported | "Added in version 2026.9." heads the Version control parameters section; help text verbatim. |
| 16 | `merge_request_automerge` honours required checks | supported | Verbatim; also "Pull requests with nothing to wait for are merged right away." Applies to `github` and `github-app`. |
| 17 | Fork branch `weblate-<project>-<component>`, force-pushed | supported | git.py L2072 and `push_to_fork` (`"push", "--force", …`). |
| 18 | "A pull request already exists" swallowed → PR updated in place | supported | git.py L3196; the handler also re-applies auto-merge to the existing PR. |
| 19 | PR base is always the tracked Repository branch | supported | `create_pull_request(credentials, current_branch, …)` with `current_branch = self.validate_branch_name(self.branch)`. |
| 20 | New PR from the same fork branch after each merge (kando) | supported | `gh api`: 20 consecutive `weblate:weblate-kando-core` → `main` PRs, each created after the previous merge (e.g. #1521 merged 09-04, #1538 opened 09-12, still open). |
| 21 | Weblate disables Actions on its fork | supported | Docstring at git.py L3094-3096 (line-wrapped): "This function disables Actions to prevent unnecessary CI runs." |
| 22 | Default pull message on main is Conventional-Commits style with widget | supported | defaults.py L95-108. **Also true at tag `weblate-2026.9.1`** (same `chore(l10n): update translations` title), so the "Translations update from Hosted Weblate" titles seen on kando/ChromaLeon are per-component/per-project overrides or an older deployed template, not the 2026.9.1 default — open question 3 narrows accordingly. |
| 23 | Pull message setting configures PR title and message | supported | Verbatim config.html#default-pull-message. |
| 24 | GitHub App recommended; no `weblate` invite or webhook | supported | Verbatim code-hosting.html#hosted-weblate-github-app. |
| 25 | App flow requires a workspace | supported | Verbatim code-hosting.html#connecting-a-workspace. |
| 26 | Migration drops separate push URLs | supported | Verbatim code-hosting.html#migrating-existing-components. |
| 27 | App permissions / events / owner / created date | supported, citation corrected | The JSON quote comes from the REST API (`GET https://api.github.com/apps/hosted-weblate`), not the HTML page at github.com/apps/hosted-weblate, which shows only "Developer: WeblateOrg". API confirms every value. |
| 28 | HTTPS PAT in push URL is documented | supported | Verbatim code-hosting.html#https-with-personal-access-token. "Self-hosted" framing comes from vcs.html "Accessing repositories" ("For self-hosted Weblate, a single private repository is often easiest to set up using an HTTPS repository URL with an access token"). |
| 29 | Push on commit needs a Repository push URL | supported | Verbatim projects.html#component-push-on-commit. |
| 30 | Push on commit is on by default | supported | Verbatim code-hosting.html#pushing-changes-from-weblate; `DEFAULT_PUSH_ON_COMMIT = True`. |
| 31 | Age of changes: all pending committed once one is older | supported | Verbatim projects.html#component-commit-pending-age. |
| 32 | Lazy-commit trigger list | supported | Verbatim continuous.html#lazy-commits. |
| 33 | Hourly `commit_pending` periodic task | supported | tasks.py L1895. Upstream code only; not a Hosted-specific statement. |
| 34 | `can_push()` / `needs_push_url = False` on PR backends | supported | component.py L2413 and L3062; git.py L2045 (`GitMergeRequestBase`), also L1833 (`SubversionRepository`). |
| 35 | Protected branches: PR flow or waive for push user | supported | Verbatim continuous.html#protected-branches. |
| 36 | Bypass lists only on org-owned repos | supported | Verbatim on about-protected-branches. |
| 37 | Push-allowed actors still need a PR; admins exempt unless enforced | supported | Verbatim; "enforce_admins" is the API name — the page says "You can optionally apply the restrictions to administrators". |
| 38 | Hosted Weblate runs `weblate-2026.9.1-81-g5f28605969` | supported | Seen in browser on /about/. |
| 39 | Lock on error text | supported, anchor corrected | Text verbatim, but the section id is `#lock-on-error` (also `#component-auto-lock-error`); `#component-lock-on-error` does not exist. |

### Not answered with a source

- Whether the fork-based PR flow on a **public** repo needs any access grant at all (TL;DR says "nothing"): inferred from GitHub fork semantics and the kando series; no doc sentence says so.
- How the GitHub-PR backend authenticates the push to an upstream *Push branch* on Hosted Weblate (SSH as `weblate` vs HTTPS token) — open question 4 remains.
- Which GitHub account, if any, the Hosted Ed25519 key `…INl+lWmT…` is attached to (a different Ed25519 key is on the `weblate` user).
- Whether the GitHub App backend (`github-app`) forks or pushes a translation branch straight into the upstream repo; docs only say "pushing translation branches".
- Whether Hosted Weblate keeps the upstream hourly `commit_pending` schedule (open question 5).
- Whether the `opennutritracker` project is in a workspace (open question 2).
