#!/usr/bin/env bash
# Agent OS v2 installer — idempotent, integrity-checked, project-aware.
#
# Usage:
#   # From a clone of this repo:
#   bash scripts/install.sh /path/to/target/repo
#
#   # Pinned remote install (recommended for other projects):
#   AGENT_OS_REF=v2.0.0 bash <(curl -fsSL \
#     https://raw.githubusercontent.com/munsanco13/agent-os/v2.3.1/scripts/install.sh)
#
# Behavior:
#   1. Verifies the target is a git repo.
#   2. Detects existing hook managers (Husky, lefthook, pre-commit-hooks) and refuses with guidance.
#   3. Copies template files (skips files that already exist — never overwrites).
#   4. Wires core.hooksPath = .githooks (warns if already set elsewhere).
#   5. Appends gitignore additions (deduplicated).
#   6. Writes .agent-os-version with the installed version + commit SHA.
#   7. Runs the placeholder validator and prints what's left to fill in.
#   8. Verifies gitleaks is installed; prints install instructions if not.
#   9. Prints branch-protection setup checklist.

set -euo pipefail

VERSION="2.0.0"
REPO_RAW_BASE="https://raw.githubusercontent.com/munsanco13/agent-os"
REPO_REF="${AGENT_OS_REF:-main}"

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
blue()   { printf '\033[0;34m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

TARGET="${1:-$PWD}"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || echo "")"

# --- 0. Detect curl-pipe mode -----------------------------------------
if [[ -z "$SOURCE" || ! -f "$SOURCE/AGENTS.md" ]]; then
  blue "→ curl-pipe mode — fetching template files at ref '$REPO_REF'"
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  paths=(
    "AGENTS.md"
    "SECURITY.md"
    "README.md"
    "VERSION"
    ".gitleaks.toml"
    ".gitignore-additions"
    "docs/sessions/README.md"
    "docs/sessions/_template.md"
    "docs/decisions/README.md"
    "docs/decisions/0000-template.md"
    "docs/decisions/0001-multi-ai-continuity.md"
    "docs/decisions/0002-secret-scanning-with-gitleaks.md"
    "docs/decisions/0003-server-side-enforcement.md"
    ".githooks/pre-commit"
    ".githooks/commit-msg"
    ".githooks/pre-push"
    ".github/workflows/security.yml"
    ".github/workflows/pr-checks.yml"
    ".github/workflows/branch-protection-audit.yml"
    ".github/workflows/hook-tests.yml"
    ".github/CODEOWNERS"
    ".github/pull_request_template.md"
    ".github/dependabot.yml"
    ".github/SECURITY.md"
    "scripts/validate.sh"
    "scripts/update.sh"
    "scripts/uninstall.sh"
    "tests/pre-commit.bats"
  )
  for p in "${paths[@]}"; do
    mkdir -p "$TMP/$(dirname "$p")"
    curl -fsSL "$REPO_RAW_BASE/$REPO_REF$p" -o "$TMP/$p" || {
      red "❌ Failed to download $p — aborting"
      exit 1
    }
  done
  SOURCE="$TMP"
fi

cd "$TARGET"

# --- 0a. Detect platform + warn on plain Windows ---------------------
PLATFORM="$(uname -s 2>/dev/null || echo unknown)"
case "$PLATFORM" in
  Darwin)              blue "→ Platform: macOS";;
  Linux)               blue "→ Platform: Linux";;
  MINGW*|MSYS*|CYGWIN*) yellow "→ Platform: Windows (Git Bash). Hooks will work; ensure 'core.autocrlf=input'.";;
  *)                   yellow "→ Platform: $PLATFORM (unverified)";;
esac

# --- 1. Verify target is a git repo -----------------------------------
if [[ ! -d .git ]] && [[ ! -f .git ]]; then
  red "❌ '$TARGET' is not a git repository. Run 'git init' first."
  exit 1
fi

