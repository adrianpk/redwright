# Cycle Tracker: RedWright Agent Ticket Execution

## Metadata

- cycle_id: `cycle-2026-05-08-redwright-agent-ticket-execution`
- status: `executing`
- state: `slice_9_ready_for_review`
- updated: `2026-05-08`
- active_slice: `9`
- active_task: `none`
- source_plan: `ops/plans/2026-05-08-redwright-agent-ticket-execution-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`

## Slice Progress

### Slice 1: Existing Boundary Audit

- status: `merged`
- branch: `feat/slice-1-agent-ticket-boundary-audit`
- PR: `merged`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T1.1 audit runtime primitives for file, command, patch, and git operations`
- [x] `T1.2 audit Kanban state transition APIs/services for development, review, and blocked outcomes`
- [x] `T1.3 audit project materialization, _workspace isolation, and reset behavior`
- [x] `T1.4 audit LLMRequestEngine request/response extension points for ticket execution`
- [x] `T1.5 record gaps and implementation constraints in tracker notes`

Commits:

- [x] `docs(ops): audit agent ticket execution boundaries`

Validation:

- [x] `not run - docs-only audit; no runtime behavior changed`

## Slice 1 Audit

### Runtime Primitive Boundary

- `lib/redwright/primitive_executor.rb` already supports `list_files`, `read_file`, `search`, `run`, `write_file`, `apply_patch`, `git_status`, `git_branch`, `git_commit`, `git_push`, and `git_undo`.
- Mutating primitives are already guardable by `allowed_projects_root` plus `enforce_mutating_projects_root`.
- Existing tests cover path escape rejection, command timeout, git status/branch, confirmation-required git commit/push, git undo behavior, and mutating-action rejection outside the allowed projects root.
- Real primitive gap: `git_branch` supports `list`, `current`, and `switch`, but not branch creation. Slice 13 should either add a small branch-create capability or implement branch creation through the existing `run` primitive with the same sandbox boundary.
- Real orchestration gap: no ticket-execution service currently translates rich LLM output into primitive actions and validation retries.

### Kanban And Ticket Boundary

- `apps/web/app/models/ticket.rb` already defines workflow statuses including `in_progress`, `reviewing`, and `blocked`.
- Existing column mapping supports `in_progress`, `review`, `reviewing`, `approved`, `blocked`, `merged`, `done`, `solved`, and `closed`.
- `Ticket#transition_to_column!` already sets lifecycle timestamps for in-progress, review, approved, merged/done, solved, and closed transitions.
- `BoardWorkflow::CommandQueryHandlers` already registers `CreateTicket`, `UpdateTicket`, `MoveTicket`, `AddTicketComment`, `StartTicketExecution`, `PickNextTicket`, `GetBoard`, and `GetTicketsByProject`.
- `MoveTicket` can move a ticket to a target column by `column_id` or `column_key`.
- `PickNextTicket` currently uses `Ticket.pick_next_for`, which prefers assigned tickets when an assignee is provided and otherwise falls back to all active tickets.
- Real policy gap: the spec's liberal pickup rule must exclude tickets self-assigned to the user/admin, but current `pick_next_for` has no user/admin exclusion policy.
- Real transition gap: existing `StartTicketExecution` records runtime correlation but does not own success-to-review or failure-to-blocked transitions.

### Runtime Bridge Boundary

- `RuntimeBridge::TicketExecutionBridge` already builds a Rails-to-runtime request from a ticket, project context, runtime context, and runtime container readiness.
- The bridge checks `RuntimeContainers::ExecutionReadiness` before contacting the local runtime socket.
- Successful bridge calls record `execution_id`, `workstream_id`, `task_id`, and runtime state on the ticket through `record_runtime_execution!`.
- Existing command API coverage verifies `StartTicketExecution` and captures the socket payload.
- Real behavior gap: the bridge starts a runtime task but does not perform the full agent ticket execution loop described by the spec.
- Real integration decision: future slices can either extend this bridge into the first execution loop coordinator or introduce a higher-level ticket execution service that calls the bridge only when needed.

