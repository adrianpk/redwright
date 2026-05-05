# Project New Operational Loop Behavior Specification

## Metadata

- id: `spec-2026-05-01-project-new-operational-loop-behavior`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-01`
- updated: `2026-05-01`
- scope: `runtime/project-new-conversation`
- derived_from:
  - `ops/specs/drafts/2026-05-01-project-new-operational-loop-behavior-draft.md`
  - `ops/quiz/2026-05-01-project-new-operational-loop-behavior-quiz.md`

## Problem Statement

The `/project new` conversational flow currently mixes strong persistence primitives with inconsistent user-visible orchestration.

Observed issues:

- outcome responses are telemetry-first instead of user-outcome-first
- clarification behavior is not consistently visible in normal interaction
- execution may proceed without a clearly exposed loop-closing confirmation model

## Goals

- define a predictable conversational loop contract for `/project new`
- keep core decision logic in a DDD-like mediator layer (verb-noun command/query model in Ruby)
- consume user-provided context first and ask only blocking questions
- prevent endless questioning loops
- keep telemetry hidden by default and visible only in debug mode

## Non-Goals

- implementation details for non-`/project new` intents
- transport-specific UI redesign beyond response contract requirements
- full replacement of existing persistence model

## Runtime Boundary Contract

### Adapter Layer

Adapters (`telegram`, slash surfaces, `tui`) are wrappers only:

- parse user input
- call mediator command/query operations
- render response templates

Adapters must not own domain decisions (gap prioritization, context sufficiency, transition policy).

### Mediator Layer

Mediator owns:

- loop state transitions
- blocking vs optional gap decisions
- context sufficiency checks
- execution authorization decisions

Mediator style is command-query conceptual (verb-noun operations), not transport-specific logic.

## Quizal Loop State Contract

### States

- `collecting_context`
- `awaiting_blocking_answers`
- `awaiting_high_impact_confirmation`
- `ready_to_execute`
- `executing`
- `done`
- `cancelled`

### Terminal Outcomes

- `cancelled`
- `confirmed_and_executed`
- `proceeded_with_defaults`

### Transition Rule

Scaffold/business generation must not start before either:

1. blocking gaps are resolved, or
2. user explicitly confirms proceeding with defaults.

## Context Sufficiency Contract

Execution may start when all required blocking context is available through:

- explicit user input
- validated inferred values
- explicit user acceptance of defaults

Context must be accumulated turn-by-turn and reused in subsequent questions.

## Anti-Loop Contract

Guardrails are mandatory:

- `max_question_turns` per `/project new` cycle
- stagnation detection for repeated unresolved slots without new information
- fallback when guardrail triggers:
  - summarize known context
  - list unresolved blockers
  - request explicit choice: `cancel` or `proceed_with_defaults`

## Response Contract

### Default Mode

User-facing responses must be outcome-first:

- project creation/activation outcome
- concise summary of understood requirements
- blocking questions only (if any)
- immediate next action

### Debug Mode

Telemetry may be included only when debug/trace flag is enabled.

When included in messenger outputs, IDs/trace values must use markdown code formatting (backticks).

## Persistence Correlation Contract

Current persistence entities remain canonical:

- `chat_contexts` for active chat/project/workstream continuity
- `clarification_sessions` for open clarification state and resolved fields
- `workstreams` and `tasks` for execution lane and runtime units
- `alignment_*` artifacts as optional reuse substrate for structured Q/A memory

No parallel ad-hoc state store should be introduced for this loop.

## Acceptance Criteria

1. `/project new` follows explicit loop states and terminal outcomes.
2. Blocking questions are asked only when required.
3. Already-provided user context is not redundantly re-asked.
4. Execution does not start before loop-closing condition is satisfied.
5. Loop guardrails prevent ad-eternum questioning.
6. Default responses are outcome-first and telemetry-light.
7. Telemetry appears only in debug mode and uses backticks in messenger outputs.
8. Domain decisions remain in mediator layer, not adapters.

## Open Questions

- exact blocking-slot taxonomy by stack
- numeric default for `max_question_turns`
- confirmation strictness threshold for high-impact decisions

## Next Step

Convert this specification into an implementation plan under `ops/plans/` with numbered slices and task IDs (`Slice 1`, `T1.1`, etc.).
