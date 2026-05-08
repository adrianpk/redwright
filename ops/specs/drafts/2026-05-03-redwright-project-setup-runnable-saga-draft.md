# RedWright Project Setup Runnable Saga

## Status

- type: `spec-draft`
- status: `draft`
- date: `2026-05-03`
- quiz: `../../conv/quiz/2026-05-03-redwright-project-setup-runnable-saga-quiz.md`

## Scope

This draft defines the next project setup evolution after the conversational Rails setup saga.

The target behavior is a clearly staged project setup saga that moves from setup request to questionnaire, materialization, initial implementation, and ticket-based operation. A completed setup must not only persist metadata. It must either produce a minimally runnable project for supported stacks or explicitly fall back to a planned state with tickets and a reason.

## Source Context

- Manual Telegram testing showed that `/project new` now enters a conversational loop and persists a complete setup context.
- The completed local workspace currently contains `.redwright/manifest.yml`, but no runnable project files.
- The manifest can contain raw user answers in the wrong semantic slot when the user is responding to confusing prompt wording.
- The setup prompt renderer calls an LLM, but LLM request and response traces are not visible in foreground execution.
- The user-facing statement "project created" is too strong when the result is only Rails state plus a manifest.

## Working Notes

### 1) Explicit Saga Instances

- provisional_status: `keep`
- current issue: setup behavior is spread across conversational state, Rails materialization, workspace creation, and runtime bridge assumptions.
- desired behavior: project setup is modeled as a saga with explicit instances: `new`, `questionnaire`, `materialization`, `initial_implementation`, and `ticket_operation`.
- consequence: every channel can explain where the project is and what remains.

### 2) Canonical Setup Context

- provisional_status: `keep`
- current issue: answers are currently persisted literally for the active slot. If the user says that a prompt is confusing while the active slot is `framework`, that sentence can become the framework value.
- desired behavior: every answer is normalized into structured semantic updates before persistence. Raw text is retained for audit, but canonical slot values must be normalized, skipped, marked ambiguous, or rejected.
- consequence: `language_runtime`, `framework`, `libraries`, and synthesized `stack` become reliable enough for scaffold selection.

### 3) LLM Observability

- provisional_status: `keep`
- current issue: foreground logs show model resolution and ingress traces, but not project setup prompt LLM requests or responses.
- desired behavior: prompt rendering and semantic answer normalization emit `LLM REQUEST` and `LLM RESPONSE` traces under the same tracing flags used by the rest of the runtime.
- consequence: manual verification can distinguish "blocked", "generating", "fallback", and "LLM returned malformed output".

### 4) Materialization Boundary

- provisional_status: `keep`
- current issue: materialization currently creates Rails project state, board state, a setup summary, workspace directory, and manifest.
- desired behavior: materialization has an explicit persisted result with paths, created entities, status, and any reason it could not proceed to initial implementation.
- consequence: `/project where`, Rails UI, and future runtime work can inspect setup outcomes without relying on Telegram logs.

### 5) Initial Implementation Boundary

- provisional_status: `keep`
- current issue: a workspace with only a manifest is not operationally satisfying as a created project.
- desired behavior: supported project archetypes produce a minimally runnable scaffold. Unsupported or uncertain setups produce a planned workspace with README/spec/tickets and a clear reason.
- consequence: "created" means either `materialized_runnable` or `materialized_planned`, not an ambiguous directory.

### 6) Ticket Operation

- provisional_status: `keep`
- current issue: after setup, later work should not continue as an opaque Telegram conversation.
- desired behavior: all post-initial-implementation work is represented in Rails board tickets and documents. Telegram and web operate against the same Rails state.
- consequence: agents can pick up work from tickets instead of hidden setup context.

### 7) Protocols and Runtime Containers

- provisional_status: `defer`
- current issue: setup context should eventually inform project Protocols and agent Runtime Containers, but implementing those surfaces during this saga may expand scope too much.
- desired behavior: the initial saga records enough context and creates explicit tickets/backlog items for Protocol and Runtime Containers follow-up.
- consequence: this cycle should not block on full Protocol or container CRUD.

## Open Questions

- Should the first runnable scaffold support only Go CLI, or also a generic Ruby CLI template because RedWright itself is Ruby-first?
- Should LLM answer normalization happen in the Telegram adapter, Rails services, or a shared library invoked before Rails persistence?
- Should the first scaffold service run toolchain validation when the local toolchain is missing, or should it record validation as skipped with reason?
- Should initial implementation be synchronous inside `/done`, or queued as an explicit saga step that Telegram can poll or observe?
- What Rails UI surface should show the saga state first: project show, setup session show, or board/document overview?

## Out of Scope

- full Projects CRUD UI
- remote repository creation
- production deployment setup
- full Protocol template management
- full Runtime Containers CRUD and sandbox orchestration
- multi-agent autonomous execution beyond starter ticket handoff

## Next Iteration Inputs

- promote this draft into a formal spec
- define a short implementation cycle with no more than five slices
- prioritize LLM traces and semantic normalization before scaffold generation
- make Go CLI the first concrete runnable scaffold acceptance scenario
