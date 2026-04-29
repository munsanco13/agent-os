#!/usr/bin/env bash
# Agent OS uninstall — reverses a default install.
# Will prompt before removing each file. Never removes git history.

set -euo pipefail

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

bold "→ Agent OS uninstall"
yellow "  This will remove Agent OS files. It will NOT modify git history or remove your"
yellow "  customizations to AGENTS.md / SECURITY.md (those are yours now)."
yellow "  Branch protection rules in GitHub must be removed manually."
echo

read -rp "Continue? [y/N]: " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || { red "Aborted."; exit 0; }

remove_if_exists() {
  local p="$1"
  if [[ -e "$p" ]]; then
    read -rp "  remove $p ? [y/N]: " yn
    if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
      rm -rf "$p"
      green "    removed"
    fi
  fi
}

# Hooks
remove_if_exists ".githooks/pre-commit"
remove_if_exists ".githooks/commit-msg"
remove_if_exists ".githooks/pre-push"
[[ -d .githooks && -z "$(ls -A .githooks)" ]] && rmdir .githooks

# Config
git config --unset core.hooksPath 2>/dev/null && green "    unset core.hooksPath" || true

# Workflows
remove_if_exists ".github/workflows/security.yml"
remove_if_exists ".github/workflows/pr-checks.yml"
remove_if_exists ".github/workflows/branch-protection-audit.yml"
remove_if_exists ".github/workflows/hook-tests.yml"

# Other GitHub config
remove_if_exists ".github/CODEOWNERS"
remove_if_exists ".github/pull_request_template.md"
remove_if_exists ".github/dependabot.yml"
remove_if_exists ".github/SECURITY.md"

# Scanner config
remove_if_exists ".gitleaks.toml"

# Version stamp
remove_if_exists ".agent-os-version"

# NOTE: deliberately leaving alone:
#   AGENTS.md, SECURITY.md, docs/sessions/, docs/decisions/, scripts/agent-os-*.sh
# These contain your project's actual content. Delete manually if desired.

echo
green "✅ Agent OS uninstalled."
yellow "  Manually delete if no longer wanted:"
yellow "    AGENTS.md  SECURITY.md  docs/sessions/  docs/decisions/"
yellow "    scripts/agent-os-validate.sh  scripts/agent-os-update.sh  scripts/agent-os-uninstall.sh"
yellow "  Manually unset GitHub branch protection rules in repo Settings."
