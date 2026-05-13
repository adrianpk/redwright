# Changelog

All notable changes to RedWright are documented in this file.

This changelog follows the spirit of [Keep a Changelog](https://keepachangelog.com/)
and is curated for product, workflow, and architecture changes rather than one
entry per commit.

## [Unreleased]

### Added

- Added Conversation as the shared place for Dumps and Quizzes.
- Added Dumps so users can capture free-form project or use-case notes, curate
  them, and reuse them as future ticket context.
- Added an authenticated Codex-backed black-box proof milestone: RedWright can
  run a ticket-like task in the proof container, validate the generated Go
  change, and push the result branch to the proof remote.

### Fixed

- Fixed `./scripts/run-dev.sh` so local provider credentials are loaded before
  the Telegram daemon starts.
- Fixed the Codex proof runtime so authenticated Codex execution can run inside
  Docker and validate Go proof repositories.

## [0.1.0-alpha.1] - 2026-05-09

Initial alpha release for RedWright's internal development baseline.

This is not an operational or stable product release. It records the current
pre-operational system capability, including the first validated ticket
execution milestone where RedWright implemented functionality from a ticket,
passed validation, created local Git evidence, and moved the ticket to review.

### Added

- Added agent ticket execution from Telegram and local command paths, including
  asynchronous acknowledgement/final feedback, targeted execution by external
  ticket key, structured LLM output application, validation retries, local Git
  evidence, and Kanban review/blocked transitions.
- Added the first validated agent-ticket implementation milestone: RedWright
  implemented functionality from a ticket, passed validation, created local Git
  evidence, and moved the ticket to review.
- Added task-aware LLM context shaping with work families, execution profiles,
  context policies, full-context fallback, dynamic preclassification, and
  traceable context inclusion/omission diagnostics.
- Added policy-selectable LLM context sources for execution contracts, modeled
  protocols, documents, quizzes, dumps, conversation, semantic code structure,
  derived LLM context, concrete files, file trees, tests, operational setup,
  and validation feedback.
- Added quiz fast/deep operation with mode switching, candidate buffering,
  processing feedback, fast-loop refill behavior, and repeated-question
  avoidance.
- Added use-case scoped tickets, documents, quizzes, and quiz entries, including
  use case management UI, safe deletion, metrics, selectors, and scoped context
  retrieval.
- Added ticket comments with Markdown rendering and mention metadata.
- Added ticket editing improvements, including modal maximization, Markdown
  preview, folded comments in maximized mode, and clearer workflow/context
  fields.
- Added project protocols as modeled state with template seeding, composition,
  workspace materialization, and management UI.
- Added runtime containers for generated projects, including readiness checks,
  management UI, and ticket-execution gating.

### Changed

- Changed agent ticket execution to run asynchronously from Telegram so manual
  commands receive immediate acknowledgement and later completion feedback.
- Changed agent workspaces to use hidden `.rw` operational setup directories
  instead of visible `rw` directories inside generated projects.
- Changed external ticket references to use human-readable ticket keys rather
  than database row ids for operator-facing invocation.
- Strengthened the agent ticket LLM prompt contract and added defensive
  normalization for recoverable near misses such as `ready`, `changes`, and
  `commands[].cmd`.
- Refactored ticket formal context ownership so tickets use optional use case
  scope instead of direct formal document attachments.
- Preserved use case scope when promoting drafts into specs and expanded scope
  coverage for documents, quizzes, and quiz entries.
- Tuned quiz fast mode so repeated questions are avoided and batched candidates
  provide a faster answer loop after the initial request.
- Refined quiz processing feedback to show a minimal dots-only activity state,
  with a concise fast-loop preparation hint when needed.
- Aligned ticket workflow metadata and ticket editor layout around status,
  ownership, delivery, and context hierarchy.
- Refactored agent ticket execution architecture boundaries so Telegram ticket
  routing, structured patch application, command-query orchestration, context
  section composition, response presentation, and validation command selection
  are owned by focused collaborators instead of oversized entrypoints.
- Changed agent ticket validation command resolution to come from operational
  setup/runtime metadata, with explicit blocking when no validation commands are
  available.
- Changed `Redwright::LLM::RequestEngine` to apply context policies to supplied
  context sections before provider calls while preserving unscoped legacy
  behavior for callers without policies.
- Changed agent ticket execution, quiz generation, project setup prompt
  rendering, and active runtime intent paths to emit default or dynamic context
  policy decisions.
- Changed protocol context selection to use modeled `ProjectProtocol` and
  `ProjectProtocolDocument` state instead of treating generated protocol files
  as the canonical source.

### Fixed

- Fixed agent ticket execution workspace guardrails so deterministic dev
  scenarios can execute inside the allowed projects root.
- Fixed agent ticket context requests so the LLM receives the rich execution
  context instead of only the minimal ticket payload.
- Fixed Telegram ticket execution timeout behavior by decoupling long-running
  agent work from the synchronous command response.
- Fixed recoverable LLM response contract drift so useful patches are applied
  instead of being blocked solely because of near-miss field names.
- Fixed provider prompt construction so policy-filtered context sections are
  actually sent to the LLM instead of only appearing in diagnostics.
- Fixed agent ticket execution context pruning by mapping concrete legacy
  sections such as `ticket`, `repository_tree`, `relevant_files`, `tests`,
  `operational_setup`, and `validation_feedback` to normalized policy layers.
- Fixed project setup, quiz, and ticket workflows after the introduction of
  scoped context and request-engine-backed LLM calls.

### Removed

- Removed direct `ticket_document_links`, the linked document picker, direct
  ticket document sync paths, command-query attachment paths, and runtime
  bridge document lines.

## 2026-05-06

### Added

- Added ticket workflow normalization artifacts, helper scripts, and the
  repository ticket workflow skill.
- Added ticket modal maximize support and modal scroll gutter/corner fixes.
- Added Markdown rendering for ticket bodies and modal description previews.
- Added ticket linked document picker support before it was later superseded by
  use case scoped formal context.
- Added ticket workflow metadata fields and editor surfaces.
- Added project use case management UI across a sliced cycle:
  - Use case domain hardening.
  - Use case command-query handlers.
  - Use cases index.
  - Use case modal forms.
  - Ticket use case selector.
  - Document use case selector.
  - Use case metrics and safe delete.
  - Full use case cycle validation.
- Added ticket comments workflow and comment metadata capture.

### Changed

- Scoped quiz index behavior to the selected project.
- Reworked quiz index actions so untreated use cases can start a new quiz while
  redundant project quiz actions are hidden.
- Tuned use case metrics modal layout and standardized visual button styling.
- Clarified repository ticket naming, delivery unit, capture, and triage rules.

### Fixed

- Fixed stale Rails PID handling in the dev runner.
- Fixed ticket modal scrolling and body resize behavior.
- Fixed ticket modal markdown body preview behavior.
- Fixed document picker usability before the later context model refactor.
- Fixed quiz index project scoping and new use case quiz affordances.

### Documentation

- Captured ticket model alignment, ticket comments alignment, use case
  management UI planning, ticket context inheritance draft material, and visual
  button consistency ticket evidence.

### Tests

- Added controller and model coverage for ticket workflow metadata, ticket use
  case selection, document use case selection, use case metrics/delete, ticket
  comments, and use case command-query behavior.

## 2026-05-05

### Added

- Added project use cases, project scoped quizzes, quiz entries, quiz entry
  denormalized scope, and quiz cardinality helpers.
- Added transversal tagging models and query support for quiz context retrieval.
- Added quiz question generation contracts, quiz loop runtime, quiz command
  queries, Telegram quiz commands, project quiz web surface, and quiz
  configuration.
- Added ticket association with use cases as part of quiz context retrieval.
- Added LLM request engine foundation, response handling, trace recorder
  boundary, context section safety, and migration of the first LLM caller to the
  request engine.
- Added a dev orchestration runner.

### Changed

- Promoted quiz artifacts from questionnaire context into formal planning and
  implementation artifacts.
- Expanded the LLM request engine specification from draft context into a
  sliced implementation cycle.
- Hardened project setup workflow behavior after quiz and LLM request engine
  integration.

### Fixed

- Fixed fallback protocol stack document generation.
- Fixed document filter assertions and project setup workflow behavior.
- Refreshed the local coverage badge artifact.

### Documentation

- Captured and formalized quiz questionnaire context.
- Drafted and expanded LLM request context composition materials.
- Planned and closed the quiz questionnaire context and LLM request engine
  cycles.

### Tests

- Added coverage for quiz domain constraints, tagging queries, LLM question
  contract guardrails, quiz loop controls, Telegram quiz flows, quiz web flows,
  ticket context retrieval scopes, quiz configuration, LLM request responses,
  migrated LLM caller behavior, trace recording coordination, and context
  safety.

## 2026-05-04

### Added

- Added project protocol domain management:
  - Project protocol domain and state.
  - Protocol template seeding.
  - Protocol document composition.
  - Protocol initialization during project setup.
  - Protocol materialization to workspace files.
  - Project protocol management UI.
  - Protocol template management UI.
- Added LLM rolling trace file configuration and trace event writing.
- Added the RedWright user guide.
- Added heavy interaction saga primitives, including saga result, prompt intent,
  reconciliation state, classified effects, observability, and structured
  prompt intent exposure.
- Added protocol management web CRUD surfaces for protocol navigation, direct
  editing, template settings, and styling harmonization.
- Added seeded protocol templates for behavioral and stack-specific protocols:
  Ruby, Go, Rails, Elixir, Zig, Rust, TypeScript, and Angular.
- Added document card previews and README screenshot gallery.

### Changed

- Aligned project setup session flow with the saga contract.
- Extracted the project setup materialization pipeline.
- Rendered Telegram project setup prompts from saga prompt intent.
- Scoped navigation to the active project.
- Kept project protocols as stable slots.
- Sourced protocols from local agent files.
- Simplified navigation and protocol surfaces.

### Fixed

- Refined login screen behavior and admin seed setup.
- Fixed board ticket card metadata alignment.
- Refined document artifact previews, then reverted type-card behavior where it
  did not match the intended design.
- Pluralized protocol template headings.

### Documentation

- Formalized project protocol templates, heavy interaction sagas, protocol
  management web CRUD, stack protocol template composition, gallery assets, and
  agent questionnaire playbooks.
- Moved spec conversations into the conversation directory and clarified
  docs-only release alignment gates.

### Tests

- Added coverage for protocol state, protocol composition, project setup
  protocol behavior, protocol materialization, protocol management,
  protocol templates, LLM rolling trace files, heavy interaction saga contracts,
  project setup materialization, saga reconciliation, prompt intent adapter
  parity, and end-to-end heavy interaction sagas.

## 2026-05-03

### Added

- Added Rails project setup conversational saga implementation:
  - Rails project setup session model and command APIs.
  - Web and Telegram project setup flows.
  - Project setup completion handling.
  - Repository materialization and board/ticket initialization.
- Added web project initialization and agent workflow behavior, including
  project creation, board seeding, setup summary documents, and starter tickets.
- Added project setup runnable saga behavior and readiness checks.
- Added runtime containers:
  - Runtime container domain and configuration.
  - Generated Go CLI runtime containers.
  - LLM contract and fallback generation for runtime containers.
  - Runtime container management UI.
  - Runtime readiness validation.
  - Ticket execution gating on runtime container readiness.
  - Runtime container context resolution.
  - Runtime container initialization during setup.
- Added project protocol template cycle drafts and implementation planning.

### Changed

- Tuned project setup completion behavior and runnable saga outcomes.
- Blocked unsupported runtime container generation.
- Connected setup materialization to runtime container readiness and ticket
  execution gating.

### Documentation

- Drafted and formalized Rails project setup conversational saga, runnable saga,
  agent runtime containers, ticket-scoped runtime recipes, project protocol
  templates, and LLM rolling trace file specs.

### Tests

- Added integration and service coverage for project setup sessions, command
  APIs, conversational flows, repository materialization, setup completion,
  runtime container generation, runtime container management, readiness gating,
  runtime container setup, and project protocol setup.

## 2026-05-02

### Added

- Added Rails core command API and project setup saga foundations.
- Added project context umbrella model and layered semantic context pipeline.
- Added web project initialization and agent workflow implementation planning.
- Added project attributes, contextual setup slots, context packet behavior,
  and retrieval boundaries for project setup and LLM-facing context.

### Changed

- Moved project setup from ad hoc state toward a structured saga and command
  API model.
- Clarified semantic context layering and project context ownership.

### Documentation

- Formalized project context umbrella, layered semantic context pipeline,
  Rails core command API, project setup saga, and web initialization specs and
  plans.

## 2026-05-01

### Added

- Added project-new operational loop behavior planning.
- Added document canvas and ticket reference model planning.
- Added runtime line coverage improvement cycle.
- Added document artifact groundwork and ticket reference model concepts that
  later fed into formal context refactors.

### Changed

- Clarified how operational project creation, documents, tickets, and runtime
  context should relate.

### Documentation

- Drafted and formalized project-new operational loop behavior, document canvas
  and ticket reference model, and runtime line coverage plans/trackers.

## 2026-04-30

### Added

- Added Rails application baseline with authentication.
- Added Kanban domain entities and persistence model.
- Added Turbo Stream Kanban board movement.
- Added ticket lifecycle timing and board metrics.
- Added ticket-first execution bridge across ingress channels.
- Added runtime loop controls and Telegram ticket progress notifications.
- Added Kanban interactions and modal ticket flows.
- Added RBAC and drag-and-drop hardening cycle:
  - Single-admin bootstrap.
  - Fixed role taxonomy.
  - Admin-gated ticket governance actions.
  - Hardened ticket drag semantics.
  - Archive/delete drop zones.
- Added provider adapter and model aliasing cycle planning.

### Changed

- Realigned runtime architecture around a Kanban-centric Rails MVP.
- Consolidated ticket-first execution as the operational center of the product.

### Fixed

- Hardened planner prompt contract behavior and routed descriptive project-new
  slash commands through the planner where appropriate.

### Documentation

- Realigned Kanban-centric runtime ADR and delivery plan.
- Added Kanban-centric Rails MVP cycle planning, Kanban RBAC/DnD planning,
  provider adapter/model aliasing planning, and planner prompt hardening
  artifacts.

### Tests

- Added Rails smoke coverage, ticket priority and lifecycle tests,
  board movement tests, unified ticket lifecycle integration coverage, ticket
  lifecycle and column ordering tests, role/authz tests, drag/drop tests, and
  modal ticket update coverage.

## 2026-04-29

### Added

- Added minimal runtime and skills cycle:
  - Turn-loop phase contract hardening.
  - Extended bounded context packet contract.
  - Planner schema skill contract fields.
  - Deterministic slash control-plane routing.
  - Hint normalizer and deterministic merge policy.
  - Skill router v1.
  - Bounded skill sub-loop executor.
  - Feedback artifacts for refinement loops.
  - Session project continuity policy.
- Added strict planner output schema validation and formal schema convergence.
- Added persistence audit and canonical state cycle:
  - Persistence inventory and zombie detection artifacts.
  - Canonical persistence ownership and lifecycle contract.
  - Persistence reference guards and startup integrity hygiene.
  - Transactional schema migrator and zombie reserve migration.
- Added operational command model:
  - Intent taxonomy.
  - Expanded deterministic slash command coverage.
  - Natural-language control parity routing.
  - Project and repo lifecycle registration.
  - Repo undo safety contract.
  - Skill subloop stop-and-apply control.
- Added project manifest schema v1, manifest writing for project creation and
  clone provenance, startup rehydration precedence, and prompt enrichment from
  manifest fields.
- Added runtime architecture hardening:
  - Telegram renderer and execution summary components.
  - Telegram control router and clarification policy.
  - Project/workstream/task command handlers.
  - Command-query envelope validation and handler registry.
  - Semantic compatibility adapter.
  - Daemon timeout errors, worktree locks, cancel contract, state root
    partitioning, session transfer, and runtime observability envelope.
- Added runtime control routing invariants and read-only operational slash
  dispatch.

### Changed

- Stabilized SQLite writes, Telegram daemon ingress, socket dispatch project
  resolution, planner action normalization, and runtime project creation
  guardrails.
- Rehydrated project state from manifests and clarified bootstrap precedence.
- Moved runtime execution toward command-query and server-compatible boundaries.

### Fixed

- Fixed clarification-first yes/no routing determinism.
- Fixed active-scope cancellation behavior.
- Fixed recoverable macro-shape execution retries.
- Fixed `/project new` without a name so it clarifies rather than side-effecting.
- Fixed operational slash routing precedence and non-meta resume behavior.
- Fixed TUI socket unavailable guard behavior.
- Restored simulated ingress clarification flows.
- Prevented nil outcome crashes on recoverable refine/clarify exits.

### Documentation

- Added runtime-next program planning, persistence model contracts, manifest and
  slash contracts, bootstrap and reset guides, runtime reliability guardrails,
  factory architecture decisions, repository ownership maps, semantic contracts,
  factory testing strategy, and agent slice execution workflow rules.

### Tests

- Added parity, runtime, persistence, architecture, command-query, renderer,
  router, CLI command, slash routing, socket guard, and clarification resolver
  regression coverage.

## 2026-04-28

### Added

- Added autonomous turn-loop cycle behavior:
  - First-run project context bootstrap.
  - Dev projects-root safety for mutating actions.
  - Bounded micro-loop for change-turn quality retries.
  - Bounded iteration context packets.
  - Confirmation-blocked success guidance.
  - Turn trace preservation.
- Added adaptive alignment loop:
  - Adaptive loop contract.
  - PSAM normalized semantic alignment schema and retrieval store.
  - LLM-driven one-question engine.
  - Pause/stop controls.
  - Max-turn governance and early sufficiency stop.
- Added rake quality tasks and local README badge rendering.
- Added canonical ingress port with simulated E2E harness.
- Added semantic deterministic runtime v2:
  - V2 state transitions and terminal reasons.
  - Semantic context packet v2.
  - Dynamic gap clarification and inferred project confirmation.
  - Convergence loop exit classification.
  - Dual-mode orchestration.
  - Multistack semantic hints.
- Added conversational control and convergence v3:
  - Planner control intent contract defaults.
  - Clarification session persistence.
  - Pending planner gap consumption before intent reclassification.
  - Multilingual control interpretation.
  - Context packet v3 bounds and tree view.
  - Deterministic bounded micro-loop caps.
  - Cancel/resume clarification semantics.
  - Human output and debug envelope contract.
  - Persistence hygiene and dev reset safety.
- Added TUI and Telegram primitive parity:
  - Console ingress foundation.
  - Primitive contract unification.
  - Busy-turn queue drain modes.
  - Control routing precedence.
  - Bootstrap minimum gate for technical gaps.
  - Minimal fullscreen TUI ingress mode.
  - Cross-channel parity matrix.
- Added server-client runtime transition:
  - Runtime lock and health commands.
  - Local IPC protocol and session bus.
  - Server dispatcher migration.
  - TUI and Telegram socket clients.
  - Recovery controls and parity invariants.

### Changed

- Switched README badges to inline local SVG style.
- Simplified README positioning, runtime usage, and messaging status notes.
- Added root config example and concise property guidance.

### Fixed

- Fixed Telegram human output by removing clarify banner prefix.
- Added adaptive alignment persistence hygiene and dev reset safety.

### Documentation

- Planned and tracked autonomous turn loop, adaptive alignment, quality badges,
  ingress, runtime v2, conversational control, TUI/Telegram parity,
  server-client runtime, and real TUI runtime cycles.

### Tests

- Added simulated ingress, parity, runtime v2, clarification, persistence,
  and matrix coverage across the runtime cycles.

## 2026-04-27

### Added

- Bootstrapped the initial RedWright repository and operating artifacts.
- Added runtime workspace path resolution and SQLite state.
- Added project, alias, workstream, task, and task-to-commit persistence.
- Added message-to-workstream flow skeleton and plan alignment state machine.
- Added git worktree lifecycle management.
- Added plan spec artifact generation and spec promotion.
- Added configurable blocked retry policy.
- Added Rake tasks for runtime, tests, and smoke paths.
- Added runtime YAML config loader with strict validation.
- Added daemon run loop command and lifecycle coverage.
- Added Telegram polling ingress, allow-list mapping, event materialization,
  acknowledgments, typing actions, and typing keepalive.
- Added model resolution for coding and non-coding models.
- Added structured Telegram result envelopes and trace banners.
- Added OpenAI-backed intent interpretation with environment-backed config.
- Added runtime trace gating, LLM exchange detail exposure, and per-event trace
  correlation.
- Added strict planning contract, validator retries, dynamic planner prompt
  context, planner rejection persistence, and manifest-driven quality gate
  validation.
- Added multi-project resolver with per-chat runtime context.
- Added primitive executor, guarded git primitives, execution summaries,
  trace query surface, and skill scaffold interfaces.
- Added macro action normalization and layered planner prompt with injection
  guardrails.
- Added workspace snapshot context in planner prompts.

### Changed

- Defined RedWright product identity and behavior scope in the README.
- Centralized mode-aware project root resolution and enforced dev workspace
  roots for state config and project paths.
- Raised OpenAI default read timeout.
- Unified runtime trace IDs across flow execution.

### Fixed

- Ignored system slash commands in Telegram ingress mapping.
- Enforced dev workspace root safety for state and project paths.

### Documentation

- Created initial specification convergence artifacts, daemon Telegram specs,
  planner-executor hardening specs, action-runtime specs, and operating cycle
  trackers.
- Formalized Ruby modular runtime boundaries.

### Tests

- Added early coverage for daemon lifecycle, planner validation, context
  resolver behavior, primitive execution, git primitives, runtime summaries,
  trace toggles, skill loading, prompt layering, quality gates, and workspace
  snapshot propagation.
