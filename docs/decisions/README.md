# Architecture Decision Records (ADRs)

Durable memory for non-obvious decisions on this project. Every AI and human reads this folder before making related decisions, so we never re-litigate the same trade-off twice.

## Index

| # | Title | Status | Date |
|---|---|---|---|
| 0001 | [Multi-AI continuity workflow](./0001-multi-ai-continuity.md) | accepted | YYYY-MM-DD |
| 0002 | [Secret scanning with gitleaks](./0002-secret-scanning-with-gitleaks.md) | accepted | YYYY-MM-DD |
| 0003 | [Server-side enforcement is the real security boundary](./0003-server-side-enforcement.md) | accepted | YYYY-MM-DD |

## When to write an ADR

Write one when you:
- Pick a library / vendor / framework over alternatives
- Adopt or reject a pattern
- Make a trade-off where the loser had real merit
- Decide *not* to do something obvious (and want to remember why)
- Establish a convention all future code should follow

Don't write one for trivial choices.

## How to write one

1. Copy `0000-template.md` to `NNNN-short-slug.md` (next number).
2. Fill in the sections. One screen if possible.
3. Status: `proposed` → `accepted` → `superseded by NNNN` → `deprecated`.
4. Add to the Index above.
5. Commit it (preferably with the change it supports).
