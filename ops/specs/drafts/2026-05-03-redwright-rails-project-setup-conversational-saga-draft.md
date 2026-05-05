# RedWright Rails Project Setup Conversational Saga

## Status
Draft

## Quiz
- `../../quiz/2026-05-03-redwright-rails-project-setup-conversational-saga-quiz.md`

## Promoted Specification
- `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`

## Scope
Define the next project setup behavior after Rails became the application core: `/project new` must start a persisted Rails-owned conversational saga, gather useful project context in a predictable loop, keep repository input optional, and create visible project workflow artifacts only after the setup context is sufficient or explicitly accepted with defaults.

## Source Context
- The prior runtime path could create a workspace directory and manifest, but it did not create the Rails application state needed for web visibility, boards, documents, and ticket-driven agent workflow.
- The newer Rails-centered path correctly routes Telegram into Rails, but the current `StartProjectSetup` contract still treats `repository_input` as mandatory and ambiguous when given a plain project name.
- The user-visible Telegram response currently exposes internal setup state such as `awaiting_repository` instead of asking a human project setup question.
- Existing Rails entities already provide useful persistence primitives: `ProjectSetupSession`, `ProjectSetupTurn`, `Project`, `ProjectAttribute`, `Document`, `Board`, and `Ticket`.
- Existing command/query handlers already provide a Rails API entrypoint for Telegram and future adapters.

## Working Notes

### 1) Rails Remains the Application Core
- provisional_status: `keep`
- current issue:
  - treating Telegram or runtime as a parallel creator risks divergent project state
- desired behavior:
  - Rails owns project setup, project creation, board/ticket/document creation, and setup artifacts through ActiveRecord
  - Telegram calls Rails command/query APIs and renders Rails results
  - runtime agents receive work from Rails tickets and execution bridge contracts, not from adapter-local project setup rules

### 2) Repository Is Optional Context, Not the First Blocking Field
- provisional_status: `keep`
- current issue:
  - `repository_input` is required by `ProjectInitialization::Command`
  - Telegram currently sends the project name as repository input, which causes repository ambiguity and poor UX
- desired behavior:
  - `/project new` starts a session even with no arguments
  - initial arguments may fill name, description, or freeform context slots
  - repository is a slot that accepts URL, SSH URL, `owner/repo`, or explicit skip/default
  - missing repository must not block the first setup turn unless a repository-backed import is explicitly requested

### 3) Two-Phase Setup Loop
- provisional_status: `keep`
- current issue:
  - existing setup can jump from start to repository clarification or guided alignment without a coherent user-visible loop
- desired behavior:
  - Phase 1 is a canonical deterministic slot pass with stable semantics and human-friendly prompt wording
  - Phase 2 is an adaptive LLM-assisted refinement pass that asks only useful follow-up questions after the canonical context is sufficient enough to reason about the project
  - the user should experience one conversation, not two technical phases
  - internal prompt text may vary, but slot keys, state transitions, completion rules, and persisted normalized answers must stay deterministic

### 4) Canonical Slot Model
- provisional_status: `keep`
- candidate slots:
  - `project_name`
  - `description`
  - `repository`
  - `stack`
  - `framework`
  - `libraries`
  - `patterns`
  - `conventions`
  - `runtime_container_profile`
  - `agent_workflow_mode`
- desired behavior:
  - every slot has `value`, `source`, `confidence`, `weight`, `requiredness`, `status`, and `updated_at`
  - answers are persisted immediately in `ProjectSetupSession.metadata` under a canonical setup context snapshot
  - every user answer also remains auditable in `ProjectSetupTurn.normalized_fields`

### 5) Persistence Strategy
- provisional_status: `keep`
- preferred shape:
  - before project creation, canonical answers live in `ProjectSetupSession.metadata`
  - turns remain immutable audit records in `ProjectSetupTurn`
  - after completion, durable project context is materialized into Rails application entities
- materialization targets:
  - first-class `Project` columns for stable identity and common display fields: name, description, root path, repo URL when present, stack slug when present
  - `ProjectAttribute` rows for weighted semantic/project context such as libraries, patterns, conventions, runtime container profile, constraints, and agent workflow preferences
  - `Document` records for human-readable setup summary, initial draft/spec/plan seeds when requested, and generated context artifacts
  - `Board` and `Ticket` records for actionable workflow that agents can pick up through Rails APIs

### 6) Loop Control and Exit Commands
- provisional_status: `keep`
- desired behavior:
  - `/skip` skips the current optional slot
  - `/done` finalizes with current answers and defaults if no blocking slot remains
  - `/cancel` cancels the setup session and leaves no project, board, document, ticket, or workspace residue unless creation already completed
  - repeated ambiguous answers trigger a concise summary plus a human choice rather than an endless loop

### 7) Telegram UX Contract
- provisional_status: `keep`
- current issue:
  - responses expose setup internals such as state names and repository validator instructions too early
- desired behavior:
  - default Telegram replies are human setup prompts generated from semantic prompt intent through the configured LLM
  - canonical slot selection is deterministic, but the final question text is not hardcoded and is not random
  - prompt generation preserves the user's language when the ingress language is identifiable
  - internal state, session ids, and trace ids appear only in debug/trace mode
  - replies include what was understood, one next question, and available control commands when useful

### 8) Web UX Contract
- provisional_status: `keep`
- desired behavior:
  - Rails web can use structured forms, Turbo streams, and explicit controls
  - web and Telegram still mutate the same Rails setup services and persisted setup context
  - web is not forced through local HTTP calls, but it must not bypass shared service invariants

### 9) Agent Workflow After Setup
- provisional_status: `keep`
- desired behavior:
  - closing setup can create a board and starter tickets when enough context exists
  - agent runtime work starts from Rails tickets through the existing runtime bridge
  - container/runtime settings are stored as project context attributes and consumed by the execution bridge
  - agents update workflow state through Rails command/query APIs rather than writing parallel application state

## Open Questions
- Should `ProjectSetupSession` receive explicit columns for current slot and phase, or is metadata sufficient for the first implementation slice?
- Which slots are truly blocking for project creation: only name, or name plus short description?
- Should `/done` create a project when only a name exists, or should it ask for one description if missing?
- Should initial board/ticket creation happen during setup completion or in a follow-up explicit command?
- What default runtime container profile should be used when stack is unknown?

## Out of Scope
- replacing Rails or ActiveRecord with a pure Ruby DDD layer
- changing Codeberg, branch, or PR workflow
- implementing full autonomous execution during setup collection
- building final web UI polish for setup screens

## Next Iteration Inputs
- neutral English Telegram transcript scenarios for sparse, rich, skipped, cancelled, and completed setup flows
- current Rails service behavior characterization tests before changing implementation
- exact default policy for stack/framework/container settings
