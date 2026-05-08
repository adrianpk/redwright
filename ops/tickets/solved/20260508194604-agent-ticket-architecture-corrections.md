---
id: TKT-20260508194604
title: Correct agent ticket execution architecture risks
status: solved
kind: cleanup
severity: high
priority: high
scope: runtime
tags: architecture, agent-ticket, runtime, llm, telegram
source: chat
reported_at: 2026-05-08T19:46:04Z
ready_at: 2026-05-08T19:46:04Z
started_at: 2026-05-08T19:46:04Z
reviewed_at: 2026-05-08T20:46:12Z
closed_at: 2026-05-08T20:46:12Z
resolution: fixed
owner:
branch: test/slice-6-agent-ticket-architecture-e2e
pr: https://codeberg.org/adrianpk/redwright/pulls/387
commits:
  - a82bae6
  - 9a77a94
  - e6a3b85
  - 7b9e488
  - 0d1cdd8
  - c83d22e
---

## Context
The first successful agent ticket execution cycle proved the vertical flow:
Telegram can trigger a ticket, RedWright can send rich LLM context, apply a
model-proposed patch, validate it, commit it, and move the ticket to review.

An architecture audit of the newly expanded runtime surface found maintainability
risks in the agent ticket execution path. The risks are not immediate functional
failures, but they will make future work harder if the next features are added
on top of the current shapes.

## Problem
The current implementation has several growth hot spots:

- `Redwright::TelegramProjectSetupAdapter` is now an oversized adapter that owns
  project setup routing, ticket command routing, quiz routing, chat-local state,
  rendering, Rails API calls, and async execution.
- `Redwright::PrimitiveExecutor` now owns shell execution, git operations, path
  safety, file writes, and a custom structured patch parser.
- `AgentTicketExecution::CommandQueryHandlers` owns dependency construction,
  request parsing, selection, workspace resolution, context composition,
  execution orchestration, Kanban transitions, and response formatting.
- `AgentTicketExecution::ContextComposer` owns all context section policy and is
  likely to become harder to evolve as Tree-sitter, docs, lint, compile,
  runtime error, and richer previous-context sections are added.
- `AgentTicketExecution::ValidationLoop` defaults to `go test ./...`, which is
  valid for the current deterministic Go fixture but not as a generic runtime
  default.

## Expected
- Telegram adapters stay thin enough to route and render without owning multiple
  workflow domains.
- Complex primitive implementations are independently testable and documented by
  focused contract tests.
- Agent ticket command-query handlers delegate request building, workflow
  orchestration, and response presentation to focused collaborators.
- Agent ticket context composition can grow by adding section providers instead
  of expanding one object.
- Validation command defaults come from operational setup or stack-aware runtime
  configuration.
- The full agent ticket execution scenario still works after the refactor cycle.

## Actual
- The vertical behavior works, but several architecture boundaries are now
  overloaded.
- Current tests cover the successful behavior, but not all lower-level contracts
  introduced by the new structured patch and orchestration boundaries.

## Fix Strategy
- Execute the architecture correction cycle defined in
  `ops/plans/2026-05-08-redwright-agent-ticket-architecture-corrections-cycle-plan.md`.
- Track progress in
  `ops/trackers/2026-05-08-redwright-agent-ticket-architecture-corrections-cycle-tracker.md`.
- Keep the cycle to six slices:
  1. Extract Telegram ticket command handling.
  2. Extract structured patch application.
  3. Split agent ticket command-query workflow responsibilities.
  4. Introduce context section providers.
  5. Move validation defaults into operational setup.
  6. Run end-to-end hardening and cycle closure validation.

## Validation
- Run focused tests for every touched boundary.
- Run `bin/rails test` when Rails-side behavior changes.
- Run `bundle exec rake test` when runtime library behavior changes.
- Run `make agent-ticket-scenario-ready`.
- Trigger or simulate the deterministic Go todo ticket execution scenario.
- Confirm the agent-created branch, patch, validation, commit, and Kanban
  transition still work.

## Outcome
Resolved through the six-slice architecture correction cycle.

- Extracted Telegram ticket command handling from the larger Telegram adapter.
- Extracted structured patch application from the primitive executor.
- Split agent ticket command-query request building, orchestration, and response
  presentation.
- Introduced context section providers for agent ticket LLM context composition.
- Moved validation command resolution into operational setup/runtime metadata.
- Completed final hardening across focused runtime tests, Rails agent ticket
  execution tests, ticket checks, and deterministic Go todo scenario reset and
  inspection.
