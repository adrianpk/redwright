# RedWright LLM Request Engine Context Composition Conversation Notes

## Status

Living discussion

## Related Draft

`../drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`

## Related Raw Capture

`2026-05-05-redwright-llm-request-engine-context-composition-conv-raw.md`

## Related Specification

`../specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`

## Purpose

Curated alignment notes for the future `LLMRequestEngine`, context composition boundary, and `LLMTraceRecorder` design.

These notes distill the completed 50-question bounded questionnaire and supersede the raw capture for decision lookup. The raw file remains available as working-memory evidence.

## Sessions

### Session 2026-05-05

#### Context

- RedWright already has multiple LLM call sites and needs a shared way to compose useful request context without duplicating incomplete prompt-building logic.
- The existing draft used `PromptEngine` as a provisional name, but the alignment moved toward `LLMRequestEngine` for the request-execution boundary and `LLMTraceRecorder` for trace recording.
- The design must support richer context composition over time without becoming a generic prompt framework or an externally reusable abstraction that is awkward inside RedWright.

#### Current Convergences

- `LLMRequestEngine` should live conceptually under a dedicated `Redwright::LLM` namespace, following the repository's existing Ruby loading conventions.
- The engine should perform the LLM request through existing provider adapter boundaries; it should not only return a request object for callers to send manually.
- Recording and tracing should remain outside the engine. `LLMTraceRecorder` is the preferred name for the component that records request, response, context metadata, and diagnostic details.
- The service that coordinates engine calls and trace recording should be the business service that already owns the use case. The spec should not introduce a generic orchestration service such as `LLMInteractionService`.
- If no business service exists in a path, the responsible controller may coordinate engine and recorder as a fallback.
- The public API should prefer semantic methods with explicit keyword parameters over one opaque `call(request:)` entry point.
- Semantic methods should describe general LLM operation shapes, not business-caller-specific workflows.
- The initial operation taxonomy should not be invented upfront. It should emerge from replacing real existing call sites.
- The first implementation should integrate one caller and expand only when concrete need requires more scope.
- Project-creation questions are the most obvious initial caller candidate, but they may not exercise the heavier context composition needed later.
- The engine should receive explicit inputs gathered by outer layers. It should not fetch repositories, configuration, project state, or business records by itself.
- Dependency direction should follow onion architecture: outer application layers call inward; inner request engine code does not reach outward into services or repositories.
- Pure internal collaborators such as builders, normalizers, token budget helpers, or provider adapter wrappers are allowed when they remove real complexity, but they should not be created as ceremony.

#### Request Shape And Classification

- `project_id` should be the normal and preferred scope for most RedWright operations, but the design should not make project scope universal because useful global or pre-project requests may exist.
- A single flat `task_type` is probably insufficient. RedWright should distinguish an operational container or request mode from the kind of work being requested.
- A small enum-like set of values is enough initially. The system should add categories only when a real caller needs them.
- Internal callers may provide explicit intent such as `model_role: coding` when the case is obvious. This remains an internal system decision, not a user-facing configuration responsibility.
- The system should generally choose the model role rather than asking the user to choose between coding and non-coding models.

#### Context Sections

- Core context concepts include `agent_context`, `project_context`, `request_context`, `ticket_context`, `protocol_context`, and `quiz_context`.
- `workspace_context`, `documentation_context`, `execution_context`, `previous_interactions`, and `output_contract` are also important, but their exact inclusion policy should be shaped by real usage.
- `workspace_context` is indispensable for coding tasks and may include tree data, selected files, symbol information, dependency hints, generated docs, project docs, and relevant configuration.
- `documentation_context` should be a separate section, not buried under workspace context.
- `execution_context` should capture validation state, command output, lint errors, compile errors, test failures, and normalized failures once a loop has produced them.
- `output_contract` should always be explicit enough for RedWright to interpret the response, even when the rendered user response is plain text.

#### Previous Interactions And Transient Context

- Previous interactions are likely useful, especially in loops, but their exact inclusion policy should be validated against real RedWright usage.
- Compact rolling summaries, raw records, or hybrid previous-interaction records should be a policy decision tested against real cases.
- The first recorder/storage mechanism for previous interactions should prefer transient filesystem storage under a scoped `tmp` area rather than a database.
- Transient storage must have pruning or cleanup so it does not accumulate stale data indefinitely.
- `agent_id` alone is not enough scope because one agent may eventually work on multiple operations. A practical starting scope is `agent + session`, where the session represents a specific operation type and operation identifier.
- Session identity ownership remains open, but controllers should not own conversational scope generation.
- The responsibility for resolving conversation scope can be named without forcing a heavy class taxonomy.

#### Preflight And Context Selection

- Preflight LLM calls can be useful for context selection and query customization, especially for complex tasks.
- A preflight may produce retrieval criteria for deterministic application code to validate and execute; it should not execute SQL or bypass deterministic query builders.
- The spec should not impose a rigid global preflight count before distinguishing preflight categories.
- Context policy should live in code first, not in user-editable configuration for MVP.
- Context budgeting and trimming are important but remain open. The design should not pretend that simple token cuts are always safe.

#### Authority, Conflicts, And Safety

- The newest and most operationally relevant source should generally win.
- A starting authority order is current user or ticket request, repository state, protocols and project docs, execution results, ticket metadata, Quiz answers, previous interactions, then old traces or generated notes.
- Strong contradictions should be handled explicitly, but the exact mechanism remains open.
- Ticket-based autonomous work may need to comment, mention the lead user, and block or wait when a conflict cannot be resolved safely.
- Redaction and filtering are day-zero requirements before context is injected. Textual prompt guardrails are not enough.
- Retrieved context should carry authority labels such as `repository_evidence`, `project_protocol`, or `historical_interaction`, without making normal project operation overly paranoid or cumbersome.

#### Response And Failure Shape

- The engine should return a normalized RedWright response shape rather than exposing provider-specific raw responses as the primary caller contract.
- Likely normalized fields include `status`, semantic payload, rendered text, provider metadata, usage, warnings, and a raw response reference, but the exact shape should remain implementation-guided.
- Raw provider details should be available through configured diagnostics or trace output, not leaked by default into user-facing Telegram or web messages.
- Provider errors, schema parse failures, redaction failures, timeouts, empty responses, and invalid semantic payloads should be normalized into RedWright statuses.

#### Provisional Decisions

- Use `LLMRequestEngine` as the prose concept and `Redwright::LLM` as the preferred namespace direction.
- Use `LLMTraceRecorder` for the separate trace recording component.
- Keep request execution inside the engine and trace recording outside the engine.
- Do not add a generic orchestration service to the spec.
- Design against one real existing caller first, then expand only as needed.
- Keep the initial deliverable simple and easy to plug in so existing LLM calls can be replaced cleanly.
- Avoid introducing managers, handlers, resolvers, and other abstractions unless implementation pressure proves they reduce complexity.

#### Open Tensions

- The exact public semantic methods are intentionally not named yet.
- The exact initial caller is not final; project setup questions are plausible but may not be representative.
- The final normalized response schema remains implementation-guided.
- The exact conflict-handling path for autonomous ticket loops remains open.
- Context budgeting and trimming strategy remains open.
- Session identity ownership remains open.
- The right balance among raw previous interactions, compact summaries, and hybrid records needs real-case testing.

#### Deferred / Out of Scope

- External-project reusable prompt framework design.
- Full task taxonomy design.
- Database-backed previous interaction store.
- Final token-budget algorithm.
- Generic LLM orchestration service.
- User-facing model role selection.
- Full migration of every LLM caller in the first implementation.

## Open Questions

- Which existing LLM call should be migrated first?
- What exact semantic method does that first migration need?
- What fields are required in the first normalized response object?
- What minimal trace record must `LLMTraceRecorder` write for the first caller?
- Where should session/scope identity be generated?
- What context redaction rules are required for the first implementation slice?
- How should conflict handling interact with ticket comments, blocked state, and user notifications?

## Edit Notes

- This file is intentionally curated and non-final.
- The raw questionnaire reached its configured 50-question cap and is closed.
- The initial formal spec was derived from this curated file plus the existing drafts, not from the raw capture alone.