# --- 1a. On Windows, force core.autocrlf=input to prevent CRLF in hooks
if [[ "$PLATFORM" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  current_autocrlf=$(git config --get core.autocrlf || echo "")
  if [[ "$current_autocrlf" != "input" && "$current_autocrlf" != "false" ]]; then
    git config core.autocrlf input
    yellow "   set   core.autocrlf = input (was '$current_autocrlf') — needed on Windows so bash hooks work"
  fi
fi

# --- 2. Detect competing hook managers --------------------------------
competing=""
[[ -d .husky ]] && competing="Husky (.husky/)"
[[ -f lefthook.yml || -f lefthook.yaml ]] && competing="lefthook"
[[ -f .pre-commit-config.yaml ]] && competing="pre-commit (Python)"
if [[ -n "$competing" ]]; then
  yellow "⚠ Detected existing hook manager: $competing"
  yellow "  Agent OS uses .githooks/ + core.hooksPath. Two hook managers will conflict."
  yellow "  Options:"
  yellow "    A. Remove the existing manager, then re-run this installer"
  yellow "    B. Manually merge .githooks/pre-commit into your existing config"
  yellow "  Aborting to avoid breaking your setup."
  exit 1
fi

bold "→ Installing Agent OS v$VERSION into: $TARGET"
echo

# --- 3. Copy files (never overwrite) ----------------------------------
copy_if_absent() {
  local src="$1" dst="$2" mode="${3:-644}"
  if [[ -e "$dst" ]]; then
    yellow "   skip  $dst (already exists)"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    chmod "$mode" "$dst"
    green "   add   $dst"
  fi
}

copy_if_absent "$SOURCE/AGENTS.md"   "AGENTS.md"
copy_if_absent "$SOURCE/SECURITY.md" "SECURITY.md"
copy_if_absent "$SOURCE/.gitleaks.toml" ".gitleaks.toml"

copy_if_absent "$SOURCE/docs/sessions/README.md"   "docs/sessions/README.md"
copy_if_absent "$SOURCE/docs/sessions/_template.md" "docs/sessions/_template.md"

copy_if_absent "$SOURCE/docs/decisions/README.md"                          "docs/decisions/README.md"
copy_if_absent "$SOURCE/docs/decisions/0000-template.md"                   "docs/decisions/0000-template.md"
copy_if_absent "$SOURCE/docs/decisions/0001-multi-ai-continuity.md"        "docs/decisions/0001-multi-ai-continuity.md"
copy_if_absent "$SOURCE/docs/decisions/0002-secret-scanning-with-gitleaks.md" "docs/decisions/0002-secret-scanning-with-gitleaks.md"
copy_if_absent "$SOURCE/docs/decisions/0003-server-side-enforcement.md"    "docs/decisions/0003-server-side-enforcement.md"

copy_if_absent "$SOURCE/.githooks/pre-commit" ".githooks/pre-commit" 755
copy_if_absent "$SOURCE/.githooks/commit-msg" ".githooks/commit-msg" 755
copy_if_absent "$SOURCE/.githooks/pre-push"   ".githooks/pre-push"   755

# Persist the executable bit in git's index so it survives Windows checkouts
# (Windows filesystems don't preserve POSIX permissions; git's tree mode does).
for h in .githooks/pre-commit .githooks/commit-msg .githooks/pre-push; do
  [[ -f "$h" ]] || continue
  git update-index --chmod=+x "$h" 2>/dev/null || true
done

# Drop in .gitattributes if absent so line endings are normalized cross-platform.
copy_if_absent "$SOURCE/.gitattributes" ".gitattributes"

# --- Multi-AI filename aliases ---
# Different AI tools look for config under different filenames:
#   Claude Code → CLAUDE.md
#   Codex / Cursor / Aider → AGENTS.md
#   Cursor (legacy) → .cursorrules
# Single-source-of-truth: AGENTS.md. Symlink the others to it so editing
# one file updates them all. On Windows (no symlink permissions), fall
# back to copies + a docs note about resyncing.
link_alias() {
  local alias_name="$1" target="$2"
  [[ -e "$alias_name" ]] && return 0   # never overwrite existing
  case "$PLATFORM" in
    Darwin|Linux)
      ln -s "$target" "$alias_name" && green "   add   $alias_name → $target (symlink)"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows symlinks need admin or developer mode; copy as fallback.
      cp "$target" "$alias_name" && yellow "   add   $alias_name (copy of $target — Windows can't symlink without admin)"
      yellow "         Re-copy after editing $target, or enable Windows Developer Mode for symlinks"
      ;;
    *)
      ln -s "$target" "$alias_name" 2>/dev/null && green "   add   $alias_name → $target (symlink)"
      ;;
  esac
}
# Aliases for every major AI coding tool (2026 reality):
link_alias "CLAUDE.md"      "AGENTS.md"   # Claude Code
link_alias ".cursorrules"   "AGENTS.md"   # Cursor (legacy)
link_alias ".clinerules"    "AGENTS.md"   # Cline
link_alias ".continuerules" "AGENTS.md"   # Continue.dev
link_alias "CONVENTIONS.md" "AGENTS.md"   # Aider
# (Codex, GitHub Copilot Workspace, Cody, Tabnine read AGENTS.md directly)

copy_if_absent "$SOURCE/.github/workflows/security.yml"                "$([[ -d .github/workflows ]] && echo .github/workflows/security.yml || echo .github/workflows/security.yml)"
copy_if_absent "$SOURCE/.github/workflows/pr-checks.yml"               ".github/workflows/pr-checks.yml"
copy_if_absent "$SOURCE/.github/workflows/branch-protection-audit.yml" ".github/workflows/branch-protection-audit.yml"
# NOTE: hook-tests.yml is intentionally NOT copied. It runs the bats test
# suite that exists in the agent-os source repo itself; installed projects
# don't ship a tests/ directory, so the workflow would fail in CI.
copy_if_absent "$SOURCE/.github/CODEOWNERS"                            ".github/CODEOWNERS"
copy_if_absent "$SOURCE/.github/pull_request_template.md"              ".github/pull_request_template.md"
copy_if_absent "$SOURCE/.github/dependabot.yml"                        ".github/dependabot.yml"
copy_if_absent "$SOURCE/.github/SECURITY.md"                           ".github/SECURITY.md"

