# RedWright Agent Ticket Execution Quiz Notes

## Status

- type: `questionnaire`
- date: `2026-05-08`
- source: `ops/conv/quiz/2026-05-08-redwright-agent-ticket-execution-quiz-raw.md`
- dump: `ops/conv/dump/2026-05-08-redwright-agent-ticket-execution-dump.md`
- state: `closed`

## Related Draft

No draft exists yet. These notes are sufficient pre-draft context for a future agent programming ticket delivery draft or spec.

## Purpose

Curated quiz notes refining how RedWright should let an agent execute a simple programming ticket in a sandboxed project workspace, validate the result, commit it, and move the ticket toward review.

## Sessions

### Session 2026-05-08

#### Context

- The quiz refines the agent ticket execution dump.
- The target is not a large autonomous coding milestone; it is a small first version that proves the future iterative loop.
- The first useful scenario is a simple programming ticket in an already established project.
- The implementation should validate two core capabilities:
  - the agent can obtain and operate inside its sandboxed environment without friction
  - the agent can send enough context to the LLM to generate or modify the files and symbols required to resolve the ticket

#### Current Convergences

- Start with a benign, well-specified ticket rather than an ambiguous task.
- Use a trivial Go CLI todo-list style project as the manual and automated exercise.
- The exercise should use only Go standard library dependencies, including tests and CLI parsing if possible.
- The project should live under `_workspace`, using a resettable and teardown-capable dev-mode space.
- The automated workflow should use strong table-driven tests and may use a rich fuzzy fake with varied LLM-style responses.
- The user will later provide a rich set of LLM-based responses for that fake or table-driven test.
- The manual acceptance path should trigger the flow from Telegram and watch the ticket move in Kanban.

#### Sandbox And Workspace

- The first sandbox setup can be a provided Dockerfile, manually generated or supplied as text.
- Automatic Docker/container inference is a later, more complex ticket-execution problem.
- RedWright can reserve a project-local operational area such as `./rw`.
- `./rw` fills a temporary gap for context that should later come directly from the platform.
- The Dockerfile used by the agent is not the same as the project's production Dockerfile.
- Versioning of `./rw` is not central to this implementation. For now, `./rw` can be created during project initialization and omitted from the generated `.gitignore`.

#### Ticket Selection And Loop Control

- Start with the liberal pickup model: an agent may take an available development ticket as long as it is not self-assigned to the user/admin.
- More complex picking rules based on priority, severity, ticket type, agent type, or tags should come later.
- Manual invocation should happen through Telegram.
- The exact Telegram command name and arguments are not fixed.
- Tests should trigger the behavior through a command in the DDD sense.
- The implementation should support both:
  - running a loop that can process available tickets
  - targeting one specific ticket and working only on that ticket
- Specific-ticket invocation should override normal picking order when the ticket is eligible.
- Pause/stop should be graceful: do not take new tickets, but finish the current ticket.
- There is no expected `SIGKILL`-style abrupt stop mode.
- Initial loop state should not auto-start after a restart. Later restart persistence may become desirable.

#### Validation And Failure Handling

- The first success condition is a solution that resolves the ticket with no lint errors, no compile errors, and correct behavior.
- Ticket comments can be omitted from the first iteration.
- If validation passes, moving the ticket to review should be included when not disproportionately complex.
- A real local commit is required.
- Push can be disabled for the test unless local fake/mock support is trivial.
- Tests should avoid dependence on a remote Git service; simulate locally whenever possible.
- If the agent exhausts iteration attempts or cannot resolve the problem, it should mark the ticket as blocked.
- The exact iteration limit should be a constant in the appropriate place and can be generous at first.
- Ticket comments and notifications for blocked outcomes can come later.
- Telegram should include a summarized technical blocked reason when possible.

#### LLM Context And Previous Interactions

- For the first simple ticket, all listed context sources should be available:
  - ticket body
  - repository tree
  - relevant files, initially likely all source/test files for the small project
  - existing tests
  - `./rw` Dockerfile or operational setup
  - project protocols such as `AGENTS.md`
  - validation outputs
  - previous agent-LLM interaction context
- The first iteration may send more context than is optimal. Context optimization should be a near-term follow-up.
- Previous interactions must not be omitted. They mean the recent agent-LLM conversation during the loop, not human participation.
- Initial previous-interaction context can be raw, or a substantial raw tail.
- Later work can densify previous context into compact relevant summaries.
- Storage of previous interactions should follow the dump's linked context-composition artifacts instead of being redefined here.

