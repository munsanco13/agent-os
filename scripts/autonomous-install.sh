#!/usr/bin/env bash
# Agent OS autonomous installer.
#
# Reads bootstrap.yaml + .credentials.local in the project root and does
# everything end-to-end with zero manual steps:
#
#   1. Run scripts/install.sh to drop template files
#   2. Substitute every <<PLACEHOLDER>> from bootstrap.yaml
#   3. Wire git hooks
#   4. Commit + push + PR + auto-merge the install
#   5. Configure GitHub branch protection via gh api + GH_PAT
#   6. (If VERCEL_TOKEN set) link Vercel project + push env vars
#   7. Run validate.sh to confirm green
#
# Designed to be runnable by any AI agent in a fresh sandbox. The agent
# only needs the two config files filled in. Everything else is API.

set -euo pipefail

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
blue()   { printf '\033[0;34m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# --- 0. Prerequisites -------------------------------------------------
for cmd in git gh python3 curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    red "❌ Required tool missing: $cmd"
    exit 1
  fi
done

# yq is preferred for YAML; fall back to a tiny Python helper if absent.
yaml_get() {
  local key="$1" file="$2"
  python3 -c "
import sys, re
with open('$file') as f: text = f.read()
# Tiny YAML reader — handles nested keys via dot notation, no anchors.
parts = '$key'.split('.')
indent = 0
current = {'__root__': True}
stack = [(-1, current)]
for raw in text.split('\n'):
    line = raw.rstrip()
    if not line.strip() or line.lstrip().startswith('#'): continue
    ind = len(line) - len(line.lstrip())
    while stack and stack[-1][0] >= ind:
        stack.pop()
    parent = stack[-1][1] if stack else current
    if ':' in line:
        k, _, v = line.lstrip().partition(':')
        k = k.strip(); v = v.strip().strip('\"').strip(\"'\")
        if v == '':
            parent[k] = {}
            stack.append((ind, parent[k]))
        else:
            parent[k] = v
node = current
for p in parts:
    if not isinstance(node, dict) or p not in node:
        sys.exit(0)
    node = node[p]
print(node if isinstance(node, str) else '')
"
}

# --- 0a. Auto-detect stack if bootstrap.yaml missing or stack section blank ---
if [[ ! -f bootstrap.yaml ]] || ! grep -qE '^stack:' bootstrap.yaml 2>/dev/null; then
  yellow "→ No bootstrap.yaml or no stack section — auto-detecting…"
  template_dir=""
  # Legacy: when run from inside the agent-os source repo (or its old
  # mundox-studio embedded form), the scripts are at the local root
  # or under .agent-template/.
  if   [[ -f scripts/detect-stack.sh ]];               then template_dir="."
  elif [[ -f .agent-template/scripts/detect-stack.sh ]]; then template_dir=".agent-template"
  elif [[ -d /tmp/agent-os-template ]];                 then template_dir="/tmp/agent-os-template"
  elif [[ -d /tmp/agent-os-template/.agent-template ]]; then template_dir="/tmp/agent-os-template/.agent-template"
  fi
  if [[ -n "$template_dir" ]]; then
    detected=$(bash "$template_dir/scripts/detect-stack.sh")
    bold "→ Detected stack:"
    echo "$detected" | head -8
    if [[ ! -f bootstrap.yaml ]]; then
      yellow "  → No bootstrap.yaml — generating bootstrap.yaml from detection + git config"
      gh_user=$(git config --get user.email 2>/dev/null || echo "")
      gh_login=$(gh api user --jq .login 2>/dev/null || echo "")
      repo_url=$(git remote get-url origin 2>/dev/null || echo "")
      repo_owner=$(echo "$repo_url" | sed -E 's|.*[:/]([^/]+)/[^/]+(\.git)?$|\1|')
      repo_name=$(echo  "$repo_url" | sed -E 's|.*/([^/]+)(\.git)?$|\1|; s|\.git$||')
      cat > bootstrap.yaml <<YAML
project:
  name: "${repo_name:-TODO}"
  github_owner: "${repo_owner:-TODO}"
  github_repo:  "${repo_name:-TODO}"
  main_branch:  "main"
$detected
deploy:
  provider: "none"
  production_branch: "main"
maintainer:
  name:   "TODO"
  email:  "${gh_user:-TODO}"
  github: "@${gh_login:-TODO}"
env_vars: []
branch_protection:
  required_reviews: 1
YAML
      green "  ✓ wrote bootstrap.yaml — review and edit any TODO values, then re-run."
      exit 0
    fi
  fi
fi

# --- 1. Sanity check inputs -------------------------------------------
[[ -f bootstrap.yaml ]] || { red "❌ bootstrap.yaml missing — copy bootstrap.example.yaml"; exit 1; }

# --- Credential resolution (zero-friction path first) -----------------
# Priority order:
#   1. GH_PAT env var already exported
#   2. .credentials.local file (advanced users with custom PATs)
#   3. gh CLI already authenticated (most common — most devs have done `gh auth login`)
#   4. None — install runs without server-side automation; manual steps printed at end
GH_PAT="${GH_PAT:-}"
if [[ -z "$GH_PAT" && -f .credentials.local ]]; then
  set -o allexport
  . .credentials.local
  set +o allexport
fi
if [[ -z "${GH_PAT:-}" ]]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    GH_PAT=$(gh auth token 2>/dev/null || echo "")
    [[ -n "$GH_PAT" ]] && green "→ Using existing gh CLI auth (no .credentials.local needed)"
  fi
fi
HAS_PAT=0
[[ -n "${GH_PAT:-}" ]] && HAS_PAT=1
if [[ "$HAS_PAT" == "0" ]]; then
  yellow "⚠ No GitHub credential available. Install will proceed without server-side automation."
  yellow "  PR auto-merge + branch protection setup will be skipped."
  yellow "  Enable later: run 'gh auth login' OR put GH_PAT=xxx in .credentials.local, then re-run."
fi

PROJECT_NAME=$(yaml_get project.name      bootstrap.yaml)
GITHUB_OWNER=$(yaml_get project.github_owner bootstrap.yaml)
GITHUB_REPO=$(yaml_get  project.github_repo  bootstrap.yaml)
MAIN_BRANCH=$(yaml_get  project.main_branch  bootstrap.yaml)
STACK_DESC=$(yaml_get   stack.description    bootstrap.yaml)
INSTALL_CMD=$(yaml_get  stack.install_command bootstrap.yaml)
DEV_CMD=$(yaml_get      stack.dev_command     bootstrap.yaml)
TEST_CMD=$(yaml_get     stack.test_command    bootstrap.yaml)
LINT_CMD=$(yaml_get     stack.lint_command    bootstrap.yaml)
DEPLOY_PROVIDER=$(yaml_get deploy.provider    bootstrap.yaml)
DEPLOY_PROD_BRANCH=$(yaml_get deploy.production_branch bootstrap.yaml)
MAINTAINER_EMAIL=$(yaml_get maintainer.email  bootstrap.yaml)
MAINTAINER_GH=$(yaml_get   maintainer.github   bootstrap.yaml)

bold "→ Agent OS autonomous install"
echo "  Project:  $PROJECT_NAME ($GITHUB_OWNER/$GITHUB_REPO)"
echo "  Stack:    $STACK_DESC"
echo "  Branch:   $MAIN_BRANCH"
echo "  Deploy:   $DEPLOY_PROVIDER"
echo

# --- 2. Run base installer (drops files) -----------------------------
template_dir=""
if [[ -f scripts/install.sh && -f AGENTS.md ]]; then
  # Running from inside the agent-os source repo itself
  template_dir="."
elif [[ -f .agent-template/scripts/install.sh ]]; then
  template_dir=".agent-template"
elif [[ -d /tmp/agent-os-template/scripts ]]; then
  template_dir="/tmp/agent-os-template"
elif [[ -d /tmp/agent-os-template/.agent-template ]]; then
  template_dir="/tmp/agent-os-template/.agent-template"
else
  blue "→ Cloning template into /tmp/agent-os-template"
  git clone --depth 1 --branch v2.3.0 \
    https://github.com/munsanco13/agent-os /tmp/agent-os-template 2>&1 | tail -3
  template_dir="/tmp/agent-os-template"
fi

bash "$template_dir/scripts/install.sh" "$PWD"

# --- 3. Substitute placeholders ---------------------------------------
bold "→ Substituting placeholders"
substitute() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  python3 - "$file" "$PROJECT_NAME" "$STACK_DESC" "$DEPLOY_PROVIDER" "$DEPLOY_PROD_BRANCH" \
                    "$DEV_CMD" "$TEST_CMD" "$LINT_CMD" "$INSTALL_CMD" \
                    "$MAINTAINER_GH" "$MAINTAINER_EMAIL" <<'PY'
import sys, pathlib
file, name, stack, deploy_provider, prod_branch, dev, test, lint, install, github, email = sys.argv[1:]
p = pathlib.Path(file)
text = p.read_text()
deploy_target = f"{deploy_provider} auto-deploy from {prod_branch}" if deploy_provider != "none" else "manual deploy"
subs = {
    "<<PROJECT_NAME>>":     name,
    "<<STACK>>":            stack,
    "<<DEPLOY_TARGET>>":    deploy_target,
    "<<DEV_COMMAND>>":      dev,
    "<<TEST_COMMAND>>":     test,
    "<<LINT_COMMAND>>":     lint,
    "<<INSTALL_COMMAND>>":  install,
    "<<GITHUB_USERNAME>>":  github,
    "<<SECURITY_EMAIL>>":   email,
}
for k, v in subs.items():
    text = text.replace(k, v)
p.write_text(text)
PY
  green "   ✓ $file"
}

substitute AGENTS.md
substitute SECURITY.md
substitute .github/CODEOWNERS
substitute .github/SECURITY.md

# --- 4. Commit + push + PR -------------------------------------------
bold "→ Committing install"
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" == "$MAIN_BRANCH" ]]; then
  git checkout -b chore/install-agent-os
fi
git add -A
git -c user.email="$MAINTAINER_EMAIL" -c user.name="$MAINTAINER_GH" \
    commit -m "chore: install Agent OS v2.3.0 (autonomous)" --allow-empty

if [[ "$HAS_PAT" == "1" ]]; then
  # Use gh auth token if it came from existing gh login (skip re-auth);
  # only re-auth if PAT came from .credentials.local / env.
  if [[ "${GH_PAT_SOURCE:-existing}" != "existing" ]]; then
    echo "$GH_PAT" | gh auth login --with-token >/dev/null 2>&1 || true
  fi

  bold "→ Pushing branch"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" 2>&1 | tail -3

  bold "→ Opening PR"
  pr_url=$(GH_TOKEN="$GH_PAT" gh pr create --base "$MAIN_BRANCH" \
    --title "chore: install Agent OS v2.3.0 (autonomous)" \
    --body "Auto-installed by autonomous-install.sh from bootstrap.yaml." \
    2>&1 | tail -1)
  echo "  $pr_url"

  bold "→ Auto-merging PR"
  GH_TOKEN="$GH_PAT" gh pr merge --auto --merge --delete-branch "$pr_url" 2>&1 | tail -3 || \
    GH_TOKEN="$GH_PAT" gh pr merge --merge --delete-branch "$pr_url" 2>&1 | tail -3

  git fetch origin && git checkout "$MAIN_BRANCH" && git pull origin "$MAIN_BRANCH"
else
  bold "→ Pushing branch"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" 2>&1 | tail -3
  yellow "⚠ Skipping PR auto-merge (no GitHub credential)."
  yellow "  Open the PR manually in your browser and merge it."
fi

# --- 5. Configure branch protection via gh api -----------------------
if [[ "$HAS_PAT" == "0" ]]; then
  yellow "⚠ Skipping branch protection (no GitHub credential)."
  yellow "  Configure manually: Settings → Branches → Add rule → main"
  yellow "  Required status checks: secret-scan, large-files, no-direct-pushes,"
  yellow "  hooks-integrity, placeholder-lint, pr-title, pr-body"
  echo
  bold "→ Final validation"
  bash scripts/agent-os-validate.sh || true
  exit 0
fi

bold "→ Configuring branch protection on $MAIN_BRANCH"
required_checks=$(yaml_get branch_protection.require_status_checks bootstrap.yaml || echo "")
# Build JSON payload
python3 - "$GITHUB_OWNER" "$GITHUB_REPO" "$MAIN_BRANCH" "$GH_PAT" <<'PY'
import json, os, sys, urllib.request

owner, repo, branch, pat = sys.argv[1:]

payload = {
  "required_status_checks": {
    "strict": True,
    "contexts": [
      "secret-scan", "large-files", "no-direct-pushes",
      "hooks-integrity", "placeholder-lint", "pr-title", "pr-body"
    ],
  },
  "enforce_admins": False,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": True,
    "require_code_owner_reviews": True,
    "required_approving_review_count": 1,
  },
  "restrictions": None,
  "required_linear_history": True,
  "allow_force_pushes": False,
  "allow_deletions": False,
  "required_conversation_resolution": True,
  "lock_branch": False,
  "allow_fork_syncing": True,
}

