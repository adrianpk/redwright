# RedWright Rails Core Command API and Project Setup Saga Specification

## Metadata

- id: `spec-2026-05-02-redwright-rails-core-command-api-and-project-setup-saga`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-02`
- updated: `2026-05-02`
- scope: `rails-core/api/telegram/project-setup-saga`
- derived_from:
  - `ops/specs/specs/2026-05-02-redwright-web-project-initialization-and-agent-workflow-spec.md`
  - `ops/specs/specs/2026-05-01-project-new-operational-loop-behavior-spec.md`
  - `ops/specs/specs/2026-05-02-redwright-project-context-umbrella-model-spec.md`
  - `docs/explanation/adr/adr-003-command-query-semantic-core-v1.md`
  - `docs/reference/application-semantics-v1.md`
  - `docs/reference/kanban-integration-contract-v1.md`

## Problem Statement

Project creation, setup, document progression, ticket operations, and agent workflow are currently split across two operational centers:

- Rails owns the web application state through ActiveRecord models such as `Project`, `Board`, `Ticket`, and `Document`.
- Telegram/runtime paths can create and operate runtime SQLite projects, workstreams, tasks, manifests, and clarification/alignment rows without creating or updating Rails application state.

This split allows `/project new` to appear successful from Telegram while leaving the Rails application without the same operational state, setup progression, visible questionnaire, document chain, ticket board changes, or agent-follow-up workflow.

The system needs Rails to become the operational source of truth for application entities while keeping Telegram and future ingress channels as adapters over a stable command/query API.

## Goals

- establish Rails as the canonical operational core for projects, documents, tickets, boards, and setup state
- preserve ActiveRecord as the persistence and invariant layer for web-owned application entities
- introduce a Rails application command/query layer that can be called by both web controllers and API controllers
- expose a Rails API that lets Telegram and agent adapters operate the same application workflows as the web UI
- restore a multi-turn project setup saga after project creation instead of terminating at a shallow success reply
- keep Telegram as an ingress adapter, not a separate domain implementation
- avoid duplicate business rules between web controllers, API controllers, Telegram handlers, and runtime dispatcher code
- provide testable cross-channel parity for project setup, document lifecycle, ticket operations, and board movement

## Non-Goals

- replacing Rails or ActiveRecord with a pure Ruby domain layer
- forcing Rails HTML/Turbo controllers to call HTTP endpoints inside the same process
- implementing final UI polish for every project/document/ticket screen
- removing the runtime executor in one step
- changing the repository's branch, PR, or release policy

## Current State Summary

### Rails Application State

Rails already contains first-class application entities:

- `Project` owns boards, project attributes, and documents.
- `Board` owns columns, tickets, and labels.
- `Ticket` owns lifecycle timestamps, priority, assignee, board column transitions, and document links.
- `Document` owns draft/spec/plan tracking types, editability policy, source draft provenance, and project ownership.

Rails also has a partial `ProjectInitialization` service boundary for repository-first project creation, but the current web flow only records guided alignment as a requested/skipped result and does not execute a persisted setup saga.

### Telegram and Runtime State

Telegram currently routes operational project creation through runtime-oriented dispatch paths. Runtime project creation can create a filesystem directory, manifest, runtime project record, workstream, and task without creating the corresponding Rails project setup state.

The runtime also contains useful alignment and clarification primitives, but they are scoped to runtime workstreams and SQLite persistence rather than Rails application entities.

### API Surface

The Rails app does not currently expose a canonical `/api/v1` command/query surface. Existing web routes are primarily HTML/Turbo, with a few controller-level JSON responses that are not a stable external integration contract.

## Target Architecture

### Rails Core

Rails is the source of truth for application-level entities and invariants:

- projects
- project setup sessions
- project setup turns
- documents
- document relations
- boards
- tickets
- ticket document links
- project attributes

Domain mutations that affect these entities must run through Rails application services using ActiveRecord transactions where needed.

### Rails Application Command/Query Layer

Rails must contain a command/query dispatcher that validates request envelopes, actor context, command/query name, payload shape, and result shape.

This layer lives inside the Rails application boundary and uses ActiveRecord directly. It is not a pure Ruby replacement for Rails models.

Web controllers may call the same application services directly. API controllers call the dispatcher and serialize results. Both paths must converge on the same mutation/query behavior.

### Rails API Adapter

The Rails API exposes the command/query layer for external adapters.

Required properties:

- stable `/api/v1` namespace
- authenticated actor context
- request id propagation
- structured success/error response envelopes
- deterministic command/query names
- no transport-specific domain branching

### Telegram Adapter

Telegram remains an ingress adapter:

- receives Telegram Bot API events
- parses slash commands and LLM-assisted intents
- builds Rails command/query requests
- calls Rails API
- renders Rails response summaries and next prompts

Telegram must not create Rails application state by reimplementing Rails business rules.

### Runtime Executor Bridge

The current runtime executor can remain as a lower-level execution engine while Rails becomes the application source of truth.

Agent/runtime execution should eventually be driven by Rails tickets and board state. Runtime project/workstream/task state may be retained during transition, but it must not be the canonical source for Rails projects, documents, tickets, or setup progression.

## Project Setup Saga Contract

### Persistence

A project setup saga must be persisted in Rails.

Minimum entities:

- `ProjectSetupSession`
  - project reference when available
  - channel/source
  - actor identifier
  - status
  - current state
  - requested repository input
  - resolved repository data
  - pending question
  - turn counter
  - terminal reason
  - request correlation metadata
- `ProjectSetupTurn`
  - session reference
  - turn index
  - question
  - answer
  - normalized fields
  - source channel
  - created timestamp

The final naming can be adjusted during implementation, but the Rails application must own this state.

### States

Required states:

- `collecting_context`
- `awaiting_repository`
- `awaiting_repository_confirmation`
- `awaiting_alignment_opt_in`
- `collecting_alignment`
- `ready_to_create`
- `creating_project`
- `completed`
- `cancelled`
- `failed`
- `needs_reconciliation`

### Terminal Outcomes

Required terminal outcomes:

- `completed_without_alignment`
- `completed_with_alignment`
- `cancelled_by_user`
- `failed_reconciled`
- `failed_needs_reconciliation`

### Side-Effect Rules

- Repository resolution must occur before project creation is finalized.
- Ambiguous repository input must enter a focused clarification state.
- Cancellation before creation must leave no project, document, board, ticket, or setup residue beyond an auditable cancelled setup session.
- Partial failures must be explicit and observable.
- Hidden half-created state is not acceptable.

### Response Contract

Every setup command response must include:

- `status`
- `request_id`
- `session_id`
- `project_id` when available
- `state`
- `next_prompt` when user input is required
- `summary`
- `effects`
- `errors`

Telegram should render `summary` and `next_prompt`. Debug telemetry must stay opt-in.

## Initial Command Set

### Project Setup Commands

- `StartProjectSetup`
- `AdvanceProjectSetup`
- `CancelProjectSetup`
- `ResolveProjectRepository`
- `CompleteProjectSetup`

### Project Queries

- `ListProjects`
- `GetProject`
- `GetProjectSetupSession`

### Document Commands

- `CreateDocument`
- `UpdateDraftDocument`
- `PromoteDraftToSpec`
- `AttachDocumentToTicket`

### Ticket and Board Commands

- `CreateTicket`
- `UpdateTicket`
- `MoveTicket`
- `PickNextTicket`
- `StartTicketExecution`
- `StartLoopExecution`
- `StopLoopExecution`

### Board and Document Queries

- `GetBoard`
- `GetTicketsByProject`
- `GetDocumentsByProject`
- `GetDocumentChain`

## Web Behavior Contract

Rails HTML/Turbo controllers should remain idiomatic Rails controllers.

They may call application services directly instead of making local HTTP calls. They must not bypass service-level rules for mutations that are also exposed by the API.

## Telegram Behavior Contract

`/project new` must not terminate with a shallow creation-only reply when setup context is still required.

Expected behavior:

1. Telegram receives creation intent.
2. Telegram calls `StartProjectSetup`.
3. Rails returns either a next prompt or a completed state.
4. User answers are sent through `AdvanceProjectSetup`.
5. Repository resolution and alignment opt-in are handled by Rails setup state.
6. Project creation and related setup side effects occur through Rails services.
7. Telegram renders the next prompt or terminal outcome.

## Agent and Board Operation Contract

Agents should operate board and document state through Rails APIs rather than writing parallel runtime state for application-visible workflow.

Allowed transitional behavior:

- runtime execution may still perform filesystem and primitive actions
- Rails tickets may reference runtime execution ids while the bridge is being completed
- runtime persistence may remain for executor-local telemetry

Disallowed behavior:

- creating application projects only in runtime SQLite
- moving board-visible workflow only in runtime state
- creating docs or tickets through adapter-specific logic outside Rails services

## Testing Contract

Required coverage areas:

- Rails command/query envelope validation
- Rails command/query dispatcher behavior
- project setup state transitions
- cancellation and reconciliation semantics
- API response envelopes
- web/API parity for project setup services
- Telegram `/project new` multi-turn setup flow
- document lifecycle commands
- ticket/board command/query behavior
- agent/runtime bridge integration without duplicate application state

Coverage must be maintained or increased for new code.

## Acceptance Criteria

1. Rails owns canonical application state for projects, documents, tickets, boards, and setup sessions.
2. Telegram project creation no longer creates a separate runtime-only project as the application source of truth.
3. `/project new` enters or advances a persisted Rails setup saga until a terminal outcome is reached.
4. Web and API mutations converge on the same Rails services and ActiveRecord invariants.
5. Rails exposes a stable command/query API for Telegram and agent adapters.
6. Project setup cancellation, repository ambiguity, and partial failure states are explicit and test-covered.
7. Document, ticket, and board operations are accessible through Rails command/query APIs.
8. Agent/runtime execution can be initiated from Rails board/ticket context without duplicating application rules.

## Open Questions

- Should runtime SQLite project records be maintained as executor-local mirrors or retired for application projects?
- What authentication mechanism should be used for local Telegram-to-Rails API calls in development?
- Should setup alignment turns be stored only as structured setup turns, also as `Document` records, or both?
- Which runtime execution identifiers must be persisted on Rails tickets for traceability?