### Project Workspace And Materialization Boundary

- `ProjectSetup::LocalWorkspaceMaterializer` already materializes local projects under `_workspace/Projects` by default, using Rails test tmp roots in test mode.
- It writes `.redwright/manifest.yml`, `README.md`, `.redwright/setup-notes.md`, scaffold files when applicable, and materialized protocol files such as `AGENTS.md` and `.agents/*`.
- Existing tests cover local workspace materialization, idempotent replay, protocol materialization, and Go CLI scaffold generation.
- The Go CLI scaffold currently records `go.mod`, `main.go`, and `main_test.go`; validation command is `go test ./...`.
- Real naming/shape gap: the spec proposes `./rw`, while current materialization uses `.redwright`. Later slices must decide whether to add `./rw`, reuse `.redwright`, or bridge both without breaking existing materialization.
- Real fixture gap: existing Go CLI scaffold is project setup oriented, not the todo-list ticket execution fixture with table-driven tests required by Slice 2.

### Runtime Containers Boundary

- `ProjectRuntimeContainer` already models runtime container profile, readiness, validation state, commands, repository mount, environment, secret placeholders, generated files, assumptions, risks, and provenance.
- `RuntimeContainers::ExecutionReadiness` already blocks sandbox-required ticket execution when runtime containers are missing, blocked, stale, or not ready.
- `RuntimeContainers::GoCliGenerator` already produces a Go CLI runtime container profile with `golang:<version>`, `go mod download`, `go test ./...`, `go vet ./...`, `go build ./...`, and `gofmt -w .`.
- Real scope alignment gap: the first spec prefers a provided operational Dockerfile or equivalent setup for ticket execution; existing runtime containers can represent generated files but are not yet wired as the direct `./rw` operational setup source for the new loop.

### LLM Request Boundary

- `Redwright::LLM::RequestEngine` already supports `generate_structured_message` with model, model role, provider, action, system prompt, user text, output contract, context sections, and trace metadata.
- `Redwright::LLM::ContextSection` already records name, content, authority, metadata, and byte size.
- `Redwright::LLM::TraceRecorder` already records request and response metadata, including project, ticket, session, source channel, actor, context summary, context bytes, context sections, parsed fields, action, role, provider, and model.
- Existing Rails quiz provider code demonstrates using `LLMRequestEngine` with action-specific output contracts and context sections.
- Real contract gap: no `ticket_execution` action/output contract exists yet for files, commands, affected files, warnings, blocking reasons, or post-actions.
- Real previous-context gap: request/response tracing exists, but no first-cycle ticket execution store/retriever currently injects a raw recent agent-LLM conversation tail into retry requests.

### Command Query Boundary

- `CommandQuery::ApplicationDispatcher` already registers board, project setup, runtime container, document, use case, protocol, and quiz handlers.
- `/api/v1/commands` already dispatches command/query envelopes and returns normalized result bodies.
- Real command gap: there is no transport-neutral command for the spec's full ticket execution loop, targeted-ticket override, liberal pickup mode, pause/stop request, or terminal success/blocked outcome.

### Slice 1 Conclusion

- The required low-level primitives mostly exist.
- Kanban, ticket, workspace materialization, runtime container readiness, and LLM request boundaries exist.
- The main missing capability is orchestration: selecting an eligible ticket, preparing the sandbox/worktree, composing ticket-specific LLM context, applying structured LLM output, validating, retrying, committing, and transitioning the ticket.
- The largest early design decision is whether to reuse `.redwright`, introduce `./rw`, or bridge both for the first operational setup surface.
- Slice 2 can proceed without runtime behavior changes by adding a resettable `_workspace` fixture for the Go todo-list ticket scenario.

### Slice 2: Test Workspace Fixture Infrastructure

