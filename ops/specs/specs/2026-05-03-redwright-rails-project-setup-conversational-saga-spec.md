# RedWright Rails Project Setup Conversational Saga Specification

## Metadata

- id: `spec-2026-05-03-redwright-rails-project-setup-conversational-saga`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- scope: `rails-core/api/telegram/project-setup-conversation`
- derived_from:
  - `ops/specs/drafts/2026-05-03-redwright-rails-project-setup-conversational-saga-draft.md`
  - `ops/specs/drafts/2026-05-03-redwright-rails-project-setup-conversational-saga-conv.md`
  - `ops/specs/specs/2026-05-02-redwright-rails-core-command-api-and-project-setup-saga-spec.md`
  - `ops/specs/specs/2026-05-01-project-new-operational-loop-behavior-spec.md`
  - `ops/specs/specs/2026-05-02-redwright-project-context-umbrella-model-spec.md`

## Problem Statement

The system now routes Telegram project setup into Rails, but the Rails setup contract still behaves as repository-first initialization. `StartProjectSetup` requires `repository_input`, and Telegram currently maps the project name to that field. This causes a plain project setup request to produce a repository clarification response instead of a human project setup conversation.

The correct behavior is Rails-owned project setup with a flexible, persisted conversational saga. Repository input is useful context, but it is optional unless the user explicitly asks to import or bind a repository.

## Goals

- make `/project new` start a Rails setup session even when no arguments are provided
- treat repository input as an optional/skippable setup slot, not the first mandatory validator
- persist canonical setup answers turn by turn before project creation
- support deterministic setup phases while allowing human-friendly prompt wording
- provide `/skip`, `/done`, and `/cancel` control behavior
- render human Telegram messages by default and hide internal state unless debug/trace mode is active
- materialize completed setup context into Rails application entities
- keep web and Telegram paths converged on Rails services and ActiveRecord invariants
- keep runtime agents downstream of Rails board/ticket/workflow state

## Non-Goals

- reverting to runtime-only project creation
- replacing Rails with a pure Ruby DDD layer
- forcing Rails HTML controllers to call local HTTP APIs
- implementing every future web UI control in the first slice
- removing runtime executor persistence used for executor-local telemetry

## Architecture Contract

### Rails Core

Rails remains the application core. Rails services and ActiveRecord models own project setup sessions, turns, projects, project attributes, documents, boards, tickets, and agent workflow correlations.

### Telegram Adapter

Telegram is an adapter. It must:

- parse Telegram messages and slash commands
- call Rails command/query APIs
- render Rails response summaries and next prompts
- avoid adapter-local project setup business rules

### Web Adapter

Rails web controllers may call Rails application services directly. They must share the same service rules used by API handlers, but they do not need to make local HTTP calls.

### Runtime Agent Bridge

Runtime agents consume Rails workflow state through bridge contracts. The runtime may keep executor-local telemetry, but it must not become the canonical source for application projects, setup state, boards, tickets, or documents.

## Setup Context Model

### Canonical Slots

The setup saga must manage these canonical slots:

- `project_name`
- `description`
- `project_type`
- `language_runtime`
- `repository`
- `stack`
- `framework`
- `libraries`
- `patterns`
- `conventions`
- `runtime_container_profile`
- `agent_workflow_mode`

Implementations may add slots, but they must preserve stable keys for these fields.

### Slot Shape

Each slot value should be represented with:

- `key`
- `value`
- `source`
- `confidence`
- `weight`
- `requiredness`
- `status`
- `updated_at`

`requiredness` values:

- `blocking`
- `recommended`
- `optional`

`status` values:

- `empty`
- `filled`
- `skipped`
- `defaulted`
- `ambiguous`

### Minimum Blocking Policy

The first implementation must block only on `project_name` by default.

A short `description` is recommended. If missing, the saga may ask for it once. `/done` may proceed with a default description after name is known.

Repository, stack, framework, libraries, patterns, conventions, runtime container profile, and agent workflow mode are optional or recommended unless a prior answer makes them blocking.

The initial compact trunk should avoid asking for `stack` as a mixed language/framework/tooling concept. It should collect `project_type`, `language_runtime`, `framework`, and `libraries` as separate semantic slots, then synthesize `stack` for Rails compatibility and downstream runtime defaults.

## Persistence Contract

### In-Progress Setup

Before project creation:

- `ProjectSetupSession.metadata` stores the current canonical setup context snapshot
- `ProjectSetupTurn` stores every user answer with normalized fields
- `ProjectSetupSession.pending_question` stores the next human prompt
- `ProjectSetupSession.current_state` stores the coarse state

### Completed Setup

After completion:

- `Project` stores stable identity and common display fields
- `ProjectAttribute` stores weighted semantic context such as libraries, patterns, conventions, constraints, container profile, and agent workflow preferences
- `Document` stores setup summary and future draft/spec/plan artifacts when produced
- `Board` and `Ticket` store visible workflow when setup creates starter work
- runtime execution correlation is stored through existing Rails runtime bridge fields and services

### Auditability

A completed project setup must remain traceable back to its setup session and turns. Audit data may live in session metadata, setup summary documents, or explicit references, but it must not depend on Telegram logs.

## Conversational Loop Contract

### Phases

The user experiences one conversation, but internally the setup saga has two phases:

1. `canonical_slot_collection`
2. `adaptive_refinement`

`canonical_slot_collection` gathers deterministic slots in a stable priority order. Prompt wording may vary later, but slot selection and persistence must be deterministic.

`adaptive_refinement` may use LLM-assisted classification or question wording after the canonical context is sufficient. It must not ask redundant questions for filled/skipped/defaulted slots.

### States

Required states:

- `collecting_context`
- `refining_context`
- `ready_to_create`
- `creating_project`
- `completed`
- `cancelled`
- `failed`
- `needs_reconciliation`

Compatibility states from the prior saga may remain during migration, but user-facing Telegram output must not expose raw state names by default.

### Control Commands

`/skip`:

- marks the current optional or recommended slot as skipped
- advances to the next useful prompt
- must not skip a blocking slot unless a default is valid

`/done`:

- completes setup with current answers and defaults when no blocking slot remains
- creates project/application artifacts through Rails services
- returns a human completion summary

`/cancel`:

- cancels the setup session
- before project creation, leaves no project, board, document, ticket, or workspace residue beyond the auditable cancelled session
- after project creation, must not destroy application data unless a separate destructive workflow is explicitly requested

## Prompt Contract

Rails services must select the next semantic prompt intent deterministically. The prompt intent includes the target slot, response language policy, and rendering requirements.

The final user-facing question text must be generated through the configured LLM. It must not be hardcoded as literal UI text and must not be varied by a random factor. The LLM prompt should bias the answer toward the selected semantic slot and a structured JSON response while allowing natural wording.

When the user's language can be inferred from the current turn or conversation context, the generated prompt must use that language. For example, a Croatian setup request should receive Croatian setup questions.

Default Telegram prompts must include:

- what the system understood, when useful
- exactly one next question
- concise available controls when useful

Default Telegram prompts must not include:

- raw state names
- session ids
- trace ids
- internal validator wording

Debug/trace mode may include internal metadata with explicit formatting.

## Project Creation Contract

Project creation happens when:

- `project_name` is known
- no blocking slot remains, or the user used `/done` and allowed defaults
- Rails services have built a valid project initialization command

If repository is skipped or absent:

- project creation must still be valid
- `Project.repo_url` may use an empty value or a deterministic placeholder only if the model requires it during migration
- repository-specific operations must be marked unavailable until a repository is provided

If stack or framework is absent:

- project creation must still be valid
- runtime container settings must use deterministic safe defaults
- stack-specific agent execution may ask later when a ticket requires it

## Initial Artifact Contract

The first complete implementation should create at minimum:

- one `Project`
- one setup summary `Document` or equivalent project context artifact
- default board structure when not already present

Starter tickets are recommended but may be split into a later slice if needed to keep the first behavior slice safe.

## Testing Contract

Required coverage:

- `/project new` starts a session with no arguments
- `/project new <name>` fills `project_name` without treating it as repository input
- quoted name plus freeform description fills name and description slots
- missing description prompts once and `/done` can proceed with a default
- repository URL fills repository slot
- ambiguous repository text does not block project setup unless repository import is active
- `/skip`, `/done`, and `/cancel` behavior
- Telegram default response hides internal state
- Rails API response still preserves structured state for adapters and tests
- completed setup materializes canonical context into Rails entities
- coverage is maintained or improved for new code

Tests and fixtures must use neutral English examples.

## Acceptance Criteria

1. `/project new` no longer requires repository input to start.
2. Telegram no longer maps the project name to `repository_input`.
3. Plain project names fill the `project_name` slot.
4. Freeform text after the project name contributes to description/context slots.
5. Repository is optional, skippable, and only blocks repository-backed operations.
6. `/skip`, `/done`, and `/cancel` work through Rails setup commands.
7. Telegram default messages are human setup prompts and do not expose raw setup state.
8. Canonical setup answers are persisted before project creation and materialized after completion.
9. Web and Telegram continue to use the same Rails service rules.
10. Agent workflow starts from Rails board/ticket context after setup completion.

## Open Questions

- Should the existing `Project.repo_url` non-null requirement be relaxed, or should the service store an empty string until repository is provided?
- Should `current_phase` and `current_slot` become columns on `ProjectSetupSession`, or remain in metadata initially?
- Should starter tickets be generated during `/done` in the first implementation slice or deferred?
- What exact default container profile should be assigned when stack is unknown?
