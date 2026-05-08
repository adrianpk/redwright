# Cycle Tracker: RedWright Agent Ticket Execution

## Metadata

- cycle_id: `cycle-2026-05-08-redwright-agent-ticket-execution`
- status: `planned`
- state: `planning_complete`
- updated: `2026-05-08`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-08-redwright-agent-ticket-execution-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`

## Slice Progress

### Slice 1: Existing Boundary Audit

- status: `planned`
- branch: `feat/slice-1-agent-ticket-boundary-audit`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T1.1 audit runtime primitives for file, command, patch, and git operations`
- [ ] `T1.2 audit Kanban state transition APIs/services for development, review, and blocked outcomes`
- [ ] `T1.3 audit project materialization, _workspace isolation, and reset behavior`
- [ ] `T1.4 audit LLMRequestEngine request/response extension points for ticket execution`
- [ ] `T1.5 record gaps and implementation constraints in tracker notes`

Commits:

- [ ] `docs(ops): audit agent ticket execution boundaries`

Validation:

- [ ] `not run`

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
