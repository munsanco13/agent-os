# Quickstart — For people who've never done this before

This guide assumes you know **nothing**. Follow it line by line, top to bottom. Don't skip steps.

By the end you'll have:
- A project where multiple AI assistants (Claude Code, Codex, Cursor, etc.) can pick up your work without losing context.
- Automatic protection against accidentally committing passwords, API keys, or secrets.
- A repo that works the same on Mac, Windows, and Linux.

**Time required:** 30-45 minutes the first time. 5 minutes for every project after.

---

## ⚡ Two paths: fully manual, or fully autonomous

You have two ways to install this template. Pick one:

### Path A — Hand it to an AI (fastest, ~5 minutes total)

If you have an AI assistant (Claude, Codex, Cursor) with bash + GitHub access:

1. Make sure you're in your project's git repo.
2. Get a GitHub fine-grained PAT with `Administration: write` + `Contents: write` + `Pull requests: write` scope. https://github.com/settings/tokens?type=beta
3. Save it in a file called `.credentials.local`:
   ```
   GH_PAT=ghp_yourActualToken
   ```
4. Tell the AI:
   ```
   Run: bash <(curl -fsSL https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/autonomous-install.sh)

   It will auto-detect my stack, generate bootstrap.yaml, install Agent OS,
   open + auto-merge the install PR, and configure GitHub branch protection
   via the API. The PAT is in .credentials.local.
   ```
5. The AI runs one command. ~5 minutes later, your repo is fully configured.

The autonomous installer **auto-detects your stack** (Node.js / Python / Rust / Go / Ruby / PHP / Elixir / Java / Deno) and fills in the right `pnpm install` / `pip install` / `cargo build` / etc. commands automatically. You don't have to know what your stack is — it sniffs your lockfiles + manifests.

If your stack isn't auto-detected, the installer writes a `bootstrap.yaml` with `TODO` markers so you can fill in custom commands.

### Path B — Manual step-by-step

Continue with Part 0 below. Recommended for learning what's actually happening, or if you don't trust autonomous installs (fair — read the script first).

---

## What you'll be doing — in plain English

You have a code project. You want to use AI assistants to help build it. You also want to:
- Switch between Claude and Codex without losing your place.
- Move between your Mac and your PC and have everything just work.
- Never accidentally upload your Stripe key or Supabase password to GitHub.
- Stop yourself from breaking things with a wrong command.

This template gives you all of that by adding **a few markdown files and some safety scripts** to your project. Once installed, the protection is invisible — you work normally, and it catches mistakes automatically.

---

## Part 0 — One-time setup on your computer

Do this **once per computer**, not per project.

### If you have a Mac

1. Open the **Terminal** app (press Cmd+Space, type "Terminal", press Enter).
2. Copy and paste this command, then press Enter:
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   This installs **Homebrew**, a tool for installing other tools. Wait for it to finish (a few minutes).

3. Now install the things you need:
   ```
   brew install git gh gitleaks
   ```
   - `git` is version control. You probably already have it.
   - `gh` is GitHub's official command-line tool.
   - `gitleaks` is the secret scanner that protects you.

4. Sign in to GitHub from the terminal:
   ```
   gh auth login
   ```
   Follow the prompts. Pick: **GitHub.com → HTTPS → Yes, authenticate Git → Login with a web browser**. Copy the code it shows, paste it in the browser tab that opens.

### If you have a Windows PC

You have two options. **Pick option A unless you have a reason not to.**

**Option A: Install WSL (Windows Subsystem for Linux)**

WSL lets you run a Linux environment inside Windows. Most modern dev tools assume Linux, so this avoids many problems.

1. Open **PowerShell as Administrator** (right-click Start button → "Windows PowerShell (Admin)" or "Terminal (Admin)").
2. Run:
   ```
   wsl --install
   ```
3. Restart your computer when it asks.
4. After restart, **Ubuntu** opens automatically. Pick a username and password (write them down).
5. Inside the Ubuntu window, run:
   ```
   sudo apt update && sudo apt install -y git gh
   ```
6. Install gitleaks:
   ```
   curl -sSL https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_linux_x64.tar.gz | tar -xz
   sudo mv gitleaks /usr/local/bin/
   ```
7. Sign in to GitHub:
   ```
   gh auth login
   ```
   Pick: **GitHub.com → HTTPS → Yes, authenticate Git → Login with a web browser**.

From now on, **always do your code work inside this Ubuntu terminal**, not regular Windows.

**Option B: Git for Windows (without WSL)**

1. Download from https://git-scm.com/download/win and install with all defaults.
2. After install, search for "**Git Bash**" in the Start menu and open it. Use this for all git commands — NOT regular cmd.exe or PowerShell.
3. In Git Bash, run:
   ```
   git config --global core.autocrlf input
   ```
