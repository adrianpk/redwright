# RedWright LLM Request Engine Context Composition Specification

## Metadata

- id: `spec-2026-05-05-redwright-llm-request-engine-context-composition`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-05`
- updated: `2026-05-05`
- scope: `runtime-core/llm-request-engine/context-composition/provider-calls/tracing-boundary`
- derived_from:
  - `ops/specs/conv/2026-05-05-redwright-llm-request-engine-context-composition-conv.md`
  - `ops/specs/conv/2026-05-05-redwright-llm-request-engine-context-composition-conv-raw.md`
  - `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
  - `ops/specs/specs/2026-05-03-redwright-llm-rolling-trace-file-spec.md`
  - `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`

## Problem Statement

RedWright has multiple productive LLM call sites. Each call site can drift toward its own partial prompt-building, context-selection, provider invocation, error handling, and trace-recording behavior.

That makes LLM behavior harder to improve because useful context composition rules are scattered across callers. It also increases the risk that one caller sends too little project context, another sends too much stale context, and another exposes raw provider failures directly to user-facing channels.

RedWright needs a simple shared LLM request boundary that is easy to plug into existing calls while leaving room for richer context composition later.

## Goals

- introduce a dedicated `Redwright::LLM` conceptual namespace for LLM request composition and related pure support components
- provide an `LLMRequestEngine` that callers can use to replace existing direct LLM calls
- keep the first integration small and practical by migrating one real caller first
- accept explicit inputs prepared by outer application layers instead of fetching repositories, configuration, or business state internally
- compose request context from named, authority-aware sections
- execute the LLM request through the existing provider adapter boundary
- return a normalized RedWright response shape instead of exposing raw provider responses as the primary interface
- normalize common provider, parsing, timeout, empty-response, redaction, and schema failures into RedWright statuses
- keep trace recording outside the engine through a separate `LLMTraceRecorder`
- let the relevant business service coordinate engine invocation and trace recording
- keep the implementation simple enough to plug into existing LLM call sites without a broad prompt framework

## Non-Goals

- universal reusable prompt framework
- external-project abstraction
- generic `LLMInteractionService` or other cross-business orchestration service
- full migration of every LLM caller in the first implementation
- complete task taxonomy
- user-facing model-role selection
- database-backed previous-interaction store
- final token-budget algorithm
- trace viewer UI
- replacement of the rolling LLM trace file specification

## Product Contract

RedWright must expose a shared LLM request engine that a caller can invoke instead of building and sending an LLM request directly.

The first version should be shaped by one real existing caller. The most likely initial candidate is project-creation questions, but that caller must not be treated as proof that the final context-composition problem is fully exercised.

The engine surface should be practical, explicit, and easy to adopt. It should not require callers to build a large generic request object when a semantic method with keyword arguments can express the operation more clearly.

## Namespace And Code Boundary

The preferred conceptual namespace is:

```ruby
Redwright::LLM
```

The exact filesystem path must follow the repository's Ruby loading conventions.

Allowed concepts under this namespace include:

- `LLMRequestEngine`
- `LLMTraceRecorder`
- small pure helpers for request building, normalization, redaction, token estimation, or provider adaptation when implementation pressure proves they are useful

The implementation must not create managers, handlers, resolvers, or similar abstractions by habit. New collaborators are justified only when they remove real complexity or clarify a responsibility that has become concrete.

## Dependency Direction

The design follows onion architecture direction:

```text
controllers / business services / runtime flows -> Redwright::LLM internals
```

`LLMRequestEngine` must receive explicit inputs from outer layers. It must not fetch project records, tickets, repositories, configuration, workspace state, or business objects by itself.

Outer layers are responsible for gathering available business state and passing the relevant values inward.

Pure internal collaborators may be used by the engine as long as they do not invert this direction by depending on application services or repositories.

## Engine Responsibility

`LLMRequestEngine` owns:

- receiving explicit request inputs
- selecting or assembling named context sections from those inputs
- applying authority and safety labeling to context sections
- applying RedWright request policy held in code
- selecting or honoring an internal model-role intent when available
- invoking the provider through existing provider adapter behavior
- normalizing successful and failed responses into RedWright response objects

`LLMRequestEngine` does not own:

- business workflow orchestration
- resolving project, ticket, use-case, tag, or session records
- generating canonical business scope identity unless that responsibility later becomes an explicit inner pure input helper
- recording traces after the response
- creating ticket comments, blocking tickets, or notifying users
- exposing raw provider errors to user-facing channels by default

