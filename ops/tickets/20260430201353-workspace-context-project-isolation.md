---
id: TKT-20260430201353
title: Isolate workspace context and project paths in dev runtime
status: solved
severity: high
scope: runtime
reported_at: 2026-04-30T20:13:53Z
started_at: 2026-04-30T20:32:00Z
closed_at: 2026-05-01T09:20:50Z
owner: adrianpk
branch: fix/tkt-20260430201353-workspace-context-isolation
pr: https://codeberg.org/adrianpk/redwright/pulls/188
commits: ["5384b65"]
---

## Context
The runtime planner prompt is receiving a workspace tree that mixes files from multiple projects.

Observed example included entries from both `cubix` and `obelix` while the active project path pointed to `_workspace/Projects/new`.

## Problem
Two related issues are likely present:
1. Project creation in dev mode is reusing `_workspace/Projects/new` instead of creating unique per-project directories.
2. Workspace context snapshot is reading from a shared parent (`_workspace/Projects`) instead of the active project directory.

## Expected
- Each new project must resolve to its own directory under `_workspace/Projects/<project-id-or-slug>`.
- Planner `Workspace Context` must include only files from the active project.
- `Significant files` should be computed from the active project scope only.

## Actual
- Prompt context shows mixed project trees.
- Active project path appears non-unique (`.../Projects/new`).

## Fix Strategy
- Correct active project path resolution and project creation path in dev runtime.
- Constrain workspace snapshot and significant-file extraction to active project root.
- Add regression tests for project isolation and prompt context scoping.

## Validation
- Start runtime in dev mode and create/switch projects sequentially.
- Trigger a planner request and verify trace prompt contains only one project tree.
- Run automated tests covering path resolution and workspace context isolation.

## Outcome
Solved.