4. Install GitHub CLI from https://cli.github.com/ — pick the Windows .msi installer.
5. Install gitleaks: download `gitleaks_8.21.2_windows_x64.zip` from https://github.com/gitleaks/gitleaks/releases — extract and copy `gitleaks.exe` to a folder in your PATH (like `C:\Windows\System32\`).
6. Sign in to GitHub:
   ```
   gh auth login
   ```

### If you have a Linux machine

You probably know what you're doing. If not, replace `apt` with your distro's package manager and follow the WSL steps from "5. Install gitleaks" onward.

---

## Part 1 — Adding the template to your project

Now you'll add the safety system to a specific code project.

### Step 1: Open your project in the terminal

If you already have a project folder, navigate to it:
```
cd /path/to/your/project
```

If you don't have a project yet and just want to test:
```
mkdir ~/test-project
cd ~/test-project
git init -b main
```

(`~/` means your home folder.)

### Step 2: Make sure it's a git repo

Type:
```
ls .git
```

If you see files listed, you're good. Skip to Step 3.

If you see "No such file or directory", run:
```
git init -b main
```

### Step 3: Run the installer

Copy and paste this **exactly**, then press Enter:

```
AGENT_OS_REF=v2.3.0 bash <(curl -fsSL https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.0/scripts/install.sh)
```

