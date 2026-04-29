## Summary

<!-- 1-3 bullets describing what this PR does and why. -->

-
-

## Test plan

<!-- Concrete steps the reviewer can run to verify. -->

- [ ]
- [ ]

## Security checklist

- [ ] No secrets, tokens, or credentials in the diff (gitleaks will catch most, but eyeball it)
- [ ] No `--no-verify`, `--no-gpg-sign`, or force-push used in this branch
- [ ] No new dependencies added without an ADR (or, if added, dependency is reputable + version pinned)
- [ ] No destructive DB / production operations introduced without explicit approval
- [ ] If env vars were added/changed, they're set in the deploy provider AND `.env.example` was updated

## Linked issues

<!-- e.g. Closes #123 -->

## Screenshots / recordings (if UI)

<!-- Drag in or paste. -->
