# Redwright Action Runtime Proto-Spec Draft

## Status

- type: `proto-spec-draft`
- date: `2026-04-27`
- source: `runtime execution brainstorming + daemon/telegram baseline`

## 1. Scope

This draft defines the next runtime evolution after daemon + Telegram ingestion:
- keep Telegram as the primary ingress
- keep SQLite as operational state persistence for now
- move from "intent normalization" to "structured execution planning"
- execute concrete software-engineering actions in project worktrees
- maintain strict traceability from inbound message to action outcomes

## 2. Runtime Responsibilities

Redwright must act as a long-running coding runtime with three explicit stages per inbound turn:
1. `context resolution`: determine target project/workstream or ask for clarification
2. `planning`: obtain a validated structured action plan
3. `execution`: execute actions, persist outcomes, and respond to the user

A turn is incomplete until execution outcomes are persisted and user response is emitted.

## 3. Structured Planning Contract (JSON)

The planner output must be strict JSON:
- `intent`: `change | inspect | meta | clarify`
- `project_ref`: `string | null`
- `workstream_ref`: `string | null`
- `needs_clarification`: `boolean`
- `clarification_question`: `string | null`
- `actions`: `Action[]`
- `final_user_message`: `string`
- `confidence`: `number` in `[0,1]`

Action item contract (`Action`):
- `id`: stable per-turn action id
- `type`: primitive action kind
- `args`: action arguments object validated by schema
- `requires_confirmation`: `boolean`
- `timeout_ms`: positive integer
- `on_failure`: `abort | continue`

Any planner output that violates schema is rejected and retried with bounded attempts.

## 4. Primitive Action Set (v1)

Initial primitive action set:
- `list_files`
- `read_file`
- `search_text`
- `run_command`
- `write_file`
- `apply_patch`
- `git_status`
- `git_branch`
- `git_commit`
- `git_push`

All primitives execute in worktree-scoped paths only.

## 5. Multi-Project Context Resolution

Context resolution is mandatory before planning.

Inputs:
- explicit message references (project alias/path/name)
- current chat memory
- active workstream metadata

State to persist per chat/user:
- `active_project_id`
- `active_workstream_id`
- `recent_project_mentions`
- `recent_turn_summaries`

Rules:
- if explicit reference maps confidently, use it
- if no explicit reference, use active context
- if ambiguity remains, produce `clarify` and do not execute actions

## 6. Execution Guardrails

Execution policies:
- only operate inside resolved project worktree path
- enforce command timeouts
- enforce allowed command prefixes for `run_command` (v1 policy file)
- block destructive commands unless explicit confirmation path exists
- persist per-action status, stdout/stderr snapshots, and failure reason

## 7. Telegram Runtime UX Contract

Telegram responses must remain concise while preserving operator visibility:
- immediate typing indicator and keepalive while processing
- structured final response with execution summary
- clarification question when ambiguity prevents safe execution

## 8. Observability Contract

Trace chain per turn must include:
- ingress trace
- planner request/response traces
- per-action execution traces
- SQLite persistence traces

Runtime trace verbosity must be configurable per trace class.

## 9. Skill System Direction (Scaffold Only)

A future skill layer is required but not in immediate execution slices:
- declarative skill manifest
- skill loader/registry
- action-level dispatch hooks

This cycle only defines interfaces needed to add skills later without runtime rewrites.

## 10. Acceptance Gate (Cycle-Level)

Cycle is complete only when all are true:
- inbound Telegram turn can produce validated structured plan
- runtime executes at least one non-trivial primitive action safely
- execution outcomes are persisted with per-action evidence
- ambiguous multi-project turns trigger clarification instead of unsafe execution
- per-turn trace chain can be correlated end-to-end

## 11. Open Items

- final schema for action args by primitive
- command allow-list policy file location and format
- rollback semantics for multi-action partial failures
- criteria to auto-open vs reuse workstreams in parallel project activity
