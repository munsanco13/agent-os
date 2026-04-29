# 0002 — Secret scanning with gitleaks (not custom regex)

- **Status:** accepted
- **Date:** 2026-04-28
- **Author:** project owner

## Context

v1 of this template shipped a custom bash regex set in the pre-commit hook to detect secrets. Self-audit revealed it covered ~8 patterns; real-world secret leaks involve hundreds of vendor-specific token formats plus high-entropy strings.

A self-rolled scanner means:
- New token formats (e.g. when Stripe / Anthropic / Supabase rotate their key prefixes) require manual hook updates.
- No entropy-based detection — base64 blobs in `config.ts` slip through.
- Each maintainer is responsible for keeping the patterns current.

## Decision

Use **gitleaks** (https://github.com/gitleaks/gitleaks) as the canonical scanner, both locally (in pre-commit + pre-push hooks) and server-side (in `.github/workflows/security.yml`).

- Local: hook calls `gitleaks protect --staged` if installed. If absent, falls back to a small built-in regex set + prints install instructions. Falling back is non-fatal so a dev can still commit without the dep, but they're warned.
- Server: CI workflow uses `gitleaks/gitleaks-action@v2` with the project's `.gitleaks.toml`. **CI failure is fatal** — this is the real gate.
- Config: `.gitleaks.toml` extends gitleaks' built-in rules (~150 patterns) and adds project-specific ones (Anthropic, OpenAI, Supabase service-role JWTs, Clerk, Intuit, Postgres connection strings, etc.).

## Alternatives considered

- **trufflehog** — also excellent. Picked gitleaks because: (a) `gitleaks-action` GitHub Action is more polished, (b) TOML config is easier to edit than YAML for this purpose, (c) `gitleaks protect --staged` is the canonical pre-commit hook flag.
- **GitHub Advanced Security secret scanning** — only available on Enterprise / public repos. Not portable.
- **detect-secrets (Yelp)** — Python, requires baseline file maintenance, more friction.
- **Custom regex (v1)** — see Context. Rejected.

## Consequences

**Positive:**
- Coverage jumps from ~8 patterns to ~150+ maintained by upstream, plus our project-specific additions.
- Entropy detection catches generic high-entropy strings.
- One config file (`.gitleaks.toml`) drives both local and CI scanning.
- Maintainers don't have to track new vendor token formats manually.

**Negative:**
- gitleaks is a binary dependency; new contributors need to install it (`brew install gitleaks` on macOS, package manager elsewhere) for local hooks to be maximally effective.
- False positives possible. We mitigate via the `[allowlist]` section in `.gitleaks.toml`.

**Reversal cost:** low — both hook and CI revert by deleting the gitleaks invocations and re-enabling the v1 regex. Config file would be removed.

## References

- gitleaks: https://github.com/gitleaks/gitleaks
- gitleaks-action: https://github.com/gitleaks/gitleaks-action
- `.gitleaks.toml` in this repo
- `.githooks/pre-commit`, `.githooks/pre-push`
- `.github/workflows/security.yml`
