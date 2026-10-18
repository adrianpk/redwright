# Playground Layout

This document defines the canonical location, naming, and lifecycle of project
playgrounds on this machine.

## Canonical Layout

- Create project playgrounds only under `~/Projects/playground/<project>/`.
- Keep each bounded experiment, manual test corpus, fixture collection, or
  exploratory scenario in its own named directory.
- Do not use playground directories as Git worktrees. Create worktrees under
  `~/Projects/worktrees/<project>/` according to `.agents/WORKTREES.md`.

## Directory Names

Name each new playground directory:

```text
YYYYMMDD-HHMM-<task-slug>
```

- Use the machine's local time at playground creation in 24-hour format.
- Use a lowercase kebab-case task slug that identifies the project behavior,
  experiment, corpus, or bounded manual test.
- Treat the timestamp as creation metadata. Do not rename an active playground
  to refresh it.
- If the same project, minute, and task slug collide, append `-2`, `-3`, and so
  on.

Examples:

```text
~/Projects/playground/odra/20260911-0920-jan-documents
~/Projects/playground/spore/20260911-1015-rendering-fixtures
```

## Lifecycle

- Keep playground content separate from canonical source checkouts and task
  worktrees.
- Record enough local structure or notes for the playground's purpose to remain
  understandable after the originating session.
- Apply this naming rule to new playgrounds. Do not move, rename, or remove an
  existing playground without explicit authorization.
