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

The initial deliverable must feel like something a business service can plug into an existing LLM call site with low ceremony:

1. gather existing caller data
2. pass explicit keyword arguments into the engine
3. receive a normalized response
4. record the trace through the recorder
5. keep the caller's user-facing behavior stable or cleaner

The spec intentionally uses strong boundaries but avoids pretending that every future helper class is already known. The questionnaire explicitly rejected abstraction by habit. The first implementation should therefore favor a narrow working path over a complete architecture skeleton.

## Decision Summary

The completed questionnaire established these concrete decisions:

- `LLMRequestEngine` is the preferred concept name for the request composition and execution boundary.
- `Redwright::LLM` is the preferred namespace direction.
- `LLMTraceRecorder` is the preferred recorder name.
- The engine executes the provider request; it is not only a builder that returns a neutral request object.
- The recorder remains outside the engine.
- Coordination belongs to the business service that owns the workflow, with controller fallback only when no service exists yet.
- The spec should not introduce a generic orchestration service.
- The engine receives explicit data from outer layers and does not query business state directly.
- The public API should use semantic methods with keyword arguments rather than one opaque generic request call.
- Semantic methods should stay business-agnostic and describe LLM operation shapes, not caller-specific workflows.
- The first real caller should drive the exact method name and argument list.
- Project setup question generation is a plausible first caller, but it is not representative of all future context pressure.
- One caller is enough for the first implementation. Scope expands only when another real caller requires it.
- The normalized response shape should be RedWright-native.
- Raw provider details belong in diagnostics or trace output, not in user-facing messages by default.
- Context sections should be named and authority-aware.
- `output_contract` should be explicit enough for RedWright to act on the response.
- Redaction and filtering are day-zero requirements.
- Previous interactions are useful but their format and policy should be validated through real loops.
- Preflight requests are optional tools for context selection, not mandatory boilerplate.

## Canonical Interaction Flow

The target interaction is:

```text
business service or controller
  -> gather project/request/ticket/use-case/workspace/trace inputs
  -> LLMRequestEngine semantic method
    -> build named context sections from explicit inputs
    -> apply authority labels and safety filters
    -> render provider-ready request
    -> call existing provider adapter behavior
    -> normalize response or failure
  -> business service handles workflow outcome
  -> LLMTraceRecorder records request/response/context metadata
  -> business service returns user-facing result or continues workflow
```

The engine is not the owner of the business outcome. It can say that an LLM call succeeded, failed, timed out, returned invalid structure, or produced a semantic payload. The surrounding business service decides whether that means asking a user, saving a model, blocking a ticket, retrying, falling back, or displaying a message.

## Required Simplicity Constraint

The design must remain easy to call from existing RedWright code.

The first implementation must not require:

- a full task taxonomy before the first caller can use the engine
- a database-backed request history model
- a new service layer solely to wrap engine and recorder
- a generalized prompt framework
- user-editable context policy
- a resolver or manager for every sub-responsibility
- migration of every LLM call site before value is delivered

Simple is not the same as vague. The implementation should have precise contracts where they matter: dependency direction, normalized responses, provider error handling, trace boundary, context section metadata, and user-facing failure behavior.

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

This means the engine may depend on objects such as:

- value objects
- context section structs
- response structs
- redaction helpers
- prompt rendering helpers
- token estimation helpers
- provider adapter interfaces already present in the runtime

It must not depend on:

- Rails controllers
- Telegram controllers or handlers
- business workflow services
- Active Record repositories or query objects that fetch project state
- ticket state transition services
- notification services
- Kanban workflow services

If a future helper needs to retrieve project data, that helper belongs outside the engine boundary unless it is explicitly reclassified as a business service input provider.

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

The engine may produce enough structured information for the business service to make those decisions, but it must not perform them internally.

## Engine Internal Phases

The first implementation may be a single class if that remains readable. Conceptually, however, the engine performs these phases:

1. `input_normalization`: normalize explicit keyword inputs into an internal call context without fetching new business state.
2. `context_section_assembly`: convert supplied facts and supplied context fragments into named sections.
3. `safety_filtering`: redact or reject sensitive material before provider invocation.
4. `authority_annotation`: label sections with priority and evidence type.
5. `request_rendering`: render the provider-ready prompt or structured provider payload.
6. `provider_invocation`: call the existing provider adapter behavior with the selected model role and operation metadata.
7. `response_normalization`: turn provider success or failure into a RedWright response object.
8. `diagnostic_packaging`: expose safe metadata and raw references for trace recording.

These phases are descriptive. They do not require separate classes in the first implementation.

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

The recorder may write to or feed existing trace infrastructure, but it should not silently become a context-selection engine. Its first responsibility is observability and diagnostics for the interaction that just happened.

Trace recording must support two different needs without collapsing them:

