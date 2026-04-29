# Persistence Model

## Scope

This document defines runtime persistence entities, ownership, and invariants.

## Database

- backend: SQLite
- bootstrap entrypoint: `Redwright::Bootstrap`
- schema source: `lib/redwright/bootstrap.rb`
- migration entrypoint: `Redwright::SchemaMigrator`

## Entity Ownership

### Runtime Core

- `projects`: `ProjectStore`
- `project_aliases`: `ProjectStore`
- `workstreams`: `WorkstreamStore`
- `tasks`: `TaskStore`
- `task_commits`: `TaskCommitStore`
- `action_executions`: `ActionExecutionStore`

### Context and Clarification

- `chat_contexts`: `ChatContextStore`
- `clarification_sessions`: `ClarificationSessionStore`

### Alignment and PSAM

- `alignments`: `AlignmentStore`
- `alignment_turns`: `AlignmentStore`
- `alignment_questions`: `PsamStore`
- `alignment_answers`: `PsamStore`
- `alignment_question_tags`: `PsamStore`
- `alignment_question_dependencies`: `PsamStore`
- `alignment_artifact_links`: `PsamStore`
- `alignment_interruptions`: `AlignmentInterruptionStore`

### Planner and Feedback Telemetry

- `planner_rejections`: `PlannerRejectionStore`
- `execution_feedbacks`: `ExecutionFeedbackStore`

### Runtime Metadata

- `runtime_metadata`: bootstrap and migration markers

## Identifier Contracts

- `project_id`: `<slug>-<6hex>` derived from normalized project path
- `workstream_id`: opaque generated id (`ws-...`)
- `task_id`: opaque generated id (`task-...`)
- `trace_id`: per-turn correlation id
- clarification session id: opaque generated id (`cls-...`)

IDs are immutable once persisted.

## Lifecycle Contracts

- project lifecycle: logical `registered -> active -> inactive` via activity ordering
- workstream states: `planning`, `executing`, `paused`, `stopped`
- task rows: append-only within a workstream
- clarification session states: `open`, `closed`, `cancelled`, `timed_out`

## Integrity Guardrails

### Write-path checks

- `ChatContextStore#upsert` rejects:
  - unknown project ids
  - unknown workstream ids
  - cross-project workstream links
- `ClarificationSessionStore#open_*` rejects unknown workstream ids

### Startup hygiene

Bootstrap executes:

1. `AlignmentPersistenceHygiene`
2. `ClarificationPersistenceHygiene`
3. `RuntimePersistenceIntegrityHygiene`

Runtime hygiene repairs dangling non-FK links and asserts critical links:

- `tasks -> workstreams`
- `action_executions -> tasks`
- `workstreams -> projects`

## Migration Contract

- migrations run transactionally via `SchemaMigrator`
- applied migrations are tracked in `runtime_metadata` under `migration.<id>`
- failed migrations rollback and do not write applied markers
- repeated bootstrap runs are idempotent

## Current Zombie-Candidate Decision

Reserved (not removed):

- `alignment_question_dependencies`
- `alignment_artifact_links`

Reason: both are part of canonical PSAM graph/linkage contracts.
