# RedWright Transferable Patterns Raw Dump

Historical capture from 2026-05-17. Repository structure, capabilities, and
proposals below describe that snapshot; they do not define current behavior.

## Metadata

- date: `2026-05-17`
- source workspace: `<workspace>`
- repository root: `<workspace>/redwright`
- capture type: raw-hard-core-data
- purpose: preserve orientation notes and concrete repository references for reusing RedWright patterns in another project

## Repository Shape

The actual RedWright repository is nested under `redwright/`.

Top-level `<workspace>` contains:

- `docs/`: older or alignment-oriented documents from before the nested repo boundary became the active root.
- `redwright/`: active repository.
- `lab/`: experiments and external comparison material.
- `tmp/`: temporary notes and migration/remote artifacts.

Inside `redwright/`, the durable structure is:

- `AGENTS.md`: top-level agent operating contract.
- `.agents/`: collaboration, architecture, documentation, lifecycle, versioning, routing, linting, and invariant rules.
- `docs/`: durable product, user, and technical documentation.
- `ops/`: operational execution ledger for specs, plans, trackers, tickets, cycle reports, dumps, and quizzes.
- `lib/redwright/`: runtime/library layer.
- `apps/web/`: Rails product surface.
- `test/`: Ruby runtime tests.
- `apps/web/test/`: Rails application tests.

## Agent Protocol Files

Important files:

- `AGENTS.md`
- `.agents/ARCHITECTURE.md`
- `.agents/CONVENTIONS.md`
- `.agents/DOCUMENTING.md`
- `.agents/INVARIANTS.md`
- `.agents/LIFECYCLE.md`
- `.agents/LINTING.md`
- `.agents/PLAYBOOKS.md`
- `.agents/ROUTING.md`
- `.agents/SLICES.md`
- `.agents/VERSIONING.md`

Key operating rules from `AGENTS.md`:

- Execute only after a clear implementation request.
- Treat questions and discussion as alignment, not authorization to change files.
- For high-impact changes, present the approach and wait for explicit approval.
- Complete the requested scope, report the outcome, and stop.
- Do not add unsolicited follow-up work.
- All code and repository documentation must be written in English.
- Product and runtime specifications belong in `docs/`.
- Working rules belong in `.agents/` and `AGENTS.md`.

Key architecture rules:

- `apps/web/` is the Rails application.
- `apps/web/app/services/` owns multi-step workflows, sagas, materializers, runtime container orchestration, protocol composition, and command/query handlers.
- Active Record models own persistence-backed invariants and associations.
- Views render state and local interaction affordances, not business workflows.
- `lib/` is for reusable runtime/library code that genuinely belongs outside Rails.
- `ops/` stores specs, plans, trackers, artifacts, and curated conversation artifacts.
- `docs/` stores user-facing and technical documentation.

## Product Identity

RedWright is a black-box software factory platform where one runtime agent operates from a Kanban board.

Current interactive surfaces:

- Telegram.
- Local TUI.
- Rails web app for boards, projects, tickets, protocols, documents, dumps, quizzes, and related management surfaces.

Current execution direction:

- Single runtime agent.
- Ticket-centric execution.
- Isolated sandboxes/workspaces.
- Future multi-agent roles are anticipated but deferred.

The product is not merely a ticket app. It is an operational runtime that turns natural language and project state into bounded, auditable, validated actions.

## Core Runtime Thesis

RedWright separates:

- user intent interpretation,
- command/query normalization,
- planning/alignment,
- bounded primitive execution,
- context composition,
- validation,
- persistence,
- traceability,
- ticket lifecycle transitions.

The main safety rule is that raw text does not execute directly.

## Durable Documentation Entry Points

Important documentation files:

- `README.md`
- `docs/index.md`
- `docs/explanation/what-is-redwright.md`
- `docs/reference/application-semantics-v1.md`
- `docs/reference/runtime-capabilities.md`
- `docs/reference/kanban-integration-contract-v1.md`
- `docs/reference/llm-context-shaping.md`
- `docs/reference/runtime-modes-and-roles-v1.md`
- `docs/reference/runtime-control-routing-invariants-v1.md`
- `docs/reference/ticket-visibility-policy-v1.md`
- `docs/reference/persistence-model.md`
- `docs/explanation/operational-vs-task-intent-model.md`
- `docs/explanation/adr/adr-003-command-query-semantic-core-v1.md`
- `docs/explanation/adr/adr-008-kanban-centric-unified-runtime-and-ticket-execution.md`

