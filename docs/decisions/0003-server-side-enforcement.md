# 0003 — Server-side enforcement is the real security boundary

- **Status:** accepted
- **Date:** 2026-04-28
- **Author:** project owner

## Context

v1 placed all enforcement in local git hooks. Self-audit identified this as the design's biggest weakness:

- `git commit --no-verify` bypasses hooks in one keystroke.
- A fresh clone has hooks unwired by default (`core.hooksPath` is per-clone state).
- Editing or deleting `.githooks/pre-commit` is unrestricted.
- A contributor on a different machine can simply not install hooks at all.

Local hooks are *advisory*, not authoritative. The authoritative boundary is the git server (GitHub).

## Decision

All security-critical checks run on the server via GitHub Actions. The local hooks remain as a **fast-feedback layer** that runs the same checks before code leaves the laptop, but they are no longer the source of truth.

**Required server-side jobs** (in `.github/workflows/security.yml`):
1. `secret-scan` — gitleaks against full history on every push and PR.
2. `large-files` — refuses files >5 MB.
3. `no-direct-pushes` — pushes to `main` must be merge commits from PRs.
4. `hooks-integrity` — confirms `.githooks/pre-commit` exists and is executable in the tree.
5. `placeholder-lint` — refuses `<<PLACEHOLDER>>` tokens leaking into shipped docs.

**PR quality jobs** (in `.github/workflows/pr-checks.yml`):
6. `pr-title` — Conventional Commits format.
7. `pr-body` — requires Summary + Test plan sections.

**Audit jobs**:
8. `branch-protection-audit` (weekly cron) — opens an issue if `main` has no protection rules.
9. `hook-tests` (on hook changes) — bats test suite for the pre-commit hook.

**Branch protection** (configured in GitHub repo settings, not in this template):
- Require all of the above status checks to pass before merge.
- Require at least 1 PR approval.
- Require linear history.
- Disallow force pushes and deletions.

## Alternatives considered

- **Pre-receive hook on the server.** Requires GitHub Enterprise or self-hosted Gitea/GitLab. Not portable.
- **Git provider-native scanning only** (GitHub Advanced Security). Public-repo-only or paid tier; vendor lock-in.
- **No CI; rely on hooks.** Rejected — see Context.
- **Code review only.** Rejected — humans miss secrets routinely; automation must be the first pass.

## Consequences

**Positive:**
- `--no-verify` no longer bypasses anything that matters. CI re-runs the same checks regardless of how the developer committed.
- Coverage is identical for every contributor, regardless of OS or hook setup.
- Branch protection + required status checks make the rules unbypassable without admin override (which is logged).
- Weekly branch-protection audit catches drift if someone disables protection.

**Negative:**
- Requires the project owner to **manually configure branch protection in GitHub Settings** — the workflows themselves can't self-install protection rules. Documented in the workflow file and SECURITY.md.
- CI runs cost minutes (free tier covers most projects).
- Slightly slower feedback loop than purely-local enforcement (but local hooks still run first).

**Reversal cost:** low — disable workflows by deleting the YAML files. Branch protection is one click to remove.

## References

- `.github/workflows/security.yml`
- `.github/workflows/pr-checks.yml`
- `.github/workflows/branch-protection-audit.yml`
- `.github/workflows/hook-tests.yml`
- GitHub branch protection docs: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches
