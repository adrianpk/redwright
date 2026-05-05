# RedWright Project Setup Runnable Saga Specification

## Metadata

- id: `spec-2026-05-03-redwright-project-setup-runnable-saga`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- scope: `rails-core/api/telegram/project-setup/materialization/initial-implementation`
- derived_from:
  - `ops/specs/drafts/2026-05-03-redwright-project-setup-runnable-saga-draft.md`
  - `ops/quiz/2026-05-03-redwright-project-setup-runnable-saga-quiz.md`
  - `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`
  - `ops/specs/specs/2026-05-02-redwright-rails-core-command-api-and-project-setup-saga-spec.md`
  - `ops/specs/specs/2026-05-02-redwright-web-project-initialization-and-agent-workflow-spec.md`

## Problem Statement

The current Rails-backed project setup saga can collect setup context and materialize Rails state, board state, a setup summary document, a local workspace directory, and `.redwright/manifest.yml`. Manual testing shows that this is not enough. A user who completes `/project new` reasonably expects the resulting project to be either minimally runnable or explicitly prepared for implementation.

The current behavior also persists raw answers directly into the active slot. If a prompt is confusing, a clarification sentence can become a canonical framework or stack value. This weakens scaffold selection and produces misleading manifest data.

The setup path needs a stronger contract: project setup is a saga with explicit stages, canonical semantic context, observable LLM calls, materialization status, initial implementation status, and ticket handoff.

## Goals

- define explicit project setup saga stages visible to Rails, Telegram, and future web surfaces
- preserve raw user answers while persisting normalized canonical setup values
- trace LLM prompt rendering and answer normalization under existing trace flags
- make materialization outcomes explicit and queryable
- create a minimally runnable project scaffold for supported local stack/archetype combinations
- create a planned fallback workspace with tickets and reasons when runnable scaffold generation is not supported
- hand off all post-initial-implementation work to Rails board tickets and documents
- keep Telegram and web as channels over Rails-owned application state
- maintain or increase test coverage for every new behavior path

## Non-Goals

- remote repository provisioning
- full project CRUD UI
- Protocol template CRUD
- Runtime Containers CRUD
- production deployment generation
- general-purpose code generation for every language and framework
- autonomous ticket execution beyond explicit starter ticket handoff

## Saga Model

The setup flow is one user conversation, but the backend must model it as staged application behavior.

### Stage 1: `new`

Purpose:

- receive the initial setup request
- create or reuse a `ProjectSetupSession`
- capture source channel, actor, language hint, trace id, and initial raw text

Exit condition:

- the session has a first prompt intent or enough context to enter `questionnaire`

### Stage 2: `questionnaire`

Purpose:

- collect canonical setup context
- normalize each answer into structured slot updates
- ask one useful next question at a time
- support `/skip`, `/done`, and `/cancel`

Required behavior:

- prompt wording is produced by the configured LLM when available
- prompt selection is deterministic and Rails-owned
- raw answers are audit data, not automatically trusted canonical values
- ambiguous or meta answers may repeat or clarify a slot instead of filling it

Exit condition:

- no blocking slot remains and the user has provided enough context or used `/done`

### Stage 3: `materialization`

Purpose:

- create Rails `Project`
- persist weighted `ProjectAttribute` context
- create setup summary `Document`
- create default `Board` and starter tickets
- create local workspace and `.redwright/manifest.yml`

Exit condition:

- materialization result is persisted with entity ids, workspace paths, status, and errors if any

### Stage 4: `initial_implementation`

Purpose:

- generate a minimal runnable scaffold for supported setups
- validate the scaffold when the required toolchain is available
- downgrade to planned fallback when runnable scaffold is unsupported or unsafe

Required outcomes:

- `materialized_runnable`
- `materialized_planned`
- `materialization_failed`

For `materialized_runnable`, the workspace must contain code or configuration that can be executed or tested locally for the selected supported profile.

For `materialized_planned`, the workspace must contain enough project documentation and tickets to continue through normal ticket operations.

### Stage 5: `ticket_operation`

Purpose:

- make later work visible and manageable through Rails board tickets
- let agents operate on tickets, notes, documents, and workflow state
- keep Telegram and web channel behavior DRY by using Rails application state

Exit condition:

- not terminal; this is the normal operating mode after setup

## State Contract

Implementations may use existing `ProjectSetupSession.current_state` values during migration, but the application contract must support these semantic states:

- `new`
- `collecting_context`
- `normalizing_context`
- `ready_to_materialize`
- `materializing_project`
- `ready_for_initial_implementation`
- `initial_implementation_running`
- `materialized_runnable`
- `materialized_planned`
- `ticket_operation_ready`
- `cancelled`
- `failed`
- `needs_reconciliation`

User-facing Telegram messages must not expose raw state names by default. Rails API responses may expose structured states for clients, tests, and UI.

## Canonical Context Contract

Each setup slot should preserve:

- `key`
- `raw_value`
- `value`
- `source`
- `confidence`
- `weight`
- `requiredness`
- `status`
- `updated_at`
- `normalization_reason`

Valid `status` values:

- `empty`
- `filled`
- `skipped`
- `defaulted`
- `ambiguous`
- `rejected`

