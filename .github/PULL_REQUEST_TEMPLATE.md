## Summary
<!-- What does this PR change and why? -->

## Type of change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactor / cleanup
- [ ] Documentation
- [ ] CI / tooling
- [ ] Localization
- [ ] Other

## Related issues
<!-- Link issues with Fixes #123 or Refs #123 -->

## Changes
<!-- Bullet list of the main user-facing or technical changes -->

## Screenshots / recordings
<!-- UI changes: before/after on Android and/or iOS if practical -->

## Test plan
- [ ] Described steps below were followed locally
- [ ] Unit / widget tests added or updated (if applicable)
- [ ] Manual check on Android
- [ ] Manual check on iOS (if applicable)

### Steps
1.
2.

## Checklist
- [ ] Code follows project style (`just format` / 120-char line width)
- [ ] New interactive widgets include `Semantics(identifier: '...')` where needed
- [ ] Localization updated in **every** `lib/l10n/intl_*.arb` with a real translation, not the English string (`lib/generated/` is gitignored — do not edit or commit it)
- [ ] Codegen ran if DBOs/DTOs/env changed (`just build`)
- [ ] No secrets or `.env` values committed
- [ ] PR title follows conventional commit style (e.g. `feat:`, `fix:`, `chore:`)
