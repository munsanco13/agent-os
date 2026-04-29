# Agent OS Changelog

## v2.3.1 — 2026-04-29 (hotfix)

### Fixed
- **Critical**: `scripts/install.sh` and `scripts/update.sh` had broken curl-pipe download URLs. They referenced a `.agent-template/` prefix that doesn't exist in the public agent-os repo, so every curl-piped autonomous install was 404'ing. Discovered while dogfooding the install on a real project.
- `scripts/autonomous-install.sh` template-directory resolution now correctly handles being run from inside a clone of the public agent-os repo.
- All install URL references across docs bumped from `v2.3.0` → `v2.3.1`.

### Documentation
- `PLAYBOOK.md` Part 1 ("Why this exists") rewritten around the cap-hit pain to match the README framing. Was security-leading; now leads with the visceral "Claude Code reset in 3 days" moment + 4 wall scenarios.
- `PLAYBOOK.md` TL;DR + roadmap updated to current state.

### Upgrade

```bash
bash scripts/agent-os-update.sh v2.3.1
```

If you're already on v2.3.0, this is critical — it fixes the broken curl-pipe install URLs.

## v2.3.0 — 2026-04-29 (final)

The "best in scope" release. After comparing against 5 peer tools in the multi-AI space (mozilla-ai/any-llm, bfly123/claude_codex_bridge, zuharz/ccode-to-codex, itswendell/palot, kamilio/agents-md-vscode-extension), adopted the genuinely-better ideas and made the scope explicit.

### Added

- **AGENTS.md aliases for every major AI tool.** `install.sh` now creates symlinks (or copies on Windows) so every tool finds the right filename:
  - `CLAUDE.md` → AGENTS.md (Claude Code)
  - `.cursorrules` → AGENTS.md (Cursor)
  - `.clinerules` → AGENTS.md (Cline)
  - `.continuerules` → AGENTS.md (Continue.dev)
  - `CONVENTIONS.md` → AGENTS.md (Aider)

  Borrowed conceptually from `kamilio/agents-md-vscode-extension` but covers 5+ tools instead of 1, lives in the install script (no editor dependency), and handles cross-platform symlink fallback for Windows.

- **`scripts/import.sh`** — ingests legacy single-tool config files (`CLAUDE.md`, `.cursorrules`, `.clinerules`, `CONVENTIONS.md`, `.aider.conf.yml`, `.github/copilot-instructions.md`) and merges them into `AGENTS.md` under an "Imported rules" section. Backs up originals to `.agent-os-import-backup/<timestamp>/`, replaces with symlinks, writes audit log. Inspired by `zuharz/ccode-to-codex`'s preview→validate→write→audit pattern, but merges instead of forking per-tool formats.

- **PLAYBOOK Part 10.5: "How Agent OS compares to peer tools"** — explicit positioning table, "use this not us" recommendations, composability notes. Sets honest scope; builds goodwill with adjacent projects.

### Why this matters

Pre-v2.3, we shipped two near-duplicate files (`AGENTS.md` + the Claude-only `CLAUDE.md` reference in install docs). Now there's one source of truth (`AGENTS.md`) with symlinks for compatibility. Edit one file → every AI tool reads the same thing.

The `import.sh` script means users with existing legacy config (e.g. an old project with a 200-line `CLAUDE.md`) can adopt Agent OS without throwing away their rules — they're merged in automatically.

### Upgrade from 2.2.0

```bash
bash scripts/agent-os-update.sh v2.3.0

# Then if you have legacy config files, optionally:
bash scripts/agent-os-import.sh
```

## v2.2.0 — 2026-04-29 (later)

The "hand the PDF to an AI and it just runs" release.

### Added

- **`scripts/autonomous-install.sh`** — single-command installer that reads `bootstrap.yaml` + `.credentials.local` and does everything end-to-end: drops files, substitutes placeholders, commits, opens PR, auto-merges, configures GitHub branch protection via `gh api`, validates. Zero user interaction after the two config files are filled.
- **`scripts/detect-stack.sh`** — auto-detects Node.js / Python / Rust / Go / Ruby / PHP / Elixir / Java / Deno from lockfiles + manifests. Outputs YAML directly consumable by `bootstrap.yaml`. Frameworks (Next.js, Rails, Laravel, Phoenix, Spring Boot, etc.) detected from manifest contents.
- **`bootstrap.example.yaml`** — single config file the user fills once. Drives every decision the installer makes.
- **`.credentials.example`** — PAT template (gitignored as `.credentials.local`). Documents which scopes are needed and where to get tokens.
- Stack-agnostic install path documented in PLAYBOOK Part 1.5: literal copy-paste prompt to give to any AI assistant.
- Stack-detection coverage table in QUICKSTART (Node.js / Python / Rust / Go variants).
- `.gitignore-additions` updated to cover `.credentials.local` and `bootstrap.local.yaml`.

