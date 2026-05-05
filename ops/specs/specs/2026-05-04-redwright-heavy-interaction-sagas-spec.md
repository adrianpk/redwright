# RedWright Heavy Interaction Sagas Specification

## Metadata

- id: `spec-2026-05-04-redwright-heavy-interaction-sagas`
- status: `formalized`
- owner: `adrianpk`
- created: `2026-05-04`
- updated: `2026-05-04`
- scope: `rails-core/heavy-interaction-sagas/application-architecture/project-setup-reference`
- derived_from:
  - `ops/quiz/2026-05-04-redwright-heavy-interaction-sagas-quiz.md`
  - `ops/specs/specs/2026-05-03-redwright-project-setup-runnable-saga-spec.md`
  - `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`
  - `ops/specs/specs/2026-05-02-redwright-rails-core-command-api-and-project-setup-saga-spec.md`

## Problem Statement

RedWright now has at least one heavy application interaction: Project Setup. This interaction is no longer a simple command. It can collect user context, persist turns, normalize answers, create application records, initialize protocols, initialize runtime containers, create tickets, materialize local workspace files, and expose progress back through Telegram and Rails.

The current implementation already has useful boundaries, but responsibility is starting to accumulate around Project Setup orchestration and materialization. If new setup steps and future MVP sagas are added by growing one service or one function at a time, the system will become harder to reason about, test, recover, and extend.

RedWright needs an explicit heavy-interaction saga architecture: a general pattern for scoped, stateful, multi-step application operations triggered from Telegram, web, or future channels. The first implementation reference is Project Setup, but the architecture must remain suitable for future sagas that may be simpler, single-step, or substantially different.

## Goals

- define a general saga pattern for heavy interactions
- keep Rails/application persistence as the canonical owner of saga state
- keep Telegram, web, and future interfaces as adapters over shared application behavior
- support domain-specific saga session models under a common contract
- separate questionnaire/context collection from materialization
- support sagas with no questionnaire, one-turn questionnaire, or bounded multi-turn questionnaire
- define step-based materialization with clear responsibility boundaries
- support structured step results without forcing ceremony on simple steps
- preserve valuable saga context across partial failures
- make failure, reconciliation, and continuation explicit
- classify effects for public, internal, and debug visibility
- expose structured prompt intent while keeping human wording adapter-owned
- preserve current external behavior during architecture refactors unless explicitly changed by a later implementation spec
- improve modularity, observability/debugging, and future saga creation ergonomics

## Non-Goals

- implementing the Project Setup refactor in this specification
- introducing a generic workflow engine DSL
- requiring one shared saga database table for every saga
- forcing every saga to use a questionnaire
- defining a rigid global stage taxonomy for all future sagas
- redesigning Rails controllers away from RESTful resource conventions
- changing existing Telegram copy or command/query response shapes as part of architecture cleanup
- defining the final web UI for saga inspection
- defining exact class names or slice decomposition for implementation

## Saga Concept

A heavy-interaction saga is a scoped sequence of related application steps that may span multiple user interactions, internal decisions, materialization steps, validations, and recovery paths.

A saga is appropriate when an operation has one or more of these properties:

- it spans multiple turns or user decisions
- it persists intermediate state
- it creates or updates multiple domain artifacts
- it can partially fail after useful context or artifacts already exist
- it needs continuation, cancellation, reconciliation, or inspection
- it should behave consistently across Telegram and web

Sagas are not synonymous with questionnaires. A questionnaire may be one phase of a saga, but some sagas may have no questionnaire or only one question-and-answer turn.

One-step sagas are acceptable when they preserve conceptual regularity and simplify future growth. Exceptions to the saga pattern may be introduced later when a concrete workflow is demonstrably simpler without it.

## Canonical Ownership

Rails/application persistence is the canonical owner of saga state.

Telegram, web, and future channels must act as adapters or renderers over application behavior. They may preserve lightweight channel-local context for ergonomic reasons, but they must not become the source of truth for saga state, turns, materialization status, or recovery state.

This continues the existing RedWright direction where Rails owns projects, setup sessions, boards, tickets, documents, protocols, runtime containers, and application workflow state.

## Persistence Model

The first architecture uses domain-specific session and turn models for each saga.

Examples:

- `ProjectSetupSession`
- `ProjectSetupTurn`
- future `TicketExecutionSession`
- future `ProtocolRefreshSession`
- future `RuntimeContainerReadinessSession`

Each domain-specific model must follow the common saga contract defined in this specification.

This approach is intentionally chosen over a generic shared `SagaRun` table for the first phase. Domain-specific models preserve domain clarity while the system is still discovering the shape of future sagas.

A generic shared persistence model may be reconsidered after repeated structure emerges across multiple implemented sagas.

## Common Saga Contract

Every heavy-interaction saga must expose a common contract, even when the persistence model is domain-specific.

The common shape includes:

