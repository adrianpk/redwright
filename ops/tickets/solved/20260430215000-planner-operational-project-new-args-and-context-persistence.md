---
id: TKT-20260430215000
title: Planner project_new operational args mismatch and stale chat context persistence
status: solved
kind: bug
severity: medium
priority: high
scope: runtime
source: trace
reported_at: 2026-04-30T21:50:00Z
ready_at: 2026-05-01T08:44:39Z
started_at: 2026-05-01T08:44:39Z
reviewed_at: 2026-05-01T09:20:50Z
closed_at: 2026-05-01T09:20:50Z
resolution: fixed
owner: adrianpk
branch: fix/tkt-20260430215000-project-new-args-and-chat-context
pr: https://codeberg.org/adrianpk/redwright/pulls/192
commits: ["00fccf0"]
---

## Context
Runtime trace shows planner returning `operational_intent: project_new` with `operational_args.project_ref`, while follow-up gaps still reference a stale active project path under `_workspace/Projects/new`.

## Problem
Two related issues remain:
1. `project_new` operational dispatch expects `project_name`/`name`, but planner may send `project_ref`.
2. After planner-operational execution, chat/session active project context is not consistently persisted for subsequent turns.

## Expected
- `project_new` should accept canonical planner args and create/switch to the requested project deterministically.
- After operational success, next turn should use updated active project context.
- Planner gaps should not keep proposing stale path `_workspace/Projects/new` when a new project intent was accepted.

## Actual
- Planner output includes:
  - `operational_intent: "project_new"`
  - `operational_args: { "project_ref": "sesame" }`
- Turn still references stale path:
  - `/home/adrian/Projects/redwright/lab/redwright/_workspace/Projects/new`

## Fix Strategy
- Extend operational mapping for `project_new` to accept `project_ref` as project name input.
- Persist chat context (`project_id`, `workstream_id`) after successful planner-operational dispatch.
- Add regression tests for both behaviors.

## Validation
- Trigger planner operational `project_new` with `operational_args.project_ref` and assert project creation/switch succeeds.
- Verify subsequent prompt context uses new project path, not legacy `.../Projects/new`.

## Outcome
Solved.