- durable debugging trace: faithful enough to inspect request/response behavior when enabled
- future context reuse: compact enough to be considered for `previous_interactions` later

The first implementation may focus on durable diagnostics and keep context-reuse summaries minimal or deferred.

The preferred coordination model is:

```text
business service -> LLMRequestEngine -> normalized response
business service -> LLMTraceRecorder
```

If a path has no business service yet, the responsible controller may coordinate both components as a fallback.

The spec must not introduce a generic orchestration service name for this responsibility.

The recorder should be invocable with explicit values. It should not discover the caller's project, ticket, session, or actor on its own.

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

The first semantic method should satisfy the first migrated caller and establish the API style. It should not try to anticipate every future operation.

A good first method has these properties:

- its name describes the LLM operation, not the business caller
- its required arguments are explicit
- optional arguments have clear defaults
- returned data is normalized
- trace-relevant metadata is available to the caller or recorder
- invalid input fails early with a RedWright-native status or exception pattern consistent with nearby code

Examples of method names are intentionally not normative in this spec. Naming should be chosen during implementation after inspecting the first call site.

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

Inputs should be grouped by meaning in the implementation, even if passed as keyword arguments:

- identity and scope: project, ticket, use case, tags, session, run, trace
- request intent: source, raw text, request mode, work kind, model-role intent
- context sections: already gathered context fragments and metadata
- output contract: schema or semantic response requirement
- diagnostics: flags or references needed by trace recording

Required inputs are caller-specific in the first implementation. The spec should not declare `project_id` universally required because pre-project and global requests may exist.

The engine should reject or normalize missing inputs according to operation needs. For example, a project-scoped request should not silently proceed as global if the caller expected project context.

## Output Request Contract

Every LLM request should include an output contract, even if minimal.

The output contract tells the model what RedWright needs semantically, not only how the final human-facing message should read.

The contract may specify:

- expected semantic payload fields
- allowed status or intent values
- whether rendered text is required
- whether hidden rationale must be omitted from user-facing output
- fallback behavior when the model cannot satisfy the request
- parseable format expectations

For the first caller, the output contract should be no larger than necessary, but it must be explicit enough that RedWright does not have to infer behavior from arbitrary prose.

## Request Classification

The first implementation should not rely on a large closed taxonomy.

RedWright should distinguish at least two conceptual axes when needed:

- `request_mode`: the operational container or source, such as ticket work, direct query, project setup, or background run
- `work_kind`: the kind of work being requested, such as planning, implementation, documentation, refinement, classification, or question generation

The initial implementation may use a small enum-like set of constants and add values only when real callers require them.

The system, not the user, should select the model role. Internal callers may pass explicit model-role intent when the case is obvious, such as coding-oriented ticket implementation or code review.

`request_mode` and `work_kind` are not meant to become a rigid ontology in the first slice. They are practical control signals for policy decisions such as:

- whether ticket context matters
- whether workspace context matters
- whether execution failures matter
- whether previous interactions might help
- whether the coding or non-coding model role should be preferred
- whether clarification or conflict handling should be available

Unknown or unsupported combinations should fail clearly or fall back deterministically. They should not produce silent prompt degradation.

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

Context section metadata should allow later debugging of two questions:

```text
Why did this information reach the LLM?
Why was expected information absent from the LLM request?
```

The first implementation does not need a full allocation report, but it should keep enough internal structure that recorder output or trace diagnostics can expose selected section names and approximate weights.

## Context Composition Policy

Context policy should live in code for the first implementation.

The policy should be conservative and caller-driven:

- include high-authority current request data first
- include project and protocol context when the request is project-scoped
- include ticket context only when the caller supplies it or the request mode implies ticket work
- include workspace and documentation context only when explicitly supplied or clearly needed by the operation
- include execution context only after validation or command output exists
- include previous interactions only under bounded conditions
- include output contract always

The engine should not try to retrieve missing sections. It can only decide how to arrange, label, filter, shrink, omit, or reject the sections it has received.

If a section is empty, the engine may omit it from the rendered provider request while retaining a diagnostic fact that the section was unavailable.

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

Minimum first-version safety behavior:

- avoid asking users for secrets, credentials, tokens, passwords, or PII
- redact obvious secrets before sending context where practical
- keep hidden model rationale out of user-facing output
- keep raw provider errors out of user-facing output by default
- label previous interactions as historical evidence
- keep current task instructions and repository state above historical summaries

The safety boundary does not need perfect data-loss-prevention behavior in the first implementation. It does need explicit code-level protections where the caller path can reasonably provide them.

## Previous Interaction Contract

Previous interactions are useful mainly for continuity, refinement, ticket work, and long-running operations.

The first storage direction is transient filesystem storage under a scoped `tmp` area, not a database-backed store.

The initial scope should be stronger than `agent_id` alone. A practical starting model is `agent + session`, where session represents a specific operation type and operation identifier.

