---
id: redwright-agent-ticket-architecture-corrections-cycle-2026-05-08
title: RedWright Agent Ticket Architecture Corrections Cycle
status: planned
created_at: 2026-05-08T19:46:04Z
ticket: TKT-20260508194604
tracker: ops/trackers/2026-05-08-redwright-agent-ticket-architecture-corrections-cycle-tracker.md
---

# RedWright Agent Ticket Architecture Corrections Cycle

## Goal
Correct the maintainability risks found in the first working agent ticket
execution cycle without changing the user-visible behavior of the flow.

The cycle keeps the current vertical behavior intact while improving ownership
boundaries around Telegram command handling, primitive mutation execution,
agent-ticket orchestration, LLM context composition, and validation defaults.

## Non-Goals
- Do not redesign the full runtime command model.
- Do not replace the current LLM contract.
- Do not add multi-agent execution.
- Do not change the board/ticket lifecycle semantics.
- Do not introduce new external dependencies.
- Do not make a broad style-only cleanup.

## Constraints
- Maximum slice count: 6.
- Each slice must be independently reviewable.
- Each slice should be behavior-preserving unless explicitly noted.
- Tests must cover the boundary being moved before or during extraction.
- The deterministic Go todo agent-ticket scenario must still pass by cycle
  closure.

## Reference Findings
The architecture audit identified these risks:

- `Redwright::TelegramProjectSetupAdapter` mixes project, ticket, quiz, Rails
  API, async execution, parsing, rendering, and chat-local state.
- `Redwright::PrimitiveExecutor` mixes primitive dispatch with a custom
  structured patch parser.
- `AgentTicketExecution::CommandQueryHandlers` mixes dependency construction,
  request parsing, selection, workspace resolution, execution orchestration,
  Kanban transitions, and response presentation.
- `AgentTicketExecution::ContextComposer` centralizes all context section policy
  and will become harder to evolve as context sources grow.
- `AgentTicketExecution::ValidationLoop` has a Go-specific validation default in
  a generic runtime loop.

## Slice 1: Extract Telegram Ticket Command Handling
- branch: `refactor/slice-1-telegram-ticket-command-adapter`
- objective: move ticket command parsing, execution dispatch, async
  acknowledgement, final ticket execution rendering, and ticket chat context out
  of `Redwright::TelegramProjectSetupAdapter`.
- scope:
  - Add a focused `Redwright::TelegramTicketCommandAdapter` or equivalent.
  - Keep project setup and quiz behavior unchanged.
  - Keep `/ticket list`, `/ticket pick`, and `/ticket start <ticket-key>`
    behavior unchanged.
  - Preserve async final-message behavior and trace propagation.
- validation:
  - `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb`
  - relevant ticket command tests after extraction.

## Slice 2: Extract Structured Patch Application
- branch: `refactor/slice-2-structured-patch-applier`
- objective: move Codex-style structured patch parsing and application out of
  `Redwright::PrimitiveExecutor`.
- scope:
  - Add a focused `Redwright::StructuredPatchApplier`.
  - Keep `PrimitiveExecutor` as primitive dispatcher and IO boundary.
  - Preserve support for current `*** Begin Patch` update/add behavior.
  - Reject unsupported operations explicitly.
  - Harden tests for path safety and parser edge cases.
- validation:
  - `ruby -Itest test/redwright/primitive_executor_test.rb` if present or the
    focused primitive executor test file that owns this behavior.
  - `bin/rails test apps/web/test/services/agent_ticket_execution/output_applier_test.rb`
  - focused structured patch tests.

## Slice 3: Split Agent Ticket Command-Query Workflow Responsibilities
- branch: `refactor/slice-3-agent-ticket-command-query-runner`
- objective: keep `AgentTicketExecution::CommandQueryHandlers` as a thin
  command-query entrypoint.
- scope:
  - Extract request building from payload/context.
  - Extract workflow orchestration into `AgentTicketExecution::Runner` or an
    equivalent focused collaborator.
  - Extract response/effects presentation if needed.
  - Preserve command-query API shape.
  - Preserve Kanban transition semantics.
- validation:
  - `bin/rails test apps/web/test/services/agent_ticket_execution/command_query_handlers_test.rb`
  - `bin/rails test apps/web/test/services/agent_ticket_execution/end_to_end_test.rb`

## Slice 4: Introduce Agent Ticket Context Section Providers
- branch: `refactor/slice-4-agent-ticket-context-providers`
- objective: prepare context composition for additional sources without growing
  `ContextComposer` into a god object.
- scope:
  - Add focused section provider objects for ticket/project, repository tree,
    relevant files/tests, operational setup, protocols, previous interactions,
    and validation feedback.
  - Preserve existing section names and payload shapes.
  - Preserve protocol file exclusion from repository scan.
  - Preserve `protocol_model` content omission when `protocol_files` is present.
- validation:
  - `bin/rails test apps/web/test/services/agent_ticket_execution/context_composer_test.rb`
  - `bin/rails test apps/web/test/services/agent_ticket_execution/llm_requester_test.rb`

## Slice 5: Move Validation Defaults Into Operational Setup
- branch: `refactor/slice-5-agent-ticket-validation-defaults`
- objective: remove Go-specific default validation from the generic validation
  loop and source validation commands from project runtime setup.
- scope:
  - Extend operational setup discovery or runtime metadata to expose validation
    commands.
  - Keep the Go todo scenario using `go test ./...`.
  - Keep explicit test injection of validation commands supported.
  - Define a conservative fallback when no validation command is configured.
- validation:
  - `bin/rails test apps/web/test/services/agent_ticket_execution/operational_setup_test.rb`
  - `bin/rails test apps/web/test/services/agent_ticket_execution/validation_loop_test.rb`
  - `make agent-ticket-scenario-ready`

## Slice 6: End-to-End Hardening and Closure
- branch: `test/slice-6-agent-ticket-architecture-e2e`
- objective: verify that all refactors preserve the full user-facing and
  developer-facing agent ticket flow.
- scope:
  - Run focused tests across Telegram adapter, primitive executor, command-query
    execution, context composition, validation loop, and e2e fixtures.
  - Run full Rails and Ruby test suites if the blast radius warrants it.
  - Run the deterministic Go todo scenario reset/inspect workflow.
  - Update this plan/tracker with final closure notes.
  - Close `TKT-20260508194604` when merged.
- validation:
  - `bin/rails test`
  - `bundle exec rake test`
  - `make agent-ticket-scenario-ready`
  - `make agent-ticket-scenario-inspect`

## Closure Criteria
- All six slices are merged into `dev`.
- `TelegramProjectSetupAdapter` no longer owns ticket command execution logic.
- `PrimitiveExecutor` no longer owns structured patch parsing/application.
- `CommandQueryHandlers` is a thin entrypoint around dedicated collaborators.
- Context composition has provider boundaries for current sections.
- Validation defaults are stack-aware or operational-setup-driven.
- The deterministic Go todo agent ticket scenario still reaches review with a
  valid branch, patch, validation, and commit.
