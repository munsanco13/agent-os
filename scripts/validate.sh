#!/usr/bin/env bash
# Agent OS validator — checks installation integrity and surfaces what's broken.
#
# Run after install, after pulling, or any time something feels off.
# Exit 0 if clean; non-zero if anything's wrong.

set -euo pipefail

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

failed=0

bold "→ Agent OS validation"
echo

# 1. Required files present
required_files=(
  "AGENTS.md"
  "SECURITY.md"
  ".gitleaks.toml"
  ".agent-os-version"
  "docs/sessions/README.md"
  "docs/sessions/_template.md"
  "docs/decisions/README.md"
  "docs/decisions/0000-template.md"
  ".githooks/pre-commit"
  ".githooks/commit-msg"
  ".githooks/pre-push"
  ".github/workflows/security.yml"
  ".github/workflows/pr-checks.yml"
  ".github/CODEOWNERS"
  ".github/pull_request_template.md"
  ".github/dependabot.yml"
)
for f in "${required_files[@]}"; do
  if [[ ! -e "$f" ]]; then
    red "   ✗ missing: $f"
    failed=1
  fi
done
[[ "$failed" == 0 ]] && green "   ✓ all required files present"

# 2. Hooks executable
echo
bold "→ Hook permissions"
for h in .githooks/pre-commit .githooks/commit-msg .githooks/pre-push; do
  if [[ -f "$h" && ! -x "$h" ]]; then
    red "   ✗ $h is not executable — run: chmod +x $h && git update-index --chmod=+x $h"
    failed=1
  fi
done
[[ "$failed" == 0 ]] && green "   ✓ hooks are executable"

# 2b. Hooks have LF line endings (Windows / cross-platform check)
echo
bold "→ Hook line endings (LF, not CRLF)"
for h in .githooks/pre-commit .githooks/commit-msg .githooks/pre-push; do
  if [[ -f "$h" ]] && grep -q $'\r' "$h" 2>/dev/null; then
    red "   ✗ $h contains CRLF line endings — hooks will fail with \$'\\r': command not found"
    red "     Fix: dos2unix $h   (or: sed -i 's/\\r\$//' $h)"
    red "     Prevent: ensure .gitattributes is in the repo root and 'core.autocrlf=input' on Windows"
    failed=1
  fi
done
[[ "$failed" == 0 ]] && green "   ✓ hooks use LF line endings"

# 3. core.hooksPath wired
echo
bold "→ Hook wiring"
hp=$(git config --get core.hooksPath || echo "")
if [[ "$hp" == ".githooks" ]]; then
  green "   ✓ core.hooksPath = .githooks"
else
  red "   ✗ core.hooksPath is '$hp' — should be '.githooks'"
  red "     Fix: git config core.hooksPath .githooks"
  failed=1
fi

# 4. gitleaks installed?
echo
bold "→ gitleaks"
if command -v gitleaks >/dev/null 2>&1; then
  green "   ✓ $(gitleaks version 2>&1 | head -1)"
else
  yellow "   ⚠ gitleaks not installed (CI still uses it; local fallback is weaker)"
fi

# 5. Placeholder check
echo
bold "→ Placeholder tokens"
unfilled=()
for f in AGENTS.md SECURITY.md .github/CODEOWNERS .github/SECURITY.md docs/decisions/*.md; do
  [[ -f "$f" ]] || continue
  if grep -qE '<<[A-Z_]+>>' "$f"; then
    tokens=$(grep -oE '<<[A-Z_]+>>' "$f" | sort -u | tr '\n' ' ')
    unfilled+=("$f → $tokens")
  fi
done
if [[ ${#unfilled[@]} -gt 0 ]]; then
  red "   ✗ unfilled placeholders:"
  for u in "${unfilled[@]}"; do echo "     $u"; done
  failed=1
else
  green "   ✓ no unfilled placeholders"
fi

# 6. Workflows reference each other correctly
echo
bold "→ Workflow integrity"
for wf in .github/workflows/security.yml .github/workflows/pr-checks.yml; do
  if [[ -f "$wf" ]]; then
    if ! grep -q "name:" "$wf"; then
      red "   ✗ $wf is malformed (no 'name:' field)"
      failed=1
    fi
  fi
done
[[ "$failed" == 0 ]] && green "   ✓ workflows present"

# 7. Version stamp readable
echo
bold "→ Version stamp"
if [[ -f .agent-os-version ]]; then
  installed=$(grep '^version:' .agent-os-version | cut -d' ' -f2)
  green "   ✓ Agent OS v$installed installed"
else
  yellow "   ⚠ no .agent-os-version (run install.sh to create)"
fi

echo
if [[ "$failed" == 0 ]]; then
  green "✅ Validation passed."
  exit 0
else
  red "❌ Validation failed — fix the items above."
  exit 1
fi
