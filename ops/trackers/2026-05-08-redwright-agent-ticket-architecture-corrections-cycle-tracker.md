---
id: redwright-agent-ticket-architecture-corrections-cycle-tracker-2026-05-08
title: RedWright Agent Ticket Architecture Corrections Cycle Tracker
state: slice_1_ready_for_review
created_at: 2026-05-08T19:46:04Z
plan: ops/plans/2026-05-08-redwright-agent-ticket-architecture-corrections-cycle-plan.md
ticket: TKT-20260508194604
active_slice: 1
---

# RedWright Agent Ticket Architecture Corrections Cycle Tracker

## Cycle Status
- state: `slice_1_ready_for_review`
- active_slice: `1`
- max_slices: `6`
- current_branch: `dev`

## Slice 1: Extract Telegram Ticket Command Handling
- branch: `refactor/slice-1-telegram-ticket-command-adapter`
- status: `ready_for_review`
- tasks:
  - [x] Identify the ticket command surface inside `TelegramProjectSetupAdapter`.
  - [x] Extract ticket command parsing/dispatch into a focused adapter.
  - [x] Preserve async acknowledgement and final message behavior.
  - [x] Preserve trace propagation and ticket context memory.
  - [x] Run focused Telegram adapter tests.
- commits:
  - `a82bae6 refactor(telegram): extract ticket command adapter`
- pr:
- validation:
  - `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb`
  - `ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

## Slice 2: Extract Structured Patch Application
- branch: `refactor/slice-2-structured-patch-applier`
- status: `pending`
- tasks:
  - [ ] Extract structured patch parsing/application from `PrimitiveExecutor`.
  - [ ] Keep `PrimitiveExecutor` as primitive dispatcher and IO boundary.
  - [ ] Add focused structured patch tests for supported and rejected cases.
  - [ ] Preserve current agent ticket output application behavior.
- commits: []
- pr:
- validation: []

## Slice 3: Split Agent Ticket Command-Query Workflow Responsibilities
- branch: `refactor/slice-3-agent-ticket-command-query-runner`
- status: `pending`
- tasks:
  - [ ] Extract request building from `CommandQueryHandlers`.
  - [ ] Extract execution orchestration into a focused runner.
  - [ ] Extract response/effects presentation if needed.
  - [ ] Preserve command-query response and Kanban behavior.
  - [ ] Run focused command-query and e2e tests.
- commits: []
- pr:
- validation: []

## Slice 4: Introduce Agent Ticket Context Section Providers
- branch: `refactor/slice-4-agent-ticket-context-providers`
- status: `pending`
- tasks:
  - [ ] Extract current context sections into provider objects.
  - [ ] Preserve section names, authorities, and payload shapes.
  - [ ] Preserve protocol exclusion/deduplication behavior.
  - [ ] Run context composer and LLM requester tests.
- commits: []
- pr:
- validation: []

## Slice 5: Move Validation Defaults Into Operational Setup
- branch: `refactor/slice-5-agent-ticket-validation-defaults`
- status: `pending`
- tasks:
  - [ ] Add validation command discovery to operational setup/runtime metadata.
  - [ ] Remove Go-specific default ownership from the generic validation loop.
  - [ ] Keep the Go todo scenario validating with `go test ./...`.
  - [ ] Run operational setup, validation loop, and scenario reset checks.
- commits: []
- pr:
- validation: []

## Slice 6: End-to-End Hardening and Closure
- branch: `test/slice-6-agent-ticket-architecture-e2e`
- status: `pending`
- tasks:
  - [ ] Run focused tests across all refactored boundaries.
  - [ ] Run full Rails and Ruby suites as warranted by the final blast radius.
  - [ ] Run deterministic Go todo scenario reset and inspection.
  - [ ] Record closure notes in this tracker.
  - [ ] Move `TKT-20260508194604` to solved after merge.
- commits: []
- pr:
- validation: []

## Decision Log
- `2026-05-08` Planned the cycle with 6 slices after the architecture audit of
  agent ticket execution, Telegram async execution, primitive patch application,
  command-query orchestration, context composition, and validation defaults.

## Activity Log
- `2026-05-08` state=`planned` note=`created ticket, plan, and tracker for the architecture correction cycle`
- `2026-05-08` state=`executing_slice` note=`started Slice 1 on refactor/slice-1-telegram-ticket-command-adapter and extracted Telegram ticket command handling into a dedicated adapter`
- `2026-05-08` state=`slice_1_ready_for_review` note=`extracted Telegram ticket command handling into Redwright::TelegramTicketCommandAdapter while preserving adapter and runtime handler tests`
