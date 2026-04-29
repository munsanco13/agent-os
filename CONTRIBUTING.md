# Contributing to Agent OS

Thanks for thinking about contributing. Here's how to make a PR that lands.

## Quick start

1. Fork the repo, clone your fork.
2. **Install gitleaks** locally so the hooks work: `brew install gitleaks` (Mac) or [download](https://github.com/gitleaks/gitleaks/releases).
3. Confirm the hooks are wired: `bash scripts/agent-os-validate.sh` should pass.
4. Create a branch: `git checkout -b feat/<topic>` (or `fix/`, `docs/`, `chore/`).
5. Make your changes.
6. Commit with [Conventional Commits](https://www.conventionalcommits.org/): `feat(scope): short description`.
7. Push, open a PR against `main`.

## What we accept

- **Bug fixes** — anything verifiably broken.
- **Stack support** — extending `scripts/detect-stack.sh` to cover more languages/frameworks.
- **Security improvements** — better gitleaks rules, more hardening, additional CI checks.
- **Cross-platform fixes** — Windows / WSL / older bash versions / weird shells.
- **Docs** — clarity, typos, expanded examples.
- **Performance** — install/validate/update faster.

## What we typically reject

- Scope creep into adjacent problems (parallel agent runtime → use [CCB](https://github.com/bfly123/claude_codex_bridge) instead; GUI → use [palot](https://github.com/itswendell/palot) instead).
- Per-team conventions disguised as universal rules.
- New mandatory dependencies without an ADR explaining why.

## PR requirements

Your PR must:

- ✅ Pass all CI checks (secret-scan, large-files, no-direct-pushes, hooks-integrity, placeholder-lint, pr-title, pr-body)
- ✅ Have a clear `## Summary` and `## Test plan` in the PR body
- ✅ Use Conventional Commits subject format
- ✅ Not include `--no-verify`, force-push, or direct main commits
- ✅ Update `CHANGELOG.md` for user-facing changes
- ✅ Add or update tests if you change hook logic (bats tests in `tests/`)

## Big changes need an ADR

If you're proposing a non-trivial design change (new pattern, library swap, architectural decision), open an ADR alongside your PR:

```bash
cp docs/decisions/0000-template.md docs/decisions/NNNN-short-slug.md
# fill it in, link from the PR description
```

## Eat your own dog food

This repo uses Agent OS on itself. Every commit goes through:
- `pre-commit` hook (gitleaks + filename + size + main-branch refusal)
- `commit-msg` hook (Conventional Commits)
- `pre-push` hook (force-push refusal + range scan)
- 4 CI workflows
- Branch protection on `main`

If a hook rejects your commit, fix the underlying issue. Don't bypass.

## Code of conduct

See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Be excellent to each other.

## Questions

Open a [Discussion](https://github.com/munsanco13/agent-os/discussions) for design questions.
Open an [Issue](https://github.com/munsanco13/agent-os/issues) for bugs.
For security vulnerabilities, see [`.github/SECURITY.md`](.github/SECURITY.md) — do NOT open a public issue.

Thanks for making this better.