This downloads and runs the installer. It will:
- Tell you what platform you're on (Mac/Linux/Windows).
- Drop several files into your project (don't worry, none overwrite anything you have).
- Wire up the safety hooks so they run automatically.

Wait for it to finish (~30 seconds). At the end it prints "✅ Agent OS v2.1.0 installed".

### Step 4: Fill in the placeholders

The installer dropped a file called `AGENTS.md` into your project. Open it in your code editor (VS Code, Cursor, whatever).

Search for `<<` (two angle brackets). Each match is a placeholder you need to fill in.

**Stack-specific values** — fill in based on what you're using:

| Placeholder | Node.js / Next.js | Python | Rust | Go |
|---|---|---|---|---|
| `<<INSTALL_COMMAND>>` | `pnpm install` | `pip install -r requirements.txt` or `uv sync` | `cargo build` | `go mod download` |
| `<<DEV_COMMAND>>` | `pnpm dev` | `python main.py` | `cargo run` | `go run .` |
| `<<TEST_COMMAND>>` | `pnpm test` | `pytest` | `cargo test` | `go test ./...` |
| `<<LINT_COMMAND>>` | `pnpm lint` | `ruff check .` | `cargo clippy -- -D warnings` | `go vet ./...` |
| `<<STACK>>` | `Next.js + Supabase + Vercel` (or whatever you're using) | `Python + FastAPI + PostgreSQL` | `Rust + Axum` | `Go + Gin + Postgres` |

**Universal values** — fill in regardless of stack:

| Placeholder | What to put | Example |
|---|---|---|
| `<<PROJECT_NAME>>` | Your project's name | `MyApp` |
| `<<DEPLOY_TARGET>>` | Where it deploys to | `Vercel auto-deploy from main` / `Fly.io` / `manual` |

> **Tip:** if you ran the autonomous installer (Path A above), all of these are already filled in based on auto-detection. You only edit if the detection got something wrong.

> **Other stacks** (Ruby, PHP, Elixir, Java, Deno, etc.) — the autonomous detector handles those too. For manual install, look at your stack's standard commands and substitute. The point of `AGENTS.md` is to tell every AI "here's how to run my project" — whatever your stack, that's the answer.

If you don't have one of these set up yet, just put `TBD` and come back later.

Now open `.github/CODEOWNERS`. Replace `<<GITHUB_USERNAME>>` with your GitHub username (with the `@` in front). Like: `@munsanco13`.

Open `.github/SECURITY.md`. Replace `<<SECURITY_EMAIL>>` with your email.

### Step 5: Verify nothing's broken

In the terminal:
```
bash scripts/agent-os-validate.sh
```

This checks that everything's wired correctly. If it says "✅ Validation passed.", you're good.

If it says anything's missing or wrong, follow the instructions it prints. Most common issue: forgot to fill in a placeholder.

### Step 6: Commit and push

```
git checkout -b chore/install-agent-os
git add .
git commit -m "chore: install Agent OS multi-AI safety template"
```

If the commit fails with "Conventional Commits" or "secrets detected" — read the error message, fix the issue, try again.

Then:
```
git push -u origin chore/install-agent-os
```

If the push fails because there's no remote (no GitHub repo yet), first create one:
```
gh repo create my-project --private --source=. --remote=origin --push
```

### Step 7: Open and merge a Pull Request

```
gh pr create --base main --head chore/install-agent-os --title "chore: install Agent OS" --body "$(cat <<'EOF'
## Summary
- Install Agent OS multi-AI safety template

## Test plan
- [ ] CI workflows pass
EOF
)"
```

This creates a PR. Open the URL it prints in your browser. Wait for the green checkmarks (CI checks). Then click **Merge pull request**.

---

## Part 2 — Configure GitHub branch protection (the most important step)

If you skip this step, **none of the security workflows actually enforce anything.** They run, they pass or fail, but GitHub doesn't care.

### Step 1: Open your repo's branch protection settings

In your browser:
1. Go to your repo on github.com.
2. Click **Settings** (top right of the repo page).
3. Click **Branches** in the left sidebar.
4. Click **Add branch protection rule**.

### Step 2: Configure the rule

In the form:

1. **Branch name pattern:** type `main`
2. **Check these boxes** (in order, top to bottom):
   - ✅ Require a pull request before merging
     - ✅ Require approvals → set to **1**
     - ✅ Dismiss stale pull request approvals when new commits are pushed
     - ✅ Require review from Code Owners
   - ✅ Require status checks to pass before merging
     - ✅ Require branches to be up to date before merging
     - In the search box, type and check each of these (they appear after the first PR has run them):
       - `secret-scan`
       - `large-files`
       - `no-direct-pushes`
       - `hooks-integrity`
       - `placeholder-lint`
       - `pr-title`
       - `pr-body`
   - ✅ Require conversation resolution before merging
   - ✅ Require linear history

3. **Don't check these boxes:**
   - ❌ Allow force pushes
   - ❌ Allow deletions

4. Click **Create**.

### Step 3: Verify it's working

Try this from your terminal:
```
git checkout main
echo "test" >> README.md
git add README.md
git commit -m "test: try direct main commit"
```

The commit gets blocked locally by the pre-commit hook. Good.

If you bypass the hook with `--no-verify` and push, GitHub itself rejects the push because of branch protection. Also good.

To recover, just:
```
git reset HEAD~1
git restore README.md
```

---

## Part 3 — Daily use

### Starting work

Always start work on a new branch, never on main:
```
git fetch
git checkout main
git pull
git checkout -b feat/whatever-im-working-on
```

`feat/` for new features, `fix/` for bugs, `chore/` for housekeeping, `docs/` for documentation.

### Making commits

Commit messages follow this format:
```
type(scope): short description
```

Examples:
- `feat(auth): add Google OAuth fallback`
- `fix(billing): handle null customer email`
- `docs(readme): clarify install steps`

If you mess up the format, the commit-msg hook rejects it and tells you why.

### Pushing

```
git push -u origin feat/whatever-im-working-on
```

The pre-push hook runs gitleaks. If you accidentally have a secret in your code, it blocks the push.

### Opening a PR

```
gh pr create --base main
```

It opens your editor with a template. Fill in the **Summary** and **Test plan** sections. Save.

The CI workflows run. Wait for green checks. Then merge.

---

## Part 4 — Handing off to another AI / another machine

### Before you stop work

In the terminal, in your project folder:

```
git status
```

If anything is uncommitted that matters, commit it:
```
git add .
git commit -m "wip: notes for next session"
git push
```

Open `HANDOFF.md` (in your project root). Add a new entry at the top describing:
- What branch you're on
- What you just did
- What's next
- Anything weird or in-progress

Save it. Commit it:
```
git add HANDOFF.md
git commit -m "docs: handoff snapshot $(date +%Y-%m-%d)"
git push
```

### On the other machine / other AI

Open the project folder. If it's not cloned yet, clone it:
```
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
cd YOUR-REPO
```

If it's already cloned, just pull the latest:
```
git fetch
git checkout main
git pull
```

Open the AI tool of your choice (Codex, Claude Code, Cursor). Paste this as your first message:

```
Read AGENTS.md, HANDOFF.md, and run `git log -10 --stat`.
Then summarize:
- What this project is
- What was done in the last session
- What's pending
- The rules you'll follow

Don't change code yet. I'll review your summary first.
```

The AI reads, writes you a summary. Read it carefully. If it got something wrong, tell it. If it got it right, give it your next task.

That's the whole handoff. Under 5 minutes.

---

## Part 5 — When things go wrong

### "The pre-commit hook isn't running"

In your project folder:
```
git config --get core.hooksPath
```

If empty, run:
```
git config core.hooksPath .githooks
```

This happens after fresh clones — the setting isn't in git, it has to be set per-clone.

### "I get $'\r': command not found"

You're on Windows and your hooks have wrong line endings. Fix:
```
sed -i 's/\r$//' .githooks/pre-commit .githooks/commit-msg .githooks/pre-push
```

To prevent it happening again, make sure `.gitattributes` exists in your repo root and that you ran `git config --global core.autocrlf input` once.

### "I committed a secret by accident"

**Don't panic. Do these in order:**

1. **Rotate the secret immediately at the vendor.** Whatever it was (Stripe, Supabase, AWS, Facebook, OpenAI), go to that service's dashboard and either delete the key or generate a new one. The old key is dead.
2. Even if your repo is private — assume the secret is compromised. Cached forks, your IDE, search engines all index private repo content sometimes.
3. Tell me (or another AI): "I committed [type of secret] in commit [SHA]. Help me remove it from git history." We'll walk you through `git filter-repo` or BFG.

The pre-commit, pre-push, and CI scans are all designed to prevent this. If they didn't catch your specific secret, it's a bug in the gitleaks config — open an issue.

### "CI says placeholder-lint failed"

You forgot to fill in a `<<PLACEHOLDER>>` somewhere. Run:
```
grep -rE '<<[A-Z_]+>>' AGENTS.md SECURITY.md HANDOFF.md .github/CODEOWNERS .github/SECURITY.md
```

Fix anything that prints. Most common miss: `<<GITHUB_USERNAME>>` in `.github/CODEOWNERS`.

### "The AI doesn't seem to know about AGENTS.md"

You have to tell it. AI tools don't automatically read AGENTS.md. Always start a session with:

```
Read AGENTS.md before doing anything else.
```

### "The dev server isn't picking up env vars"

You probably need to pull them locally:
```
cd apps/web
vercel link
vercel env pull .env.local
```

(Replace `apps/web` with wherever your Next.js app lives.)

---

## Part 6 — What's in the box (reference)

After install, your project has these new files:

| File | What it's for | You edit it? |
|---|---|---|
| `AGENTS.md` | Tells every AI the rules | Yes — fill placeholders |
| `SECURITY.md` | Threat model, what's banned | Optional |
| `HANDOFF.md` | Where you are right now | Yes — every session |
| `.gitattributes` | Line ending rules | No |
| `.gitleaks.toml` | Secret scanner config | Only if false positives |
| `.agent-os-version` | What version is installed | No |
| `docs/sessions/` | Per-session work logs | Yes — chronological entries |
| `docs/decisions/` | Why you chose what (ADRs) | Yes — when you make architecture choices |
| `.githooks/` | Local safety hooks | No |
| `.github/workflows/` | Server-side CI checks | No |
| `.github/CODEOWNERS` | Who must review what | Yes — fill `<<GITHUB_USERNAME>>` |
| `.github/pull_request_template.md` | Forces PR structure | No |
| `.github/dependabot.yml` | Weekly dep updates | Optional — uncomment your stack |
| `scripts/agent-os-*.sh` | Validate / update / uninstall | No |

---

## Part 7 — The most common mistakes

In rough order of frequency:

1. **Skipping branch protection setup.** The local hooks are advisory. Without GitHub branch protection, anyone (including you in a hurry) can `--no-verify` past everything.
2. **Not filling in `<<GITHUB_USERNAME>>` in CODEOWNERS.** This silently makes "require Code Owner review" useless. The placeholder-lint workflow catches it now in v2.1.0+.
3. **Forgetting to update `HANDOFF.md` between sessions.** After 3 sessions of skipping, the handoff is fiction. Set a personal rule: the last commit of every session is the HANDOFF update.
4. **Trying to commit directly to main.** Always `git checkout -b feat/something` first.
5. **Using cmd.exe instead of WSL/Git Bash on Windows.** The hooks are bash. They need bash to run.
6. **Pasting secrets into chat with an AI.** Reference secrets by name (e.g. "the Supabase URL is in Vercel env vars"), never paste the value.

---

## Part 8 — Glossary

- **Repo / repository** — Your project's folder, tracked by git.
- **Branch** — A parallel version of your code. `main` is the live one. You make changes on a side branch and merge them in.
- **Commit** — A save point in your code's history. Has a message describing the change.
- **Push** — Upload commits to GitHub.
- **Pull** — Download commits from GitHub.
- **PR / Pull Request** — Asking to merge your branch into main. Other people can review and comment.
- **Hook** — A script that runs automatically on a git action (commit, push). Used here for security checks.
- **CI / CI workflow** — Continuous Integration. Scripts that run on GitHub's servers when you push or open a PR.
- **Branch protection** — Rules in GitHub that prevent direct pushes / require PR reviews / require CI to pass.
- **CODEOWNERS** — File listing who must approve changes to which files.
- **gitleaks** — Open-source tool that scans for secrets in code.
- **WSL** — Windows Subsystem for Linux. Lets you run Ubuntu inside Windows.
- **Conventional Commits** — A standard for commit message format: `type(scope): description`.
- **ADR** — Architecture Decision Record. A short doc explaining why you picked X over Y.
- **Sensitive variable** — In Vercel, a variable marked Sensitive is encrypted and hidden from the UI.

---

**You're done.** If you're stuck, paste the exact error message into your AI assistant and ask. The system is designed to fail loudly with actionable messages — most "stuck" moments solve themselves once you read the error.
