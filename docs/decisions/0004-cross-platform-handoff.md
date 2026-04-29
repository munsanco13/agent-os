# 0004 — Cross-platform handoff (Mac ↔ Windows ↔ Linux)

- **Status:** accepted
- **Date:** 2026-04-29
- **Author:** project owner

## Context

Real-world projects switch between machines: developer's MacBook at home, work Windows laptop, Linux CI runner, AI sandbox running Ubuntu. Without explicit handling, three classes of bug appear:

1. **Line-ending corruption.** Git on Windows defaults to checking out CRLF. Bash hooks then fail with `$'\r': command not found`. Silent on Mac/Linux, broken on Windows.
2. **Executable bit loss.** Windows filesystems don't preserve POSIX `chmod +x`. A hook committed as 755 from Mac can land on Windows without execute permission.
3. **Shell availability.** Native Windows lacks bash. The hooks rely on bash. Without WSL or Git Bash (bundled with Git for Windows), nothing works.

## Decision

**Three guardrails, all in git:**

1. **`.gitattributes` at repo root** forces `eol=lf` for all shell scripts, hooks, markdown, and config files. This defeats CRLF corruption regardless of `core.autocrlf` setting on the developer's machine.
2. **Hooks committed with `git update-index --chmod=+x`** so the executable bit travels with the file in git's index, not the filesystem. Works cross-platform.
3. **AGENTS.md documents the Windows requirement** explicitly: WSL2 (preferred) or Git Bash. Native cmd.exe / PowerShell is not supported.

## Alternatives considered

- **Rewrite hooks in Node.js.** Cross-platform, but adds a runtime dep before the hook can even check secrets. Rejected: bash + LF + Git Bash is the path of least resistance.
- **Rewrite hooks in PowerShell.** Doesn't run on Mac/Linux. Would require dual maintenance.
- **Rewrite hooks in Python.** Heavier than bash, requires Python 3 on PATH for every contributor. Some Windows users still don't have it. Considered for v3.
- **Skip hook enforcement on Windows.** Rejected — would create a per-platform security gap.

## Consequences

**Positive:**
- A single repo works on Mac, Linux, Windows-with-Git-Bash, Windows-with-WSL2, and AI sandboxes (Linux containers).
- Line-ending bugs are detected at install time, not at commit-time on the wrong machine.
- The hook executable bit travels with the file.

**Negative:**
- Pure-Windows-no-WSL developers are unsupported. Documented; rare in 2026.
- `.gitattributes` is one more file at the repo root.

**Reversal cost:** zero — delete `.gitattributes` and the project goes back to OS-default behavior.

## Implementation checklist

When installing on a new machine:

- **Mac:** works out of the box. Bash 3.2 is fine after v2.1.0.
- **Linux:** works out of the box.
- **Windows (recommended):** install **WSL2 + Ubuntu**, do all git work inside WSL.
- **Windows (alternative):** install **Git for Windows** (which bundles Git Bash). Run `git config --global core.autocrlf input` once. Always use Git Bash for `git commit` operations so hooks fire with bash on PATH.

## Verification

After cloning on any platform:

```bash
# Confirm hooks have LF line endings
file .githooks/pre-commit
# Expected: ".githooks/pre-commit: a /usr/bin/env bash script, ASCII text executable"
# NOT:      ".githooks/pre-commit: ... ASCII text executable, with CRLF line terminators"

# Confirm executable bit
ls -la .githooks/pre-commit
# Expected: -rwxr-xr-x ...

# Confirm core.hooksPath wired
git config --get core.hooksPath
# Expected: .githooks
```

If any of these fail on Windows, run `bash scripts/agent-os-validate.sh` for a guided diagnostic.

## References

- `.gitattributes` (repo root)
- `scripts/install.sh` (sets executable bits via `chmod 755`, `git update-index --chmod=+x` post-install)
- AGENTS.md "Cross-platform" section
- Microsoft WSL install guide: https://learn.microsoft.com/en-us/windows/wsl/install
- Git for Windows: https://git-scm.com/download/win