The compact setup trunk remains:

- `project_name`
- `description`
- `project_type`
- `language_runtime`
- `framework`
- `libraries`

Derived or optional slots include:

- `stack`
- `repository`
- `patterns`
- `conventions`
- `runtime_container_profile`
- `agent_workflow_mode`

`stack` must be synthesized from normalized language, framework, libraries, and archetype. It must not blindly reuse a confusing or meta answer from `framework`.

## Semantic Normalization Contract

Every non-control answer in the questionnaire must pass through normalization before canonical slot persistence.

The normalizer must return strict structured data:

- `language`
- `slot_updates`
- `ambiguous`
- `reask_slot`
- `operator_message`
- `confidence`
- `warnings`

The normalizer may use an LLM when configured. It must also have deterministic fallback behavior for common cases and malformed LLM responses.

Examples of required behavior:

- answer `Go 1.26.2` during `language_runtime` fills `language_runtime` with `Go 1.26.2`
- answer `urfave/cli` during `libraries` fills `libraries` with `urfave/cli`
- answer indicating prompt confusion during `framework` must not fill `framework`; it should mark the slot as `ambiguous` or ask a clearer question
- answer `Rails app` may fill both `language_runtime=Ruby` and `framework=Rails` when confidence is high

## LLM Trace Contract

Project setup must emit LLM traces for:

- prompt rendering
- semantic answer normalization
- any initial implementation LLM assistance if added later

Tracing must use the existing `Trace.llm_request` and `Trace.llm_response` mechanisms.

Required trace fields:

- trace id
- model role
- provider
- model
- action
- payload bytes
- system prompt when tracing is enabled
- user text or structured payload when tracing is enabled
- output bytes
- finish reason when available
- raw output when tracing is enabled
- parsed message or parsed normalized fields when available
- decision source: `llm`, `fallback`, or `error`

LLM failures must not be silent. They may fall back, but the fallback must be traceable.

## Materialization Contract

Materialization creates application state and local workspace state.

Required Rails artifacts:

- `Project`
- setup `ProjectAttribute` rows
- setup summary `Document`
- default `Board`
- starter tickets when workflow is requested or initial implementation remains planned

Required workspace artifacts:

- `.redwright/manifest.yml`
- `README.md` or equivalent setup summary projection
- runnable scaffold files for supported profiles, or planned fallback files for unsupported profiles

The manifest must include:

- project identity
- Rails project id
- root path
- repo URL or local placeholder
- canonical setup context
- materialization status
- initial implementation status
- validation command and result when available
- starter ticket ids when available

## Initial Implementation Contract

The first implementation cycle must support at least one deterministic scaffold profile:

- project type: `cli`
- language/runtime: `go`
- framework: `none` or omitted
- libraries: optional, including `urfave/cli`

Minimum Go CLI runnable scaffold:

- `go.mod`
- `main.go` or `cmd/<project>/main.go`
- `README.md`
- basic test when practical
- `.redwright/manifest.yml`

Expected validation:

- `go test ./...` when `go` is available
- a recorded `validation_skipped` result with reason when `go` is unavailable

Unsupported setups must not pretend to be runnable. They must produce:

- planned README/spec notes
- setup summary document
- starter implementation ticket
- `materialized_planned` status with reason

## Telegram Contract

Telegram must render clear setup progress:

- during questionnaire, ask one next question
- during materialization, state that the project is being created or prepared
- after initial implementation, state whether the workspace is runnable or planned
- include workspace path when available
- avoid colon shortcode artifacts
- avoid raw state names, trace ids, session ids, and validator details unless debug is enabled

## Web Contract

The Rails application should expose the same saga state eventually, but the first implementation cycle may keep UI changes minimal.

At minimum, Rails API/query state must make it possible for future UI to display:

- current saga stage
- canonical setup context
- materialization status
- initial implementation status
- workspace path
- linked board/tickets/documents

## Testing Contract

Required tests:

- missing LLM traces are characterized and then covered for prompt rendering
- semantic normalization prevents prompt-confusion text from becoming framework or stack
- Go CLI setup normalizes name, description, type, runtime, framework, and libraries
- Go CLI setup produces runnable or validation-skipped scaffold artifacts
- unsupported setup produces planned fallback artifacts and starter ticket
- materialization is idempotent on repeated completion
- Telegram completion accurately states runnable vs planned
- Rails API exposes structured saga status
- repository coverage is maintained or increased

Fixtures and examples must be neutral English.

## Acceptance Criteria

1. Project setup has explicit persisted saga stages from `new` through `ticket_operation`.
2. LLM prompt and normalization calls are visible in foreground trace output when tracing is enabled.
3. Raw answers and canonical normalized slot values are not conflated.
4. Confusion/meta answers do not become framework or stack values.
5. `stack` is synthesized from normalized setup context.
6. Completing a supported Go CLI setup creates a workspace with minimally runnable scaffold files.
7. Completing an unsupported setup creates a planned workspace with documents, starter tickets, and a reason.
8. Telegram says whether the result is runnable or planned.
9. Later work is represented through Rails board tickets and documents.
10. Coverage is maintained or increased for new behavior paths.
