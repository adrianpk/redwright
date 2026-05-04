# Project New Operational Loop Behavior

## Status
Draft

## Promoted Specification
- `ops/specs/specs/2026-05-01-project-new-operational-loop-behavior-spec.md`

## Conversation Counterpart
- `../conv/2026-05-01-project-new-operational-loop-behavior-conv.md`

## Scope
Capture ongoing brainstorming about `/project new` behavior, operational feedback loops, and human-in-the-loop escalation rules.

## Source Context
- Command used:
  - `/project new "TaskMaster" "Una CLI para crear, listar y completar tareas de manera sencilla con persistencia en archivos locales."`
- Current runtime behavior observed:
  - project directory is created in the correct path (`_workspace/Projects/TaskMaster` in dev mode)
  - project manifest is generated
  - user-facing reply is highly technical and telemetry-first
  - app scaffold/business logic generation is not reliably triggered
  - clarification questioning loop is not reliably triggered

## Working Notes
This document is intentionally iterative. Items can be revised, removed, or split.

### 1) Operational Reply UX for `/project new`
- provisional_status: `keep`
- current issue:
  - reply is runtime-centric (IDs/state/trace) instead of user outcome-centric
- desired behavior:
  - primary reply should confirm meaningful outcome in human terms
  - runtime telemetry should be hidden by default
  - telemetry may be shown only when a debug/trace config flag is enabled
  - when shown, telemetry must be formatted with markdown code style (backticks), compatible with Telegram

### 2) Stack-Aware Questioning Without Redundant Prompts
- provisional_status: `keep`
- current issue:
  - agent may ask for details already provided by user
- desired behavior:
  - if prompt contains enough specifics, proceed directly
  - ask only for missing, blocking decisions
  - avoid deterministic/redundant re-asking of user-provided details

### 3) Internal Looping vs Visible Human Loop
- provisional_status: `keep`
- desired behavior:
  - allow internal, non-visible refinement loops (agent self-check/passes)
  - expose questions to user only when:
    - a blocking decision exists, or
    - a high-impact confirmation is required
  - preserve elegant exits for human-facing loops

### 4) Scaffold vs Full Functional Generation
- provisional_status: `unsure`
- open tension:
  - previous behavior reportedly generated a fully functional app
  - current behavior appears to stop at manifest/project setup in some paths
- pending decision:
  - should `/project new` default to scaffold-only, functional baseline generation, or adaptive behavior based on prompt richness?

### 5) Candidate Multi-Layer Loop Pattern
- provisional_status: `unsure`
- candidate model:
  - intent interpretation loop
  - clarification loop
  - execution loop
  - review/acceptance loop
- note:
  - keep only if this abstraction helps implementation clarity; avoid unnecessary framework overhead

## Open Questions
- What is the minimum expected output of `/project new` when description is rich?
- Which decisions are considered blocking vs safe-defaultable?
- What exact config flag should control telemetry visibility?
- Should stack/module/package prompts trigger only when stack is explicit, or also when inferable from description?

## Out of Scope
- concrete code changes
- final schema/contract wording
- migration of existing ticket states

## Next Iteration Inputs
- additional real command transcripts
- examples of preferred concise user-facing responses
- edge cases where asking is necessary vs annoying

### 6) Layering: Slash Commands as Wrapper Surface
- provisional_status: `keep`
- decision note:
  - slash commands are interaction wrappers, not the core behavior layer
  - core behavior should live in domain/runtime command-query style primitives (verb-noun semantics)
  - the same domain operations must remain invokable from multiple ingress surfaces (telegram, tui, etc.)
- consequence:
  - avoid embedding business behavior directly in slash parsing branches
  - slash layer should map user input to domain operations and return user-facing summaries

## Current Runtime Entities and Persistence Correlation

### A) Runtime Entities Participating in `/project new` Conversational Cycle
- `Project`
  - represents the active project identity and filesystem root
- `Chat Context`
  - binds messenger chat to active `project_id` and optional `workstream_id`
- `Workstream`
  - runtime execution lane for intents and state progression
- `Task`
  - concrete runtime unit under a workstream
- `Clarification Session`
  - open/closed Q&A state for pending user clarifications
- `Planner Gap`
  - structured unresolved field/question payload persisted inside clarification session
- `Alignment Question/Answer`
  - persisted question/answer memory that can support context carry-forward patterns

### B) Status Fields Currently Present
- `workstreams.state`:
  - generic lifecycle state (`executing`, `waiting_user`, `ready`, etc. depending on flow)
- `tasks.status`:
  - task-level operational status
- `clarification_sessions.status`:
  - `open`, `closed`, `cancelled`, `timed_out`
- `alignments.status`:
  - alignment/planning status (`collecting_context`, `waiting_user`, `ready`, ...)

### C) Key Tables Used by the Current Cycle

1. `projects`
- purpose:
  - canonical project identity and path
- key columns:
  - `id`, `name`, `path`, `last_active_at`, `source_type`, `source_ref`

2. `chat_contexts`
- purpose:
  - active conversational binding per chat
- key columns:
  - `chat_id`, `project_id`, `workstream_id`, `updated_at`
- correlation:
  - links ingress conversation to project/workstream continuity

3. `workstreams`
- purpose:
  - runtime lane per project and intent
- key columns:
  - `id`, `project_id`, `intent`, `state`, `branch`, `worktree_path`, timestamps
- correlation:
  - parent of `tasks`, `alignments`, and optional clarification association

4. `tasks`
- purpose:
  - executable runtime units
- key columns:
  - `id`, `workstream_id`, `trace_id`, `description`, `status`, timestamps

5. `clarification_sessions`
- purpose:
  - conversational pending-question state
- key columns:
  - `id`, `chat_id`, `workstream_id`, `status`, `gap_type`, `payload_json`, `resolved_fields_json`, `last_question_id`, `turn_counter`
- correlation:
  - `payload_json` can embed planner gaps and contextual carry-forward
  - `resolved_fields_json` captures answers used in follow-up turns

6. `alignments`, `alignment_questions`, `alignment_answers`, `alignment_turns`
- purpose:
  - existing persisted Q/A substrate for iterative context gathering
- correlation:
  - currently strong in planning flows; candidate reuse for `/project new` structured questioning

7. `action_executions`
- purpose:
  - action-level execution outcomes per task
- correlation:
  - supports post-hoc evidence of what was actually executed

8. `planner_rejections`
- purpose:
  - planner parse/contract rejection diagnostics
- correlation:
  - useful for understanding loop breakpoints and fallback behavior

### D) Practical Correlation Map
- ingress message (`/project new ...`) -> slash wrapper / planner intent
- -> resolved active project/chat context (`chat_contexts`)
- -> optional clarification open (`clarification_sessions` with `planner_gap` payload)
- -> runtime execution lane (`workstreams` + `tasks`)
- -> optional actions (`action_executions`)
- -> chat context update for next turn (`chat_contexts`)

### E) Observed Gap vs Desired Direction
- observed:
  - persistence primitives exist, but conversational orchestration is not consistently visible in user-facing flow
- desired:
  - make loop transitions explicit and predictable while reusing these persisted entities instead of adding ad-hoc parallel state