#### LLM Output And Harness Execution

- RedWright already has a formalized LLM response semantics, but ticket execution may require extending both request and response schemas.
- Possible additions include arguments, post-actions, execution directives, affected files, commands, and structured implementation content.
- The harness layer should operate through the minimum possible primitives.
- The cycle should avoid extending primitive actions unless the code/spec review proves it is necessary.
- Future harness skills are out of scope and would still be convenient groupings over the same primitives.
- Relevant prior artifacts include:
  - `docs/explanation/adr/adr-001-integration-topology-harness-first.md`
  - `ops/plans/2026-04-28-redwright-tui-and-telegram-primitives-parity-cycle-plan.md`
  - `ops/trackers/2026-04-28-redwright-tui-and-telegram-primitives-parity-cycle-tracker.md`
  - `ops/plans/2026-04-28-redwright-real-tui-runtime-cycle-plan.md`
  - `ops/trackers/2026-04-28-redwright-real-tui-runtime-cycle-tracker.md`
  - `ops/specs/specs/2026-04-27-redwright-action-runtime-proto-spec.md`
  - `ops/specs/specs/2026-04-27-redwright-planner-executor-hardening-spec.md`

#### Git And Protocols

- The agent should work on a specific branch per ticket.
- Branch naming should come from project Protocols.
- RedWright should not use branch names, commit messages, or similar surfaces to self-promote or mark authorship.
- The produced code belongs to the user; RedWright is a tool.
- Commit messages must follow project protocols, including conventional commits when specified.
- Protocols should be materialized by the project materialization phase.
- The formal context path should eventually be model/persistence through `LLMRequestEngine`.
- Temporary protocol duplication between files and model context is acceptable and should be observable in traces.

#### Tracing And Observability

- LLM request/response tracing already exists through a rolling file.
- Broader debug logging is welcome when it helps inspect workflow behavior.
- Validation error context can initially go into a single property.
- A later corrective ticket can split lint, compile, runtime, and warning outputs if this is not cleanly handled in the first phase.

#### Telegram And Manual UX

- Manual ticket-scoped invocation must send an initial acknowledgement quickly.
- RedWright should not leave a typing indicator active for minutes.
- The operation should continue asynchronously.
- A final Telegram confirmation should always be sent.
- Intermediate visible progress is not required in the first version.
- A planned ticket checklist feature can later expose intermediate agent progress.

#### Provisional Decisions

- First target: simple, well-specified programming ticket in an established `_workspace` project.
- Test project: Go CLI todo-list style project using only the standard library.
- Sandbox: provided Dockerfile under a project operational area such as `./rw`.
- Context: send full practical context for the small project; optimize later.
- Previous context: include recent raw agent-LLM conversation context from the start.
- Invocation: Telegram for manual runs, DDD command for automated tests.
- Stop semantics: graceful stop only.
- Failure: mark ticket blocked.
- Success: validate, commit, and move to review when practical.
- Git: per-ticket branch, protocol-driven naming and commit messages.
- Acceptance: automated workflow plus manual Telegram/Kanban verification.

#### Deferred / Out Of Scope

- Ambiguous or underspecified tickets.
- Automatic Docker/container setup inference.
- Rich ticket comments and notifications.
- Ticket checklist progress marking.
- Push/remote integration when not locally fakeable.
- Multi-agent parallel execution.
- Review and merge automation.
- Sophisticated ticket-picking rules.
- Context deduplication and optimization.
- Previous-context densification.
- Harness skill system.

## Open Questions

- What exact Telegram command names and arguments should start, stop, and target a ticket?
- What exact constant should cap iteration attempts?
- Which existing primitive/action contracts already cover the required file, command, patch, and git operations?
- What exact request/response schema extensions are needed for ticket execution?
- Where should `./rw` contents be generated in the current project initialization flow?
- Which current Kanban states map to blocked and ready-for-review in code?
- How much validation/debug output should remain normal trace versus debug-level trace?
- Should push remain fully disabled for the first test, or be represented by a local fake?

## Edit Notes

- This file is intentionally curated and non-final.
- It should feed a later draft/spec only when explicitly requested.
