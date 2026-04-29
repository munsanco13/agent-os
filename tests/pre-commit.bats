#!/usr/bin/env bats
# bats tests for .githooks/pre-commit
# Run locally: bats tests/
# Run in CI:   .github/workflows/hook-tests.yml

setup() {
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"
  git init -q -b feature
  git config user.email "test@example.com"
  git config user.name  "test"
  git config commit.gpgsign false

  # Copy hook into the test repo
  HOOK_SRC="${BATS_TEST_DIRNAME}/../.githooks/pre-commit"
  mkdir -p .githooks
  cp "$HOOK_SRC" .githooks/pre-commit
  chmod +x .githooks/pre-commit
  git config core.hooksPath .githooks

  # Optional gitleaks config
  if [[ -f "${BATS_TEST_DIRNAME}/../.gitleaks.toml" ]]; then
    cp "${BATS_TEST_DIRNAME}/../.gitleaks.toml" .gitleaks.toml
  fi
}

teardown() {
  cd /
  rm -rf "$TMPDIR"
}

# --- Filename pattern tests ---

@test "blocks .env file" {
  echo "FOO=bar" > .env
  git add .env
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q ".env"
}

@test "blocks .env.production" {
  echo "FOO=bar" > .env.production
  git add .env.production
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

@test "allows .env.example" {
  echo "FOO=your-value-here" > .env.example
  git add .env.example
  run git commit -m "feat: add env example"
  [ "$status" -eq 0 ]
}

@test "blocks credentials.json" {
  echo "{}" > credentials.json
  git add credentials.json
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

@test "blocks file.pem" {
  echo "x" > server.pem
  git add server.pem
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

@test "blocks id_rsa" {
  echo "x" > id_rsa
  git add id_rsa
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

# --- Content scan tests (only run if gitleaks installed) ---

@test "blocks AWS access key id pattern" {
  if ! command -v gitleaks >/dev/null 2>&1; then
    skip "gitleaks not installed; fallback regex covers this case"
  fi
  echo "key = AKIAIOSFODNN7EXAMPLEX" > config.txt
  git add config.txt
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

@test "blocks Anthropic API key pattern" {
  if ! command -v gitleaks >/dev/null 2>&1; then
    skip "gitleaks not installed"
  fi
  cat > config.ts <<'EOF'
export const KEY = "sk-ant-api03-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
EOF
  git add config.ts
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

@test "blocks PEM private key" {
  cat > leaked.txt <<'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAKj34GkxFhD9
-----END RSA PRIVATE KEY-----
EOF
  git add leaked.txt
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

# --- Large file test ---

@test "blocks file > 5MB" {
  dd if=/dev/zero of=big.bin bs=1m count=6 2>/dev/null || dd if=/dev/zero of=big.bin bs=1M count=6 2>/dev/null
  git add big.bin
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
}

@test "allows file < 5MB" {
  dd if=/dev/zero of=small.bin bs=1k count=10 2>/dev/null
  git add small.bin
  run git commit -m "feat: small file"
  [ "$status" -eq 0 ]
}

# --- Main branch refusal ---

@test "blocks direct commit to main" {
  git checkout -q -b main
  echo "ok" > readme.md
  git add readme.md
  run git commit -m "feat: try"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "main"
}

@test "allows commit to feature branch" {
  echo "ok" > readme.md
  git add readme.md
  run git commit -m "feat: ok"
  [ "$status" -eq 0 ]
}

@test "allows main commit when AGENT_OS_ALLOW_MAIN_COMMIT=1" {
  git checkout -q -b main
  echo "ok" > readme.md
  git add readme.md
  AGENT_OS_ALLOW_MAIN_COMMIT=1 run git commit -m "feat: ok"
  [ "$status" -eq 0 ]
}

# --- Clean commit on a feature branch passes ---

@test "clean code commit succeeds" {
  cat > index.js <<'EOF'
function add(a, b) { return a + b; }
module.exports = { add };
EOF
  git add index.js
  run git commit -m "feat: add helper"
  [ "$status" -eq 0 ]
}