- status: `merged`
- branch: `feat/slice-2-agent-ticket-workspace-fixture`
- PR: `merged`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T2.1 add resettable _workspace test setup for agent ticket execution`
- [x] `T2.2 generate a small Go CLI todo-list project using only the standard library`
- [x] `T2.3 initialize local Git repository and generated .gitignore`
- [x] `T2.4 add table-driven tests for the first feature ticket behavior`
- [x] `T2.5 cover setup and teardown behavior with automated tests`

Commits:

- [x] `test(runtime): add agent ticket workspace fixture`
- [x] `test(runtime): cover agent ticket fixture lifecycle`

Validation:

- [x] `bin/rails test test/support/agent_ticket_execution_workspace_fixture_test.rb`

Notes:

- Added test support for a resettable Go todo CLI fixture under `_workspace/testing/Projects` so automated tests do not collide with manual project workspaces.
- The fixture creates a local-only Git repository, generated `.gitignore`, stdlib-only Go source, and table-driven tests for the first `done <task-number>` ticket.
- The Rails fixture tests assert workspace creation, local Git isolation, reset behavior, and teardown without requiring a remote Git server or live LLM.

### Slice 3: Project Operational Setup

- status: `merged`
- branch: `feat/slice-3-agent-ticket-operational-setup`
- PR: `merged`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T3.1 define the first ./rw operational directory shape`
- [x] `T3.2 place or accept a provided Dockerfile or equivalent runtime setup`
- [x] `T3.3 expose operational setup to ticket execution context`
- [x] `T3.4 keep production Dockerfile concerns separate`
- [x] `T3.5 cover operational setup discovery in tests`

Commits:

- [x] `feat(runtime): add agent operational setup discovery`
- [x] `test(runtime): cover agent operational setup context`

Validation:

- [x] `bin/rails test test/services/agent_ticket_execution/operational_setup_test.rb test/services/runtime_bridge/project_context_builder_test.rb`
- [x] `bin/rails test test/services/project_setup/context_loop_service_test.rb -n test_go_cli_setup_materializes_scaffold_files_and_validation_outcome`

Notes:

- Added `AgentTicketExecution::OperationalSetup` as the first `./rw` operational setup boundary.
- The first directory shape is `rw/agent`, with `rw/agent/Dockerfile`, `rw/agent/runtime-setup.json`, and `rw/agent/README.md`.
- Existing project-provided `rw/agent/Dockerfile` files are accepted without overwrite.
- When no provided setup exists, the materializer writes the generated runtime container Dockerfile into `rw/agent/Dockerfile`.
- `RuntimeBridge::ProjectContextBuilder` exposes operational setup metadata without materializing files.
- Local project materialization includes operational setup in the workspace payload and `.redwright/manifest.yml`.

### Slice 4: Ticket Execution Command Boundary

- status: `merged`
- branch: `feat/slice-4-agent-ticket-command`
- PR: `#362 closed_admin_dev_contains_commits`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T4.1 define command inputs for targeted ticket execution`
- [x] `T4.2 define command inputs for liberal pickup execution`
- [x] `T4.3 route command through application/domain boundary without Telegram coupling`
- [x] `T4.4 return normalized command acknowledgement and terminal outcome shapes`
- [x] `T4.5 cover command dispatch with unit/service tests`

Commits:

- [x] `feat(runtime): add agent ticket execution command`
- [x] `test(runtime): cover agent ticket execution command`

Validation:

- [x] `bin/rails test test/services/agent_ticket_execution/command_query_handlers_test.rb`
- [x] `bin/rails test test/controllers/api/v1/command_queries_controller_test.rb -n test_accepts_agent_ticket_execution_through_command_api`

Notes:

- Added transport-neutral `ExecuteAgentTicket` command under `AgentTicketExecution::CommandQueryHandlers`.
- Targeted mode requires `ticket_id` and resolves ticket project/board context.
- Pickup mode accepts `project_id` or `board_id` for future liberal ticket selection.
- The first executor is an accepted/no-op boundary so Telegram and tests can trigger the command before the full loop exists.
- The response shape includes acknowledgement and terminal outcome slots; injected executors can already return terminal outcomes for future orchestration.

### Slice 5: Telegram Invocation And Async UX

- status: `merged`
- branch: `feat/slice-5-agent-ticket-telegram`
- PR: `merged`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T5.1 add initial Telegram command route for agent ticket execution`
- [x] `T5.2 send quick acknowledgement before async execution`
- [x] `T5.3 dispatch the transport-neutral command`
- [x] `T5.4 send final success or blocked message`
- [x] `T5.5 cover Telegram acknowledgement and final response behavior`