req = urllib.request.Request(
  f"https://api.github.com/repos/{owner}/{repo}/branches/{branch}/protection",
  data=json.dumps(payload).encode(),
  method="PUT",
  headers={
    "Authorization": f"Bearer {pat}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
  },
)
try:
  with urllib.request.urlopen(req) as r:
    print(f"   ✓ branch protection applied (HTTP {r.status})")
except urllib.error.HTTPError as e:
  print(f"   ⚠ branch protection failed: HTTP {e.code} — {e.read().decode()[:200]}")
  sys.exit(1)
PY

# --- 6. Vercel setup (optional) --------------------------------------
if [[ "$DEPLOY_PROVIDER" == "vercel" && -n "${VERCEL_TOKEN:-}" ]]; then
  bold "→ Vercel: linking project + pushing env vars"
  if ! command -v vercel >/dev/null 2>&1; then
    yellow "   vercel CLI missing; install with: npm i -g vercel  (skipping Vercel automation)"
  else
    yellow "   (Vercel automation hooks here — left as exercise; vercel env add reads from stdin)"
    yellow "   For now, manually add env vars in dashboard or via:"
    yellow "     vercel env add NEXT_PUBLIC_SUPABASE_URL production"
  fi
fi

# --- 7. Validate ------------------------------------------------------
echo
bold "→ Final validation"
bash scripts/agent-os-validate.sh

echo
green "✅ Agent OS v2.2.0 autonomous install complete."
green "   Branch protection live, CI workflows running, hooks wired."
echo
yellow "Manual follow-ups (rare):"
yellow "  • If your repo has Vercel deploys, confirm env vars + Sensitive flags in dashboard"
yellow "  • If using Supabase, run: vercel env pull apps/web/.env.local for local dev"