### Why this matters

Pre-v2.2, the playbook required ~30 minutes of an AI asking the user 20 questions ("What's your project name? GitHub username? Stack?"). Post-v2.2, the AI reads bootstrap.yaml, runs one command, and reports done. Hand the PDF to Claude/Codex/Cursor → they execute it autonomously.

### Upgrade from 2.1.0

```bash
bash scripts/agent-os-update.sh v2.2.0
```

If you were previously filling placeholders manually, you can keep doing that — the autonomous flow is opt-in. To use it: copy `bootstrap.example.yaml` to `bootstrap.yaml`, fill in values (or let `detect-stack.sh` do it), copy `.credentials.example` to `.credentials.local` with your GH_PAT, run `bash scripts/autonomous-install.sh`.

## v2.1.0 — 2026-04-29

Bug-fix release addressing every critical item in the v2 self-audit.

### Fixed

- **macOS bash 3.2 compatibility** — pre-commit hook used `mapfile` (bash 4+); replaced with portable `while read` loop. Stock macOS now works.
- **JWT detection in gitleaks config** — replaced literal-base64 trick (`c2VydmljZV9yb2xl`) with shape-based + entropy detection. Real Supabase service_role JWTs are now caught regardless of byte alignment in the base64 payload.
- **Squash-merge false positive** in `no-direct-pushes` workflow — replaced parent-count heuristic with GitHub API check (`/repos/{owner}/{repo}/commits/{sha}/pulls`). Squash, rebase, and merge styles all pass correctly.
- **gitleaks installer URL** in `hook-tests.yml` — pinned to exact version via `releases/download/v$VERSION/`. The previous `releases/latest/download/...$VERSION...` would 404 on each gitleaks release.
- **CODEOWNERS placeholder fail-open** — `placeholder-lint` workflow now scans `.github/CODEOWNERS` and `.github/SECURITY.md` in addition to root docs. Without this, an unfilled `<<GITHUB_USERNAME>>` left "require Code Owner review" silently allowing all PRs.
- **`.gitleaks.toml` allowlist scope** — narrowed from blanket `\.agent-template/` exclusion to specific paths (`tests/*.bats`). Template ADRs, READMEs, and fixtures are now scanned.
- **`pre-push` silent no-op** without gitleaks — now hard-fails if gitleaks is missing. Bypass with `AGENT_OS_SKIP_GITLEAKS=1` (logged warning) for the rare valid case.
- **`branch-protection-audit` `gh issue create`** — explicit `GH_TOKEN=GITHUB_TOKEN` env var so the gh CLI can authenticate to open issues.
- **`update.sh` trashing user customizations** — `AGENTS.md` and `SECURITY.md` removed from the auto-update path. Treated as user-owned after first install.
- **Bash-fallback regex coverage** — added Clerk live/test key pattern + generic JWT pattern. Coverage gap with gitleaks config narrowed.

### Added

- **SHA-pinned GitHub Actions** — `actions/checkout` and `gitleaks/gitleaks-action` now reference exact SHAs, not floating major tags. Dependabot updates them.
- **Dependabot `groups`** for actions — single weekly PR for all action SHA bumps instead of per-action churn.
- This `CHANGELOG.md`.

### Known limitations (still on the v2 audit list, deferred)

- No `cosign` signing of release artifacts. Supply-chain integrity for the `install.sh` one-liner still depends on GitHub-account integrity.
- No automated `gh` script to configure branch protection — still a 12-step manual checklist in the README.
- No project-type variants (Next.js / Python / Rust) shipped.
- `update.sh` over curl-pipe still deadlocks on `read -rp` if no TTY (added detection-and-abort to the v2.2 plan).

### Upgrade from 2.0.0

```bash
bash scripts/agent-os-update.sh v2.1.0
```

`AGENTS.md` and `SECURITY.md` are no longer touched by `update.sh` — your customizations are safe.

## v2.0.0 — 2026-04-28

Major rewrite from v1. See PR #4.

- gitleaks integration (replaces homemade regex)
- 4 GitHub Actions workflows for server-side enforcement
- `commit-msg` and `pre-push` hooks
- Sessions log replaces single HANDOFF.md
- CODEOWNERS, PR template, dependabot, vulnerability disclosure
- Idempotent install / validate / update / uninstall scripts
- 14 bats tests for the pre-commit hook
- Weekly branch-protection audit

## v1.0.0 — 2026-04-27

Initial template extraction.
