<div align="center">

<img src="docs/images/hero.png" alt="Agent OS — multi-AI handover" width="100%" />

# Agent OS

### **Hit your AI usage limit? Keep building in another tool — without losing your place.**

**Drop-in template for switching between any AI coding tools mid-project. When one hits its cap, fails, or just isn't the right fit for the task, the next one picks up exactly where you left off in under 2 minutes. Works across Claude Code, Codex, Cursor, Cline, Aider, Continue.dev, and any AI tool that reads markdown.**

[![Version](https://img.shields.io/github/v/tag/munsanco13/agent-os?label=version&color=2563eb)](https://github.com/munsanco13/agent-os/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Stars](https://img.shields.io/github/stars/munsanco13/agent-os?style=social)](https://github.com/munsanco13/agent-os/stargazers)
[![Issues](https://img.shields.io/github/issues/munsanco13/agent-os)](https://github.com/munsanco13/agent-os/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)

[**Install in 5 minutes →**](#-install-paste-this-into-your-ai)
&nbsp;·&nbsp;
[**The pain this solves**](#the-real-problem-every-ai-tool-has-a-wall-and-switching-means-losing-your-place)
&nbsp;·&nbsp;
[**See it vs alternatives**](#how-agent-os-compares)
&nbsp;·&nbsp;
[**Read the playbook**](PLAYBOOK.md)

</div>

---

## The real problem: every AI tool has a wall, and switching means losing your place

You're deep in a hard problem with your favorite AI coding tool. The model is dialed in — it knows your codebase, it's nailed the bug pattern, you're 30 minutes from shipping the fix.

Then one of these things happens:

- 🛑 **"You've reached your usage limit"** — and the reset is days away
- 🤷 **The model is just wrong** for this task — you need a different one (different reasoning style, different context window, different strengths)
- 💻 **You change machines** — work laptop, second device, different OS, you've got a different AI installed there
- 👥 **Someone else picks it up** — a teammate, a contractor, future-you in three months

Whichever wall you hit, you have **three bad options:**

### ❌ Option 1 — Stop and wait
Lose your flow state. Forget what you were doing. The deadline slips.

### ❌ Option 2 — Switch to the metered API
Pay per token. Modern agentic tooling spawning sub-agents burns through context fast — a single serious dev day can cost **hundreds of dollars** in API charges. The whole reason you used the subscription was to avoid this.

### ❌ Option 3 — Switch to a different AI tool, but cold
You open the next tool (Codex, Cursor, Cline, Aider, whatever you have access to). It knows nothing about your project, your conventions, what you were just trying to do. You spend **30 minutes re-onboarding it** — pasting context, re-explaining the bug, re-establishing rules. By the time the new AI is up to speed, your flow is dead.

### ✅ The fourth option (with Agent OS): switch in under 2 minutes

Your project has `AGENTS.md` and a `docs/sessions/` log committed. You push your work-in-progress and tell the next tool (any tool — Claude Code, Codex, Cursor, Cline, Aider, Continue.dev, doesn't matter):

> *"Pick up work on https://github.com/me/myproject. Read AGENTS.md and the latest session log to bootstrap."*

The new tool reads the files, sees exactly where the previous AI left off, what's pending, what to watch out for, what the project's conventions are. **It's productive in 2 minutes**, not 30. You finish shipping.

When you switch back later (cap reset, different machine, different teammate, different model that's better for the next task), the new tool reads the same files and is just as oriented. **The handoff is bidirectional and tool-agnostic.**

**This is what Agent OS is for: when one AI tool hits any wall — usage cap, wrong model for the task, machine switch, contributor handoff — the next one keeps your project moving without losing momentum.**

---

### Why this happens to every AI tool

Every flat-rate AI subscription product has caps. The exact limits and who hits them vary:

- **Claude Code** (Pro / Max) — weekly usage caps; heavy users (especially Pro) hit them routinely
- **Codex** (ChatGPT Plus / Pro) — usage caps too, often more generous in practice
- **Cursor** (Pro / Business) — has its own usage envelopes depending on the model
- **Cline / Aider / Continue.dev / Cody** — many bring-your-own-key but you can mix subscription + API

Caps shift over time as vendors tune pricing. Pinning to a specific "Claude Code → Codex" handoff would be wrong — **the value is being able to switch in any direction, between any pair, whenever a wall hits.** Pick whichever AI you have runway on, point it at your repo, and keep going.

---

## How Agent OS solves it

The insight: **every AI tool reads markdown files in your repo.** They just look for different filenames.

- Claude Code reads `CLAUDE.md`
- Codex reads `AGENTS.md`
- Cursor reads `.cursorrules`
- Cline reads `.clinerules`
- Continue.dev reads `.continuerules`
- Aider reads `CONVENTIONS.md`

Agent OS installs into your project and:
1. **Creates one source-of-truth file** (`AGENTS.md`) describing your project, tech stack, conventions, and current state
2. **Symlinks all the other filenames to it** so every AI tool sees the same content
3. **Adds a `docs/sessions/` log** so each AI can leave a note for the next ("here's what I just did, here's what's pending, here's what to watch out for")
4. **Adds an `AGENTS.md` section that AI agents auto-read on every fresh session** so they bootstrap themselves with current state in 30 seconds, not 30 minutes

**The handoff becomes git push → git clone → "read AGENTS.md and the latest session log."** That's it. Total switch time: ~2 minutes.

You also get (as a bonus) a hardened repo: no committed secrets, no force-push to `main`, no rogue branches. But that's the side benefit — the headline is *use cheap subscriptions interchangeably.*

---

## How this works (the install, plain)

**Agent OS works exactly like installing a dev dependency** — think `npm install eslint --save-dev` or `pip install -r requirements.txt`.

1. **You install Agent OS ONCE into YOUR project's repo.** The installer drops files into your project's working tree: `AGENTS.md`, `.githooks/`, `.github/workflows/`, `docs/decisions/`, etc.
2. **Those files get committed and pushed.** They are now part of your project's git history.
3. **Anyone (or any AI) who clones your project gets them automatically** — the files are inside your repo. They never visit `github.com/munsanco13/agent-os`.
4. **After install, the agent-os repo is invisible to you.** Your project owns those files now, just like ESLint becomes part of your project once it's in `package.json`.

```
                                 install ONCE                    clone forever
   ┌──────────────────────┐     ───────────►       ┌──────────────────────┐
   │  YOU on Device A     │                         │  YOU (or AI) on B    │
   │  Project: cool-app   │ ──── git push ────►     │  git clone cool-app  │
   │  + Agent OS files    │                         │  AGENTS.md is here   │
   │    committed inside  │                         │  hooks are here      │
   └──────────────────────┘                         └──────────────────────┘
                                                          ▲
                                                          │ never visits
                                                          │ agent-os repo
                                                          ▼
                            ┌──────────────────────┐
                            │  munsanco13/agent-os │  ◄── only consulted ONCE,
                            │  (this repo)         │      at install time
                            └──────────────────────┘
```

---

## ⚡ Install (paste this into your AI)

In your project's repo (any tech stack, Mac/Linux/WSL), paste this **single message** into Claude Code, Codex, Cursor, Cline, Aider, or any AI coding assistant with shell access:

> Install Agent OS in this repo. The instructions are at https://github.com/munsanco13/agent-os — read the README, then run the autonomous installer. Use my existing `gh` CLI authentication (run `gh auth status` first to confirm). The installer auto-detects my tech stack, drops template files, opens an install PR, configures GitHub branch protection via the API, and validates. No setup needed from me. Report when done.

**The AI handles everything.** Total time: **2-5 minutes**.

> 💡 **No PAT setup needed** — the installer uses your existing `gh auth login`. If you've ever pushed to GitHub from your machine, you're already set up.

For the manual install path (no AI handy), or for a deep walkthrough, see [`INSTALL.md`](INSTALL.md).

---

## What you get

### 1. Tool-agnostic handoffs (the headline)

When ANY AI tool hits a wall — usage cap, wrong-model-for-the-task, machine switch, teammate handoff — Agent OS lets you:

1. Commit your work-in-progress (push)
2. Open whichever AI tool you want next (Claude Code, Codex, Cursor, Cline, Aider, Continue.dev, GPT-5.5, etc.)
3. Tell it: *"Pick up the project. Read AGENTS.md and the latest session log."*
4. Productive in **~2 minutes**, not 30

**Your project doesn't stall when one tool fails you.** You keep building in the next tool. When the original is available again, you switch back. Same `AGENTS.md` + same session log = every AI always in sync.

This works for **any combination, in any direction**: Claude Code ↔ Codex, Codex ↔ Cursor, Cursor ↔ Cline, Aider → Codex, etc. The handoff protocol doesn't care which tools you use.

### 2. Multi-AI continuity (what you actually use day-to-day)

| Capability | What it does for you |
|---|---|
| Single source-of-truth `AGENTS.md` | Edit once, every AI tool reads the same content |
| Symlinks for `CLAUDE.md`, `.cursorrules`, `.clinerules`, `.continuerules`, `CONVENTIONS.md` | Five AI tools all read your one file — no duplicate maintenance |
| `docs/sessions/` log pattern | Each AI session ends with a 1-paragraph note for the next AI |
| `docs/decisions/` (ADRs) | Architectural decisions get documented once, every future AI reads them |
| Stack auto-detection (Node/Python/Rust/Go/Ruby/PHP/Elixir/Java/Deno + 15 frameworks) | The installer fills in your install/dev/test/lint commands so AI tools know how to actually build your code |
| Cross-platform support (Mac/Linux/WSL/Git Bash) | Switching between MacBook and Windows/WSL Just Works |

### 3. Repo hygiene + security (the bonus you didn't ask for but will appreciate)

| Capability | What it prevents |
|---|---|
| Pre-commit hook with gitleaks | Catches `.env` files, API keys, JWTs before they leave your laptop |
| Server-side gitleaks-action on every push and PR | Backstop in case you bypass the local hook |
| `pre-push` force-push refusal | Protects shared branches from history rewrites |
| `commit-msg` Conventional Commits enforcement | Keeps your git log readable across multiple contributors |
| GitHub branch protection automation (via `gh api`) | No direct pushes to main, required reviews, required CI checks |
| Weekly drift audit | Opens an issue if branch protection gets disabled |
| Dependabot configuration | Weekly dep security updates |
| `CODEOWNERS`, PR templates, vulnerability disclosure | The boilerplate every repo eventually needs |

### 4. Developer experience polish

- `validate.sh` — one command confirms install integrity
- `update.sh` — pull newer template versions with diff preview
- `uninstall.sh` — clean reverse install
- `import.sh` — merge legacy `CLAUDE.md` / `.cursorrules` into unified `AGENTS.md`

---

## How Agent OS compares

We benchmarked against the 5 most relevant peer tools. Each solves a different slice of the AI-tooling space:

| Capability | [any-llm](https://github.com/mozilla-ai/any-llm) | [CCB](https://github.com/bfly123/claude_codex_bridge) | [ccode-to-codex](https://github.com/zuharz/ccode-to-codex) | [palot](https://github.com/itswendell/palot) | [agents-md-vsc](https://github.com/kamilio/agents-md-vscode-extension) | **Agent OS** |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Multi-AI filename aliases | ❌ | ❌ | ❌ | ❌ | 1 | **5** |
| Legacy config import | ❌ | ❌ | partial | ❌ | ❌ | **✅** |
| Stack auto-detection (10+ stacks) | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Cross-platform Mac↔Windows | partial | partial | ❌ | ✅ | ✅ | **✅** |
| Autonomous install via API | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| ADRs + sessions log | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Server-side CI enforcement | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Branch protection automation | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Threat-modeled SECURITY.md | ❌ | ❌ | ❌ | ❌ | ❌ | **✅** |
| Parallel agent runtime | ❌ | **✅** | ❌ | ❌ | ❌ | n/a (use CCB) |
| Desktop GUI | ❌ | ❌ | ❌ | **✅** | ❌ | n/a (use palot) |
| LLM provider SDK | **✅** | ❌ | ❌ | ❌ | ❌ | n/a (use any-llm) |

**Agent OS owns 9 of 12 capability dimensions.** The 3 we don't own are deliberately out of scope (parallel runtime, GUI, SDK). Agent OS is the base layer the others sit on top of.

---

## FAQ

<details>
<summary><b>What problem does Agent OS actually solve?</b></summary>

**The "I hit a wall and now I'm stuck" problem.** Whether the wall is a usage cap (Claude Code says "weekly limit reached"), a wrong-model-for-the-task moment, a machine switch, or a teammate handoff — without Agent OS, the next AI tool you open knows nothing about your project. You lose 30 minutes re-onboarding it.

With Agent OS, your project has `AGENTS.md` + a session log committed to the repo. **Any** AI tool (Claude Code, Codex, Cursor, Cline, Aider, Continue.dev, GPT-5.5 — doesn't matter) reads those files and is productive in ~2 minutes. The handoff is tool-agnostic and bidirectional.

The security/hygiene features (gitleaks, branch protection, hooks) ship by default and are real — but they're a side benefit. The headline is "when one AI tool fails you for any reason, the next one picks up where it left off."
</details>

<details>
<summary><b>Why not just use the API instead of switching tools?</b></summary>

Because for serious agentic dev work, the API is brutally expensive — modern tools spawn sub-agents and burn context, costing hundreds per day. Subscriptions exist exactly because flat-rate pricing makes serious AI-assisted development affordable. Agent OS makes the subscription model viable for power users who'd otherwise hit caps.
</details>

<details>
<summary><b>Does this work with my tech stack?</b></summary>

Almost certainly yes. The auto-detector covers **Node.js (Next.js, Vite, Remix, NestJS, Express, Fastify, SvelteKit, React)**, **Python (uv, Poetry, pip, pipenv)**, **Rust**, **Go**, **Ruby (Rails)**, **PHP (Laravel, Symfony)**, **Elixir (Phoenix)**, **Java (Maven, Gradle, Spring Boot)**, and **Deno**.

If your stack isn't covered, the installer writes a `bootstrap.yaml` with `TODO` markers and the rest of the system works identically.
</details>

<details>
<summary><b>Do I need to install Agent OS on every device that uses my project?</b></summary>

**No.** You install Agent OS into your project's repo **once, on any machine.** The files get committed. Every other device that clones your project gets Agent OS automatically — because the files are inside your repo. They never visit the agent-os repo.

Think `npm install eslint --save-dev`. You install ESLint once, commit it, and every other dev who clones your project gets it for free.
</details>

<details>
<summary><b>What if I already have a CLAUDE.md / AGENTS.md / .cursorrules?</b></summary>

The installer skips files that already exist (never overwrites). To merge legacy single-tool configs into a unified `AGENTS.md`, run:

```bash
bash scripts/agent-os-import.sh
```

It backs up originals, merges them, and replaces with symlinks pointing at `AGENTS.md`. Audit log + reversible.
</details>

<details>
<summary><b>I just want to use one AI tool. Do I need this?</b></summary>

Probably not. Agent OS pays for itself when you use 2+ AI tools. If you're committed to a single tool (e.g. only Claude Code, only Codex), the security features still apply but the multi-AI continuity layer is unused.

For single-tool users, the security features alone may not justify the install — your time may be better spent on `husky` or `pre-commit-py` for hooks and a manual GitHub branch protection setup.
</details>

<details>
<summary><b>Does the autonomous install work without a GitHub PAT?</b></summary>

Yes. The installer resolves credentials in this order:
1. `GH_PAT` env var
2. `.credentials.local` file
3. **Existing `gh auth token`** (most common — most devs have done `gh auth login`)
4. None — install drops files only and prints manual branch-protection instructions

If you've ever run `gh auth login`, you're set. No PAT setup needed.
</details>

<details>
<summary><b>Can I uninstall it?</b></summary>

Yes, interactively:
```bash
bash scripts/agent-os-uninstall.sh
```

Removes hooks, workflows, scripts, configs. Leaves your customized `AGENTS.md`, `SECURITY.md`, and `docs/` alone (those are yours now).
</details>

<details>
<summary><b>Is this safe to install in a private/work repo?</b></summary>

Yes. The installer:
- Never overwrites existing files
- Refuses to run if you have a competing hook manager (Husky, lefthook, pre-commit) without explicit guidance
- Drops files only — no telemetry, no network calls after install (other than fetching files from this public repo)
- Source code is auditable; it's all bash + TOML + Markdown

The whole template is MIT-licensed and ~3,000 lines you can read in an hour.
</details>

<details>
<summary><b>How do I update?</b></summary>

```bash
bash scripts/agent-os-update.sh           # latest tagged version
bash scripts/agent-os-update.sh v2.4.0    # pin to a specific version
```

Shows you the diff, applies on approval. Your `AGENTS.md` and `SECURITY.md` are user-owned post-install — the updater never touches them.
</details>

<details>
<summary><b>Why is this free?</b></summary>

Because **multi-AI workflow chaos is a problem worth solving for everyone**, and gatekeeping it would be net-negative.

Built by [@munsanco13](https://github.com/munsanco13). MIT license. PRs welcome. ⭐ if it helps.
</details>

---

## Roadmap

- [x] **v2.0** — gitleaks + CI workflows + sessions log
- [x] **v2.1** — bash 3.2 fix, JWT regex, squash-merge fix, cross-platform
- [x] **v2.2** — autonomous install + stack auto-detection
- [x] **v2.3** — multi-tool symlinks (Claude/Cursor/Cline/Continue/Aider) + legacy config import
- [ ] **v2.4** — automated branch protection setup via API for non-PAT users (GitHub OIDC)
- [ ] **v2.5** — visual install diagram + 90-second demo video
- [ ] **v3.0** — cosign-signed releases + SLSA Level 3 provenance
- [ ] **future** — project-type variants (Next.js / Python / Rust starters)

---

## Contributing

PRs welcome. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

This repo eats its own dog food — every commit goes through the gates Agent OS installs into other projects.

---

## License + Author

[MIT License](LICENSE) · Built by [Mundo Sanchez](https://github.com/munsanco13)

If Agent OS keeps your project moving when one AI tool fails you, **⭐ the repo**.

For the full design rationale, threat model, and deep dive: [`PLAYBOOK.md`](PLAYBOOK.md).

---

<div align="center">

**Hit a wall? Don't lose the day. Switch AI tools, keep building.**

[**Install in 5 minutes →**](#-install-paste-this-into-your-ai)

</div>