mkdir -p scripts
copy_if_absent "$SOURCE/scripts/validate.sh"  "scripts/agent-os-validate.sh"  755
copy_if_absent "$SOURCE/scripts/update.sh"    "scripts/agent-os-update.sh"    755
copy_if_absent "$SOURCE/scripts/uninstall.sh" "scripts/agent-os-uninstall.sh" 755

# --- 4. Wire core.hooksPath -------------------------------------------
current_hookspath=$(git config --get core.hooksPath || echo "")
if [[ "$current_hookspath" != ".githooks" ]]; then
  if [[ -n "$current_hookspath" ]]; then
    yellow "   warn  core.hooksPath is currently '$current_hookspath' — leaving alone."
    yellow "         Manually merge .githooks/pre-commit into your existing hook setup."
  else
    git config core.hooksPath .githooks
    green "   set   core.hooksPath = .githooks"
  fi
fi

# --- 5. Append gitignore additions (deduplicated) ---------------------
if [[ -f "$SOURCE/.gitignore-additions" ]]; then
  touch .gitignore
  added=0
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue
    if ! grep -qxF "$line" .gitignore 2>/dev/null; then
      echo "$line" >> .gitignore
      added=$((added+1))
    fi
  done < "$SOURCE/.gitignore-additions"
  if [[ "$added" -gt 0 ]]; then
    green "   add   $added new lines to .gitignore"
  else
    yellow "   skip  .gitignore (all entries already present)"
  fi
fi

# --- 6. Write version stamp -------------------------------------------
INSTALL_SHA=$(curl -fsSL "https://api.github.com/repos/munsanco13/agent-os/commits/$REPO_REF" 2>/dev/null | grep -m1 '"sha"' | cut -d'"' -f4 || echo "unknown")
cat > .agent-os-version <<EOF
version: $VERSION
ref: $REPO_REF
installed_sha: $INSTALL_SHA
installed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
green "   add   .agent-os-version"

# --- 7. Validate placeholders -----------------------------------------
echo
bold "→ Validating placeholders…"
unfilled=$(grep -lE '<<[A-Z_]+>>' AGENTS.md SECURITY.md docs/decisions/*.md .github/CODEOWNERS .github/SECURITY.md 2>/dev/null || true)
if [[ -n "$unfilled" ]]; then
  yellow "   These files still contain <<PLACEHOLDER>> tokens — fill them before your first PR:"
  for f in $unfilled; do
    tokens=$(grep -oE '<<[A-Z_]+>>' "$f" | sort -u | tr '\n' ' ')
    echo "     $f → $tokens"
  done
else
  green "   ✓ no unfilled placeholders"
fi

# --- 8. Verify gitleaks -----------------------------------------------
echo
bold "→ Checking gitleaks…"
if command -v gitleaks >/dev/null 2>&1; then
  green "   ✓ gitleaks $(gitleaks version 2>&1 | head -1)"
else
  yellow "   gitleaks NOT installed — strongly recommended"
  yellow "     macOS:        brew install gitleaks"
  yellow "     Linux:        https://github.com/gitleaks/gitleaks/releases"
  yellow "     Without it, the local hook falls back to a small regex set."
  yellow "     CI still uses gitleaks regardless, so secrets are still caught — just not as fast."
fi

# --- 9. Final checklist -----------------------------------------------
echo
bold "✅ Agent OS v$VERSION installed"
echo
bold "Required next steps:"
echo "   1. Replace all <<PLACEHOLDER>> tokens in AGENTS.md, SECURITY.md, CODEOWNERS, etc."
echo "      Run anytime: bash scripts/agent-os-validate.sh"
echo "   2. Configure GitHub branch protection on main:"
echo "      Settings → Branches → Add rule → main"
echo "        ✅ Require PR before merging (1 approval)"
echo "        ✅ Require status checks: secret-scan, large-files, no-direct-pushes,"
echo "           hooks-integrity, placeholder-lint, pr-title, pr-body"
echo "        ✅ Require linear history"
echo "        ❌ Disallow force pushes & deletions"
echo "   3. (Optional) Add BRANCH_PROTECT_TOKEN secret with a fine-grained PAT"
echo "      (Administration: read) for the weekly branch-protection-audit workflow."
echo "   4. Commit the install:"
echo "      git checkout -b chore/install-agent-os-v$VERSION"
echo "      git add AGENTS.md SECURITY.md .gitleaks.toml docs/ .githooks/ .github/ scripts/ .gitignore .agent-os-version"
echo "      git commit -m 'chore: install Agent OS v$VERSION'"
echo "      git push -u origin chore/install-agent-os-v$VERSION"
echo "   5. (Recommended) Test the hooks:"
echo "      echo 'AKIAIOSFODNN7EXAMPLE-TEST' > .env.test && git add .env.test && git commit -m 'test: try'"
echo "      (should be blocked; then 'rm .env.test' and 'git reset HEAD .env.test')"
echo
green "Done."