## Trace Recorder Responsibility

`LLMTraceRecorder` owns trace recording after an LLM interaction is complete.

The recorder is separate from the engine even though both operate on LLM request and response data.

`LLMTraceRecorder` may receive:

- the logical request inputs
- selected context metadata
- provider and model metadata
- normalized response status
- raw response references or raw diagnostics when enabled
- usage metadata
- warnings and failures
- caller-provided project, ticket, session, source, actor, or trace correlation metadata

`LLMTraceRecorder` should coordinate with the existing rolling LLM trace file behavior rather than redefine its durable file contract.

The preferred coordination model is:

```text
business service -> LLMRequestEngine -> normalized response
business service -> LLMTraceRecorder
```

If a path has no business service yet, the responsible controller may coordinate both components as a fallback.

The spec must not introduce a generic orchestration service name for this responsibility.

## Public API Direction

The engine API should prefer semantic methods with explicit keyword arguments.

The first implementation must not invent a broad operation taxonomy upfront. Method names should be introduced only when a real caller needs them.

Acceptable direction:

```ruby
engine.some_semantic_operation(
  project_id:,
  request_mode:,
  work_kind:,
  source:,
  raw_text:,
  context_sections:,
  model_role: nil,
  output_contract:
)
```

The exact method name and arguments are implementation-guided by the first migrated caller.

The engine should avoid one opaque `call(request:)` as the only public shape if named methods can communicate intent more clearly. Ruby can still use symbols, keyword arguments, and pattern matching as lightweight dispatch mechanisms where that keeps the code simple.

## Input Contract

The engine should accept structured explicit values when the caller has them.

Likely inputs include:

- `project_id`
- `use_case_id`
- `ticket_id`
- `tags`
- `request_mode`
- `work_kind`
- `source`
- `raw_text`
- `agent_context`
- `project_context`
- `request_context`
- `ticket_context`
- `protocol_context`
- `quiz_context`
- `workspace_context`
- `documentation_context`
- `execution_context`
- `previous_interactions`
- `output_contract`
- internal `model_role` intent when the caller has a clear system reason
- trace and session correlation metadata for downstream recording

Project scope is the normal preferred path, but it is not universal. RedWright may have useful global, pre-project, or provider/framework questions that should not be forced into a project.

## Request Classification

The first implementation should not rely on a large closed taxonomy.

RedWright should distinguish at least two conceptual axes when needed:

- `request_mode`: the operational container or source, such as ticket work, direct query, project setup, or background run
- `work_kind`: the kind of work being requested, such as planning, implementation, documentation, refinement, classification, or question generation

The initial implementation may use a small enum-like set of constants and add values only when real callers require them.

The system, not the user, should select the model role. Internal callers may pass explicit model-role intent when the case is obvious, such as coding-oriented ticket implementation or code review.

## Context Section Contract

The engine should treat context as named sections, not as one undifferentiated prompt blob.

Core section concepts:

- `agent_context`
- `project_context`
- `request_context`
- `ticket_context`
- `protocol_context`
- `quiz_context`
- `workspace_context`
- `documentation_context`
- `execution_context`
- `previous_interactions`
- `output_contract`

Each included section should carry enough metadata for debugging and authority handling when practical:

- section name
- source
- freshness
- scope
- authority label
- reason selected
- estimated size when available

Omission reporting may be useful but is not a central first-version requirement. The rolling trace and recorder path may provide enough request-composition visibility.

## Section Semantics

`agent_context` captures stable agent posture and operating rules.

`project_context` captures project-scoped facts and project configuration known by RedWright.

`request_context` captures the current user text, normalized intent, and immediate request facts.

`ticket_context` captures ticket state, comments, acceptance context, and work constraints when a ticket exists.

`protocol_context` captures applicable project protocols, architecture rules, lifecycle rules, and repository operating constraints.

`quiz_context` captures human-provided project, product, use-case, or preference knowledge from Quiz/questionnaire data.

`workspace_context` captures repository structure and selected code/workspace evidence needed for coding tasks.

`documentation_context` captures internal, generated, dependency, framework, library, or API documentation. It is separate from workspace context.

`execution_context` captures validation outputs, command results, normalized failures, lint errors, compile errors, test failures, and refinement state.

`previous_interactions` captures bounded historical evidence from prior RedWright/LLM calls. It must never outrank the current task, repository state, protocols, or guardrails.

`output_contract` describes the required semantic response shape so RedWright can act on the answer.