- `state`
- `stage`
- `status`
- `turns`
- `effects`
- `next_prompt_intent`
- `terminal_reason`
- `metadata`

Not every saga needs to use every field heavily.

Single-step sagas may have no user turns, no next prompt intent, and a small effect list. Complex sagas may have many turns, stages, effects, and reconciliation metadata.

### `state`

`state` is the technical current state inside a saga.

It may be specific to the saga domain.

Examples:

- `collecting_context`
- `creating_project`
- `initializing_protocols`
- `validating_runtime_container`
- `completed`
- `needs_reconciliation`

### `stage`

`stage` is the semantic progress grouping used for inspection, UI, and debugging.

Each saga must declare its own stage taxonomy.

Shared stage names may be reused when they fit naturally, but this specification does not define a rigid global stage list.

### `status`

`status` is the coarse operational condition.

Expected examples:

- `open`
- `running`
- `ready`
- `completed`
- `cancelled`
- `failed`
- `needs_reconciliation`

### `turns`

`turns` preserve user and system interaction history where a saga needs it.

For questionnaire-based sagas, turns include questions, answers, normalized fields, source channel, and request identifiers.

### `effects`

`effects` describe meaningful things produced or observed by the saga.

Effects are not all equally public. They must support visibility classification.

### `next_prompt_intent`

`next_prompt_intent` is structured prompt intent, not final human-facing copy.

It lets adapters render channel-specific UI:

- Telegram can render one concise message.
- Web can render forms, cards, controls, or richer grouped UI.

### `terminal_reason`

`terminal_reason` explains why the saga ended.

Examples:

- `completed`
- `completed_without_questionnaire`
- `completed_with_alignment`
- `cancelled_by_user`
- `failed_needs_reconciliation`

### `metadata`

`metadata` carries saga-specific structured context. It must not become a dumping ground for unmodeled behavior when a clearer domain field or step result is warranted.

## Questionnaire Contract

Questionnaires are optional.

If a saga includes a questionnaire, it must follow the quiz playbook.

Required behavior:

- precompute a finite candidate question set
- cap the session at a maximum of 50 questions
- ask exactly one question at a time
- allow bounded follow-up depth
- stop early when sufficient clarity is reached
- maintain raw questionnaire capture during long sessions with `...-quiz-raw.md`
- curate raw capture into canonical `...-quiz.md` notes when needed

The questionnaire phase collects and normalizes context. It must not create persistent domain artifacts that belong to materialization.

Project Setup currently acts as the reference case:

- questionnaire collects setup context
- materialization creates project records, documents, protocols, runtime containers, tickets, and workspace files

If current code mixes these concerns, that coupling is a refactor target.

## Prompt Intent and Adapter Rendering

Sagas must expose prompt intent as structured data.

Prompt intent should identify the semantic next step without deciding final channel wording.

Example fields may include:

- `kind`
- `slot`
- `question_key`
- `controls`
- `requiredness`
- `expected_input_shape`
- `locale`
- `llm_allowed`

Adapters and renderers own final presentation.

Telegram should prefer concise, bounded prompts. Web may render richer grouped forms or cards from the same intent.

Complex Telegram interactions may naturally decompose into bounded internal segments. This specification does not introduce a nested-saga abstraction for those segments. Existing `stage`, `state`, `turns`, and `next_prompt_intent` are sufficient for the first phase.

A lightweight `segment` field may be introduced later if progress display or ergonomics require it.

## Materialization Contract

Materialization is the phase that creates or updates persistent domain artifacts and filesystem projections.

Materializers must be pipelines of named steps. Each step must have one primary responsibility.

For Project Setup, example materialization steps include:

- create project
- create default board
- persist setup attributes
- write setup summary document
- initialize project protocols
- initialize runtime containers
- create starter tickets
- materialize local workspace

This list is illustrative for the reference saga. Future sagas may define different materialization steps.

The materializer pipeline should make step boundaries explicit enough that tests can validate each responsibility without requiring one large end-to-end assertion for every detail.

## Step Result Contract

Materializer steps should return structured results.

The robust result shape supports:

- `status`
- `data`
- `effects`
- `errors`
- `reconciliation`

Simple steps may omit empty fields or return a lightweight form when the full shape adds ceremony without value.

Expected `status` examples:

- `ok`
- `skipped`
- `pending`
- `failed`
- `needs_reconciliation`

`data` carries produced identifiers or structured output.

`effects` describe visible, internal, or debug events from the step.

`errors` must be structured enough for logs, clients, and tests.

`reconciliation` should describe retry safety, created artifacts, missing artifacts, and cleanup choices when relevant.

## Effects Contract

Saga effects must support classification.

Minimum visibility classes:

- `public`
- `internal`
- `debug`

`public` effects can be returned to clients or rendered as user-visible outcomes.

`internal` effects support application coordination and audit but do not need to be shown in normal UI.

