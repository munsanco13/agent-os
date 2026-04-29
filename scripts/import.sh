#!/usr/bin/env bash
# Agent OS — import existing AI rule files into AGENTS.md.
#
# Looks for legacy single-tool config files (CLAUDE.md from before AGENTS.md
# existed, .cursorrules, .clinerules, etc.) and merges their content into
# AGENTS.md under a "Imported rules" section, then replaces them with
# symlinks pointing at AGENTS.md.
#
# Run this AFTER installing Agent OS into a project that already had legacy
# config from a single AI tool.
#
# Inspired by zuharz/ccode-to-codex's migration pattern: preview → validate →
# write → audit-log. Difference: we merge into one file instead of forking
# per-tool formats.

set -euo pipefail

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

[[ -f AGENTS.md ]] || { red "❌ AGENTS.md not found. Run install.sh first."; exit 1; }

# Files we know how to import. (Only legacy single-tool files — NOT the
# symlinks our own installer creates, which already point at AGENTS.md.)
declare -a CANDIDATES=(
  "CLAUDE.md:Claude Code"
  ".cursorrules:Cursor"
  ".clinerules:Cline"
  ".continuerules:Continue.dev"
  "CONVENTIONS.md:Aider"
  ".aider.conf.yml:Aider config"
  ".github/copilot-instructions.md:GitHub Copilot Workspace"
)

# --- 1. Detect what's importable ---
to_import=()
for entry in "${CANDIDATES[@]}"; do
  file="${entry%%:*}"
  tool="${entry##*:}"
  if [[ -f "$file" && ! -L "$file" ]]; then
    # Real file (not already a symlink). Worth importing.
    size=$(wc -c < "$file" 2>/dev/null || echo 0)
    [[ "$size" -gt 10 ]] && to_import+=("$file:$tool")
  fi
done

if [[ ${#to_import[@]} -eq 0 ]]; then
  green "✓ Nothing to import — no legacy single-tool config files found."
  exit 0
fi

# --- 2. Preview ---
bold "→ Found ${#to_import[@]} legacy config file(s) to import:"
for entry in "${to_import[@]}"; do
  file="${entry%%:*}"
  tool="${entry##*:}"
  size=$(wc -l < "$file" | tr -d ' ')
  echo "   $file ($tool, $size lines)"
done
echo

# --- 3. Confirm ---
if [[ "${AGENT_OS_IMPORT_YES:-0}" != "1" ]]; then
  read -rp "Merge these into AGENTS.md? Original files will be backed up to .agent-os-import-backup/ then replaced with symlinks to AGENTS.md. [y/N]: " confirm
  [[ "$confirm" == "y" || "$confirm" == "Y" ]] || { yellow "Aborted."; exit 0; }
fi

# --- 4. Backup originals ---
mkdir -p .agent-os-import-backup
ts=$(date +%Y-%m-%dT%H-%M-%S)
backup_dir=".agent-os-import-backup/$ts"
mkdir -p "$backup_dir"

# --- 5. Append to AGENTS.md ---
{
  echo
  echo "---"
  echo
  echo "## Imported rules (merged $(date -u +%Y-%m-%dT%H:%M:%SZ))"
  echo
  echo "These sections were imported from legacy single-tool config files. Edit them inline as you would any other section of AGENTS.md."
  echo
} >> AGENTS.md

for entry in "${to_import[@]}"; do
  file="${entry%%:*}"
  tool="${entry##*:}"
  # Backup
  cp "$file" "$backup_dir/$(basename "$file")"
  # Append section
  {
    echo "### From \`$file\` ($tool)"
    echo
    cat "$file"
    echo
  } >> AGENTS.md
  green "   merged $file → AGENTS.md"
  # Replace with symlink (or copy on Windows)
  rm "$file"
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) cp AGENTS.md "$file" ;;
    *)                    ln -s AGENTS.md "$file" ;;
  esac
  green "   relinked $file → AGENTS.md"
done

# --- 6. Audit log ---
{
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)  imported ${#to_import[@]} file(s):"
  for entry in "${to_import[@]}"; do echo "    ${entry%%:*}"; done
  echo "  backup: $backup_dir"
} >> .agent-os-import-backup/audit.log

echo
green "✅ Imported ${#to_import[@]} file(s) into AGENTS.md."
yellow "   Originals backed up to: $backup_dir"
yellow "   Audit log:              .agent-os-import-backup/audit.log"
echo
yellow "Recommended:"
echo "   1. Open AGENTS.md and consolidate duplicate / redundant sections from imports"
echo "   2. Remove the 'Imported rules' header once content is integrated"
echo "   3. Commit: git add AGENTS.md .agent-os-import-backup && git commit -m 'chore: import legacy AI config into AGENTS.md'"
