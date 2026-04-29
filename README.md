# Agent OS — Multi-AI Continuity & Security Template

A drop-in template that lets a project safely use **multiple AI assistants interchangeably** (Claude Code, Codex, Cursor, Cline, Aider, GPT-5.5, local models) without losing context, leaking secrets, or stepping on each other.

**Version:** 2.3.0 · **License:** MIT · **Author:** Mundo Sanchez ([@munsanco13](https://github.com/munsanco13))

---

## Install (paste this into your AI)

In your project's repo, paste this single message into Claude Code, Codex, Cursor, Cline, or any AI coding assistant with shell access:

> Install Agent OS in this repo. The instructions are at https://github.com/munsanco13/agent-os — read the README, then run the autonomous installer. Use my existing `gh` CLI authentication (run `gh auth status` first to confirm). The installer auto-detects my tech stack, drops template files, opens an install PR, configures GitHub branch protection via the API, and validates. No setup needed from me. Report when done.

The AI handles everything. Total time: ~2-5 minutes.

For more detail (or if you don't have an AI handy and want to install manually), see [`INSTALL.md`](./INSTALL.md).

---

## What's in the box

```
.agent-template/
├── README.md                                   # this file
├── VERSION                                     # 2.0.0
├── AGENTS.md                                   # universal AI contract every agent reads first
├── SECURITY.md                                 # threat model + hard rules
├── .gitleaks.toml                              # gitleaks config (extends upstream + project-specific)
├── .gitignore-additions                        # appended to your existing .gitignore
│
├── docs/
│   ├── sessions/
│   │   ├── README.md                           # how the per-session log works
│   │   └── _template.md                        # template for new session entries
│   └── decisions/
│       ├── README.md                           # ADR index
│       ├── 0000-template.md
│       ├── 0001-multi-ai-continuity.md
│       ├── 0002-secret-scanning-with-gitleaks.md
│       └── 0003-server-side-enforcement.md
│
├── .githooks/
│   ├── pre-commit                              # gitleaks scan + filename + size + main-branch refusal
│   ├── commit-msg                              # Conventional Commits enforcement
│   └── pre-push                                # final gate: force-push refusal + range scan
│
├── .github/
│   ├── workflows/
│   │   ├── security.yml                        # secret-scan, large-files, no-direct-pushes, hooks-integrity, placeholder-lint
│   │   ├── pr-checks.yml                       # pr-title, pr-body
│   │   ├── branch-protection-audit.yml         # weekly audit; opens issue if main is unprotected
│   │   └── hook-tests.yml                      # bats test suite for the hooks
│   ├── CODEOWNERS                              # required reviewers for security-critical paths
│   ├── pull_request_template.md                # forces Summary + Test plan + Security checklist
│   ├── dependabot.yml                          # weekly dependency security updates
│   └── SECURITY.md                             # vulnerability disclosure policy
│
├── scripts/
│   ├── install.sh                              # idempotent installer
│   ├── validate.sh                             # checks installation integrity
│   ├── update.sh                               # pulls newer template, shows diff, applies
│   └── uninstall.sh                            # reverses the install
│
└── tests/
    └── pre-commit.bats                         # bats tests for the pre-commit hook
```

---

## Defense layers (what actually keeps you safe)

| Layer | What it does | Bypass cost |
|---|---|---|
| 1. `AGENTS.md` | Tells every AI the rules | AI ignores → caught at next layer |
| 2. `.gitignore` | Stops accidental staging | Trivial — but unlikely accidentally |
| 3. `pre-commit` hook (local) | Fast feedback on secrets/size/main-branch | Can be skipped with `--no-verify`, **but CI re-runs everything** |
| 4. `commit-msg` hook (local) | Conventional Commits | Same as above |
| 5. `pre-push` hook (local) | Force-push refusal + full-range gitleaks scan | Same |
| 6. **`.github/workflows/security.yml` (server)** | The authoritative gate. gitleaks + size + branch checks on every push and PR. | **No bypass without admin override (logged)** |
| 7. Branch protection (manual setup) | GitHub refuses direct pushes / unmerged PRs | Admin override only |
| 8. CODEOWNERS | Required reviewer for `AGENTS.md`, `SECURITY.md`, `.gitleaks.toml`, `.githooks/`, `.github/workflows/` | Cannot bypass once branch protection requires owner review |
| 9. `branch-protection-audit` (weekly) | Catches drift if protection is silently disabled | Maintainer is notified within 7 days |
| 10. Dependabot | Weekly dependency security PRs | None — automated |

The critical insight: **the local hooks are advisory. The CI workflow + branch protection are authoritative.** A motivated attacker bypassing local hooks just delays the failure to the PR check.

---

## Install

### One-liner (pinned, recommended)

From inside the project you want to add this to:

```bash
AGENT_OS_REF=v2.0.0 bash <(curl -fsSL \
  https://raw.githubusercontent.com/munsanco13/agent-os/v2.0.0/scripts/install.sh)
```

> **Why pinning matters:** running `main` means whatever's on HEAD right now executes on your machine. Pinning to a tagged release ensures auditability. After running, check the file `.agent-os-version` in your repo — it records the exact commit SHA that was installed.

### Local clone install

```bash
git clone https://github.com/munsanco13/agent-os /tmp/agent-os
cd /path/to/your/project
bash /tmp/agent-os/.agent-template/scripts/install.sh .
```

### What the installer does

1. Verifies the target is a git repo.
2. **Detects competing hook managers** (Husky, lefthook, pre-commit) and refuses with guidance — never silently breaks an existing setup.
3. Copies template files **without overwriting** any existing files.
4. Wires `git config core.hooksPath = .githooks` (warns if already set elsewhere).
5. Appends gitignore entries (deduplicated).
6. Writes `.agent-os-version` with version + commit SHA + timestamp.
7. Runs the placeholder validator and lists what's still `<<UNFILLED>>`.
8. Checks gitleaks is installed; prints install instructions if not.
9. Prints the manual branch-protection setup checklist.

The installer is **idempotent** — run it again any time. Files that exist are never overwritten.

---

## Customize after install

Open these and replace `<<PLACEHOLDER>>` tokens:

- `AGENTS.md` → `<<PROJECT_NAME>>`, `<<STACK>>`, `<<DEPLOY_TARGET>>`, `<<DEV_COMMAND>>`, `<<TEST_COMMAND>>`, `<<LINT_COMMAND>>`, `<<INSTALL_COMMAND>>`
- `.github/CODEOWNERS` → `<<GITHUB_USERNAME>>`
- `.github/SECURITY.md` → `<<SECURITY_EMAIL>>`

Run anytime to find what's left:

```bash
bash scripts/agent-os-validate.sh
```

The CI workflow `placeholder-lint` will fail any PR that ships unfilled tokens.

---

## Required manual step: branch protection

The workflows enforce nothing unless GitHub branch protection requires their status checks. **You must configure this once in GitHub**:

Settings → Branches → Add branch protection rule → `main`:

- ✅ Require a pull request before merging (1 approval)
- ✅ Dismiss stale approvals when new commits are pushed
- ✅ Require review from Code Owners
- ✅ Require status checks to pass:
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
- ❌ Disallow force pushes
- ❌ Disallow deletions

`branch-protection-audit.yml` runs weekly and opens an issue if these rules drift.

---

## Validate / Update / Uninstall

```bash
bash scripts/agent-os-validate.sh           # check install integrity
bash scripts/agent-os-update.sh             # pull latest tagged version, show diff, apply
bash scripts/agent-os-update.sh v2.1.0      # pin to a specific version
bash scripts/agent-os-uninstall.sh          # reverse install (interactive)
```

---

## Threat model

See `SECURITY.md` for the full threat model. In short:

**Defended:** accidental secret commits (developer or AI), force-push to main, direct commits to main, `--no-verify` bypass, large-file accidents, dependency vulnerabilities, branch-protection drift.

**Not defended:** social engineering against maintainers, upstream supply-chain compromise, GitHub itself getting popped, malicious insiders with admin access. These require operational controls (2FA, hardware keys, minimum-permission principle) the template can't provide.

---

## Why not a CLI / npm package / cargo crate?

Because:
1. Markdown files don't need a runtime.
2. AI agents read flat markdown reliably; they read wrapper-tool output unreliably.
3. Forking is the simplest extension model — copy, edit, ship. Updates flow via the `update.sh` diff workflow, not a dependency manager.
4. Less surface area = fewer supply-chain attack vectors. There's no package to typosquat.

---

## Contributing back

If you improve the template in your project, copy the improvement back into `agent-os` repo and open a PR. The `update.sh` script will distribute it to other projects on their next update.

---

## Releases

Tagged versions live at https://github.com/munsanco13/agent-os/tags. Use those refs (e.g. `AGENT_OS_REF=v2.0.0`) for deterministic installs.

| Version | Highlights |
|---|---|
| 2.0.0 | gitleaks integration; CI workflows are authoritative; sessions log replaces single HANDOFF.md; commit-msg + pre-push hooks; bats test suite; CODEOWNERS, PR template, dependabot, vulnerability disclosure; idempotent install + validate + update + uninstall scripts; weekly branch-protection audit |
| 1.0.0 | Initial: AGENTS.md, HANDOFF.md, SECURITY.md, ADR scaffold, regex-based pre-commit hook |