## Command/Query Semantic Core

Source references:

- `docs/reference/application-semantics-v1.md`
- `docs/explanation/adr/adr-003-command-query-semantic-core-v1.md`
- `apps/web/app/services/command_query/dispatcher.rb`
- `apps/web/app/services/command_query/envelope.rb`
- `apps/web/app/services/command_query/result.rb`
- `apps/web/app/services/command_query/registry.rb`

Contract:

- Every operational behavior converges to an explicit semantic action.
- Writes are `command`.
- Reads are `query`.
- Adapters may interpret input, but execution is allowed only after mapping into a validated command/query payload.
- Invalid envelope returns structured `invalid_envelope`.
- Unsupported command/query returns structured `unsupported_action`.
- Handler errors return structured `execution_failed`.

Representative command names:

- `CreateTicket`
- `UpdateTicket`
- `AssignTicket`
- `MoveTicket`
- `StartWorkOnTicket`
- `PickNextTicket`
- `OpenQuiz`
- `AdvanceQuiz`
- `OpenDump`
- `AppendDump`
- `DoneDump`
- `CancelDump`
- `CurateDump`

Representative query names:

- `GetTicket`
- `GetTickets`
- `GetBoard`
- `GetFactoryStatus`
- `GetExecutionRun`
- `ListQuizzes`
- `ListDumps`
- `ShowDump`

Transferable pattern:

- Normalize every ingress surface into a typed envelope before any mutation.
- Keep transport adapters thin.
- Put auth, transition policy, and workflow behavior behind handlers.

## Ticket-First Runtime

Source references:

- `docs/explanation/adr/adr-008-kanban-centric-unified-runtime-and-ticket-execution.md`
- `docs/reference/runtime-modes-and-roles-v1.md`
- `docs/reference/kanban-integration-contract-v1.md`
- `apps/web/app/models/ticket.rb`
- `apps/web/app/services/agent_ticket_execution/`

Decision:

- RedWright moved from separate `interactive` and `factory` runtimes to one unified Kanban-centric runtime.
- All mutating execution must target a ticket.
- If an ingress request has no ticket, the system derives or creates one.
- Runtime modes are `single_ticket` and `loop`.
- MVP topology is one bot and one runtime process.

Ticket workflow statuses:

- `open`
- `ready`
- `in_progress`
- `reviewing`
- `blocked`
- `solved`
- `closed`

Ticket metadata classes:

- kinds: `unclassified`, `bug`, `task`, `cleanup`, `follow_up`, `research`, `decision`
- severities: `unclassified`, `low`, `medium`, `high`, `critical`
- scopes: `unclassified`, `ops`, `web`, `runtime`, `llm`, `project_setup`, `docs`, `infra`
- sources: `chat`, `manual_test`, `review`, `trace`, `user_report`, `implementation`
- resolutions: `fixed`, `wont_do`, `duplicate`, `obsolete`, `moved`, `answered`

Ticket key pattern:

- prefix: `RW`
- pattern: `RW-<number>`

Transferable pattern:

- Make the work item the atomic execution and audit boundary.
- Store time and status changes as lifecycle data, not only UI state.
- Use human-readable ticket keys externally and database ids internally.

## Rails Domain Model

Important model files:

- `apps/web/app/models/project.rb`
- `apps/web/app/models/board.rb`
- `apps/web/app/models/column.rb`
- `apps/web/app/models/ticket.rb`
- `apps/web/app/models/document.rb`
- `apps/web/app/models/project_protocol.rb`
- `apps/web/app/models/project_protocol_template.rb`
- `apps/web/app/models/project_runtime_container.rb`
- `apps/web/app/models/project_setup_session.rb`
- `apps/web/app/models/project_setup_turn.rb`
- `apps/web/app/models/quiz.rb`
- `apps/web/app/models/quiz_entry.rb`
- `apps/web/app/models/dump.rb`
- `apps/web/app/models/dump_entry.rb`
- `apps/web/app/models/use_case.rb`
- `apps/web/app/models/ticket_comment.rb`
- `apps/web/app/models/tag.rb`
- `apps/web/app/models/tagging.rb`

Main associations:

- `Project` has many boards, documents, setup sessions, use cases, quizzes, dumps, taggings.
- `Project` has one protocol and one runtime container.
- `Board` belongs to project and has columns, tickets, labels.
- `Column` belongs to board and has tickets.
- `Ticket` belongs to board and column, optionally use case, and has labels, comments, tags.