`debug` effects act as observability taps. They may expose pipeline checkpoints or diagnostic values without changing saga behavior.

Adapters may choose what to render, but the effect classification should make that choice explicit.

## Failure and Reconciliation

Saga context must be preserved by default when materialization fails.

This is especially important for persisted questionnaire turns, normalized context, and user-provided setup answers. A late materialization failure must not destroy useful context by default.

When a materialization pipeline partially succeeds and then fails, the saga should enter an explicit failed or reconciliation state.

If cleanup would delete useful artifacts or state, the system should offer a user-facing choice in the tone of:

- preserve partial state to continue later
- discard or clean up created artifacts

Rollback is allowed when safe, but it must be explicit and careful. It must not silently discard valuable context or artifacts.

## Lifecycle Contract

The minimum saga lifecycle should support:

- start
- advance
- execute or materialize steps
- complete
- fail or reconcile
- cancel
- inspect current state

This is a practical starting contract, not a rigid universal law.

Each saga may expose these operations through its own application-facing command/query names.

## Application Boundary

The architecture should continue the current RedWright direction.

Rails controllers may remain RESTful where that is natural for web/resource UI.

Transport-agnostic internal application operations may use verb-noun command/query naming.

The important boundary is not naming purity. The important boundary is that Telegram and web converge on the same application behavior and canonical persisted state.

The existing codebase should guide exact boundaries while refactors improve modularity.

## Project Setup Reference Contract

Project Setup is the first reference saga.

It should not be treated as proof that all future sagas have the same shape.

Project Setup is useful as a reference because it already includes:

- multi-turn setup context collection
- semantic answer normalization
- saga state persistence
- materialization
- protocol initialization
- runtime container initialization
- ticket creation
- workspace materialization
- Telegram rendering
- command/query API responses

The first implementation pass for this architecture should use Project Setup as the reference case and preserve its current external behavior.

Refactoring Project Setup should prioritize areas where responsibilities are already accumulating, especially the boundary between questionnaire and materialization.

## Refactor Policy

Existing behavior is starting to work as envisioned. Architecture cleanup must therefore be conservative and contract-preserving.

Refactors must preserve by default:

- command/query response shapes
- Telegram behavior
- persisted state semantics
- existing successful setup outcomes
- test-covered behavior

Any behavior or contract change must be explicit in a later implementation spec or plan.

Cosmetic renames are not the goal. Structural moves are acceptable when they improve taxonomy, modularity, conceptual homogeneity, and maintainability.

## Observability and Debugging

The saga architecture must improve operational understanding, not only file organization.

The system should make it clear:

- which saga is active
- which stage/state it is in
- which step ran
- which effects were produced
- which step failed
- whether context was preserved
- what can be retried or reconciled

Debug effects and structured step results are part of this observability model.

## Acceptance Criteria

1. Heavy-interaction sagas are defined as a general architectural pattern.
2. Rails/application persistence remains canonical for saga state.
3. Telegram and web remain adapters over shared application behavior.
4. Domain-specific saga session models are allowed and preferred initially.
5. Domain-specific models follow a common saga contract.
6. The common contract includes state, stage, status, turns, effects, next prompt intent, terminal reason, and metadata.
7. Each saga declares its own stage taxonomy.
8. No rigid global stage taxonomy is required in the first phase.
9. Questionnaires are optional per saga.
10. Questionnaire-based sagas follow the bounded quiz playbook.
11. Questionnaire/context collection is separate from materialization.
12. Materialization is modeled as a named step pipeline.
13. Materializer steps have one primary responsibility.
14. Step results support status, data, effects, errors, and reconciliation hints.
15. Lightweight step results are allowed when the full shape is unnecessary.
16. Saga context is preserved by default on materialization failure.
17. Partial failure can ask the user whether to preserve state for later continuation or discard artifacts.
18. Effects support visibility classification including public, internal, and debug.
19. Sagas expose structured prompt intent rather than final human copy.
20. Adapters/renderers own channel-specific user-facing wording.
21. The architecture does not introduce nested-saga modeling in the first phase.
22. The lifecycle supports start, advance, execute/materialize, complete, fail/reconcile, cancel, and inspect.
23. Rails RESTful surfaces and internal verb-noun operations may coexist.
24. Project Setup is the first reference saga.
25. Project Setup refactors preserve current external command/query and Telegram behavior unless explicitly changed by a later spec.
26. The architecture improves modularity, observability/debugging, and future saga creation ergonomics.

## Open Questions

- Which Project Setup materialization responsibility should be extracted first during implementation planning?
- Should a generic shared saga persistence model be introduced after multiple sagas exist?
- Are `public`, `internal`, and `debug` sufficient effect visibility classes?
- Should lightweight `segment` metadata be introduced later for UI progress display?
- How should preserve-versus-discard reconciliation be rendered differently in Telegram and web?
