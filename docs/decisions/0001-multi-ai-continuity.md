# 0001 — Multi-AI continuity workflow

- **Status:** accepted
- **Date:** YYYY-MM-DD
- **Author:** project owner

## Context

This project is worked on with multiple AI assistants interchangeably (Claude Code, Codex, Cursor, Cline, Aider, etc.). Each AI has its own context window and no native memory of what the others did. Without a deliberate handoff protocol, every session starts cold and decisions get re-litigated.

Common failure modes:
- One AI commits half-finished work; the next AI has no idea what's done vs pending.
- Plan-mode plans (in `~/.claude/plans/` or equivalent) are local-only and invisible to other AIs.
- Architectural choices made in one session get re-questioned in the next.
- Runtime context (env vars, local DB state) doesn't sync via git.

## Decision

The git repo is the source of truth. Three living documents at the repo root + `docs/decisions/` are the bridge:

1. **`AGENTS.md`** — long-lived project rules, conventions, AI guardrails. Updated rarely.
2. **`HANDOFF.md`** — rolling 1-page status snapshot. Updated every session before stopping.
3. **`SECURITY.md`** — hard rules; never violated.
4. **`docs/decisions/`** — ADRs for non-obvious decisions. Append-only.

### Required handoff protocol

**Before stopping work:** clean tree or commit WIP to a feature branch → push → update HANDOFF → commit + push.

**Starting work:** fetch + checkout → read AGENTS.md, HANDOFF.md, last 5 commits, new ADRs → re-pull deps + env vars → start working.

### Branch policy

- Never commit directly to the main branch.
- Feature branch + PR is the only path.
- Either AI may merge its own PRs after review.

### What does NOT sync via git

- Plan-mode plans (Claude-local, transient). Copy meaningful plans into HANDOFF or an ADR.
- `.env.local` (gitignored). Re-pull from deploy provider.
- IDE state, running dev servers, terminal scrollback.

## Alternatives considered

- **Single AI only.** Rejected — tool diversity is a feature; pick the right model per task.
- **Shared external memory store** (Notion, custom MCP server). Rejected — adds infra, fragile sync, AI can't read without setup. Git is already the lingua franca.
- **Conversation transcripts in repo.** Rejected — too noisy. Distill into ADRs instead.
- **Commit messages alone.** Rejected — they capture *what changed*, not *what was abandoned, why, or what's next*.

## Consequences

**Positive:**
- Any AI can clone fresh and be productive within ~10 minutes of reading 3 files.
- Decisions documented in ADRs are stable across sessions and AIs.
- Reversible: just markdown files; abandoning costs nothing.

**Negative:**
- Discipline tax: requires updating HANDOFF every session and writing ADRs when decisions are made.
- ADRs can rot if not maintained. Mitigation: status field; supersede explicitly.

**Reversal cost:** zero.

## References

- `AGENTS.md` — operational rules.
- `HANDOFF.md` — rolling status.
- `SECURITY.md` — hard rules.
