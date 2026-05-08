# Cycle Tracker: RedWright Agent Ticket Execution

## Metadata

- cycle_id: `cycle-2026-05-08-redwright-agent-ticket-execution`
- status: `executing`
- state: `slice_1_ready_for_review`
- updated: `2026-05-08`
- active_slice: `1`
- active_task: `none`
- source_plan: `ops/plans/2026-05-08-redwright-agent-ticket-execution-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`

## Slice Progress

### Slice 1: Existing Boundary Audit

- status: `ready_for_review`
- branch: `feat/slice-1-agent-ticket-boundary-audit`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [x] `T1.1 audit runtime primitives for file, command, patch, and git operations`
- [x] `T1.2 audit Kanban state transition APIs/services for development, review, and blocked outcomes`
- [x] `T1.3 audit project materialization, _workspace isolation, and reset behavior`
- [x] `T1.4 audit LLMRequestEngine request/response extension points for ticket execution`
- [x] `T1.5 record gaps and implementation constraints in tracker notes`

Commits:

- [x] `pending docs(ops): audit agent ticket execution boundaries`

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

- status: `planned`
- branch: `feat/slice-2-agent-ticket-workspace-fixture`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T2.1 add resettable _workspace test setup for agent ticket execution`
- [ ] `T2.2 generate a small Go CLI todo-list project using only the standard library`
- [ ] `T2.3 initialize local Git repository and generated .gitignore`
- [ ] `T2.4 add table-driven tests for the first feature ticket behavior`
- [ ] `T2.5 cover setup and teardown behavior with automated tests`

Commits:

- [ ] `test(runtime): add agent ticket workspace fixture`
- [ ] `test(runtime): cover agent ticket fixture lifecycle`

Validation:

- [ ] `not run`

### Slice 3: Project Operational Setup

- status: `planned`
- branch: `feat/slice-3-agent-ticket-operational-setup`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T3.1 define the first ./rw operational directory shape`
- [ ] `T3.2 place or accept a provided Dockerfile or equivalent runtime setup`
- [ ] `T3.3 expose operational setup to ticket execution context`
- [ ] `T3.4 keep production Dockerfile concerns separate`
- [ ] `T3.5 cover operational setup discovery in tests`

Commits:

- [ ] `feat(runtime): add agent operational setup discovery`
- [ ] `test(runtime): cover agent operational setup context`

Validation:

- [ ] `not run`

### Slice 4: Ticket Execution Command Boundary

- status: `planned`
- branch: `feat/slice-4-agent-ticket-command`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T4.1 define command inputs for targeted ticket execution`
- [ ] `T4.2 define command inputs for liberal pickup execution`
- [ ] `T4.3 route command through application/domain boundary without Telegram coupling`
- [ ] `T4.4 return normalized command acknowledgement and terminal outcome shapes`
- [ ] `T4.5 cover command dispatch with unit/service tests`

Commits:

- [ ] `feat(runtime): add agent ticket execution command`
- [ ] `test(runtime): cover agent ticket execution command`

Validation:

- [ ] `not run`

### Slice 5: Telegram Invocation And Async UX

- status: `planned`
- branch: `feat/slice-5-agent-ticket-telegram`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T5.1 add initial Telegram command route for agent ticket execution`
- [ ] `T5.2 send quick acknowledgement before async execution`
- [ ] `T5.3 dispatch the transport-neutral command`
- [ ] `T5.4 send final success or blocked message`
- [ ] `T5.5 cover Telegram acknowledgement and final response behavior`

Commits:

- [ ] `feat(telegram): add agent ticket execution command`
- [ ] `test(telegram): cover agent ticket execution feedback`

Validation:

- [ ] `not run`

### Slice 6: Ticket Eligibility And Selection

- status: `planned`
- branch: `feat/slice-6-agent-ticket-selection`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T6.1 implement targeted ticket eligibility checks`
- [ ] `T6.2 implement liberal pickup eligibility checks`
- [ ] `T6.3 exclude tickets self-assigned to the user/admin`
- [ ] `T6.4 map to existing development-capable Kanban states`
- [ ] `T6.5 cover eligible, ineligible, self-assigned, and blocked cases`

Commits:

- [ ] `feat(tickets): add agent ticket selection policy`
- [ ] `test(tickets): cover agent ticket eligibility`

Validation:

- [ ] `not run`

### Slice 7: Sandbox Workspace Execution Boundary

- status: `planned`
- branch: `feat/slice-7-agent-ticket-sandbox-boundary`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T7.1 resolve project workspace for selected ticket`
- [ ] `T7.2 prepare ticket-specific working branch state`
- [ ] `T7.3 enforce mutating primitive boundary against sandbox/worktree root`
- [ ] `T7.4 reject accidental harness-root mutation`
- [ ] `T7.5 cover allowed and rejected execution roots`

Commits:

- [ ] `feat(runtime): constrain agent ticket workspace execution`
- [ ] `test(runtime): cover agent ticket workspace guardrails`

Validation:

- [ ] `not run`

### Slice 8: Ticket Execution Context Composition

- status: `planned`
- branch: `feat/slice-8-agent-ticket-context`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T8.1 gather ticket body, project metadata, repository tree, and relevant files`
- [ ] `T8.2 gather tests and operational setup context`
- [ ] `T8.3 gather materialized and modeled protocol context when available`
- [ ] `T8.4 pass explicit context inputs to LLMRequestEngine`
- [ ] `T8.5 expose context diagnostics through existing trace behavior`

Commits:

- [ ] `feat(llm): compose agent ticket execution context`
- [ ] `test(llm): cover agent ticket context sections`

Validation:

- [ ] `not run`

### Slice 9: Previous Interaction Context

- status: `planned`
- branch: `feat/slice-9-agent-ticket-previous-context`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T9.1 identify current previous-interaction storage boundary`
- [ ] `T9.2 persist or collect recent raw agent-LLM messages for a ticket execution run`
- [ ] `T9.3 inject a substantial recent tail into retry requests`
- [ ] `T9.4 avoid human chat context confusion`
- [ ] `T9.5 cover retry request context with tests`

Commits:

- [ ] `feat(llm): add agent ticket previous interaction context`
- [ ] `test(llm): cover agent ticket previous context`

Validation:

- [ ] `not run`

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
