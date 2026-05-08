# RedWright Agent Ticket Execution Specification

## Metadata

- id: `spec-2026-05-08-redwright-agent-ticket-execution`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-08`
- updated: `2026-05-08`
- scope: `rails-web/telegram/runtime/kanban/agent-ticket-execution/sandbox/llm-context/git`
- derived_from:
  - `ops/conv/dump/2026-05-08-redwright-agent-ticket-execution-dump.md`
  - `ops/conv/dump/2026-05-08-redwright-agent-ticket-execution-dump-raw.md`
  - `ops/conv/quiz/2026-05-08-redwright-agent-ticket-execution-quiz.md`
  - `ops/conv/quiz/2026-05-08-redwright-agent-ticket-execution-quiz-raw.md`
  - `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
  - `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
  - `ops/specs/specs/2026-04-27-redwright-action-runtime-proto-spec.md`
  - `ops/specs/specs/2026-04-27-redwright-planner-executor-hardening-spec.md`
  - `docs/explanation/adr/adr-001-integration-topology-harness-first.md`

## Problem Statement

RedWright has Kanban tickets, project setup artifacts, project protocols, `LLMRequestEngine`, runtime primitives, and workspace materialization concepts. Those pieces are not yet connected into a complete first ticket-execution loop where an agent can take a programming ticket, work inside a sandboxed project environment, ask the LLM for implementation guidance with the right context, apply changes through the harness, validate the result, commit it, and move the ticket toward review.

The first implementation must avoid pretending to solve the full autonomous software factory. It should prove the smallest credible loop on a benign, well-specified programming ticket in an already established project. Once that works, larger tasks, ambiguous tickets, richer picking policy, review automation, merge automation, and automatic runtime setup inference can be added by focused follow-up cycles.

## Goals

- let the user trigger agent ticket execution manually from Telegram
- support a targeted mode where a specific ticket is assigned to the execution run
- support a liberal pickup mode where the agent may take an eligible available development ticket
- keep initial scope single-agent and avoid parallel multi-agent execution
- run ticket work inside a sandboxed project workspace
- use a provided project operational Dockerfile or equivalent runtime setup for the first cycle
- reserve a project-local operational area such as `./.rw` for RedWright runtime setup files when needed
- build rich ticket-execution LLM context through `LLMRequestEngine`
- include recent agent-LLM interaction context during retry loops
- use existing harness/runtime primitives where possible instead of expanding the primitive catalog
- validate implementation through lint/build/test or equivalent project commands
- iterate on validation failures until success or a bounded retry limit is reached
- create a real local commit on a ticket-specific branch when validation succeeds
- move the ticket to review when validation and commit succeed
- mark the ticket blocked when the agent cannot resolve the ticket
- send Telegram acknowledgement and final completion or blocked feedback
- provide automated coverage using a resettable `_workspace` project and rich fake LLM behavior
- support a manual acceptance path using Telegram plus Kanban observation

## Non-Goals

- solve ambiguous or underspecified tickets in the first cycle
- infer Docker/container setup automatically in the first cycle
- implement multi-agent parallel execution
- implement review or merge automation
- implement push to a real remote as a first-cycle requirement
- depend on a remote Git service for automated tests
- add a broad ticket-picking rule engine
- add a ticket checklist progress UI
- add rich ticket comments or notifications for every intermediate event
- redesign Kanban states
- optimize LLM context selection or deduplicate every repeated context source
- densify previous interaction context
- add a harness skill system
- replace existing runtime primitives or `LLMRequestEngine`
- use RedWright branding or authorship markers in generated branches, commits, or code

## Product Contract

RedWright must provide a first agent ticket-execution loop that can be exercised in two ways:

1. automated workflow validation against a resettable `_workspace` project
2. manual validation by triggering a Telegram command and watching a Kanban ticket move to review

The first successful exercise should use a small Go CLI todo-list style project. The project should use only the Go standard library. The ticket should be well specified and should ask for a simple feature such as marking a task as done. The point is not the feature itself; the point is proving that RedWright can operate the loop.

The first success condition is:

- select or target an eligible ticket
- prepare or use the sandboxed project workspace
- gather full practical context for the small project
- invoke `LLMRequestEngine`
- apply code/test changes through the harness
- run validation
- retry with validation context when needed
- produce passing behavior without lint or compile errors
- commit on a ticket-specific branch using project protocol rules
- move the ticket to review
- send final Telegram confirmation

If the agent cannot resolve the ticket within the configured retry limit, RedWright must mark the ticket blocked and send a final Telegram message with a summarized technical reason when possible.

## Primary Scenario

The canonical first scenario is:

1. A project exists under `_workspace`.
2. The project has a simple Go CLI todo-list implementation.
3. The project has a well-specified ticket asking for a small feature such as marking a task as done.
4. The project has table-driven tests or an equivalent validation suite.
5. The project has a RedWright operational setup, likely under `./.rw`, with a provided Dockerfile or equivalent runtime instructions.
6. The user triggers the agent through Telegram.
7. RedWright sends a quick acknowledgement and continues asynchronously.
8. The agent creates or selects a ticket-specific branch.
9. The agent composes LLM context through `LLMRequestEngine`.
10. The agent applies changes through existing runtime primitives.
11. The agent runs validation commands.
12. On failure, the agent sends errors and recent prior interaction context into the next LLM request and retries.
13. On success, the agent creates a commit following project protocols.
14. The ticket moves to review.
15. Telegram sends a final completion message.

## Operating Model

### Actor Model

RedWright remains a single-user system for this scope.

The user/admin creates tickets and may self-assign tickets. A ticket self-assigned to the user/admin should not be picked up by the agent in liberal pickup mode.

The first delivery model is mono-agent. The spec should not introduce scheduling semantics for multiple agents operating in parallel.

### Ticket Eligibility

A ticket is eligible for first-cycle execution when:

- it belongs to an established project
- it represents implementation or correction work
- it is not self-assigned to the user/admin
- it is in a Kanban state that permits development work
- it is not blocked
- it has enough specification for the benign first case

The exact existing Kanban state names are already defined elsewhere. This spec does not rename or redesign them. Implementation must map to the existing states for development, blocked, and review.

### Ticket Selection Modes

RedWright must support two first-cycle modes:

- `targeted_ticket`: the user indicates a specific ticket; this ticket overrides normal picking order when eligible
- `liberal_pickup`: the agent may select an available eligible ticket that is not self-assigned to the user/admin

Sophisticated picking rules based on priority, severity, tags, UI area, agent type, or replicas are deferred.

### Loop Invocation

Manual invocation should use Telegram.

The exact command name is not fixed by this spec. The command surface must eventually support:

- starting ticket execution
- targeting one ticket
- starting or continuing a loop
- requesting pause or stop

Automated tests should invoke the same behavior through an application command in the DDD sense, not by relying on Telegram transport internals.

### Pause And Stop

Pause/stop semantics are graceful:

- do not take new tickets
- finish the current ticket attempt
- report final status after the current ticket completes, blocks, or reaches a terminal state

This spec does not define an abrupt kill mode. A `SIGKILL`-style product behavior is not expected.

Initial implementation should not auto-start agent loops after process restart. Future restart persistence may be specified later.

## Sandbox And Workspace

### Workspace Root

Ticket execution should operate under `_workspace`, using the repository's existing project isolation model.

Automated tests must use a resettable and teardown-capable `_workspace` area so test runs do not depend on manual cleanup or mutate the RedWright harness repository.

### Project Operational Area

RedWright may reserve a project-local operational area named `./.rw`.

The `./.rw` area can hold runtime setup context that currently cannot be represented conveniently by the platform model. It is a bridge, not the final source of truth.

For the first implementation:

- `./.rw` may be created during project initialization
- `./.rw` does not need to be added to the generated project's `.gitignore`
- the generated project should still receive a `.gitignore`
- versioning policy for `./.rw` is not central to this implementation

### Runtime Setup

The first runtime setup can be a provided Dockerfile or equivalent text artifact. It may be manually generated.

The agent must use the provided setup for the specific project stack and dependency set.

The Dockerfile used by the agent is not the production Dockerfile for the project. Treat it as an operational work environment, not a product deployment artifact.

Automatic Docker setup inference is deferred. It is effectively a more complex ticket-execution task and should be handled after the first loop exists.

### Secrets And Environment

The agent depends on LLM provider credentials and possibly other environment values. Those values must be injectable into the sandboxed environment.

This spec does not define the full secrets UI or long-term ergonomics. A manual per-project approach is acceptable at first, provided it is explicit and safe enough for local development.

## LLM Request Context

### Boundary

All LLM provider requests for ticket execution must go through `LLMRequestEngine`.

The ticket execution service or command handler is responsible for gathering business state and passing explicit inputs. `LLMRequestEngine` must not fetch project, ticket, workspace, or Kanban records by itself.

### Required First-Cycle Context

For the small first-cycle project, RedWright should prefer complete practical context over early optimization.

The request context should include:

- ticket body and acceptance criteria
- project identity and relevant metadata
- repository tree
- full relevant source files and test files when payload size permits
- existing tests
- `./.rw` operational setup, including Dockerfile or equivalent runtime setup
- project protocols, including materialized protocol files such as `AGENTS.md` when available
- modeled protocol context when available
- validation command output from previous attempts
- lint, compile, runtime, and behavioral errors or warnings
- recent previous agent-LLM interaction context
- output contract for structured implementation response

Context duplication is acceptable in the first cycle when the same protocol appears through files and through model/persistence context. This should be visible in `LLMRequestEngine` traces and can be optimized later.

### Context Selection Policy

For the first small project, send everything practical within payload limits.

Do not block first delivery on intelligent file selection, Tree-sitter ranking, semantic relevance ranking, or deduplication. Those are near-term follow-up improvements.

### Previous Interactions

Previous interactions are required for retry loops.

For this spec, previous interactions mean the recent agent-LLM conversation during the autonomous ticket execution loop. They do not mean human-in-the-loop conversation.

The first implementation may include:

- raw prior messages
- or a substantial raw tail of recent messages

Rolling summaries, densification, hybrid raw/summary records, and selective retrieval are deferred.

Storage should follow the previous-interaction model already referenced by:

- `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
- `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
- `ops/conv/quiz/2026-05-05-redwright-llm-request-engine-context-composition-quiz.md`

## LLM Output Contract

The existing RedWright LLM response semantics may need to be extended for ticket execution.

The ticket execution response should be rich enough for the agent/harness to act without relying on loose prose interpretation. It may include:

- summary of intended solution
- files to inspect or modify
- proposed file contents or patches
- commands to run
- validation expectations
- post-actions
- warnings
- inability/blocking reason
- next retry instruction when validation failed

The implementation should not require directly applying raw LLM patches if the existing harness flow works better through command/code/action instructions. The key requirement is that the response be semantically organized enough for deterministic orchestration.

## Harness And Primitive Execution

The harness remains the execution substrate.

Ticket execution should use existing primitive actions where possible, such as:

- read/list/search
- run
- write
- apply patch
- git status/branch/commit

This spec should not expand the primitive catalog unless implementation review proves an existing primitive gap. Future harness skills are out of scope and should be treated as convenience groupings over the same primitives, not as new execution powers.

Mutating actions must operate only inside the resolved sandbox/worktree boundary.

Host safety should primarily come from sandbox isolation. Repository safety should primarily come from Git and remote permissions, including not operating on protected branches and using scoped tokens when remote operations are later introduced.

## Validation Loop

### Validation Inputs

Validation should use project-appropriate commands. For the Go CLI first scenario, standard Go commands and table-driven tests are expected.

The first project should avoid external Go dependencies and external test libraries.

### Retry Behavior

On validation failure, RedWright should:

1. capture the failed command and output
2. add validation context to the next LLM request
3. include recent previous agent-LLM interaction context
4. request a corrective response
5. apply the next changes
6. rerun validation

The iteration limit should be a named constant in the appropriate code boundary. It can be generous at first. Exact value belongs to implementation slicing, not this spec.

### Error Shape

The first implementation may pass validation errors in a single property.

If easy during this cycle, separate error categories should be used:

- lint errors
- compile errors
- test failures
- runtime errors
- warnings
- behavioral mismatches

If not cleanly handled now, a near-term corrective ticket should split those categories.

## Git Behavior

### Branching

The agent should create or use a ticket-specific branch.

Branch naming is defined by project Protocols. RedWright must not default to self-promotional prefixes such as `rw/`.

RedWright should not mark authorship in branch names, commit messages, or code comments. The produced code belongs to the user. RedWright is a tool.

### Commit

On successful validation, the agent must create a real local commit.

Commit messages must follow project Protocols. If the project requires Conventional Commits, the agent must comply.

Commit creation is part of validating that protocol context was composed and respected correctly.

### Push

Push to a real remote is not required for the first automated test.

If push is trivial to fake locally, the workflow may include it. Otherwise, the ticket-review transition may temporarily avoid requiring push.

Automated tests must not depend on a remote Git service.

## Kanban Behavior

Ticket state transitions must use existing RedWright Kanban APIs or service boundaries.

The first implementation must support:

- moving an executing ticket into the appropriate active/development state when execution begins, if the current Kanban model requires it
- moving a successful ticket to review
- marking an unresolved ticket blocked

This spec does not define new Kanban state names.

Comments and notifications for blocked or intermediate states are deferred. A final Telegram message should still summarize the blocked reason when available.

## Telegram Behavior

Manual ticket execution is asynchronous from the user's point of view.

Telegram must:

- send a quick acknowledgement after receiving the command
- avoid showing typing indicators for minutes
- let ticket execution continue asynchronously
- send a final completion or blocked message

Intermediate progress messages are not required in the first version.

A future ticket checklist system may expose intermediate progress such as sandbox ready, tests failed, retrying, commit created, and review transition.

## Tracing And Observability

LLM request/response tracing already exists through a rolling file and must continue to capture ticket-execution LLM interactions.

Broader workflow logs are welcome when they help debug the loop. Useful debug evidence includes:

- selected ticket
- selected workspace
- branch name
- context source summary
- command execution records
- validation outputs
- retry count
- applied file list
- commit hash
- ticket transition
- final outcome

Some of this may live at debug level. The first implementation should not block on a polished trace viewer.

## Testing Strategy

### Automated Test Harness

The automated test should use a real project under `_workspace`, not only an in-repo static fixture.

The `_workspace` test area must be resettable and teardown-capable.

The test should avoid remote network Git dependencies.

### Test Project

The first test project should be a Go CLI todo-list style project using only the standard library.

The ticket should be simple and well specified.

The project should include table-driven tests sufficient to verify the expected behavior.

### Fake LLM

The automated workflow should support a rich fake LLM or fuzzy table-driven fake with varied possible responses.

The user may provide a rich set of LLM-based responses for this fake once the test shape is established.

The fake should validate orchestration behavior without making the entire test suite depend on a live LLM provider.

### Manual Acceptance

Manual acceptance should include:

1. open Kanban in a browser tab
2. trigger ticket execution from Telegram
3. receive an initial Telegram acknowledgement
4. observe the ticket move through the expected state path
5. observe the ticket move to review on success
6. receive a final Telegram confirmation

## Acceptance Criteria

- A well-specified programming ticket in an established `_workspace` project can be executed by the agent.
- The project can use a provided operational Dockerfile or equivalent setup under `./.rw`.
- The agent can run inside the sandboxed workspace without mutating the RedWright harness repository.
- Telegram can trigger a targeted ticket execution.
- Telegram sends an initial acknowledgement and final outcome message.
- The execution path can select an eligible non-user-assigned ticket in liberal pickup mode.
- The execution path can target a specific eligible ticket.
- Stop/pause requests prevent new ticket pickup while allowing the current ticket to finish.
- `LLMRequestEngine` receives explicit ticket execution inputs from the outer service or command boundary.
- The LLM context includes ticket body, repository tree, relevant files, tests, operational setup, protocols, validation output, and recent previous agent-LLM context.
- First-cycle context may be over-inclusive when payload limits allow.
- Validation failures are fed back into the next LLM request.
- Retry attempts stop at a configured constant.
- On success, validation passes with no lint, compile, or behavioral failures.
- On success, a local commit is created on a ticket-specific branch.
- Commit message and branch behavior follow project Protocols.
- On success, the ticket moves to review when the existing Kanban state model permits it.
- On failure, the ticket is marked blocked.
- Automated tests run without depending on a remote Git service.
- Manual Telegram/Kanban acceptance is possible.

## Implementation Slices

This spec is intentionally one specification, but the implementation should be delivered in slices. The slice count should not be artificially compressed into a tiny number, and should remain under 20 unless later discovery proves the scope materially larger.

### Slice 1: Existing Boundary Audit

- verify current runtime primitives for read, search, run, write, patch, git branch, git commit, and git status
- verify current Kanban state transition services/API boundaries
- verify current project materialization and `_workspace` reset behavior
- verify current `LLMRequestEngine` request/response extension points
- document implementation gaps without changing behavior

### Slice 2: Test Workspace Fixture Infrastructure

- create resettable `_workspace` test setup for agent ticket execution
- create the small Go CLI todo-list project shape
- generate `.gitignore`
- initialize a local Git repository
- include table-driven tests for the first ticket behavior

### Slice 3: Project Operational Setup

- materialize or accept `./.rw`
- place the provided operational Dockerfile or equivalent setup there
- expose the operational setup as context for ticket execution
- keep production Dockerfile concerns separate

### Slice 4: Ticket Execution Command Boundary

- add an application command for targeted ticket execution
- support a liberal pickup command path
- keep the command transport-neutral for tests
- avoid Telegram-specific behavior in the core command

### Slice 5: Telegram Invocation And Async UX

- add initial Telegram command handling
- send quick acknowledgement
- dispatch asynchronous ticket execution
- send final success or blocked message
- avoid long typing indicators

### Slice 6: Ticket Eligibility And Selection

- implement targeted-ticket eligibility checks
- implement liberal pickup eligibility checks
- exclude tickets self-assigned to the user/admin
- defer advanced priority/severity/tag selection

### Slice 7: Sandbox Workspace Execution Boundary

- resolve the project workspace for the ticket
- ensure mutating primitive execution is constrained to the sandbox/worktree
- prepare branch state for ticket execution
- prevent accidental harness-root mutation

### Slice 8: Ticket Execution Context Composition

- gather ticket body, project metadata, repository tree, relevant files, tests, operational setup, and protocols
- pass explicit inputs to `LLMRequestEngine`
- allow over-inclusive context for the small first project
- expose context diagnostics through existing trace behavior

### Slice 9: Previous Interaction Context

- store or retrieve recent raw agent-LLM interaction context for the current execution loop
- inject a substantial recent tail into retry requests
- align storage with existing previous-interaction context documents
- defer densification

### Slice 10: Ticket Execution LLM Contract

- extend or specialize the LLM request action for ticket implementation
- extend response semantics for files, commands, actions, warnings, and blocking reasons as needed
- keep all provider calls behind `LLMRequestEngine`
- preserve trace recording

### Slice 11: Harness Application Of LLM Output

- translate structured LLM output into existing primitive actions
- apply file/code changes in the sandbox
- avoid adding new primitives unless the audit proves a hard gap
- record affected files and action outcomes

### Slice 12: Validation Loop

- run project validation commands
- capture lint, compile, test, runtime, and behavioral outputs
- feed failures into corrective LLM requests
- enforce retry limit constant
- mark unresolved tickets blocked

### Slice 13: Git Branch And Commit

- create or use ticket-specific branch according to Protocols
- create local commit after successful validation
- enforce commit message protocol
- avoid RedWright authorship markers

### Slice 14: Kanban Transition Integration

- move successful ticket to review
- mark unresolved ticket blocked
- keep comments and rich notifications deferred
- expose enough state for manual Kanban observation

### Slice 15: Automated End-To-End Coverage

- use the resettable `_workspace` Go project
- use rich fake/fuzzy LLM responses
- verify context composition, action application, validation retry, commit, and Kanban transition
- keep tests local and deterministic enough for normal CI

### Slice 16: Manual Acceptance Pass

- run the Telegram-triggered path manually
- observe Kanban transition
- inspect rolling LLM trace
- inspect local commit
- record residual issues for follow-up tickets

## Implementation Closure Notes

- The first implementation cycle delivered the local targeted ticket execution loop for a simple Go todo CLI ticket.
- Automated acceptance covers command dispatch, context composition, fake fuzzy LLM responses, output application, validation retry, local commit creation, and Kanban transition.
- Telegram behavior is covered through simulated adapter tests for `/ticket start <id>` acknowledgement and final outcome rendering.
- Live external manual acceptance with a real Telegram bot session and browser Kanban tab is intentionally recorded as a post-merge operator check because it requires services outside the repository test environment.

## Follow-Up Candidates

- automatic Docker/container setup inference
- context source optimization and deduplication
- Tree-sitter or semantic file selection for larger repositories
- previous-interaction densification
- ticket checklist progress updates
- rich ticket comments and notifications
- push and PR creation
- review and merge automation
- advanced ticket-picking policy
- multi-agent scheduling and isolation
- harness skills over existing primitives

## Open Questions

- What exact Telegram command names and arguments should be used?
- What retry limit constant should be used first?
- Which existing Kanban states map to active execution, review, and blocked?
- Which current primitive contracts are sufficient, and which gaps are real?
- What exact shape should the `LLMRequestEngine` ticket-execution request use?
- What exact response schema should ticket execution require?
- Where exactly should `./.rw` materialization live in current project initialization code?
- Should the first local fake represent push, or should push be entirely skipped?
- How much validation/debug output should be normal trace versus debug-only trace?