Commits:

- [x] `feat(telegram): add agent ticket execution command`
- [x] `test(telegram): cover agent ticket execution feedback`

Validation:

- [x] `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb -n test_routes_ticket_commands_through_rails_api_after_project_context_is_known`
- [x] `ruby -Itest test/redwright/telegram_runtime_handler_test.rb -n test_handle_routes_ticket_start_to_rails_agent_execution_with_ack_and_final_messages`

Notes:

- `/ticket start <id>` now dispatches Rails `ExecuteAgentTicket` instead of the older runtime-start command.
- Telegram delivery can send multiple messages from one Rails adapter result, enabling immediate acknowledgement plus terminal outcome messages when returned by the command.
- Ticket execution responses render the normalized acknowledgement and terminal outcome shape from Slice 4.
- Existing ticket list and pick behavior remain unchanged.

### Slice 6: Ticket Eligibility And Selection

- status: `merged`
- branch: `feat/slice-6-agent-ticket-selection`
- PR: `merged`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T6.1 implement targeted ticket eligibility checks`
- [x] `T6.2 implement liberal pickup eligibility checks`
- [x] `T6.3 exclude tickets self-assigned to the user/admin`
- [x] `T6.4 map to existing development-capable Kanban states`
- [x] `T6.5 cover eligible, ineligible, self-assigned, and blocked cases`

Commits:

- [x] `feat(tickets): add agent ticket selection policy`
- [x] `test(tickets): cover agent ticket eligibility`

Validation:

- [x] `bin/rails test test/services/agent_ticket_execution/ticket_selection_policy_test.rb test/services/agent_ticket_execution/command_query_handlers_test.rb`

Notes:

- Added `AgentTicketExecution::TicketSelectionPolicy` for targeted and pickup ticket eligibility.
- Targeted execution accepts only visible development-ready tickets.
- Pickup execution selects from development-capable columns and workflow states.
- Liberal pickup skips tickets self-assigned to the configured admin/user assignee.
- `ExecuteAgentTicket` now selects the concrete ticket before invoking its executor.

### Slice 7: Sandbox Workspace Execution Boundary

- status: `merged`
- branch: `feat/slice-7-agent-ticket-sandbox-boundary`
- PR: `merged`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T7.1 resolve project workspace for selected ticket`
- [x] `T7.2 prepare ticket-specific working branch state`
- [x] `T7.3 enforce mutating primitive boundary against sandbox/worktree root`
- [x] `T7.4 reject accidental harness-root mutation`
- [x] `T7.5 cover allowed and rejected execution roots`

Commits:

- [x] `feat(runtime): constrain agent ticket workspace execution`
- [x] `test(runtime): cover agent ticket workspace guardrails`

Validation:

- [x] `bin/rails test test/services/agent_ticket_execution/workspace_boundary_test.rb test/services/agent_ticket_execution/command_query_handlers_test.rb`

Notes:

- Added `AgentTicketExecution::WorkspaceBoundary` to resolve ticket project workspaces.
- The boundary returns deterministic ticket branch names while leaving actual branch creation for the later Git/commit slice.
- Resolved workspaces provide a `Redwright::PrimitiveExecutor` constrained to the ticket workspace root.
- Mutating primitive calls against the harness root are rejected by the bounded executor.
- `ExecuteAgentTicket` can now receive resolved workspace context through an injected workspace boundary.

### Slice 8: Ticket Execution Context Composition