Transferable pattern:

- Product state belongs in Rails models.
- Orchestration belongs in service modules.
- Runtime abstractions can remain separate under `lib/`.

## Service Boundaries

Top-level Rails service namespaces:

- `agent_ticket_execution`
- `board_workflow`
- `command_query`
- `document_management`
- `dump_loops`
- `heavy_interaction_sagas`
- `project_initialization`
- `project_protocols`
- `project_setup`
- `quiz_loops`
- `runtime_bridge`
- `runtime_containers`
- `ticket_management`
- `use_cases`

Transferable pattern:

- Group workflows by business capability.
- Keep controllers and command entrypoints thin.
- Use plain Ruby service objects for sagas and orchestration.

## Agent Ticket Execution Flow

Important files:

- `apps/web/app/services/agent_ticket_execution/runner.rb`
- `apps/web/app/services/agent_ticket_execution/request_builder.rb`
- `apps/web/app/services/agent_ticket_execution/ticket_selection_policy.rb`
- `apps/web/app/services/agent_ticket_execution/workspace_boundary.rb`
- `apps/web/app/services/agent_ticket_execution/context_composer.rb`
- `apps/web/app/services/agent_ticket_execution/context_section_providers.rb`
- `apps/web/app/services/agent_ticket_execution/llm_requester.rb`
- `apps/web/app/services/agent_ticket_execution/llm_contract.rb`
- `apps/web/app/services/agent_ticket_execution/output_applier.rb`
- `apps/web/app/services/agent_ticket_execution/validation_loop.rb`
- `apps/web/app/services/agent_ticket_execution/validation_executor.rb`
- `apps/web/app/services/agent_ticket_execution/git_finalizer.rb`
- `apps/web/app/services/agent_ticket_execution/kanban_transitioner.rb`
- `apps/web/app/services/agent_ticket_execution/response_presenter.rb`
- `apps/web/app/services/agent_ticket_execution/previous_interaction_store.rb`
- `apps/web/app/services/agent_ticket_execution/operational_setup.rb`
- `apps/web/app/services/agent_ticket_execution/command_query_handlers.rb`

Execution path:

1. Resolve command payload.
2. Select targeted or next eligible ticket.
3. Resolve workspace under allowed root.
4. Move ticket to in-progress.
5. Compose execution context.
6. Request structured LLM response.
7. Validate the LLM response contract.
8. Apply files, patches, commands, or direct primitive actions.
9. Run validation commands.
10. Retry with validation/application feedback if needed.
11. Commit successful changes on a ticket branch.
12. Move completed ticket to review.
13. Move unresolved work to blocked with structured reason.

Failure states:

- invalid payload,
- selection error,
- workspace error,
- invalid LLM response,
- LLM blocked,
- output application failed,
- validation commands missing,
- validation failed,
- retry limit exhausted,
- git finalization failed.

Transferable pattern:

- The LLM should produce structured output against a contract.
- Output application should be a separate boundary from LLM calling.
- Validation feedback should be fed back into the next attempt.
- Ticket lifecycle should be updated by a dedicated transitioner.

## Context Composition and LLM Policy

Source references:

- `docs/reference/llm-context-shaping.md`
- `lib/redwright/llm/request_engine.rb`
- `lib/redwright/llm/context_policy.rb`
- `lib/redwright/llm/context_preclassifier.rb`
- `lib/redwright/llm/context_section.rb`
- `apps/web/app/services/agent_ticket_execution/context_composer.rb`
- `apps/web/app/services/agent_ticket_execution/context_section_providers.rb`

Context layers:

- `agent`
- `project`
- `prompt`
- `concrete_files`
- `file_tree`
- `tree_sitter`
- `llm_based`
- `docs`
- `quizzes`
- `dumps`
- `conversation`
- `protocols`

Work families:

- `exploration`
- `implementation`
- `modification`
- `diagnosis`
- `evaluation`
- `operation`
- `planning`
- `documentation`

Default policies:

- `exploration_default`
- `implementation_default`
- `modification_default`
- `diagnosis_default`
- `evaluation_default`
- `operation_default`
- `planning_default`
- `documentation_default`
- `full_context_fallback`

Implemented context sources for agent ticket execution:

