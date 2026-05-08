# Cycle Plan: RedWright Agent Ticket Execution

## Metadata

- cycle_id: `cycle-2026-05-08-redwright-agent-ticket-execution`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-08`
- updated: `2026-05-08`
- goal: `prove the first end-to-end agent programming ticket loop from Telegram trigger through sandboxed work, LLM context, validation, commit, and Kanban review transition`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`
- source_references:
  - `ops/conv/dump/2026-05-08-redwright-agent-ticket-execution-dump.md`
  - `ops/conv/quiz/2026-05-08-redwright-agent-ticket-execution-quiz.md`
  - `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
  - `ops/specs/specs/2026-04-27-redwright-action-runtime-proto-spec.md`
  - `ops/specs/specs/2026-04-27-redwright-planner-executor-hardening-spec.md`

## Slice List

### Slice 1: Existing Boundary Audit

- status: `planned`
- branch: `feat/slice-1-agent-ticket-boundary-audit`
- pr_title: `feat(slice-1): audit agent ticket execution boundaries`
- objective: `verify the existing runtime, Kanban, workspace, and LLM boundaries before implementation`
- tasks:
- [ ] `T1.1 audit runtime primitives for file, command, patch, and git operations`
- [ ] `T1.2 audit Kanban state transition APIs/services for development, review, and blocked outcomes`
- [ ] `T1.3 audit project materialization, _workspace isolation, and reset behavior`
- [ ] `T1.4 audit LLMRequestEngine request/response extension points for ticket execution`
- [ ] `T1.5 record gaps and implementation constraints in tracker notes`
- acceptance:
- `required existing boundaries are identified`
- `real primitive gaps are distinguished from orchestration gaps`
- `no runtime behavior changes are introduced`
- planned_commits:
- `docs(ops): audit agent ticket execution boundaries`

### Slice 2: Test Workspace Fixture Infrastructure

- status: `planned`
- branch: `feat/slice-2-agent-ticket-workspace-fixture`
- pr_title: `feat(slice-2): add agent ticket workspace fixture`
- objective: `create resettable _workspace fixture infrastructure for a simple Go CLI ticket execution scenario`
- tasks:
- [ ] `T2.1 add resettable _workspace test setup for agent ticket execution`
- [ ] `T2.2 generate a small Go CLI todo-list project using only the standard library`
- [ ] `T2.3 initialize local Git repository and generated .gitignore`
- [ ] `T2.4 add table-driven tests for the first feature ticket behavior`
- [ ] `T2.5 cover setup and teardown behavior with automated tests`
- acceptance:
- `test workspace is resettable and teardown-capable`
- `fixture project is created under _workspace`
- `tests do not depend on remote Git or live LLM`
- planned_commits:
- `test(runtime): add agent ticket workspace fixture`
- `test(runtime): cover agent ticket fixture lifecycle`

### Slice 3: Project Operational Setup

- status: `planned`
- branch: `feat/slice-3-agent-ticket-operational-setup`
- pr_title: `feat(slice-3): add agent ticket operational setup`
- objective: `materialize or consume project-local operational setup under ./.rw for sandboxed agent work`
- tasks:
- [ ] `T3.1 define the first ./.rw operational directory shape`
- [ ] `T3.2 place or accept a provided Dockerfile or equivalent runtime setup`
- [ ] `T3.3 expose operational setup to ticket execution context`
- [ ] `T3.4 keep production Dockerfile concerns separate`
- [ ] `T3.5 cover operational setup discovery in tests`
- acceptance:
- `agent ticket execution can locate project operational setup`
- `./.rw is treated as RedWright operational context`
- `production runtime setup is not conflated with agent work setup`
- planned_commits:
- `feat(runtime): add agent operational setup discovery`
- `test(runtime): cover agent operational setup context`

### Slice 4: Ticket Execution Command Boundary

- status: `planned`
- branch: `feat/slice-4-agent-ticket-command`
- pr_title: `feat(slice-4): add agent ticket execution command`
- objective: `introduce a transport-neutral application command for targeted and liberal ticket execution`
- tasks:
- [ ] `T4.1 define command inputs for targeted ticket execution`
- [ ] `T4.2 define command inputs for liberal pickup execution`
- [ ] `T4.3 route command through application/domain boundary without Telegram coupling`
- [ ] `T4.4 return normalized command acknowledgement and terminal outcome shapes`
- [ ] `T4.5 cover command dispatch with unit/service tests`
- acceptance:
- `tests can trigger ticket execution without Telegram transport`
- `targeted and liberal pickup modes share the same command boundary`
- `command responses are structured enough for Telegram and tests`
- planned_commits:
- `feat(runtime): add agent ticket execution command`
- `test(runtime): cover agent ticket execution command`

### Slice 5: Telegram Invocation And Async UX

- status: `planned`
- branch: `feat/slice-5-agent-ticket-telegram`
- pr_title: `feat(slice-5): add Telegram agent ticket invocation`
- objective: `let the user start ticket execution from Telegram with quick acknowledgement and final async outcome`
- tasks:
- [ ] `T5.1 add initial Telegram command route for agent ticket execution`
- [ ] `T5.2 send quick acknowledgement before async execution`
- [ ] `T5.3 dispatch the transport-neutral command`
- [ ] `T5.4 send final success or blocked message`
- [ ] `T5.5 cover Telegram acknowledgement and final response behavior`
- acceptance:
- `manual command receives prompt acknowledgement`
- `Telegram does not rely on long typing indicators`
- `final outcome is delivered after execution completes`
- planned_commits:
- `feat(telegram): add agent ticket execution command`
- `test(telegram): cover agent ticket execution feedback`

### Slice 6: Ticket Eligibility And Selection

- status: `planned`
- branch: `feat/slice-6-agent-ticket-selection`
- pr_title: `feat(slice-6): add agent ticket selection`
- objective: `implement first-cycle ticket eligibility, targeted ticket override, and liberal pickup behavior`
- tasks:
- [ ] `T6.1 implement targeted ticket eligibility checks`
- [ ] `T6.2 implement liberal pickup eligibility checks`
- [ ] `T6.3 exclude tickets self-assigned to the user/admin`
- [ ] `T6.4 map to existing development-capable Kanban states`
- [ ] `T6.5 cover eligible, ineligible, self-assigned, and blocked cases`
- acceptance:
- `specific eligible ticket can be selected directly`
- `liberal pickup skips user/admin self-assigned tickets`
- `advanced priority and tag picking remain deferred`
- planned_commits:
- `feat(tickets): add agent ticket selection policy`
- `test(tickets): cover agent ticket eligibility`

### Slice 7: Sandbox Workspace Execution Boundary

- status: `planned`
- branch: `feat/slice-7-agent-ticket-sandbox-boundary`
- pr_title: `feat(slice-7): constrain agent ticket sandbox execution`
- objective: `resolve the ticket worktree and constrain mutating execution to the sandbox/worktree boundary`
- tasks:
- [ ] `T7.1 resolve project workspace for selected ticket`
- [ ] `T7.2 prepare ticket-specific working branch state`
- [ ] `T7.3 enforce mutating primitive boundary against sandbox/worktree root`
- [ ] `T7.4 reject accidental harness-root mutation`
- [ ] `T7.5 cover allowed and rejected execution roots`
- acceptance:
- `ticket execution operates in the resolved project workspace`
- `mutating primitives cannot affect harness root`
- `branch preparation is ready for later commit slice`
- planned_commits:
- `feat(runtime): constrain agent ticket workspace execution`
- `test(runtime): cover agent ticket workspace guardrails`

### Slice 8: Ticket Execution Context Composition

- status: `planned`
- branch: `feat/slice-8-agent-ticket-context`
- pr_title: `feat(slice-8): compose agent ticket context`
- objective: `gather full practical first-cycle context and pass explicit inputs to LLMRequestEngine`
- tasks:
- [ ] `T8.1 gather ticket body, project metadata, repository tree, and relevant files`
- [ ] `T8.2 gather tests and operational setup context`
- [ ] `T8.3 gather materialized and modeled protocol context when available`
- [ ] `T8.4 pass explicit context inputs to LLMRequestEngine`
- [ ] `T8.5 expose context diagnostics through existing trace behavior`
- acceptance:
- `LLMRequestEngine receives explicit ticket execution inputs`
- `first-cycle context is intentionally over-inclusive when payload permits`
- `protocol duplication is trace-visible when present`
- planned_commits:
- `feat(llm): compose agent ticket execution context`
- `test(llm): cover agent ticket context sections`

### Slice 9: Previous Interaction Context

- status: `planned`
- branch: `feat/slice-9-agent-ticket-previous-context`
- pr_title: `feat(slice-9): add agent ticket previous context`
- objective: `include recent raw agent-LLM interaction context during ticket retry loops`
- tasks:
- [ ] `T9.1 identify current previous-interaction storage boundary`
- [ ] `T9.2 persist or collect recent raw agent-LLM messages for a ticket execution run`
- [ ] `T9.3 inject a substantial recent tail into retry requests`
- [ ] `T9.4 avoid human chat context confusion`
- [ ] `T9.5 cover retry request context with tests`
- acceptance:
- `retry requests include recent agent-LLM conversation context`
- `storage aligns with existing previous-interaction docs`
- `densification remains deferred`
- planned_commits:
- `feat(llm): add agent ticket previous interaction context`
- `test(llm): cover agent ticket previous context`

### Slice 10: Ticket Execution LLM Contract

- status: `planned`
- branch: `feat/slice-10-agent-ticket-llm-contract`
- pr_title: `feat(slice-10): add agent ticket LLM contract`
- objective: `extend or specialize LLM request and response semantics for ticket implementation`
- tasks:
- [ ] `T10.1 define ticket execution LLM request action/operation`
- [ ] `T10.2 define response fields for files, commands, actions, warnings, and blocking reasons`
- [ ] `T10.3 keep provider calls behind LLMRequestEngine`
- [ ] `T10.4 preserve rolling trace recording`
- [ ] `T10.5 cover successful, corrective, and blocked response shapes`
- acceptance:
- `LLM response is structured enough for deterministic orchestration`
- `provider calls do not bypass LLMRequestEngine`
- `trace recording remains available`
- planned_commits:
- `feat(llm): add agent ticket execution contract`
- `test(llm): cover agent ticket execution responses`

### Slice 11: Harness Application Of LLM Output

- status: `planned`
- branch: `feat/slice-11-agent-ticket-harness-apply`
- pr_title: `feat(slice-11): apply agent ticket LLM output`
- objective: `translate structured LLM output into existing primitive actions and apply changes inside the sandbox`
- tasks:
- [ ] `T11.1 map response file/code instructions to existing primitives`
- [ ] `T11.2 apply file and patch changes inside sandbox`
- [ ] `T11.3 execute requested safe commands inside sandbox`
- [ ] `T11.4 record affected files and action outcomes`
- [ ] `T11.5 cover apply success, invalid output, and primitive failure paths`
- acceptance:
- `structured LLM output can modify the workspace`
- `no new primitive is introduced unless a hard gap was documented`
- `affected files and action outcomes are available to the loop`
- planned_commits:
- `feat(runtime): apply agent ticket LLM output`
- `test(runtime): cover agent ticket output application`

### Slice 12: Validation Loop

- status: `planned`
- branch: `feat/slice-12-agent-ticket-validation-loop`
- pr_title: `feat(slice-12): add agent ticket validation loop`
- objective: `run validation, feed failures back to the LLM, retry within a configured limit, and block unresolved tickets`
- tasks:
- [ ] `T12.1 run project validation commands for the Go fixture`
- [ ] `T12.2 capture lint, compile, test, runtime, and behavioral output`
- [ ] `T12.3 feed validation failures into corrective LLM requests`
- [ ] `T12.4 enforce retry limit constant`
- [ ] `T12.5 mark unresolved execution blocked through command outcome`
- acceptance:
- `validation failures trigger corrective LLM iterations`
- `retry limit prevents unbounded loops`
- `unresolved failures produce blocked outcome with technical reason`
- planned_commits:
- `feat(runtime): add agent ticket validation loop`
- `test(runtime): cover agent ticket validation retries`

### Slice 13: Git Branch And Commit

- status: `planned`
- branch: `feat/slice-13-agent-ticket-git-commit`
- pr_title: `feat(slice-13): add agent ticket git commit`
- objective: `create a protocol-compliant local commit on a ticket-specific branch after successful validation`
- tasks:
- [ ] `T13.1 create or select ticket-specific branch using protocol-derived naming`
- [ ] `T13.2 prevent RedWright authorship/self-promotion markers`
- [ ] `T13.3 create local commit after validation success`
- [ ] `T13.4 enforce commit message protocol`
- [ ] `T13.5 cover branch and commit behavior in local Git tests`
- acceptance:
- `successful execution creates a local commit`
- `branch and commit message follow Protocols`
- `remote push is not required`
- planned_commits:
- `feat(git): add agent ticket branch and commit`
- `test(git): cover agent ticket commit workflow`

### Slice 14: Kanban Transition Integration

- status: `planned`
- branch: `feat/slice-14-agent-ticket-kanban-transition`
- pr_title: `feat(slice-14): add agent ticket Kanban transitions`
- objective: `move successful tickets to review and unresolved tickets to blocked through existing Kanban boundaries`
- tasks:
- [ ] `T14.1 map existing states for execution start, review, and blocked`
- [ ] `T14.2 move successful ticket to review`
- [ ] `T14.3 mark unresolved ticket blocked`
- [ ] `T14.4 keep comments and rich notifications deferred`
- [ ] `T14.5 cover Kanban transitions in command/service tests`
- acceptance:
- `successful execution transitions ticket to review`
- `unresolved execution transitions ticket to blocked`
- `state changes use existing Kanban boundaries`
- planned_commits:
- `feat(tickets): add agent ticket Kanban transitions`
- `test(tickets): cover agent ticket state transitions`

### Slice 15: Automated End-To-End Coverage

- status: `planned`
- branch: `feat/slice-15-agent-ticket-e2e`
- pr_title: `feat(slice-15): add agent ticket execution e2e`
- objective: `prove the full automated local workflow with a resettable workspace and rich fake LLM responses`
- tasks:
- [ ] `T15.1 wire the Go fixture, ticket, fake LLM, command, and workspace together`
- [ ] `T15.2 exercise successful implementation through validation and commit`
- [ ] `T15.3 exercise retry after validation failure`
- [ ] `T15.4 exercise blocked outcome after retry exhaustion`
- [ ] `T15.5 assert no remote Git dependency`
- acceptance:
- `automated e2e covers context, application, validation, commit, and Kanban transition`
- `fake LLM responses can vary without breaking deterministic assertions`
- `tests remain local and CI-suitable`
- planned_commits:
- `test(runtime): add agent ticket execution e2e`
- `test(runtime): cover agent ticket blocked e2e`

### Slice 16: Manual Acceptance And Cycle Closure

- status: `planned`
- branch: `feat/slice-16-agent-ticket-manual-closure`
- pr_title: `feat(slice-16): close agent ticket execution cycle`
- objective: `run manual Telegram/Kanban acceptance, inspect traces, update artifacts, and close the cycle`
- tasks:
- [ ] `T16.1 run Telegram-triggered manual execution`
- [ ] `T16.2 observe Kanban transition to review`
- [ ] `T16.3 inspect rolling LLM trace and local commit`
- [ ] `T16.4 record residual risks and follow-up candidates`
- [ ] `T16.5 update spec notes and tracker closure state`
- acceptance:
- `manual Telegram/Kanban acceptance is recorded`
- `trace and commit evidence are inspected`
- `cycle closes with residual risks captured`
- planned_commits:
- `chore(ops): close agent ticket execution cycle`

## Global Exit Criteria

- A well-specified programming ticket in an established `_workspace` project can be executed by the agent.
- The first scenario uses a Go CLI todo-list project with only standard-library dependencies.
- The project has a provided operational setup under `./.rw` or equivalent.
- Telegram can trigger targeted ticket execution with quick acknowledgement and final outcome.
- The command boundary can execute targeted and liberal pickup modes.
- The agent operates inside the sandbox/worktree boundary.
- `LLMRequestEngine` receives explicit ticket execution context.
- Recent agent-LLM context is included in retry requests.
- Validation failures produce corrective iterations.
- Retry exhaustion marks the ticket blocked.
- Success produces a protocol-compliant local commit on a ticket-specific branch.
- Success moves the ticket to review.
- Automated tests are local and do not require remote Git or live LLM.
- Manual Telegram/Kanban acceptance is completed.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>` when Rails code changes.
- Runtime/library tests must be run from repository root with `bundle exec ruby -Itest <paths>` when lib runtime code changes.
- Full Rails validation must run from `apps/web` with `bundle exec bin/rails test` before cycle closure when Rails behavior changes.
- Repository workflow checks must run from repository root with `scripts/agent/tickets/check.sh` when ticket metadata changes.
- Validation entries must include command plus `(pass)` or `(fail)`.
- Each slice PR body must use `Summary`, `Changes`, and `Validation`.

## Non-Goals

- Do not infer Docker/container setup automatically in this cycle.
- Do not solve ambiguous ticket refinement in this cycle.
- Do not implement multi-agent parallel execution.
- Do not implement review or merge automation.
- Do not require remote Git push.
- Do not add a harness skill system.
- Do not align `dev -> main` as part of this cycle.
