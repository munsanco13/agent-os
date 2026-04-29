# SECURITY.md — Hard rules + threat model

> These rules are **absolute**. Violating any of them is a bug, not a judgment call. Local git hooks provide fast feedback; the authoritative enforcement is the GitHub Actions workflows in `.github/workflows/` plus branch protection (configured in repo settings).

## Threat model

This template defends against a specific set of threats:

| Threat | Defense |
|---|---|
| Accidental secret commit by a developer | Local pre-commit hook + gitleaks + server-side gitleaks-action |
| Accidental secret commit by an AI agent | Same + AGENTS.md rules + CI required status checks |
| Force-push wiping main | `pre-push` hook + GitHub branch protection (disallow force-push) |
| Direct commit to main bypassing review | `pre-commit` hook + `no-direct-pushes` workflow + branch protection |
| Bypassing local hooks via `--no-verify` | All checks re-run server-side; no path bypasses CI |
| Hooks silently disabled (`core.hooksPath` unset) | `hooks-integrity` workflow verifies the hook exists in tree |
| Large binaries bloating history | `large-files` workflow + local `pre-commit` size check |
| Vulnerable dependency lands silently | Dependabot opens PRs weekly |
| Branch protection silently disabled | Weekly `branch-protection-audit` workflow opens an issue |
| Maintainer account compromise pushes to main | Required CODEOWNERS review + 2FA on GitHub (you must enable separately) |

This template does **not** defend against:
- Social engineering attacks against maintainers (use 2FA, hardware keys).
- Compromise of upstream dependencies (mitigation: Dependabot + lockfiles + vendor pinning).
- Compromise of GitHub itself (no client-side mitigation).
- Insider threats with admin access (use minimum-permission principle, audit logs).

## Rule 0 — Secrets never enter git

**Never commit:**
- `.env`, `.env.local`, `.env.production`, `.env.staging`, `.env.*` (any file matching `.env*`, except `.env.example`)
- `*.pem`, `*.key`, `id_rsa*`, `id_ed25519*`, `*.p12`, `*.pfx`
- `credentials.json`, `service-account*.json`, `*service_account*.json`
- `secrets.{yaml,yml,json,toml}`
- `.aws/credentials`, `.netrc`, `.pgpass`
- High-entropy strings or vendor-prefixed tokens (gitleaks catches these)

**Where secrets DO live:**
- Locally: `.env.local` (gitignored, never committed)
- Production: deploy provider env vars (Vercel / Fly / Railway / AWS Parameter Store / GCP Secret Manager)
- Source-of-truth: vendor dashboards (Stripe, Supabase, Clerk, etc.)
- CI: GitHub Actions repository / environment secrets

**If a secret has been committed:**
1. **Rotate immediately at the vendor.** The secret is compromised the moment it touches git, even in a private repo (third-party clones, cached forks, IDE indexers, etc.).
2. Force-remove from history with `git filter-repo` or `bfg-repo-cleaner`.
3. Force-push (with explicit, contemporaneous human approval).
4. Notify everyone who cloned the repo to delete and re-clone.
5. Open an ADR documenting what happened and how it was prevented going forward.

## Rule 1 — No direct commits to the main branch

- All changes go through a feature branch + PR.
- This applies to "trivial" fixes too. Even a typo.
- Direct push to `main` is blocked locally by the `pre-commit` hook and server-side by the `no-direct-pushes` workflow.

## Rule 2 — Never bypass safety mechanisms

Forbidden without explicit, contemporaneous human approval:
- `git commit --no-verify`
- `git commit --no-gpg-sign` / `-c commit.gpgsign=false`
- `git push --force` to any shared branch
- `git push --force-with-lease` to `main` / `master` / `trunk`
- `git reset --hard` on a shared branch
- `rm -rf .git/hooks` or `git config --unset core.hooksPath`
- Removing `.githooks/`, `.gitleaks.toml`, or any file under `.github/workflows/`

If a hook fails: **fix the underlying issue.** Do not work around it.

## Rule 3 — Never share secret values in chat or logs

- Reference secrets by **name**, never value, in any chat (with humans or AIs).
- Build logs, error messages, and Sentry payloads must scrub env values.
- If you accidentally paste a secret somewhere, treat as compromised → rotate.

## Rule 4 — Destructive operations require explicit per-action approval

For each instance, the human must say "yes do it":
- `DROP`, `TRUNCATE`, `DELETE FROM ... WHERE ...` against any non-local DB.
- `rm -rf` on anything outside scoped temp dirs.
- Deleting branches, tags, or releases on the remote.
- Cancelling subscriptions, deleting users, modifying billing.

"You said do it last time" is **not** approval for this time.

## Rule 5 — Audit trail

Every change goes through:
1. A commit with a Conventional-Commits-formatted message (enforced by `commit-msg` hook).
2. A PR with required Summary + Test plan sections (enforced by `pr-checks.yml`).
3. CI checks: `secret-scan`, `large-files`, `no-direct-pushes`, `hooks-integrity`, `placeholder-lint`, `pr-title`, `pr-body`.
4. CODEOWNERS review for security-critical paths (`AGENTS.md`, `SECURITY.md`, `.gitleaks.toml`, `.githooks/`, `.github/workflows/`).

If you find an action that bypasses this trail, treat it as a vulnerability and report it.

## Rule 6 — Dependencies

- Adding a dependency is a security decision, not just an engineering one.
- Prefer existing libs already in the project.
- For a new dep, verify: maintainer reputation, last commit date, weekly downloads, known CVEs (`npm audit`, `pip-audit`, `cargo audit`).
- Pin versions. Use lockfiles. Never `--no-package-lock` or `--no-frozen-lockfile` in CI.
- Dependabot runs weekly and opens PRs for security updates.

## Rule 7 — Public data only in public places

- README, ADRs, sessions, AGENTS.md, SECURITY.md may NOT contain: customer names, real email addresses, real phone numbers, internal URLs with secrets, prod DB IDs that map to real users.
- Use placeholders: `user@example.com`, `Acme Corp`, `xxx-xxx-xxxx`.

## Branch protection (REQUIRED — configure in repo settings)

The maintainer must enable branch protection on `main` with:

- ✅ Require a pull request before merging
- ✅ Require approvals: **1** (or more)
- ✅ Dismiss stale approvals when new commits are pushed
- ✅ Require review from Code Owners
- ✅ Require status checks to pass before merging:
  - `secret-scan`
  - `large-files`
  - `no-direct-pushes`
  - `hooks-integrity`
  - `placeholder-lint`
  - `pr-title`
  - `pr-body`
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Require linear history
- ❌ Do NOT allow force pushes
- ❌ Do NOT allow deletions

The `branch-protection-audit` workflow runs weekly and opens an issue if these rules drift or get disabled.

## Reporting a security issue

See `.github/SECURITY.md` for the vulnerability disclosure policy.