- ticket and project data,
- repository tree,
- concrete repository files,
- tests,
- operational setup,
- Tree-sitter style code structure,
- protocol documents,
- repository and app documents,
- quiz context,
- dump context,
- derived LLM context,
- previous agent interactions,
- human conversation evidence,
- validation feedback.

Transferable pattern:

- Context should be structured into named sections with explicit authority and layer metadata.
- Business callers own data gathering.
- The request engine selects sections by policy; it does not fetch domain records itself.
- Trace policy decisions and omitted context.

## Runtime Library Layer

Important files:

- `lib/redwright/runtime_flow.rb`
- `lib/redwright/primitive_executor.rb`
- `lib/redwright/structured_patch_applier.rb`
- `lib/redwright/llm/request_engine.rb`
- `lib/redwright/llm/context_policy.rb`
- `lib/redwright/llm/context_preclassifier.rb`
- `lib/redwright/llm/trace_recorder.rb`
- `lib/redwright/telegram_runtime_handler.rb`
- `lib/redwright/tui/socket_client_runner.rb`
- `lib/redwright/local_ipc_server.rb`
- `lib/redwright/server_runtime_dispatcher.rb`
- `lib/redwright/project_store.rb`
- `lib/redwright/workstream_store.rb`
- `lib/redwright/task_store.rb`
- `lib/redwright/action_execution_store.rb`

Runtime flow concepts:

- `project`
- `workstream`
- `task`
- `alignment`
- `action_results`
- `terminal_reason`

Primitive action types:

- `list_files`
- `read_file`
- `search`
- `run`
- `write_file`
- `apply_patch`
- `git_status`
- `git_branch`
- `git_commit`
- `git_push`
- `git_undo`

Safety patterns:

- path confinement through `safe_path`,
- optional allowed project root enforcement for mutating actions,
- confirmation requirement for commit and push,
- timeout enforcement,
- structured action execution results,
- no raw text execution.

Transferable pattern:

- Treat filesystem, shell, and git as typed primitives.
- Keep mutation under an allowed root.
- Return structured execution results for audit and retries.

## Telegram Runtime Handler

Important file:

- `lib/redwright/telegram_runtime_handler.rb`

Responsibilities:

- Resolve project/chat context.
- Route project setup adapter first.
- Dispatch semantic compatibility adapter.
- Parse slash commands.
- Handle clarify/control/operational routes.
- Interpret natural language through LLM intent interpreter.
- Enforce bootstrap gate and clarification policy.
- Route skill activation and subloops.
- Process change turns with quality feedback and retry guards.
- Send Telegram result envelopes and human-readable summaries.

Important routing invariant:

- direct control slashes are resolved before planner interpretation.
- explicit `control_intent` wins over `operational_intent`.
- natural-language control is allowed only under constrained conditions.

Transferable pattern:

- Chat ingress should resolve operational scope before task execution.
- Slash commands should act as deterministic control anchors.
- Natural-language interpretation should not override explicit control.

## Project Setup and Protocols

Important files:

- `apps/web/app/services/project_setup/state_machine.rb`
- `apps/web/app/services/project_setup/context_loop_service.rb`
- `apps/web/app/services/project_setup/guided_alignment_service.rb`
- `apps/web/app/services/project_setup/materialization_pipeline.rb`
- `apps/web/app/services/project_protocols/composer.rb`
- `apps/web/app/services/project_protocols/filesystem_materializer.rb`
- `apps/web/app/services/project_protocols/template_catalog.rb`
- `apps/web/app/services/project_protocols/template_registry.rb`

Project setup states:

- `collecting_context`
- `awaiting_repository`
- `awaiting_repository_confirmation`
- `awaiting_alignment_opt_in`
- `collecting_alignment`
- `ready_to_create`
- `creating_project`
- `completed`
- `cancelled`
- `failed`
- `needs_reconciliation`

Core setup slots:

- `project_name`
- `description`
- `project_type`
- `language_runtime`
- `framework`
- `libraries`

Additional runtime bridge slots:

- `repository`
- `stack`
- `patterns`
- `conventions`
- `runtime_container_profile`
- `agent_workflow_mode`

Transferable pattern:

- Model project setup as a state machine.
- Store each answer as a turn.
- Store normalized setup slots as project attributes.
- Materialize protocols from modeled state rather than treating generated files as the primary source of authority.

## Runtime Bridge

Important files:

- `apps/web/app/services/runtime_bridge/ticket_execution_bridge.rb`
- `apps/web/app/services/runtime_bridge/project_context_builder.rb`