- status: `merged`
- branch: `feat/slice-8-agent-ticket-context`
- PR: `merged`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T8.1 gather ticket body, project metadata, repository tree, and relevant files`
- [x] `T8.2 gather tests and operational setup context`
- [x] `T8.3 gather materialized and modeled protocol context when available`
- [x] `T8.4 pass explicit context inputs to LLMRequestEngine`
- [x] `T8.5 expose context diagnostics through existing trace behavior`

Commits:

- [x] `feat(llm): compose agent ticket execution context`
- [x] `test(llm): cover agent ticket context sections`

Validation:

- [x] `bin/rails test test/services/agent_ticket_execution/context_composer_test.rb test/services/agent_ticket_execution/command_query_handlers_test.rb test/services/agent_ticket_execution/workspace_boundary_test.rb`
- [x] `bin/rails test test/controllers/api/v1/command_queries_controller_test.rb -i test_accepts_agent_ticket_execution_through_command_api`
- [x] `ruby -Itest test/redwright/llm_request_engine_test.rb`

Notes:

- Added `AgentTicketExecution::ContextComposer` to build explicit LLM request inputs for ticket execution.
- Context sections include ticket, project metadata, repository tree, relevant files, tests, operational setup, materialized protocol files, and modeled protocol state.
- The command handler can inject a context composer and pass the composed package to executors without changing the accepted async boundary.
- Context diagnostics expose section names, authorities, and byte counts for trace visibility.

### Slice 9: Previous Interaction Context

- status: `ready_for_review`
- branch: `feat/slice-9-agent-ticket-previous-context`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `dev`

Tasks:

- [x] `T9.1 identify current previous-interaction storage boundary`
- [x] `T9.2 persist or collect recent raw agent-LLM messages for a ticket execution run`
- [x] `T9.3 inject a substantial recent tail into retry requests`
- [x] `T9.4 avoid human chat context confusion`
- [x] `T9.5 cover retry request context with tests`

Commits:

- [x] `feat(llm): add agent ticket previous interaction context`
- [x] `test(llm): cover agent ticket previous context`

Validation:

- [x] `bin/rails test test/services/agent_ticket_execution/previous_interaction_store_test.rb test/services/agent_ticket_execution/context_composer_test.rb test/services/agent_ticket_execution/command_query_handlers_test.rb`
- [x] `bin/rails test test/controllers/api/v1/command_queries_controller_test.rb -i test_accepts_agent_ticket_execution_through_command_api`
- [x] `git --no-pager diff --no-ext-diff --check`

Notes:

- Added transient filesystem storage for raw agent-LLM ticket execution records under a scoped tmp root.
- Previous interaction records are scoped by ticket, session, and agent rather than by human chat context.
- `ContextComposer` now includes a `previous_interactions` section labeled as historical agent-LLM evidence.
- Densification and selective retrieval remain deferred.

### Slice 10: Ticket Execution LLM Contract

- status: `planned`
- branch: `feat/slice-10-agent-ticket-llm-contract`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T10.1 define ticket execution LLM request action/operation`
- [ ] `T10.2 define response fields for files, commands, actions, warnings, and blocking reasons`
- [ ] `T10.3 keep provider calls behind LLMRequestEngine`
- [ ] `T10.4 preserve rolling trace recording`
- [ ] `T10.5 cover successful, corrective, and blocked response shapes`

Commits:

- [ ] `feat(llm): add agent ticket execution contract`
- [ ] `test(llm): cover agent ticket execution responses`

Validation:

- [ ] `not run`

### Slice 11: Harness Application Of LLM Output

- status: `planned`
- branch: `feat/slice-11-agent-ticket-harness-apply`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T11.1 map response file/code instructions to existing primitives`
- [ ] `T11.2 apply file and patch changes inside sandbox`
- [ ] `T11.3 execute requested safe commands inside sandbox`
- [ ] `T11.4 record affected files and action outcomes`
- [ ] `T11.5 cover apply success, invalid output, and primitive failure paths`

Commits:

- [ ] `feat(runtime): apply agent ticket LLM output`
- [ ] `test(runtime): cover agent ticket output application`

Validation:

- [ ] `not run`

### Slice 12: Validation Loop

- status: `planned`
- branch: `feat/slice-12-agent-ticket-validation-loop`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T12.1 run project validation commands for the Go fixture`
- [ ] `T12.2 capture lint, compile, test, runtime, and behavioral output`
- [ ] `T12.3 feed validation failures into corrective LLM requests`
- [ ] `T12.4 enforce retry limit constant`
- [ ] `T12.5 mark unresolved execution blocked through command outcome`

