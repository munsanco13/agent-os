# Sessions log

Append-only chronological record of work sessions. Replaces the single `HANDOFF.md` file (which was a guaranteed merge-conflict generator across parallel branches).

## Why per-session files

- **No merge conflicts.** Each session writes a *new* file; no one ever edits the same file simultaneously.
- **Audit trail.** A grep across this folder reconstructs the full project history from any AI's perspective.
- **Per-branch isolation.** Long-running feature branches keep their own session log without colliding with main.

## File naming

```
docs/sessions/YYYY-MM-DD-<slug>.md
```

Examples:
- `2026-04-28-claude-env-vars-cleanup.md`
- `2026-04-29-codex-add-checkpost-scaffold.md`
- `2026-05-02-mundo-fix-deploy-oom.md`

The slug includes the AI / human author name so you can grep `*-claude-*` or `*-codex-*` to see what each contributor touched.

## Required sections

Use `_template.md` to start a new entry. At minimum:

- **Branch** — branch name worked on
- **Done** — what changed this session
- **Pending** — what's queued next
- **Sharp edges** — gotchas the next session should know
- **New ADRs** — references to any ADRs added in `docs/decisions/`

## Bootstrapping protocol

When you (any AI) start a fresh session:

1. Read the **last 3 entries** in this folder (sorted by filename — they're date-prefixed).
2. Read any ADRs newer than the last session.
3. Run `git log -10 --stat` to confirm what's been committed since.
4. Create a new entry from `_template.md` *before* you start working — fill `Done` as you go.

## Pruning

Keep all sessions in git forever. Disk cost is trivial; the historical context is priceless when debugging "why did we do it this way 6 months ago." If the folder gets noisy in browse, group quarterly into subfolders (`docs/sessions/2026-Q2/`).
