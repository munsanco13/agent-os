# The Multi-AI Handover Playbook

**Subtitle:** How to run a real codebase across Claude Code, Codex, Cursor, and any AI assistant — without losing context, leaking secrets, or stepping on yourself.

**Audience:** solo founders and small teams shipping software with AI assistants in 2026.

**Reading time:** 25 minutes. Setup time: 30 minutes. Once set up, free forever.

---

## TL;DR

1. **The real pain:** every AI coding tool has a usage cap (or isn't the right model for the task), and switching tools means losing 30 minutes re-onboarding the new one.
2. **The fix:** install Agent OS into your project's repo (one command). It drops `AGENTS.md`, hooks, CI workflows, ADR scaffold into your repo. Files get committed.
3. **Daily use:** when one AI hits a wall, push your work-in-progress, open whichever AI tool still has runway, tell it to read `AGENTS.md` and the latest session log. Productive in ~2 minutes, not ~30.
4. **Bonus security layer:** gitleaks secret scanning, branch protection automation, Conventional Commits enforcement, cross-platform support — all enforced server-side via GitHub Actions.
5. **A handoff is just `git push` → `git clone` → "read AGENTS.md."** That's the entire protocol.

That's the whole system. Everything below is the why and the how.

## Stack-agnostic by design

Agent OS works for **any tech stack** — Node.js, Python, Rust, Go, Ruby, PHP, Elixir, Java, Deno, anything. The autonomous installer auto-detects your stack from your lockfiles + manifests:

| You have... | Detected as | Commands wired |
|---|---|---|
| `package.json` + `pnpm-lock.yaml` | Node.js / Next.js / pnpm | `pnpm install`, `pnpm dev`, `pnpm test`, `pnpm lint` |
| `package.json` + `yarn.lock` | Node.js / yarn | `yarn install`, `yarn dev`, etc. |
| `package.json` + `bun.lockb` | Node.js / bun | `bun install`, `bun dev`, etc. |
| `pyproject.toml` + `uv.lock` | Python / uv | `uv sync`, `uv run`, `uv run pytest` |
| `pyproject.toml` + `poetry.lock` | Python / Poetry | `poetry install`, `poetry run pytest` |
| `requirements.txt` | Python / pip | `pip install -r requirements.txt`, `pytest` |
| `Cargo.toml` | Rust | `cargo build`, `cargo run`, `cargo test`, `cargo clippy` |
| `go.mod` | Go | `go mod download`, `go run .`, `go test ./...` |
| `Gemfile` (with rails) | Ruby on Rails | `bundle install`, `bundle exec rails`, `bundle exec rspec` |
| `composer.json` (with laravel) | PHP / Laravel | `composer install`, `php -S localhost:8000`, `vendor/bin/phpunit` |
| `mix.exs` | Elixir / Phoenix | `mix deps.get`, `mix phx.server`, `mix test` |
| `pom.xml` | Java / Maven | `mvn install`, `mvn spring-boot:run`, `mvn test` |
| `build.gradle` | JVM / Gradle | `./gradlew build`, `./gradlew bootRun`, `./gradlew test` |
| `deno.json` | Deno | `deno install`, `deno run -A main.ts`, `deno test -A` |

Frameworks are detected from manifest contents — Next.js, Vite, Remix, NestJS, Express, Fastify, SvelteKit, Rails, Laravel, Symfony, Phoenix, Spring Boot, etc. The detection script is at `scripts/detect-stack.sh` and you can run it standalone:

```bash
bash scripts/detect-stack.sh
```

It outputs YAML you can paste into `bootstrap.yaml`.

If your stack isn't covered, the installer writes a `TODO`-marked `bootstrap.yaml` with blanks for you to fill. The rest of the system works identically — only the install/dev/test/lint commands change per stack.

---

## Part 1 — Why this exists

### The problem

You're 6 hours deep into a hard problem in **Claude Code**. The model is dialed in. You're 30 minutes from shipping a fix.

Then you see this:

> *"You've reached your weekly usage limit. Resets in 3 days."*

You have three bad options:

1. **Wait 3 days** — lose flow state, miss the deadline.
2. **Pay the API** — a serious agentic dev day on the API costs hundreds of dollars; the whole point of the subscription was to avoid this.
3. **Switch to a different AI** (Codex, Cursor, Cline, Aider — whichever still has runway) — but the new tool knows nothing about your project. You spend 30 minutes re-onboarding it.

Variations of the same wall:

- The model is just **wrong for this task** (different reasoning, different context window, different strengths). You need to switch tools mid-session.
- You **change machines** — work laptop, second device, different OS, different AI installed there.
- **Someone else picks the project up** — a teammate, a contractor, future-you in three months.

In every variation, the core friction is identical: switching tools means losing your place. Unless the project carries its own rules + status + conventions inside the repo itself.

### The insight

**Git is the only memory that survives all of this.** AI sessions die, plans live on the wrong machine, conversations get garbage-collected. Files in git survive everything.

So the system is:
- The repo carries its own rules (`AGENTS.md`).
- The repo carries its own status (`HANDOFF.md` or `docs/sessions/`).
- The repo carries its own enforcement (hooks + CI workflows).
- A handoff is `git push` followed by `git pull` on the other machine.

No external memory store, no AI-specific config files, no syncing services. Just git.

---

## Part 1.5 — Hand the playbook to an AI: zero-click install

Since v2.2.0, the playbook is engineered so that **handing this PDF to any AI assistant with bash + GitHub access lets the AI execute the entire install autonomously.**

### What the AI does on its own (no human input required)

- Detects your tech stack from your lockfiles (Node/Python/Rust/Go/etc.)
- Writes `bootstrap.yaml` with auto-detected stack commands + repo info
- Runs the base installer to drop template files
- Substitutes every `<<PLACEHOLDER>>` with real values
- Wires git hooks
- Creates an install branch, commits, pushes, opens a PR
- Auto-merges the PR
- **Configures GitHub branch protection via the API** (no UI clicks)
- Validates the install

### What you provide once

A single file called `.credentials.local` in the project root with at minimum:

```
GH_PAT=ghp_yourFineGrainedToken
```

The PAT needs these permissions on the target repo:
- `Administration: write` (for branch protection)
- `Contents: write` (for commits)
- `Pull requests: write`
- `Metadata: read`

Get one at https://github.com/settings/tokens?type=beta

Optionally:
```
VERCEL_TOKEN=...           # if you want auto-Vercel setup
SUPABASE_ACCESS_TOKEN=...  # if you want auto-Supabase setup
```

### The literal command to give the AI

Paste this verbatim:

```
I want to install Agent OS on this repo. I have a .credentials.local
file with my GH_PAT. Run this command and report what happens:

bash <(curl -fsSL https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/autonomous-install.sh)

If it pauses at a TODO in bootstrap.yaml, fill in reasonable values
based on the repo contents and re-run. Don't ask me unless something
truly ambiguous comes up.
```

### What you'll see at the end

The AI reports:
- "Detected stack: Python (uv) / FastAPI" (or whatever yours is)
- "Branch protection applied (HTTP 200)"
- "Validation passed."
- A PR URL to confirm the install commit landed in main

Total elapsed time: 2-5 minutes depending on network.

### What still needs you (rare)

- **Approving the install PR** if you have admin self-approval disabled in branch protection.
- **Manually adding env vars in Vercel dashboard** if `VERCEL_TOKEN` isn't provided. (With token: `vercel env add` is fully scriptable.)
- **Rotating any vendor secrets** that ended up exposed in earlier history.

That's it. Past those edge cases, the install is fully autonomous.

---

## Part 2 — The 5-minute install

This is the install for a NEW project. (For an existing project, see Part 3.)

### Step 1: Create the repo

```bash
mkdir my-new-project && cd my-new-project
git init -b main
```

### Step 2: Run the installer

```bash
AGENT_OS_REF=v2.3.0 bash <(curl -fsSL \
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/install.sh)
```

The installer:
- Verifies you're in a git repo
- Refuses to run if you have a competing hook manager (Husky, lefthook)
- Drops `AGENTS.md`, `SECURITY.md`, `.gitleaks.toml`, hooks, workflows, ADR scaffold, sessions log, scripts
- Wires `core.hooksPath = .githooks`
- Makes hooks executable AND persists the bit in git (so Windows works)
- Adds `.gitattributes` so line endings stay LF cross-platform
- Appends sensible entries to your `.gitignore`
- Writes `.agent-os-version` recording exactly what was installed

### Step 3: Customize the placeholders

Open `AGENTS.md`. Search for `<<` — those are project-specific tokens.

Fill these in with real values:

- `<<PROJECT_NAME>>` — e.g. "My App"
- `<<STACK>>` — e.g. "Next.js 16 + Supabase + Vercel"
- `<<DEPLOY_TARGET>>` — e.g. "Vercel auto-deploy from main"
- `<<DEV_COMMAND>>` — e.g. "pnpm dev"
- `<<TEST_COMMAND>>` — e.g. "pnpm test"
- `<<LINT_COMMAND>>` — e.g. "pnpm lint"
- `<<INSTALL_COMMAND>>` — e.g. "pnpm install"

Repeat for `.github/CODEOWNERS` (one token: `<<GITHUB_USERNAME>>`) and `.github/SECURITY.md` (`<<SECURITY_EMAIL>>`).

Run `bash scripts/agent-os-validate.sh` to confirm nothing's left blank.

### Step 4: Install gitleaks (recommended)

```bash
# macOS
brew install gitleaks

# Ubuntu / WSL2
sudo apt-get install gitleaks   # or download a release binary

# Windows: install Git for Windows + gitleaks via scoop or chocolatey
scoop install gitleaks
```

The pre-commit hook works without gitleaks (falls back to a small regex set), but gitleaks gives you 150+ patterns vs ~10. Strongly recommended. The pre-push hook hard-fails without it (with an explicit bypass flag for the rare valid case).

### Step 5: First commit + push

```bash
git checkout -b chore/install-agent-os
git add .
git commit -m "chore: install Agent OS v2.3.0"
git push -u origin chore/install-agent-os
```

Open a PR on GitHub. The CI workflows will run on the PR — confirm they go green.

### Step 6: Configure branch protection (the most important step)

This is the step most people skip. Don't skip it.

GitHub repo → **Settings** → **Branches** → **Add branch protection rule** → branch name pattern: `main`

Check these boxes:
- ✅ **Require a pull request before merging**
  - ✅ Require approvals: 1
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ✅ Require review from Code Owners
- ✅ **Require status checks to pass before merging**
  - Search for and check: `secret-scan`, `large-files`, `no-direct-pushes`, `hooks-integrity`, `placeholder-lint`, `pr-title`, `pr-body`
- ✅ **Require branches to be up to date before merging**
- ✅ **Require conversation resolution before merging**
- ✅ **Require linear history**
- ❌ **Do not allow force pushes**
- ❌ **Do not allow deletions**

Save the rule. From this moment forward, no one can push directly to main.

### Step 7: Merge your install PR

Approve your own PR (since you're the only one), confirm CI is green, click Merge. The `chore/install-agent-os` branch is now in `main`.

You're done. The system is live.

---

## Part 3 — Adding Agent OS to an EXISTING project

Same as Part 2, but skip Step 1 (you already have a repo).

If you have an existing `.gitignore`, `pre-commit` hook, or `docs/decisions/`, the installer skips them — never overwrites. After install, manually merge any conflicts (rare).

If you have **Husky** or **lefthook** already wired, the installer refuses to run. Pick one approach:
- Remove the existing hook manager → re-run installer.
- Manually merge `.githooks/pre-commit` from this repo into your existing config.

---

## Part 4 — The handover dance (the actual point of this template)

You've shipped your project. Now you want to put down your laptop and pick up at a different machine — or hand the work to a different AI.

### Before you stop work (10 seconds)

```bash
git status                    # working tree clean?
git push origin <branch>      # all WIP committed and pushed?
```

If you have uncommitted work, decide: commit it (even as `wip:` if Conventional Commits enforces) or stash it. Don't leave dangling work undocumented.

### Update the session log (1 minute)

```bash
cp docs/sessions/_template.md docs/sessions/$(date +%Y-%m-%d)-<your-name>.md
# edit it — branch, what done, what next, sharp edges
git add docs/sessions/*.md
git commit -m "docs: session log $(date +%Y-%m-%d)"
git push
```

### Pick up on the new machine (2 minutes)

If the new machine has the repo cloned:
```bash
git fetch && git checkout <branch> && git pull
bash scripts/agent-os-validate.sh    # confirms hooks still wired correctly
<<INSTALL_COMMAND>>                  # in case deps changed
```

If the new machine is fresh, see Part 5 (cross-platform setup).

### Brief the AI on the new machine

Open Codex / Claude Code / Cursor. First message:

```
Read these files in order and summarize what you learned:

1. /AGENTS.md
2. /HANDOFF.md (or the most recent file in /docs/sessions/)
3. The output of: git log -10 --stat
4. Any new ADRs in /docs/decisions/

Then write a status report:
- What you understand the project to be
- What was just done last session
- What's pending
- The rules you'll follow

Don't change code yet.
```

The AI reads. The AI summarizes. You verify it got it right. You give it a real task.

The full state transfer takes under 5 minutes.

---

## Part 5 — Cross-platform handoff (Mac ↔ Windows ↔ Linux)

The classic "works on my Mac, broken on PC" cause is line endings. Bash hooks fail with `$'\r': command not found` if checked out as CRLF on Windows.

Agent OS handles this with:

1. **`.gitattributes`** at the repo root forces `eol=lf` for all hooks, scripts, and config.
2. **`git update-index --chmod=+x`** during install so hook executable bits travel in git's tree, not the filesystem.
3. **Platform detection in `install.sh`** that warns + fixes `core.autocrlf` on Windows.

### macOS

Works out of the box. Bash 3.2 (stock) is supported as of v2.1.0.

### Linux

Works out of the box.

### Windows — choose ONE

**Option A (recommended): WSL2 + Ubuntu.** Do all your git work inside WSL. Hooks run identically to Linux. Microsoft's setup: https://learn.microsoft.com/en-us/windows/wsl/install

**Option B: Git for Windows + Git Bash.** Bundled when you install Git for Windows. Always run `git commit` operations from Git Bash (not cmd.exe / PowerShell) so the hooks fire with bash on PATH. Run once after first clone:
```bash
git config --global core.autocrlf input
```

**Native cmd.exe / PowerShell are NOT supported.** The hooks need bash. Pushes from native Windows still get caught server-side by GitHub Actions, but you lose the fast local feedback loop.

### Validating cross-platform after clone

After cloning on any new machine:
```bash
bash scripts/agent-os-validate.sh
```

That checks: hooks present, hooks executable, hooks have LF line endings, `core.hooksPath` wired, gitleaks installed, no unfilled placeholders.

---

## Part 6 — The security model

### Local hooks (advisory — fast feedback)

| Hook | What it does |
|---|---|
| `pre-commit` | Refuses `.env*`, common credential filenames, files >5MB; runs gitleaks on staged diff; refuses direct commits to main |
| `commit-msg` | Enforces Conventional Commits subject format (`type(scope): description`) |
| `pre-push` | Refuses force-push to main; runs gitleaks on the full range about to be pushed |

A motivated developer can bypass all of this with `--no-verify`. That's fine — we have a second layer.

### Server-side workflows (authoritative)

GitHub Actions re-run all the same checks on every push and PR. **CI failure is fatal — no bypass.**

| Workflow | What it does |
|---|---|
| `security.yml` → `secret-scan` | gitleaks against full history, every push and PR |
| `security.yml` → `large-files` | refuses anything > 5MB |
| `security.yml` → `no-direct-pushes` | confirms every commit on main came from a merged PR |
| `security.yml` → `hooks-integrity` | verifies hooks exist + executable in tree |
| `security.yml` → `placeholder-lint` | refuses unfilled `<<PLACEHOLDER>>` tokens (including in CODEOWNERS) |
| `pr-checks.yml` → `pr-title` | Conventional Commits on PR title |
| `pr-checks.yml` → `pr-body` | requires `## Summary` and `## Test plan` sections |
| `branch-protection-audit.yml` | weekly cron; opens an issue if main protection is removed |
| `hook-tests.yml` | runs the bats test suite when hooks change |

Combined with branch protection (Part 2 Step 6), the only way to get code into main is:
1. Open a PR.
2. Pass all required status checks.
3. Get a CODEOWNERS approval.
4. Merge linearly.

No way around it without admin override. Admin overrides are logged in the GitHub audit log.

### What this defends against

- ✅ Accidental secret commits (developer or AI)
- ✅ Force-push to main wiping history
- ✅ Direct commits to main
- ✅ `--no-verify` bypass
- ✅ Large binaries bloating the repo
- ✅ Vulnerable dependencies (Dependabot weekly)
- ✅ Branch protection silently removed (weekly audit)

### What this does NOT defend against

- Social engineering against you (use 2FA + hardware keys on GitHub)
- Compromise of an upstream dependency you depend on
- Compromise of GitHub itself
- Insider threat with admin access

---

## Part 7 — Daily workflow

### Starting work

```bash
git fetch && git pull
git checkout -b feat/your-topic
```

Read the latest session log. Read any new ADRs. Begin.

### Working

Commit early, commit often. Each commit gets a Conventional Commits message:

```
feat(auth): add Google OAuth fallback

Users can now sign in with Google when their email auth bounces.
Falls back to email if Google is unavailable.
```

The `commit-msg` hook validates the format. If it rejects, fix the message.

### Pushing

```bash
git push -u origin feat/your-topic
```

The `pre-push` hook runs gitleaks on the range. If anything looks like a secret, it blocks.

### Opening a PR

Use the template (auto-populated). Fill in:
- Summary
- Test plan
- Security checklist (tick the boxes)

The `pr-checks` workflow validates the title format and required sections.

### Merging

Wait for CI green + Code Owner approval. Then:
- Merge button (creates a merge commit), or
- Squash and merge (keeps main linear)

Either works — the `no-direct-pushes` workflow handles both.

### Recording a decision

If you made a non-obvious choice (library pick, architectural pattern), copy `docs/decisions/0000-template.md` to `0005-whatever.md` (next number), fill in the sections, commit it.

Future you (or future AI) reads it before re-litigating.

### Stopping work

See Part 4. 30 seconds total.

---

## Part 8 — Customizing for your project

### One-off conventions

If your project has a unique rule ("we don't use Redux, we use Zustand", "all DB calls go through Drizzle"), add it to the `## Project-specific notes` section at the bottom of `AGENTS.md`. Every AI reads that.

### Multi-package monorepos

If you have multiple apps (`apps/web`, `apps/worker`, `packages/shared`), put a sub-`CLAUDE.md` or sub-`AGENTS.md` in each app folder with app-specific rules. Modern AI tools read both root and nested files.

### Different test commands per package

Update the `<<TEST_COMMAND>>` placeholder in AGENTS.md to a command that runs all tests (`pnpm -r test`), then mention per-package overrides in the project-specific notes.

### Different deploy targets

Update `<<DEPLOY_TARGET>>`. If you have staging + production, document both ("`main` → production via Vercel; `staging` → preview via Vercel").

---

## Part 9 — Troubleshooting

### "I just installed and the pre-commit hook isn't firing"

```bash
git config --get core.hooksPath
```

If empty, run:
```bash
git config core.hooksPath .githooks
```

Most likely cause on a fresh clone — `core.hooksPath` isn't tracked in git, so each clone needs it set once. The installer does it, but if you cloned without re-running install, it's not wired.

### "The hook fails with $'\r': command not found"

Line endings are CRLF. You're on Windows or your `.gitattributes` isn't there.

```bash
# Quick fix:
dos2unix .githooks/pre-commit .githooks/commit-msg .githooks/pre-push

# Permanent fix:
git config --global core.autocrlf input
# Then re-clone, or:
git rm --cached -r .
git reset --hard
```

### "gitleaks isn't installed but my push went through anyway"

The pre-push hook hard-fails without gitleaks (since v2.1.0). If your push went through:
- You're on an old install — run `bash scripts/agent-os-update.sh v2.3.0`.
- You set `AGENT_OS_SKIP_GITLEAKS=1`. Re-think that.
- Server-side CI will still scan. Don't rely on bypass.

### "CI fails on `placeholder-lint`"

Run:
```bash
grep -rE '<<[A-Z_]+>>' AGENTS.md SECURITY.md .github/CODEOWNERS .github/SECURITY.md HANDOFF.md
```

Anything matching needs to be filled in. The most-missed one is `<<GITHUB_USERNAME>>` in CODEOWNERS — if left, branch protection silently allows everything because the named owner doesn't exist.

### "Codex / Claude can't find AGENTS.md"

They can. You need to TELL them to read it. AI tools don't auto-load AGENTS.md the way docs imply (some do, but don't rely on it). Always include "read /AGENTS.md and /HANDOFF.md first" in your kickoff prompt.

### "I committed a secret"

In order:
1. **Rotate the secret at the vendor immediately.** It's compromised now, even if you noticed in 30 seconds. Anyone who cloned your repo since the commit has it.
2. Remove from git history with `git filter-repo` (preferred) or BFG.
3. Force-push (with explicit teammate approval).
4. Notify everyone who cloned to delete and re-clone.
5. Open an ADR documenting the leak + the prevention going forward.

The pre-commit + pre-push + CI gitleaks scans are designed to catch this before step 1 is needed. If they didn't, treat it as a vulnerability and update the gitleaks config to catch it next time.

---

## Part 10 — A typical day with Agent OS installed

Here's what a representative working day looks like once Agent OS is in your project. The exact details vary, but the shape is the same.

1. **Morning, MacBook:** A developer notices production secrets sitting in `apps/web/.vercel.bak/.env.production.local` — pulled locally by `vercel env pull`, never committed, but on disk. They ask their AI if it's safe to commit. The AI refuses, identifies the file as containing real secrets, walks through verifying canonical copies in the deploy provider, then deletes the local backup. The pre-commit hook would have caught this anyway, but the AI catches it earlier.

2. **Late morning:** While reviewing changes, the AI writes a separate handoff document for an unrelated product idea that came up in conversation. It deliberately leaves the file untracked so it doesn't pollute this project's repo — destined for a different repo. Clean separation.

3. **Mid-afternoon:** Production deploy fails. Symptoms look like an out-of-memory error at first glance. Diagnosis on the build log: not OOM — duration was 33 seconds (OOMs run minutes). The Next.js build was trying to prerender an auth page that calls `createClient()` at render time, which needs runtime env vars unavailable at build. Fix: `export const dynamic = "force-dynamic"` in the root layout. Feature branch + PR + merge — Agent OS's `no-direct-pushes` rule means no possibility of someone hot-patching main.

4. **Afternoon:** Discovery that there are two Vercel projects pointing at the same GitHub repo — one stale, one canonical. Env vars were added to the wrong one. Fix: migrate env vars to the canonical project, mark sensitive vars as `Sensitive` (Production + Preview only, not Development), delete the stale project.

5. **Evening:** Time to hand the project to a different AI on a different machine. Update `HANDOFF.md` with what was done today + what's pending. Push. The next AI clones, reads `AGENTS.md` + `HANDOFF.md` + the last 10 commits, runs `bash scripts/agent-os-validate.sh`, pulls env vars from the deploy provider, and is productive within 5 minutes.

That's the system working as designed: every checkpoint enforced, every decision documented, every handoff seamless.

---

## Part 10.5 — How Agent OS compares to peer tools

Agent OS isn't trying to do everything. It owns one slice — **documentation + enforcement + handoff for sequential multi-AI development** — and refuses to bloat into adjacent problems. Here's where the line is.

### What Agent OS does that nothing else does

- ✅ Server-side CI enforcement (gitleaks-action + branch protection automation via `gh api`)
- ✅ Stack-agnostic auto-detection (Node / Python / Rust / Go / Ruby / PHP / Elixir / Java / Deno + framework sniffing)
- ✅ Self-contained PDF handoff with embedded install commands + URLs
- ✅ Cross-platform Mac↔Windows handling (`.gitattributes`, exec-bit-in-git, platform-aware installer)
- ✅ Autonomous installer that configures GitHub branch protection via API
- ✅ ADR + sessions log pattern for multi-machine continuity
- ✅ Threat-modeled SECURITY.md with explicit defended/not-defended scope
- ✅ Aliases for every major AI tool (CLAUDE.md, .cursorrules, .clinerules, CONVENTIONS.md, .continuerules) → all symlinked to AGENTS.md
- ✅ `import.sh` ingests legacy single-tool config files and merges into AGENTS.md

### When to use something else

Agent OS doesn't compete with these — they solve different problems. If you need any of these, use the right tool:

| Problem | Use this | Not us |
|---|---|---|
| Run multiple AI agents in parallel with inter-agent messaging | [bfly123/claude_codex_bridge (CCB)](https://github.com/bfly123/claude_codex_bridge) — terminal split-pane runtime, `/ask reviewer` cross-agent comms | We're sequential, not parallel |
| Desktop GUI for a single AI agent (OpenCode) | [itswendell/palot](https://github.com/itswendell/palot) — Electron app with diff viewer, scheduled runs | We don't ship a GUI |
| Provider-agnostic Python SDK to call any LLM | [mozilla-ai/any-llm](https://github.com/mozilla-ai/any-llm) — unified API across OpenAI, Anthropic, Mistral, Ollama | Different layer entirely (app code, not workflow) |
| Migrate Claude Code skills/agents to Codex's `.codex/skills/` format | [zuharz/ccode-to-codex](https://github.com/zuharz/ccode-to-codex) — Python migration tool | We merge into AGENTS.md instead of forking per-tool formats |
| VS Code symlink between AGENTS.md and CLAUDE.md only | [kamilio/agents-md-vscode-extension](https://github.com/kamilio/agents-md-vscode-extension) — minimal extension | We do this in `install.sh` for 5+ tools, no VS Code dependency |

### Composability

The peer tools above are complementary, not exclusive:

- Use **Agent OS** for the project's rules + enforcement + handoff continuity.
- Use **CCB** *inside* an Agent-OS-managed project when you need parallel agents on the same codebase (`/ask reviewer "check the PR I just opened"`).
- Use **palot** as your editor on top of an Agent-OS-managed project.
- Use **any-llm** in your application code if it calls LLMs at runtime.
- Use **ccode-to-codex** for one-shot format migration if you have a heavy investment in Codex skill packages.

The point of Agent OS is to be the **base layer** every other tool sits on, not to replace them.

---

## Part 11 — When to NOT use this

This template is overkill for:

- One-file scripts and prototypes you'll throw away in a week.
- Projects with a single contributor who never switches machines or AIs.
- Repos that already have aggressive security tooling (Snyk, Datadog, GitHub Advanced Security with custom secret scanners) — you'd be duplicating coverage.
- Compliance-regulated projects (SOC 2, HIPAA, PCI) — those need a dedicated security review, not a starter template.

For everything in between — solo founder, small team, AI-assisted, multi-machine, secrets-bearing — it's the right amount of structure.

---

## Part 12 — Future versions

| Version | Status | What's new |
|---|---|---|
| v1.0.0 | shipped | Initial template, regex pre-commit |
| v2.0.0 | shipped | gitleaks, CI workflows, sessions log, hooks |
| v2.1.0 | shipped | bash 3.2 fix, JWT regex, squash-merge fix, CRLF/Windows handling, CHANGELOG |
| v2.2.0 | shipped | autonomous install + stack auto-detection (Node / Python / Rust / Go / Ruby / PHP / Elixir / Java / Deno) |
| v2.3.0 | shipped | multi-tool symlinks (CLAUDE.md / .cursorrules / .clinerules / .continuerules / CONVENTIONS.md), legacy config import, peer comparison |
| v2.4.0 | planned | cosign signing of releases, automated branch-protection setup via `gh` for non-PAT users (GitHub OIDC), project-type variants (Next/Python/Rust starters) |
| v3.0.0 | future | SLSA Level 3 provenance, tamper-detection workflow, policy-as-code |

---

## Appendix A — Filesystem map

```
.
├── AGENTS.md                                # universal contract
├── SECURITY.md                              # threat model + hard rules
├── HANDOFF.md                               # rolling status (or use docs/sessions/)
├── .gitleaks.toml                           # secret scanner config
├── .gitattributes                           # line-ending normalization
├── .agent-os-version                        # what version is installed (do not delete)
│
├── docs/
│   ├── sessions/
│   │   ├── README.md
│   │   ├── _template.md
│   │   └── YYYY-MM-DD-<author>.md           # per-session entries (chronological)
│   └── decisions/
│       ├── README.md                        # ADR index
│       ├── 0000-template.md
│       ├── 0001-multi-ai-continuity.md
│       ├── 0002-secret-scanning-with-gitleaks.md
│       ├── 0003-server-side-enforcement.md
│       └── 0004-cross-platform-handoff.md
│
├── .githooks/
│   ├── pre-commit                            # local fast-feedback
│   ├── commit-msg                            # Conventional Commits enforcement
│   └── pre-push                              # final local gate
│
├── .github/
│   ├── workflows/
│   │   ├── security.yml                      # AUTHORITATIVE security gates
│   │   ├── pr-checks.yml                     # PR title/body validation
│   │   ├── branch-protection-audit.yml       # weekly drift detection
│   │   └── hook-tests.yml                    # bats tests
│   ├── CODEOWNERS                            # required reviewers
│   ├── pull_request_template.md              # forces structure
│   ├── dependabot.yml                        # weekly dep updates
│   └── SECURITY.md                           # vulnerability disclosure
│
├── scripts/
│   ├── agent-os-validate.sh                  # check install integrity
│   ├── agent-os-update.sh                    # pull newer template
│   └── agent-os-uninstall.sh                 # reverse install
│
└── tests/
    └── pre-commit.bats                       # hook tests
```

---

## Appendix B — Commands reference card

```bash
# Validate install
bash scripts/agent-os-validate.sh

# Update to latest template version
bash scripts/agent-os-update.sh
bash scripts/agent-os-update.sh v2.3.0       # pin to specific version

# Uninstall
bash scripts/agent-os-uninstall.sh

# Pull env vars from Vercel
cd apps/web && vercel link && vercel env pull .env.local

# Override main-branch commit refusal (for merge commits — rare)
AGENT_OS_ALLOW_MAIN_COMMIT=1 git commit ...

# Skip gitleaks pre-push (rare, you should know why)
AGENT_OS_SKIP_GITLEAKS=1 git push

# Skip commit-msg format check (emergencies only)
AGENT_OS_SKIP_COMMIT_MSG=1 git commit -m "anything"

# Bootstrap a new AI session
echo "Read AGENTS.md, HANDOFF.md, latest docs/sessions/ entry, and run git log -10 --stat. Summarize."
```

---

## Appendix C — The kickoff prompt to give any AI

Copy-paste this verbatim when you open a new AI session in this repo:

```
Before doing anything else, read these files in order and summarize what you learned:

1. /AGENTS.md
2. The most recent file in /docs/sessions/  (or /HANDOFF.md if sessions/ doesn't exist)
3. /SECURITY.md (skim the hard rules section)
4. Any new ADRs in /docs/decisions/ since the last session
5. Run: git log -10 --stat

Then write a status report:
- What the project is
- What was done in the last session
- What's pending or blocked
- The rules you'll follow (especially: feature branches, no direct main commits, Conventional Commits, gitleaks if installed, no --no-verify)

Do not change code or run destructive commands until I confirm your understanding is correct.
```

That prompt is the single most important thing in this entire playbook. Use it every time.

---

## Appendix D — Complete file manifest (everything an AI needs)

**Every file the autonomous installer touches lives at stable URLs pinned to `v2.2.0`. Hand this PDF to any AI with bash + curl — the AI has every link it needs to bootstrap a project end-to-end.**

### The "give this to your AI" master prompt

Copy this exact text. Pasted into Claude / Codex / Cursor / any AI assistant with shell access, it triggers a fully autonomous install:

```
Install Agent OS v2.2.0 in this repo.

Step 1 — Create .credentials.local in the repo root (gitignored automatically):
  GH_PAT=<my fine-grained PAT with Administration:write, Contents:write, PRs:write>
  Get one at https://github.com/settings/tokens?type=beta

Step 2 — Run the autonomous installer:
  bash <(curl -fsSL https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/autonomous-install.sh)

The installer will:
- Auto-detect my tech stack (Node/Python/Rust/Go/Ruby/PHP/Elixir/Java/Deno)
- Generate bootstrap.yaml from the detection + my git config
- Drop all template files (AGENTS.md, SECURITY.md, hooks, CI workflows, ADRs)
- Substitute every <<PLACEHOLDER>> with values from bootstrap.yaml
- Wire git hooks (core.hooksPath = .githooks)
- Commit, push, open + auto-merge an install PR
- Configure GitHub branch protection via gh api
- Run validate.sh

Report when done. Don't ask me unless something is genuinely ambiguous.
```

### Canonical install entrypoints

```
Autonomous installer (single command, full automation):
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/autonomous-install.sh

Manual installer (if you don't have a GH_PAT, drops files only):
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/install.sh

Stack detector (standalone, prints YAML):
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/detect-stack.sh

Validator:
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/validate.sh

Updater:
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/update.sh

Uninstaller:
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/uninstall.sh

PDF rebuilder:
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/build-pdf.py
```

### Configuration files (inline — copy directly)

These two files are what the user fills in. They're short, so the PDF includes them verbatim. **An AI handed this PDF can write them straight from this appendix.**

#### `bootstrap.example.yaml` (copy to `bootstrap.yaml`)

```yaml
# Agent OS bootstrap config — fill once, AI does the rest.

project:
  name: "My App"
  description: "Short description of what this project does"
  github_owner: "your-github-username"
  github_repo:  "your-repo-name"
  main_branch:  "main"

stack:
  description: "Next.js + Supabase + Vercel"
  install_command: "pnpm install"
  dev_command:     "pnpm dev"
  test_command:    "pnpm test"
  lint_command:    "pnpm lint"

deploy:
  provider: "vercel"
  vercel_team:    "your-team-slug"
  vercel_project: "your-project-name"
  production_branch: "main"

maintainer:
  name:   "Your Name"
  email:  "you@example.com"
  github: "@your-github-username"

env_vars:
  - name: NEXT_PUBLIC_SUPABASE_URL
    sensitivity: public
  - name: NEXT_PUBLIC_SUPABASE_ANON_KEY
    sensitivity: public
  - name: SUPABASE_SERVICE_ROLE_KEY
    sensitivity: sensitive

branch_protection:
  required_reviews: 1
  require_codeowner_review: true
  require_status_checks:
    - secret-scan
    - large-files
    - no-direct-pushes
    - hooks-integrity
    - placeholder-lint
    - pr-title
    - pr-body
  require_linear_history: true
  allow_force_pushes: false
  allow_deletions: false
```

#### `.credentials.example` (copy to `.credentials.local` — gitignored)

```
# GitHub fine-grained PAT — required.
# https://github.com/settings/tokens?type=beta
# Permissions: Administration:write, Contents:write, Pull requests:write, Metadata:read
GH_PAT=

# Optional. Only if your bootstrap.yaml uses provider=vercel.
# https://vercel.com/account/tokens
VERCEL_TOKEN=

# Optional. Only for auto-creation of Supabase projects.
# https://supabase.com/dashboard/account/tokens
SUPABASE_ACCESS_TOKEN=
```

### Template files (URLs — pinned to v2.2.0)

These are dropped into your project by the installer. The AI doesn't need to read them ahead of time — but the URLs are here so any AI can fetch them on demand for inspection or manual install.

```
Documentation:
  AGENTS.md           https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/AGENTS.md
  SECURITY.md         https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/SECURITY.md
  README.md           https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/README.md
  PLAYBOOK.md         https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/PLAYBOOK.md
  QUICKSTART.md       https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/QUICKSTART.md
  CHANGELOG.md        https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/CHANGELOG.md
  INSTALL.md          https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/INSTALL.md
  CONTRIBUTING.md     https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/CONTRIBUTING.md

Configuration:
  .gitleaks.toml      https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.gitleaks.toml
  .gitattributes      https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.gitattributes
  .gitignore-additions https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.gitignore-additions
  VERSION             https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/VERSION

Git hooks (.githooks/):
  pre-commit          https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.githooks/pre-commit
  commit-msg          https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.githooks/commit-msg
  pre-push            https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.githooks/pre-push

GitHub Actions workflows (.github/workflows/):
  security.yml                  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/workflows/security.yml
  pr-checks.yml                 https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/workflows/pr-checks.yml
  branch-protection-audit.yml   https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/workflows/branch-protection-audit.yml
  hook-tests.yml                https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/workflows/hook-tests.yml

GitHub repo files (.github/):
  CODEOWNERS                    https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/CODEOWNERS
  pull_request_template.md      https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/pull_request_template.md
  dependabot.yml                https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/dependabot.yml
  SECURITY.md                   https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.github/SECURITY.md

ADR templates (docs/decisions/):
  README.md                              https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/decisions/README.md
  0000-template.md                       https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/decisions/0000-template.md
  0001-multi-ai-continuity.md            https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/decisions/0001-multi-ai-continuity.md
  0002-secret-scanning-with-gitleaks.md  https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/decisions/0002-secret-scanning-with-gitleaks.md
  0003-server-side-enforcement.md        https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/decisions/0003-server-side-enforcement.md
  0004-cross-platform-handoff.md         https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/decisions/0004-cross-platform-handoff.md

Sessions log (docs/sessions/):
  README.md       https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/sessions/README.md
  _template.md    https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/docs/sessions/_template.md

Configuration templates:
  bootstrap.example.yaml    https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/bootstrap.example.yaml
  .credentials.example      https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/.credentials.example

Tests:
  pre-commit.bats   https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/tests/pre-commit.bats
```

### Browse the entire template

If the AI wants to see everything before installing:

```
Source tree:        https://github.com/munsanco13/agent-os/tree/v2.2.0
Tarball:            https://github.com/munsanco13/agent-os/archive/refs/tags/v2.2.0.tar.gz
Zip:                https://github.com/munsanco13/agent-os/archive/refs/tags/v2.2.0.zip
```

### Verify what was installed

After install, the file `.agent-os-version` in the project root records exactly what was installed:

```
version: 2.2.0
ref: v2.2.0
installed_sha: <commit SHA>
installed_at: 2026-04-29T...Z
```

If anything is ever in doubt, run:

```
bash scripts/agent-os-validate.sh
```

It checks file presence, hook permissions, line endings, gitleaks installation, unfilled placeholders, version stamp.

---

**End of playbook.**

If you find a bug, send a PR. If you find a security issue, see `.github/SECURITY.md` for the disclosure process.