Bridge responsibilities:

- Build a runtime request from a Rails ticket.
- Include project setup context and runtime container context.
- Check runtime container readiness before dispatch.
- Send request through local socket.
- Normalize runtime response into Rails execution status.

Transferable pattern:

- Product app should not directly own every runtime detail.
- Build a transport-neutral runtime payload.
- Keep readiness checks host-side.

## Operational Ledger

Source references:

- `ops/README.md`
- `ops/specs/README.md`
- `ops/plans/README.md`
- `ops/templates/`
- `ops/tickets/TEMPLATE.md`

Operational directories:

- `ops/specs/drafts/`: working specification drafts.
- `ops/specs/specs/`: refined and formal specs.
- `ops/plans/`: approved cycle plans.
- `ops/trackers/`: live execution status ledgers.
- `ops/artifacts/`: generated inventories, matrices, reports, and audits.
- `ops/conv/dump/`: raw and curated free-form knowledge dumps.
- `ops/conv/quiz/`: bounded questionnaire artifacts.
- `ops/tickets/`: repository-local development ticket workflow.

Transferable pattern:

- Keep durable docs separate from execution artifacts.
- Use specs, plans, trackers, and reports for higher-risk cycles.
- Use local markdown tickets for backlog and agent-visible task capture.

## Important Cycle Reports

Agent ticket execution:

- `ops/artifacts/2026-05-08-redwright-agent-ticket-execution-cycle-report.md`

Delivered:

- targeted and pickup ticket selection,
- sandbox workspace resolution,
- execution context composition,
- structured LLM request contract,
- output application through primitives,
- validation loop,
- local git branch and commit,
- Kanban transition integration,
- automated end-to-end tests.

Residual risks:

- live Telegram/browser acceptance still needed after merge,
- context composition favors completeness over token optimization,
- Docker/container inference not implemented,
- push/PR/review/merge automation out of scope.

Codex black-box proof:

- `ops/artifacts/2026-05-12-codex-black-box-engine-proof-report.md`

Decision:

- Codex black-box engine boundary is viable with constraints.
- Final proof reached Codex inside container but failed with API `401 Unauthorized`.
- Failure was classified as auth blocker, not worker boundary failure.

Artifacts:

- prompt,
- events JSONL,
- stderr,
- execution result,
- result envelope,
- changed files list,
- git diff,
- commit log,
- push log,
- validation stdout/stderr,
- post-Codex status.

Policy finding:

- Worker-side push is structurally viable in proof mode.
- Production should prefer host-owned finalization so RedWright can enforce validation, branch naming, retry, audit, and cleanup before remote mutation.

## Tests and Validation Surface

Test directories:

- `test/redwright/`
- `apps/web/test/`

Notable test clusters:

- runtime flow,
- primitive executor,
- LLM request engine,
- context policy/preclassifier,
- Telegram runtime handler,
- command/query dispatcher,
- project setup,
- project protocols,
- runtime bridge,
- runtime containers,
- agent ticket execution,
- Rails controllers/models/integration tests.

Transferable pattern:

- Test the behavioral boundary being changed.
- Use unit tests for local rules.
- Use integration tests for workflow contracts.
- Keep end-to-end tests local and deterministic where possible.

## Reuse Priority for Another Project

Recommended extraction order:

1. `.agents` operating protocol and `AGENTS.md`.
2. `docs/` vs `ops/` split.
3. local `ops/conv/dump`, `ops/conv/quiz`, and `ops/tickets` conventions.
4. command/query envelope.
5. ticket-first execution model.
6. context sections and context policy.
7. validation loop.
8. primitive executor boundary.
9. runtime bridge.
10. isolated worker proof model.

Avoid copying first:

- full Rails implementation,
- full Telegram runtime handler,
- complete runtime persistence,
- multi-step project setup saga,
- Codex/Docker worker proof.

Those are heavier and should be introduced only when the target project needs them.

## New Target System Direction From User

The target system should be treated as a carving process rather than a fully defined up-front specification. The user expects to provide broad direction first and refine the shape iteratively.

Initial user direction:

- The user wants a "portable" version of RedWright-like capabilities.
- The command/product name will be `ChrysoCoord`.
- `Chryso` comes from Chrysocolla, a cyan/turquoise mineral stone close to the historical Go visual imagination: Go blue, the Go logo, and the gopher.
- The color association should feel technical, clean, cool, friendly, and pragmatic.
- Chrysocolla is less like a shiny gemstone and more like a matte industrial mineral, which fits runtimes, tooling, distributed systems, and infrastructure software.
- `Coord` refers to coordination/coordinator.
- The core idea is not an isolated agent but the coordination of multiple agents, workers, or cooperating nodes.
- The name should evoke a distributed runtime responsible for orchestration, synchronization, and collective execution, almost like a conductor coordinating orchestra sections in real time.
- The CLI command will be `chc`.
- The previous desired short name `cc` was rejected because it collides with `/usr/bin/cc`, the system C compiler.
- The word "portable" is acknowledged as imperfect, but it points toward a smaller, relocatable, project-local system rather than a centralized web/database product.
- No web UI is wanted.
- No UI should be treated as the official operating surface in the first phase.
- A CLI or TUI may help later, but only as support surfaces.
- The CLI may eventually trigger loops.
- The TUI, if it exists, may make state easier to inspect, but it is not mandatory in the first phase.
- The system must be able to run and manage its loops using only information stored in project assets.
- The system should be file-based.
- Artifacts should be Markdown files.
- The implementation language should be Go.
- The target use case is resolving or working on codebases implemented in Go.

Persistence direction:

- Everything that is database-backed in RedWright should map to files in the new system.
- Files should live in a specific hidden project-local directory.
- If the project is named `projectname`, the directory should be `.projectname`.
- The user likes the file-based approach.
- The user also sees value in having a per-project database because of query capability.

Persistence dilemma:

- SQLite is attractive because it enables one database per project without external setup.
- Dgraph is attractive because graph relationships could connect information in useful ways for preparing LLM context.
- The unresolved question is whether the portable system should stay purely file-based, use file-based source-of-truth plus SQLite index/cache, or adopt a graph database model such as Dgraph for richer context retrieval.

Persistence refinement:

- Markdown can remain canonical content.
- SQLite can provide queryability and referentiality.
- SQLite does not need to store large text chunks as canonical content.
- SQLite can index paths, artifact metadata, anchors, references, semantic relationships, and query dimensions.
- The semantic model still needs to be defined.
- Prompt context assembly should support combined semantic queries such as: retrieve everything for use case `X`, related to concern `Y`, with priority `A`, and severity `B`.
- `uxui` was only an example value for a concern or query dimension, not a special tag requirement.
- The important requirement is multi-dimensional retrieval across use cases, concerns, priority, severity, artifacts, references, and other semantic fields.

Resulting persistence model candidate:

- Markdown files are canonical assets.
- SQLite is a semantic index and query layer.
- The index can be rebuilt from Markdown files and generated code indexes.
- Context assembly queries SQLite for relevant artifacts, sections, relationships, and dimensions, then loads canonical text from Markdown files.

Immediate interpretation:

- The system should not begin as a web application.
- The system should not assume a central server.
- The system should likely operate from the target repository root.
- The project-local hidden directory should be the operational state root.
- Markdown files should remain first-class artifacts rather than export formats.
- Any database should be evaluated as an implementation aid, index, cache, or optional adapter, not automatically as the canonical state.
- Loops should be asset-driven.
- If a CLI exists, it should dispatch or inspect loops rather than define the core state model.
- If a TUI exists, it should visualize and navigate existing assets rather than become the source of truth.

Operational channel additions:

- Telegram should be able to start and stop ticket-resolution loops.
- Telegram notifications should be configurable.
- Telegram should receive operational events such as PRs created, diffs, blockers, and user-response requests.
- If an agent loop stops progressing after a retry threshold, time threshold, or loop counter threshold, the system should notify the user and ask for input when the blocker may be resolvable by user response.
- The same blocker or clarification event must be recorded persistently in Markdown assets.
- Ticket comments are likely needed as a durable artifact type.
- Email is probably not a fast interaction channel.
- Email may be useful for progress notifications, summaries, reports, and longer-form operational updates.
- These channels do not replace the asset-driven operating model; they trigger, notify, or capture responses around it.

## Project-Local Asset Directory Direction

The system needs an ergonomic organization inside the hidden per-project directory.

Provisional directory root:

- `.<projectname>/`

Assets that need a place inside the hidden directory:

- specs,
- drafts,
- tickets,
- ticket comments,
- architecture notes,
- conventions,
- playbooks,
- database or indexes if used,
- additional durable operational assets still to be identified.

