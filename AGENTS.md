# AGENTS.md — Universal AI Contract

> **Read this first.** Every AI agent (Claude Code, Codex, Cursor, Cline, Aider, GPT-5.5, local models) working in this repo reads this file before doing anything else. Both humans and AIs treat it as binding.

## Project: <<PROJECT_NAME>>

- **Stack:** <<STACK>>
- **Deploy:** <<DEPLOY_TARGET>>
- **Dev command:** `<<DEV_COMMAND>>`
- **Test command:** `<<TEST_COMMAND>>`
- **Lint command:** `<<LINT_COMMAND>>`
- **Install command:** `<<INSTALL_COMMAND>>`
- **Main branch:** auto-detected from git; configurable via `.agent-os.conf`
- **Agent OS version:** see `.agent-os-version`

## Bootstrap checklist (every fresh session)

Run these in order before making changes:

1. `git fetch && git status` — confirm branch + clean tree.
2. Read **last 3 entries** in `docs/sessions/` (sorted by filename — date-prefixed).
3. `git log -10 --stat` — what changed recently.
4. List new ADRs in `docs/decisions/` since your last session.
5. `<<INSTALL_COMMAND>>` — in case dependencies changed.
6. Re-pull env vars if needed (e.g. `vercel env pull`).
7. Confirm hooks are wired: `git config --get core.hooksPath` should output `.githooks`. If not: run `bash .agent-template/install.sh .` to fix.
8. Confirm `gitleaks` is installed: `gitleaks version`. If absent, install (`brew install gitleaks` on macOS) for the strongest local defense.

If any step surfaces unexpected state, STOP and ask the human before proceeding.

## Hard rules (SECURITY-CRITICAL — never violate)

These are enforced by `.githooks/pre-commit`, `.githooks/pre-push`, and the GitHub Actions workflows in `.github/workflows/`. Server-side checks run on every push and PR — bypassing local hooks just delays the failure.

1. **Never commit secrets.** No `.env*` (except `.env.example`), no API keys, no tokens, no service-role keys, no private keys, no `credentials.json`. gitleaks scans the staged diff locally and the full history server-side.
2. **Never commit directly to the main branch.** Always feature-branch + PR. Even one-line fixes. Server-side workflow `no-direct-pushes` enforces this.
3. **Never use `--no-verify`, `--no-gpg-sign`, or force-push to a protected branch** without explicit human approval. CI re-runs the same checks server-side, so bypassing accomplishes nothing except delaying the failure.
4. **Never share secret values** in chat / logs / commit messages / external tools. Reference by name only.
5. **Never delete or rewrite git history** on shared branches.
6. **Never disable hooks or workflows** (`git config --unset core.hooksPath`, deleting `.githooks/`, deleting workflows in `.github/workflows/`).
7. **Never run destructive commands** (`rm -rf` outside scoped temp dirs, `DROP TABLE`, `DELETE FROM ... WHERE ...` against any non-local DB, `git reset --hard origin/main`) without explicit per-action human approval.

## Soft conventions

- **Branch naming:** `feat/<topic>`, `fix/<topic>`, `chore/<topic>`, `docs/<topic>`, `refactor/<topic>`, `security/<topic>`.
- **Commit format:** Conventional Commits — `type(scope)?: subject` ≤72 chars. Enforced by `.githooks/commit-msg` and `pr-checks.yml`.
- **PRs:** small + focused. One logical change per PR. Use the template in `.github/pull_request_template.md` (Summary + Test plan are required).
- **Tests:** if you change logic, add or update a test. If a test you write fails, fix the code or the test, don't comment it out.
- **Comments:** explain *why*, not *what*.
- **Dependencies:** prefer existing libs already in the project. Non-trivial new dep requires an ADR.

## Multi-AI handoff protocol

This repo is shared across multiple AI assistants. Continuity is via git, not external memory.

**Before stopping work:**
1. Working tree clean OR all WIP committed to a feature branch.
2. `git push origin <branch>`.
3. Create a new session log: `docs/sessions/YYYY-MM-DD-<slug>.md` from `_template.md`. Fill: branch, what was done, what's next, sharp edges, new ADRs.
4. Commit + push the session log.

**Starting work (any AI):**
1. Run the bootstrap checklist above.
2. Read the last 3 session logs in `docs/sessions/`.
3. Confirm branch matches the most-recent session's `Pending` line.
4. Begin work. Create your own new session file when you start (don't reuse someone else's).

## Decision-making

- Non-obvious choices (library, architectural pattern, vendor) require an ADR in `docs/decisions/`.
- Use the template at `docs/decisions/0000-template.md`.
- Number sequentially, append to the index in `docs/decisions/README.md`.
- Status flow: `proposed` → `accepted` → `superseded by NNNN` → `deprecated`.

## Verification before declaring "done"

Before telling the human "this is fixed" or "this is shipped":

1. Read your own diff. Confirm the code path actually executes the way you intended.
2. Lint / types pass: `<<LINT_COMMAND>>`.
3. Tests pass: `<<TEST_COMMAND>>`.
4. The user-facing flow has been actually exercised — load the page, hit the endpoint, click the button. Don't claim a fix you didn't observe working.
5. No new secrets, debug logs, `console.log`, or commented-out code in the diff.
6. CI status checks pass on the PR (gitleaks, large-files, no-direct-pushes, hooks-integrity, placeholder-lint, pr-title, pr-body).

## When you (the AI) are uncertain

Ask. Do not guess on:
- Auth / billing / data-deletion behavior.
- Production deploy steps.
- Anything labeled `<<...>>` placeholder in this file.
- Anything in `SECURITY.md`.

## Tool / agent specifics

### Claude Code
- Plan mode is encouraged for multi-file refactors.
- Plans live in `~/.claude/plans/` (local-only, not in git).
- Copy plan substance into a session log or ADR if it should survive.

### OpenAI Codex
- Reads this file as the project context root.
- Use feature branches; do not push directly to main.

### Cursor / Cline / Aider / others
- Same rules. Point your tool's project-rules file at this `AGENTS.md`.

## Cross-platform handoff (Mac ↔ Windows ↔ Linux)

This project's hooks are bash scripts. They work natively on macOS and Linux. **On Windows, you MUST use one of:**

- **WSL2 + Ubuntu** (recommended). Do all git operations inside WSL. Hooks work identically to Linux.
- **Git for Windows** (which bundles Git Bash). Run `git config --global core.autocrlf input` once, then always use Git Bash for `git commit` operations.

Native Windows cmd.exe / PowerShell is **not supported** — the hooks won't fire and your push will only be caught server-side.

`.gitattributes` at the repo root forces LF line endings for all hooks, scripts, markdown, and config — defeats CRLF corruption regardless of OS settings. See `docs/decisions/0004-cross-platform-handoff.md`.

When picking up the project on a new machine, run `bash scripts/agent-os-validate.sh` to confirm hooks have correct line endings + executable bits + `core.hooksPath` wired.

## Project-specific notes

(Conventions unique to this codebase: directory layout, deploy gotchas, "module X is being rewritten so don't touch", etc.)

- _placeholder — fill in_
