#!/usr/bin/env bash
# Agent OS update — pulls a newer template version, shows the diff, and lets
# you apply selected changes. Conservative: never overwrites without confirmation.
#
# Usage:
#   bash scripts/agent-os-update.sh [target-version]
#   bash scripts/agent-os-update.sh                  # uses latest tag
#   bash scripts/agent-os-update.sh v2.3.0           # specific version

set -euo pipefail

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

REPO_RAW_BASE="https://raw.githubusercontent.com/munsanco13/agent-os"
TARGET_REF="${1:-}"

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [[ ! -f .agent-os-version ]]; then
  red "❌ No .agent-os-version found — Agent OS doesn't appear to be installed."
  echo "   Run install.sh first."
  exit 1
fi

current=$(grep '^version:' .agent-os-version | cut -d' ' -f2)
bold "→ Currently installed: Agent OS v$current"

# Resolve target version
if [[ -z "$TARGET_REF" ]]; then
  TARGET_REF=$(curl -fsSL "https://api.github.com/repos/munsanco13/agent-os/tags" 2>/dev/null \
    | grep -m1 '"name"' | cut -d'"' -f4 || echo "main")
  yellow "→ Latest tag: $TARGET_REF"
fi

# Download new template into a temp dir
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
green "→ Fetching template at ref '$TARGET_REF'..."

# NOTE: AGENTS.md and SECURITY.md are user-owned after install. The
# installer ships starter content with placeholders; users customize
# them with project-specific values. Re-syncing them on update would
# trash those customizations. If you want to compare your version to
# upstream's latest, see scripts/agent-os-diff-userdocs.sh (TODO).
paths=(
  ".gitleaks.toml"
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
)

for p in "${paths[@]}"; do
  mkdir -p "$TMP/$(dirname "$p")"
  if ! curl -fsSL "$REPO_RAW_BASE/$TARGET_REF$p" -o "$TMP/$p"; then
    yellow "   warn  could not fetch $p (may not exist in this version)"
    rm -f "$TMP/$p"
  fi
done

# Show diff and let user approve per-file
echo
bold "→ Differences (current → $TARGET_REF):"
echo

changes=()
for p in "${paths[@]}"; do
  if [[ ! -f "$TMP/$p" ]]; then continue; fi
  if [[ ! -f "$p" ]]; then
    yellow "   NEW    $p"
    changes+=("$p")
  elif ! diff -q "$p" "$TMP/$p" >/dev/null 2>&1; then
    yellow "   CHANGE $p"
    changes+=("$p")
  fi
done

if [[ ${#changes[@]} -eq 0 ]]; then
  green "✅ Already up to date."
  exit 0
fi

echo
bold "→ Apply updates?"
echo "   [y] yes, all"
echo "   [d] show full diff first"
echo "   [n] no, abort"
read -rp "Choice [y/d/n]: " choice

case "$choice" in
  d|D)
    for p in "${changes[@]}"; do
      if [[ -f "$p" ]]; then
        echo "─── $p ───"
        diff -u "$p" "$TMP/$p" || true
        echo
      else
        echo "─── NEW $p ───"
        cat "$TMP/$p"
        echo
      fi
    done
    read -rp "Apply all changes now? [y/n]: " choice
    [[ "$choice" != "y" && "$choice" != "Y" ]] && { red "Aborted."; exit 0; }
    ;;
  y|Y) ;;
  *) red "Aborted."; exit 0 ;;
esac

# Apply
for p in "${changes[@]}"; do
  mkdir -p "$(dirname "$p")"
  cp "$TMP/$p" "$p"
  green "   updated $p"
done

# Update version stamp
INSTALL_SHA=$(curl -fsSL "https://api.github.com/repos/munsanco13/agent-os/commits/$TARGET_REF" 2>/dev/null | grep -m1 '"sha"' | cut -d'"' -f4 || echo "unknown")
NEW_VERSION=$(curl -fsSL "$REPO_RAW_BASE/$TARGET_REFVERSION" 2>/dev/null | tr -d '\n' || echo "$TARGET_REF")
cat > .agent-os-version <<EOF
version: $NEW_VERSION
ref: $TARGET_REF
installed_sha: $INSTALL_SHA
installed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo
green "✅ Updated to Agent OS v$NEW_VERSION ($TARGET_REF)"
echo
yellow "Next:"
echo "   bash scripts/agent-os-validate.sh    # confirm clean install"
echo "   git diff                              # review what changed"
echo "   git checkout -b chore/update-agent-os-$NEW_VERSION"
echo "   git add . && git commit -m 'chore: update Agent OS to $NEW_VERSION'"