## Authority And Safety Contract

The engine should label context sections with authority cues that help the LLM resolve conflicts.

A starting authority order is:

1. current user request or active ticket instruction
2. current repository state
3. formal project protocols and architecture docs
4. current execution results and validation failures
5. ticket metadata and comments
6. Quiz or questionnaire answers
7. previous interactions
8. old traces, stale summaries, or low-confidence generated notes

RedWright should prefer the newest and most operationally relevant source when sources conflict.

Strong contradictions must be surfaced explicitly. The first spec does not finalize whether the engine returns a conflicts section, returns a `needs_clarification` status, or lets the business service block ticket work and create a comment. Ticket-based autonomous work may require comments, user mentions, blocked state, and future notification integration.

Redaction and filtering are day-zero requirements before context is injected into an LLM request. Prompt text alone is not a sufficient safety control.

## Previous Interaction Contract

Previous interactions are useful mainly for continuity, refinement, ticket work, and long-running operations.

The first storage direction is transient filesystem storage under a scoped `tmp` area, not a database-backed store.

The initial scope should be stronger than `agent_id` alone. A practical starting model is `agent + session`, where session represents a specific operation type and operation identifier.

Stored previous-interaction material should be pruned or cleaned so transient storage does not accumulate indefinitely.

The exact choice among compact rolling summaries, raw interaction records, and hybrid records should be validated against real RedWright cases.

## Preflight Contract

Preflight LLM calls are optional context-selection tools, not the default for every request.

Potential preflight uses include:

- task classification
- context source selection
- file or symbol retrieval planning
- Quiz or questionnaire context selection
- previous interaction selection
- database query planning
- refinement after validation failures

When a preflight produces retrieval criteria, deterministic RedWright code must validate and execute the final retrieval. The LLM must not bypass deterministic query builders or execute raw database logic.

The first implementation should not impose a rigid global preflight cap until the useful preflight categories are better understood.

## Response Contract

The engine returns a normalized RedWright response object.

The exact shape is implementation-guided, but likely fields include:

- `status`
- `semantic_payload`
- `rendered_text`
- `provider_metadata`
- `usage`
- `warnings`
- `raw_response_ref`

Raw provider data may be recorded or referenced for diagnostics when configured, but it should not be the main caller contract and should not leak into user-facing Telegram or web messages by default.

Failures should be normalized into RedWright statuses, including:

- provider error
- timeout
- empty response
- schema parse failure
- invalid semantic payload
- redaction failure
- safety failure
- unsupported provider or model configuration

## First Implementation Scope

The first implementation should:

1. define the `Redwright::LLM` namespace and `LLMRequestEngine` boundary
2. define the minimal normalized response object needed by the first caller
3. define the minimal `LLMTraceRecorder` boundary needed to record the first caller's interaction
4. migrate one existing LLM call site
5. pass explicit inputs from the outer caller into the engine
6. invoke the existing provider adapter behavior through the engine
7. keep trace recording coordinated by the caller's business service or controller fallback
8. normalize provider and parse failures for that caller
9. keep the API narrow and expand only when the next real caller needs more

## Acceptance Criteria

1. A first `Redwright::LLM` implementation exists under the repository's Ruby loading conventions.
2. `LLMRequestEngine` can replace one existing LLM call site without requiring that caller to build a large opaque request object.
3. The migrated caller passes explicit values into the engine rather than having the engine fetch business state.
4. The engine invokes existing provider adapter behavior internally.
5. The engine returns a normalized RedWright response shape.
6. Provider errors and parse failures are normalized for the migrated caller.
7. Raw provider diagnostics are not shown directly in user-facing output by default.
8. `LLMTraceRecorder` remains outside the engine.
9. The business service or controller fallback coordinates trace recording after the engine returns.
10. The first implementation avoids introducing unused managers, handlers, resolvers, or broad taxonomies.
11. Tests cover the first migrated caller's successful response path and normalized failure path.

## Open Questions

- Which existing LLM call should be migrated first?
- What exact semantic method name and keyword arguments does that first caller need?
- What is the minimal normalized response object for the first caller?
- What exact trace event or trace record should `LLMTraceRecorder` emit for the first caller?
- Where should conversation/session scope identity be generated?
- What exact redaction rules are required before the first implementation slice?
- How should conflict handling integrate with ticket comments, blocked state, mentions, and notifications?
- Which previous-interaction format works best in real RedWright loops: compact summary, raw records, or hybrid?
