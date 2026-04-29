#!/usr/bin/env bash
# Agent OS stack auto-detection.
#
# Sniffs the project for known manifest/lockfile signatures and outputs the
# commands an AI should use for install / dev / test / lint. Designed to be
# called from autonomous-install.sh OR run standalone (`bash detect-stack.sh`)
# to print a YAML snippet for bootstrap.yaml.
#
# Detection priority (first match wins):
#   1. Node.js (package.json) — pnpm > yarn > bun > npm based on lockfile
#   2. Python (pyproject.toml / requirements.txt) — uv > poetry > pip
#   3. Rust (Cargo.toml)
#   4. Go (go.mod)
#   5. Ruby (Gemfile)
#   6. PHP (composer.json)
#   7. Elixir (mix.exs)
#   8. Java/Kotlin (pom.xml, build.gradle)
#   9. Deno (deno.json)
#  10. Unknown — emit blanks with TODOs

set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

emit() {
  cat <<YAML
stack:
  description: "$1"
  install_command: "$2"
  dev_command:     "$3"
  test_command:    "$4"
  lint_command:    "$5"
detected:
  language: "$6"
  framework: "${7:-unknown}"
  package_manager: "${8:-unknown}"
YAML
}

# --- Node.js / TypeScript ---
if [[ -f package.json ]]; then
  pkg_mgr="npm"
  install_cmd="npm install"
  dev_cmd="npm run dev"
  test_cmd="npm test"
  lint_cmd="npm run lint"

  # Detect package manager from lockfile
  if   [[ -f pnpm-lock.yaml ]];   then pkg_mgr="pnpm"; install_cmd="pnpm install"; dev_cmd="pnpm dev"; test_cmd="pnpm test"; lint_cmd="pnpm lint"
  elif [[ -f yarn.lock ]];        then pkg_mgr="yarn"; install_cmd="yarn install"; dev_cmd="yarn dev"; test_cmd="yarn test"; lint_cmd="yarn lint"
  elif [[ -f bun.lockb ]];        then pkg_mgr="bun";  install_cmd="bun install";  dev_cmd="bun dev";  test_cmd="bun test";  lint_cmd="bun run lint"
  fi

  # Detect framework
  framework="node"
  if grep -q '"next"' package.json 2>/dev/null;     then framework="next.js"
  elif grep -q '"vite"' package.json 2>/dev/null;    then framework="vite"
  elif grep -q '"@remix-run' package.json 2>/dev/null; then framework="remix"
  elif grep -q '"@nestjs' package.json 2>/dev/null;  then framework="nestjs"
  elif grep -q '"express"' package.json 2>/dev/null; then framework="express"
  elif grep -q '"fastify"' package.json 2>/dev/null; then framework="fastify"
  elif grep -q '"sveltekit"\|"@sveltejs/kit"' package.json 2>/dev/null; then framework="sveltekit"
  elif grep -q '"react"' package.json 2>/dev/null;   then framework="react"
  fi

  # Override dev/lint scripts if defined in package.json
  for script in dev start build test lint typecheck; do
    if grep -qE "\"$script\"\\s*:" package.json 2>/dev/null; then
      case "$script" in
        dev|start) [[ "$dev_cmd" == *"$script"* ]] || dev_cmd="$pkg_mgr run $script" ;;
      esac
    fi
  done

  emit "Node.js / $framework ($pkg_mgr)" "$install_cmd" "$dev_cmd" "$test_cmd" "$lint_cmd" "JavaScript/TypeScript" "$framework" "$pkg_mgr"
  exit 0
fi

# --- Python ---
if [[ -f pyproject.toml ]]; then
  if   [[ -f uv.lock ]];           then emit "Python (uv)"        "uv sync"            "uv run python main.py"     "uv run pytest"   "uv run ruff check ." "Python" "uv-managed" "uv"
  elif [[ -f poetry.lock ]];       then emit "Python (Poetry)"    "poetry install"     "poetry run python main.py" "poetry run pytest" "poetry run ruff check ." "Python" "poetry-managed" "poetry"
  else emit "Python (pyproject.toml)" "pip install -e ."      "python main.py"            "pytest"          "ruff check ." "Python" "pyproject" "pip"
  fi
  exit 0
fi
if [[ -f requirements.txt ]]; then
  emit "Python (requirements.txt)" "pip install -r requirements.txt" "python main.py" "pytest" "ruff check ." "Python" "requirements" "pip"
  exit 0
fi
if [[ -f Pipfile ]]; then
  emit "Python (pipenv)" "pipenv install" "pipenv run python main.py" "pipenv run pytest" "pipenv run ruff check ." "Python" "pipenv" "pipenv"
  exit 0
fi

# --- Rust ---
if [[ -f Cargo.toml ]]; then
  emit "Rust (Cargo)" "cargo build" "cargo run" "cargo test" "cargo clippy -- -D warnings" "Rust" "cargo" "cargo"
  exit 0
fi

# --- Go ---
if [[ -f go.mod ]]; then
  emit "Go" "go mod download" "go run ." "go test ./..." "go vet ./... && gofmt -l ." "Go" "go" "go"
  exit 0
fi

# --- Ruby ---
if [[ -f Gemfile ]]; then
  framework="ruby"
  if grep -q "rails" Gemfile 2>/dev/null; then framework="rails"; fi
  emit "Ruby ($framework)" "bundle install" "bundle exec ${framework}" "bundle exec rspec" "bundle exec rubocop" "Ruby" "$framework" "bundler"
  exit 0
fi

# --- PHP ---
if [[ -f composer.json ]]; then
  framework="php"
  grep -q "laravel/framework" composer.json 2>/dev/null && framework="laravel"
  grep -q "symfony/" composer.json 2>/dev/null && framework="symfony"
  emit "PHP ($framework)" "composer install" "php -S localhost:8000 -t public" "vendor/bin/phpunit" "vendor/bin/phpcs" "PHP" "$framework" "composer"
  exit 0
fi

# --- Elixir ---
if [[ -f mix.exs ]]; then
  emit "Elixir / Phoenix" "mix deps.get" "mix phx.server" "mix test" "mix credo" "Elixir" "phoenix" "mix"
  exit 0
fi

# --- Java / Kotlin ---
if [[ -f pom.xml ]]; then
  emit "Java (Maven)" "mvn install" "mvn spring-boot:run" "mvn test" "mvn checkstyle:check" "Java" "maven" "maven"
  exit 0
fi
if [[ -f build.gradle || -f build.gradle.kts ]]; then
  emit "JVM (Gradle)" "./gradlew build" "./gradlew bootRun" "./gradlew test" "./gradlew check" "JVM" "gradle" "gradle"
  exit 0
fi

# --- Deno ---
if [[ -f deno.json || -f deno.jsonc ]]; then
  emit "Deno" "deno install" "deno run -A main.ts" "deno test -A" "deno lint" "TypeScript" "deno" "deno"
  exit 0
fi

# --- Unknown ---
cat <<'YAML'
stack:
  description: "TODO — could not auto-detect stack"
  install_command: "# TODO: fill in"
  dev_command:     "# TODO: fill in"
  test_command:    "# TODO: fill in"
  lint_command:    "# TODO: fill in"
detected:
  language: "unknown"
  framework: "unknown"
  package_manager: "unknown"
YAML
exit 0
