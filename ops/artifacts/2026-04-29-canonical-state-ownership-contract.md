# Canonical State Ownership Contract

## Scope

This contract defines ownership, lifecycle, and id/idempotency boundaries for runtime persistence.

## Ownership Matrix

### Runtime Core

- table: `projects`
  - owner: `ProjectStore`
  - operations: `register`, `resolve`, `get`, `list`, `mark_active`
- table: `project_aliases`
  - owner: `ProjectStore`
  - operations: `register` alias upsert, `resolve` alias lookup
- table: `workstreams`
  - owner: `WorkstreamStore`
  - operations: `open`, `stop`, `pause`, `resume`, `advance`
- table: `tasks`
  - owner: `TaskStore`
  - operations: `create`, `list`, `by_workstream`
- table: `task_commits`
  - owner: `TaskStore`
  - operations: `append commit refs to task`
- table: `action_executions`
  - owner: `ActionExecutionStore`
  - operations: `insert action execution result per action`

### Context and Clarification

- table: `chat_contexts`
  - owner: `ChatContextStore`
  - operations: `upsert active project/workstream by chat`
- table: `clarification_sessions`
  - owner: `ClarificationSessionStore`
  - operations: `open`, `advance`, `close`, `query open`

### Alignment/PSAM

- table: `alignments`
  - owner: `AlignmentStore`
  - operations: `ensure session`, `set pending`, `complete`
- table: `alignment_turns`
  - owner: `AlignmentStore`
  - operations: `append turn`
- table: `alignment_questions`
  - owner: `PsamStore`
  - operations: `create question`
- table: `alignment_answers`
  - owner: `PsamStore`
  - operations: `create answer`
- table: `alignment_question_tags`
  - owner: `PsamStore`
  - operations: `add tag`
- table: `alignment_question_dependencies`
  - owner: `PsamStore`
  - operations: `add dependency`
- table: `alignment_artifact_links`
  - owner: `PsamStore`
  - operations: `link artifact`
- table: `alignment_interruptions`
  - owner: `AlignmentInterruptionStore`
  - operations: `record interruption`, `resume`

### Planner and Feedback Telemetry

- table: `planner_rejections`
  - owner: `PlannerRejectionStore`
  - operations: `insert rejection events`
- table: `execution_feedbacks`
  - owner: `ExecutionFeedbackStore`
  - operations: `insert normalized failure feedback`, `query recent`

### Runtime Metadata

- table: `runtime_metadata`
  - owner: `Bootstrap`
  - operations: `schema_version upsert`

## Lifecycle States

### Project

- `registered` -> `active` -> `inactive` (logical via `last_active_at` ordering)

### Workstream

- `planning`
- `executing`
- `paused`
- `stopped`

### Task

- append-only rows linked to a workstream
- terminal semantics are derived from workstream transitions and action execution aggregates

### Clarification Session

- `open`
- `closed`
- `timed_out` (hygiene transition)

### Alignment

- `open` (pending question exists)
- `stable` (no pending question, unresolved count is zero)

## Identifier Contract

- `project_id`: `<slug>-<6hex>` generated from normalized path hash
- `workstream_id`: opaque stable id generated at creation
- `task_id`: opaque stable id generated at creation
- `trace_id`: per-ingress turn correlation id
- `clarification_session.id`: opaque id, unique per session lifecycle

Constraints:

- ids are immutable once persisted
- references across entities are by id only
- project path/name can mutate; id cannot

## Idempotency and Dedup Boundaries

- `ProjectStore#register(path)` is idempotent per normalized path.
- `ChatContextStore#upsert(chat_id, project_id, workstream_id)` is idempotent by key.
- `ClarificationSessionStore` open calls replace/close previous open scope entries where applicable.
- `ActionExecutionStore` is append-only and not idempotent by default; dedup must be externalized by `task_id + action_id` policy at caller boundary.
- `ExecutionFeedbackStore` is append-only; repeated fingerprints are expected and used by convergence logic.

## Keep/Remove Guidance from Slice 2 Candidates

- `alignment_question_dependencies`
  - status: `keep_for_now`
  - reason: canonical PSAM graph contract is defined even if low-frequency reads.
- `alignment_artifact_links`
  - status: `keep_for_now`
  - reason: canonical artifact linkage contract is part of PSAM context recovery model.

## Deferred Decisions

- optional normalization of append-only telemetry tables into summarized projections
- long-term retention/compaction policy for feedback/action execution rows