The directory should be organized so loops can run from the stored assets. CLI/TUI wrappers can later make this easier to trigger or inspect, but the files must remain sufficient.

Possible structure to evaluate later:

```text
.<projectname>/
  AGENTS.md
  manifest.yml
  agents/
    ARCHITECTURE.md
    CONVENTIONS.md
    DOCUMENTING.md
    INVARIANTS.md
    LIFECYCLE.md
    PLAYBOOKS.md
    ROUTING.md
  docs/
    architecture/
    conventions/
    reference/
  ops/
    specs/
      drafts/
      accepted/
    tickets/
      open/
      ready/
      in_progress/
      reviewing/
      blocked/
      solved/
      closed/
    conv/
      dump/
      quiz/
    playbooks/
    reports/
  context/
    agent/
    project/
    lsp/
    treesitter/
    file_tree/
    interactions/
    graph/
  db/
    sqlite/
    dgraph/
  indexes/
    gograph/
```

This is not yet a final layout. It captures the asset categories that must be carved into an ergonomic project-local structure.

## Context Source Direction

RedWright context ideas that seem useful for the portable system:

- agent-related context,
- project-related context,
- LSP-based context,
- Tree-sitter-based context,
- file tree context,
- previous interactions,
- graph/code-relationship context,
- other context layers still to be identified.

The target system should prepare LLM context from structured assets and codebase indexes, not from a UI.

## Gograph Reference

User-provided reference:

- `https://www.bytesizego.com/blog/gograph-a-go-cli-that-parses-your-codebase-for-ai-agents`

Observed details from the article:

- Gograph is a local repository indexer for Go projects.
- It parses Go code with standard AST packages.
- It writes a compact `.gograph/graph.json`.
- It writes JSON plus Markdown reports under `.gograph/`.
- It provides query commands for packages, symbols, calls, routes, SQL, tests, config reads, and quality signals.
- Default mode is AST-only and tolerates incomplete code.
- Precise mode uses `golang.org/x/tools/go/packages`, SSA, interface implementation checks, and call graph enrichment.
- Useful commands include `source`, `callers`, `callees`, `context`, `hotspot`, `deps`, `changes`, and `path`.
- The MCP server is a thin wrapper over the same search functions and runs over stdio.
- The article's package separation is useful: scanner, parser, graph, search, precise, MCP, reports.

Potential relevance:

- The user considers all of the Gograph-like approach applicable.
- In Go, this is a strong complement to Tree-sitter and LSP.
- It may eventually replace both Tree-sitter and LSP for the portable system's Go-focused context needs.
- The portable system can copy the design restraint and the core shape.
- A Go-first asset system can build or consume an AST graph for context.
- The graph/index can be local and project-contained.
- A fast incomplete-code mode is valuable during agent work.
- A precise mode is valuable before risky refactors.
- Markdown reports from the graph fit the file-based artifact model.
- MCP could be optional later, not required for first-phase loops.

Updated interpretation:

- For Go codebases, a Gograph-like AST/graph layer should be treated as a primary context engine candidate.
- Tree-sitter and LSP remain useful comparison points or complementary layers, but they are not automatically required if the Go graph covers enough context needs.
- The design should avoid prematurely committing to three parallel code-intelligence systems.

Additional user clarification:

- The user does not yet know whether Gograph-like indexing complements or replaces Tree-sitter/LSP.
- The user has read the reference only at a high level and does not want to make a fast architecture decision from that alone.
- The user understands enough to believe it solves a problem highly aligned with the target system.
- LSP and Tree-sitter are ubiquitous and mature, not experimental or marginal libraries.
- The key question is whether these systems complement each other or repeat the same information.

Architecture uncertainty to preserve:

- Gograph-like tooling may eventually replace both Tree-sitter and LSP if it provides the same information in a better organized form for Go.
- Tree-sitter and LSP may still provide distinct signals that a Go AST graph does not cover.
- The system needs an evidence-based comparison before choosing a context-engine architecture.

Comparison dimensions to evaluate:

- syntax structure,
- symbol definitions,
- references and usages,
- call graph,
- interface implementation relationships,
- imports/dependencies,
- tests related to code,
- route/SQL/config discovery,
- incomplete-code tolerance,
- type-aware precision,
- editor/server dependency,
- setup complexity,
- output artifact quality,
- query ergonomics,
- suitability for LLM context packing.
