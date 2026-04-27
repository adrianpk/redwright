# Redwright Action Runtime Proto-Spec

## Status

- type: `proto-spec`
- date: `2026-04-27`
- source: `ops/specs/drafts/2026-04-27-redwright-action-runtime-proto-spec-draft.md`

## 1. Objective

Evolve Redwright from ingestion + persistence into a structured execution runtime that can safely perform concrete software-engineering actions from Telegram turns.

## 2. Mandatory Turn Lifecycle

Every processed turn must pass these stages:
1. context resolution
2. structured planning
3. guarded execution
4. persistence and response emission

A turn that does not finish stage 4 is a failed turn.

## 3. Planner Output Contract

Planner output must be valid JSON with this required shape:
- `intent`: `change | inspect | meta | clarify`
- `project_ref`: nullable string
- `workstream_ref`: nullable string
- `needs_clarification`: boolean
- `clarification_question`: nullable string
- `actions`: array of action items
- `final_user_message`: string
- `confidence`: number in `[0,1]`

Each action item must include:
- `id`
- `type`
- `args`
- `requires_confirmation`
- `timeout_ms`
- `on_failure` (`abort | continue`)

Invalid planner output must not execute.

## 4. Primitive Actions (v1)

The runtime must support these primitives:
- `list_files`, `read_file`, `search_text`
- `run_command`, `write_file`, `apply_patch`
- `git_status`, `git_branch`, `git_commit`, `git_push`

Each primitive requires explicit schema validation and bounded execution.

## 5. Multi-Project Context Rules

Per chat/user runtime memory must store:
- active project
- active workstream
- recent project mentions
- recent turn summaries

If project/workstream cannot be resolved confidently, runtime must return clarification and perform no execution.

## 6. Guardrails

Execution guardrails are mandatory:
- worktree path boundaries
- command timeout enforcement
- policy-based command allow-list for `run_command`
- explicit handling of destructive operations
- per-action result persistence with stdout/stderr/error snapshots

## 7. Response and Trace Contract

Runtime must provide:
- typing hint lifecycle while processing
- concise structured response to Telegram
- trace correlation across ingress, planning, execution, and persistence

Trace classes must be independently toggleable.

## 8. Skill Readiness Interface

This cycle must leave extension points for a future skill system:
- skill manifest interface
- registry/loader seam
- planner-to-executor dispatch hook

No full skill behavior is required in this cycle.

## 9. Cycle Exit Criteria

The cycle is complete when:
- structured planning drives executable actions
- execution effects are visible in filesystem/git where expected
- per-action evidence is persisted
- ambiguity handling is safe-by-default
- end-to-end turn correlation is observable
