# Install Agent OS

**The only thing you need to do:** paste this URL into your AI assistant (Claude Code / Codex / Cursor / Cline / Aider — any of them) and tell it to install Agent OS.

```
https://github.com/munsanco13/agent-os
```

Or paste this prompt directly:

```
Install Agent OS in this repo. The instructions are at
https://github.com/munsanco13/agent-os — read the README,
then run the autonomous installer. Use my existing gh CLI
authentication (run `gh auth status` first to confirm).

The installer auto-detects my tech stack, drops template files,
opens an install PR, configures GitHub branch protection via
the API, and validates. No setup needed from me.

Report when done.
```

That's it. Your AI handles everything.

---

## What happens

1. AI clones / reads the Agent OS repo
2. AI runs the autonomous installer in your project:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.1/scripts/autonomous-install.sh)
   ```
3. Installer auto-detects your stack (Node / Python / Rust / Go / Ruby / PHP / Elixir / Java / Deno + frameworks like Next.js, Rails, Laravel, Phoenix, Spring Boot)
4. Drops in: `AGENTS.md`, `SECURITY.md`, git hooks, GitHub Actions workflows, ADR scaffold, sessions log
5. Symlinks aliases so every AI tool reads the same source: `CLAUDE.md`, `.cursorrules`, `.clinerules`, `.continuerules`, `CONVENTIONS.md` → all point to `AGENTS.md`
6. Wires git hooks: secret scanner, Conventional Commits, force-push refusal
7. Opens + auto-merges an install PR (via your existing `gh` auth)
8. Configures GitHub branch protection: 7 required status checks, 1 review, linear history, no force pushes
9. Validates the install

Total time: ~2-5 minutes.

---

## Prerequisites your AI's environment needs

Almost every AI coding tool already has these:

- `git` — yes, every tool
- `gh` CLI authenticated — yes, every tool (run `gh auth status` to confirm)
- `bash` + `curl` — yes, every Unix-like environment

If `gh` isn't authenticated, the installer falls back to file-only install + prints manual branch-protection instructions. Nothing breaks; you just do the GitHub Settings click manually.

---

## What your repo gets

After install:

- A protected `main` branch nothing can bypass (no direct pushes, no force, no deletions, required status checks)
- Server-side secret scanning on every push and PR (gitleaks)
- Conventional Commits enforcement
- Stack-specific dev/test/lint commands documented in `AGENTS.md` for every AI tool
- ADR + sessions log pattern for cross-AI handoffs
- Cross-platform (Mac / Linux / WSL / Git Bash on Windows)
- Weekly branch-protection drift audit
- Dependabot for dependency security updates

---

## Troubleshooting

If something goes wrong, your AI will tell you. Most common:

- **"`gh auth status` shows not logged in"** — your AI runs `gh auth login` once, then re-runs the installer.
- **"Detected stack: TODO"** — your stack isn't in the auto-detector. Your AI fills in the install/dev/test/lint commands manually based on your project, then proceeds.
- **"Branch protection API returned 403"** — your `gh` token doesn't have admin scope on the repo. Either elevate scope (`gh auth refresh -h github.com -s admin:repo`) or skip server-side protection and configure manually.

---

## Read more (optional)

- `README.md` — what's in the box
- `PLAYBOOK.md` — the full design rationale + threat model + daily workflow (35 pages)
- `QUICKSTART.md` — beginner-friendly step-by-step (for users without an AI assistant)
- `SECURITY.md` — threat model + hard rules
- `CHANGELOG.md` — version history

But you don't need to read any of those to install. Just paste the URL into your AI.

---

License: MIT · Author: [Mundo Sanchez](https://github.com/munsanco13) · Source: https://github.com/munsanco13/agent-os