Stored previous-interaction material should be pruned or cleaned so transient storage does not accumulate indefinitely.

The exact choice among compact rolling summaries, raw interaction records, and hybrid records should be validated against real RedWright cases.

Previous interaction records, when introduced, should preserve at least:

- operation kind
- project or global scope
- ticket/use-case/session/run identifiers when available
- request summary
- response summary
- outcome
- failure summary when relevant
- creation time
- selected context section names

They should not blindly append full prompts and responses forever. The rolling trace file can serve durable debugging when enabled; previous-interaction material should be optimized for possible future prompt reuse.

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

Preflight must not recursively create unbounded preflight chains.

When preflight is added, each preflight category should define:

- why the deterministic caller cannot select enough context directly
- what inputs it receives
- what structured output it returns
- how deterministic code validates that output
- what happens when the preflight fails

No first implementation task should add preflight unless the selected caller clearly needs it.

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

The normalized response should distinguish at least these concepts, even if the exact Ruby shape differs:

- transport/provider status
- semantic parse status
- user-facing rendered text
- machine-facing semantic payload
- diagnostics safe for logs
- diagnostics requiring opt-in raw tracing

The caller should not need to understand provider-specific exception classes to decide its business outcome.

## Provider Adapter Contract

The engine should reuse the provider behavior RedWright already has.

The first design recognizes the current operational model:

- RedWright distinguishes coding-oriented and non-coding model roles.
- A user may configure the same model for both roles.
- Provider focus includes OpenAI, Kimi, DeepSeek, and OpenRouter.
- OpenRouter may route to providers not directly supported by RedWright.

The engine should work with that model rather than invent a parallel provider abstraction in the first slice.

Provider adapter inputs should include enough metadata for tracing:

- provider
- model or model alias
- resolved model when available
- model role
- action or operation name
- payload size when available
- trace correlation identifiers when available

## Error Handling Contract

Errors should be handled according to caller visibility:

- raw provider exception details may be stored or referenced for diagnostics when tracing is configured
- normalized failure status should be returned to the caller
- user-facing messages should be plain and useful
- schema or parse failures should not be mistaken for provider success
- safety/redaction failures should stop or degrade the request according to operation policy
- trace writer failures must not break LLM execution

The business service remains responsible for deciding whether a normalized failure means retry, fallback, blocked workflow, ticket comment, or user-visible explanation.

## Context Allocation Visibility

A formal context allocation report is not a central first-version requirement.

However, the engine should preserve enough metadata for trace/debug output to explain:

- which section names were included
- which high-level scopes were represented
- approximate size or byte counts when available
- authority labels
- safety filtering result
- provider action and model role

This can be emitted through `LLMTraceRecorder` or the rolling trace mechanism. It does not need to become a separate persisted artifact in the first implementation.

## First Caller Selection Guidance

The first caller should be selected for low migration risk and real value.

Project setup question generation is a candidate because it already exists and likely has a bounded LLM interaction shape. It is not a complete stress test for later context-heavy work.

The first caller should be rejected if migrating it would require broad unrelated changes. A better first caller is one that:

- already has an LLM call
- has clear inputs available at the call site
- has a parseable or semi-structured expected output
- has a visible failure path that can benefit from normalization
- can be tested without migrating every provider path
- does not require full previous-interaction support

The implementation plan may inspect current call sites before finalizing the first one.

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

## Test Strategy

The first implementation should include focused tests for the migrated caller and unit-level tests for pure boundaries introduced by the engine.

Minimum test coverage:

- successful provider response normalization
- provider error normalization
- invalid or unparsable semantic response normalization
- hidden raw diagnostics not appearing in user-facing rendered output
- explicit input passing from caller into engine
- trace recorder remaining outside engine invocation
- first caller behavior preserved or intentionally improved

If redaction logic is introduced, tests must cover at least obvious token, password, credential, and bearer-token examples.

If context section objects are introduced, tests should cover section naming, authority labels, and rendered inclusion order for the first operation.

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
12. The first implementation records enough trace metadata to identify operation name, provider/model role, response status, and selected section names when available.
13. The migrated path includes an explicit output contract.
14. The migrated path does not fetch business state from inside `LLMRequestEngine`.
15. Documentation or tracker notes identify which existing LLM call was migrated first and why.

## Open Questions

- Which existing LLM call should be migrated first?
- What exact semantic method name and keyword arguments does that first caller need?
- What is the minimal normalized response object for the first caller?
- What exact trace event or trace record should `LLMTraceRecorder` emit for the first caller?
- Where should conversation/session scope identity be generated?
- What exact redaction rules are required before the first implementation slice?
- How should conflict handling integrate with ticket comments, blocked state, mentions, and notifications?
- Which previous-interaction format works best in real RedWright loops: compact summary, raw records, or hybrid?