Commits:

- [ ] `feat(runtime): add agent ticket validation loop`
- [ ] `test(runtime): cover agent ticket validation retries`

Validation:

- [ ] `not run`

### Slice 13: Git Branch And Commit

- status: `planned`
- branch: `feat/slice-13-agent-ticket-git-commit`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T13.1 create or select ticket-specific branch using protocol-derived naming`
- [ ] `T13.2 prevent RedWright authorship/self-promotion markers`
- [ ] `T13.3 create local commit after validation success`
- [ ] `T13.4 enforce commit message protocol`
- [ ] `T13.5 cover branch and commit behavior in local Git tests`

Commits:

- [ ] `feat(git): add agent ticket branch and commit`
- [ ] `test(git): cover agent ticket commit workflow`

Validation:

- [ ] `not run`

### Slice 14: Kanban Transition Integration

- status: `planned`
- branch: `feat/slice-14-agent-ticket-kanban-transition`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T14.1 map existing states for execution start, review, and blocked`
- [ ] `T14.2 move successful ticket to review`
- [ ] `T14.3 mark unresolved ticket blocked`
- [ ] `T14.4 keep comments and rich notifications deferred`
- [ ] `T14.5 cover Kanban transitions in command/service tests`

Commits:

- [ ] `feat(tickets): add agent ticket Kanban transitions`
- [ ] `test(tickets): cover agent ticket state transitions`

Validation:

- [ ] `not run`

### Slice 15: Automated End-To-End Coverage

- status: `planned`
- branch: `feat/slice-15-agent-ticket-e2e`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T15.1 wire the Go fixture, ticket, fake LLM, command, and workspace together`
- [ ] `T15.2 exercise successful implementation through validation and commit`
- [ ] `T15.3 exercise retry after validation failure`
- [ ] `T15.4 exercise blocked outcome after retry exhaustion`
- [ ] `T15.5 assert no remote Git dependency`

Commits:

- [ ] `test(runtime): add agent ticket execution e2e`
- [ ] `test(runtime): cover agent ticket blocked e2e`

Validation:

- [ ] `not run`

### Slice 16: Manual Acceptance And Cycle Closure

- status: `planned`
- branch: `feat/slice-16-agent-ticket-manual-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T16.1 run Telegram-triggered manual execution`
- [ ] `T16.2 observe Kanban transition to review`
- [ ] `T16.3 inspect rolling LLM trace and local commit`
- [ ] `T16.4 record residual risks and follow-up candidates`
- [ ] `T16.5 update spec notes and tracker closure state`

Commits:

- [ ] `chore(ops): close agent ticket execution cycle`

Validation:

- [ ] `not run`

## Cycle Notes

- The cycle has 16 planned slices, below the requested maximum of 20.
- Slice execution must stop after each PR until the previous slice is merged into `dev`.
- The first implementation intentionally proves a simple programming ticket loop instead of broad autonomous coding.
- Context optimization, automatic Docker inference, and review/merge automation are follow-up work.

## Residual Risks

- The exact Telegram command naming is still open.
- Current primitive coverage may reveal a real hard gap during Slice 1.
- Existing Kanban state names must be mapped without redesigning the board.
- The first fake LLM response set may need tuning after the E2E test shape exists.
- Manual acceptance may expose async UX issues not visible in automated tests.

## Event Log

- `2026-05-08` state=`planning_complete` note=`created spec, cycle plan, and tracker from closed dump and quiz artifacts; cycle planned with 16 slices under the requested 20-slice maximum`
- `2026-05-08` state=`slice_1_ready_for_review` note=`completed docs-only boundary audit for runtime primitives, Kanban/tickets, runtime bridge, workspace materialization, runtime containers, LLM request engine, and command-query gaps`
