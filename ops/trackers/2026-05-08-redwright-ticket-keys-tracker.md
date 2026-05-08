# Cycle Tracker: RedWright Ticket Keys

## Metadata

- cycle_id: `cycle-2026-05-08-redwright-ticket-keys`
- status: `in_progress`
- state: `slice_1_validation_passed`
- updated: `2026-05-08`
- active_slice: `1`
- source_plan: `ops/plans/2026-05-08-redwright-ticket-keys-plan.md`
- source_spec: `ops/specs/specs/2026-05-08-redwright-ticket-keys-spec.md`

## Slice Progress

### Slice 1: Ticket Key Foundation

- status: `in_progress`
- branch: `fix/ticket-key-rename`
- PR: `pending`
- merge_target: `dev`

Tasks:

- [x] `T1.1 document the ticket key behavior and command contract`
- [x] `T1.2 add ticket key persistence, backfill, validation, and generation`
- [x] `T1.3 expose ticket keys in board payloads and ticket cards`
- [x] `T1.4 resolve agent ticket execution by ticket key while keeping numeric compatibility`
- [x] `T1.5 update the deterministic Go todo scenario reset to print the ticket-key Telegram command`

Commits:

- [x] `refactor(tickets): rename external ticket identifier`

Validation:

- [x] `bin/rails test test/models/ticket_test.rb test/services/agent_ticket_execution/command_query_handlers_test.rb test/services/agent_ticket_execution/workspace_boundary_test.rb test/services/board_workflow/command_query_handlers_test.rb test/controllers/api/v1/command_queries_controller_test.rb`
- [x] `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb test/redwright/telegram_runtime_handler_test.rb`
- [x] `make agent-ticket-scenario-reset`

Notes:

- The first key format is `RW-<number>`.
- Numeric ticket IDs remain internal and temporarily accepted for backwards compatibility.
- Manual Telegram testing should use `/ticket start RW-<number>`.
- The current deterministic scenario prints `/ticket start RW-10` and restores the active workspace under `_workspace/Projects/go-todo-agent`.
