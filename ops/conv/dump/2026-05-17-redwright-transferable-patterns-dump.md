# RedWright Transferable Patterns Curated Dump

Historical capture from 2026-05-17. Repository structure, capabilities, and
proposals below describe that snapshot; they do not define current behavior.

## Central Topic

Extract reusable RedWright patterns for another project without copying the whole implementation.

## Raw Source

- `ops/conv/dump/2026-05-17-redwright-transferable-patterns-dump-raw.md`

## Summary

RedWright is best understood as a ticket-first operational runtime, not merely as a Rails Kanban app. The Rails app owns the product surface and persistence-backed domain state. The runtime layer owns command normalization, bounded primitives, LLM request handling, context shaping, traceability, and execution flow.

The most transferable value is the operating protocol: clear repository rules, a durable documentation model, an operational ledger, command/query boundaries, ticket-centric execution, and structured context capture. The heavier runtime components are useful references, but they should be introduced in another project only when the project needs autonomous or semi-autonomous execution.

The emerging target is a Go-built, repository-local, file-based version of the useful RedWright operating model. It should avoid web UI and central database assumptions. Its artifacts should be Markdown files under a hidden project-local directory such as `.projectname`. The official operating model should be asset-driven: loops must be manageable from repository assets, with CLI/TUI surfaces acting only as optional helpers.

The working command/product name is `ChrysoCoord`. The CLI command is `chc`. The earlier short name candidate `cc` was rejected because it collides with the system C compiler on the current Linux environment (`/usr/bin/cc`).

Name origin:

- `Chryso` comes from Chrysocolla, a cyan/turquoise mineral stone close to Go's visual language: Go blue, the Go logo, and the gopher.
- The intended color tone is technical, clean, cool, friendly, and pragmatic.
- Chrysocolla feels more like a matte industrial mineral than a shiny gemstone, which fits runtimes, tooling, distributed systems, and infrastructure software.
- `Coord` comes from coordination/coordinator.
- The system is not centered on an isolated agent; it is about coordinating multiple agents, workers, or cooperating nodes.
- The name should evoke a distributed runtime for orchestration, synchronization, and collective execution.

## Key Concepts

- **Ticket-first execution**: mutating work should be represented by a ticket or equivalent work item.
- **No raw text execution**: natural-language input must become a validated command/query or structured request before mutation.
- **Thin adapters**: Telegram, TUI, web, CLI, or future channels should map input into the same core semantics.
- **Context sections**: LLM context should be explicit, layered, traceable, and policy-selectable.
- **Asset-driven loops**: the loop must be defined by project-local files, not by a UI surface.
- **Go code graph context**: Go AST, LSP, Tree-sitter, file tree, and previous interaction data should become structured context inputs.
- **Bounded primitives**: filesystem, shell, and git operations should be typed actions with path and confirmation constraints.
- **Validation loop**: implementation output should be applied, validated, and retried with feedback before completion.
- **Host-owned finalization**: production finalization should remain under the host system's policy, even if a worker produces the diff.
- **Docs vs ops split**: durable knowledge belongs in `docs/`; working execution artifacts belong in `ops/`.

## Decisions and Strong Preferences

- Reuse patterns before code.
- Start with operating protocol and artifact structure.
- Keep configuration and documentation in English.
- Avoid importing the full runtime until the target project has a real need for automated execution.
- Prefer command/query normalization before building adapters.
- Prefer host-controlled validation, branch naming, audit, and finalization.
- Use local markdown artifacts for early context capture before database/product surfaces exist.
- Build the new system in Go.
- Use `ChrysoCoord` as the working command/product name.
- Use `chc` as the CLI command.
- Do not use `cc` as the CLI alias because it collides with the C compiler.
- Target Go codebases first.
- Do not build a web UI.
- Do not make UI the official operating surface.
- Allow a CLI later as a loop trigger or inspection wrapper.
- Allow a TUI later as a nicer state viewer, but not as a first-phase requirement.
- Allow Telegram as an operational control and notification channel for starting/stopping ticket loops and resolving blockers.
- Allow email later for progress notifications, reports, and less interactive updates.
- Treat Markdown files as primary artifacts.
- Keep state project-local under a hidden directory named from the project.
- Make loops runnable from information stored in project assets.
- Use SQLite as a likely semantic index/query layer over canonical Markdown assets.
- Avoid storing large canonical text chunks in SQLite.
- Support prompt context assembly through combined semantic queries, for example by use case, related concern, priority, and severity.

## Transfer Plan for Another Project

### Phase 1: Protocol and Knowledge Structure

Add:

- `.projectname/AGENTS.md`
- `.projectname/agents/ARCHITECTURE.md`
- `.projectname/agents/CONVENTIONS.md`
- `.projectname/agents/DOCUMENTING.md`
- `.projectname/agents/LIFECYCLE.md`
- `.projectname/agents/ROUTING.md`
- `.projectname/agents/INVARIANTS.md`
- `.projectname/docs/`
- `.projectname/ops/`
- `.projectname/ops/conv/dump/`
- `.projectname/ops/conv/quiz/`
- `.projectname/ops/tickets/`

Goal:

- Make collaboration and memory reusable before building runtime behavior.
- Ensure the system can operate from files before adding CLI/TUI convenience.

### Phase 1b: Hidden Directory Layout

Define the first ergonomic shape of `.<projectname>/`.

Candidate categories:

- `agents/`: agent operating rules and collaboration contracts.
- `docs/`: durable project architecture, conventions, reference, and explanations.
- `ops/specs/`: specs and drafts.
- `ops/tickets/`: lifecycle-managed Markdown tickets.
- `ops/conv/`: dumps, quizzes, and interaction-derived artifacts.
- `ops/playbooks/`: repeatable procedures.
- `context/`: generated or curated context assets.
- `db/`: optional project-local databases.
- `indexes/`: derived indexes such as Go code graphs.

Goal:

- Make the hidden directory navigable without requiring a UI.
- Keep canonical Markdown assets separate from derived indexes.

### Phase 2: Work Item Model

Add a minimal ticket/work-item model with:

- stable human-readable key,
- title,
- description/body,
- status,
- priority,
- assignee,
- scope/type,
- source,
- timestamps,
- resolution/blocking reason,
- comments or operational conversation records.

Goal:

- Create one auditable unit for work and execution.
- Preserve blocker clarification, notifications, and user replies against the ticket.

### Phase 3: Command/Query Boundary

Add:

- command/query envelope,
- result envelope,
- registry/dispatcher,
- explicit unsupported/invalid/error responses.

Goal:

- Prevent transport-specific behavior from becoming business logic.

### Phase 4: Context Capture

Add structured context artifacts:

- raw dumps,
- curated dumps,
- quizzes,
- project protocols,
- operational setup notes.
- codebase indexes,
- file tree snapshots,
- LSP-derived facts,
- Tree-sitter-derived facts,
- Go AST graph facts,
- previous interaction records.

Goal:

- Preserve user intent and project decisions in durable, searchable form.
- Prepare targeted LLM context from assets and indexes instead of broad file reads.

### Phase 4b: Go Code Graph Exploration

Evaluate a Gograph-like layer as a primary Go context engine candidate.

Reference:

- `https://www.bytesizego.com/blog/gograph-a-go-cli-that-parses-your-codebase-for-ai-agents`

Applicable design points from the reference:

- local Go repository index,
- AST-only fast mode that tolerates incomplete code,
- optional precise mode using `go/packages`, SSA, interface checks, and call graph enrichment,
- local JSON graph output,
- Markdown reports,
- query commands such as source, callers, callees, context, hotspot, deps, changes, and path,
- package separation around scanner, parser, graph, search, precise enrichment, MCP, and reports.

Goal:

- Decide whether to build, vendor, wrap, or emulate this kind of Go context graph.
- Decide whether this layer complements Tree-sitter/LSP or eventually replaces them for Go codebases.

### Phase 5: Execution Boundary

Only if needed, add:

- typed primitives,
- workspace boundary,
- output applier,
- validation loop,
- git finalizer,
- runtime bridge.

Goal:

- Support agent execution without losing control over mutation and validation.

### Phase 6: Operational Notifications

Add channel adapters around the asset-driven loop.

Candidate channels:

- Telegram for fast operational control and clarification.
- Email for progress notifications and reports.

Telegram responsibilities:

- start ticket-resolution loops,
- stop or pause loops,
- notify PRs created,
- send diffs or diff summaries,
- report blockers,
- request user answers when a loop is stuck,
- record user responses as ticket comments or related Markdown artifacts.

Email responsibilities:

- progress summaries,
- run reports,
- periodic status,
- lower-urgency notifications.

Goal:

- Keep loops autonomous and asset-driven while giving the user practical control and visibility.

## Tensions and Tradeoffs

- **Completeness vs token cost**: RedWright currently favors rich context; another project may need stricter context budgets earlier.
- **Autonomy vs control**: ticket-first execution adds overhead, but it keeps execution auditable.
- **Worker-side finalization vs host-side finalization**: worker-side push is simpler for proofs; host-side finalization is better for production governance.
- **Rails product surface vs generic runtime**: the Rails app is useful if the other project needs UI and persistence, but the operating model can stand without Rails.
- **Markdown artifacts vs database state**: markdown is faster to bootstrap; database state is better once workflows become product features.
- **File source-of-truth vs query engine**: file-based artifacts are portable and inspectable; richer queries may require SQLite or graph indexing.
- **SQLite vs Dgraph**: SQLite is easy to embed per project; Dgraph is conceptually attractive for relationship-heavy context retrieval but adds operational weight.
- **Portable local tool vs service**: a local Go tool fits the desired shape better than a server-backed product, but advanced LLM context retrieval may pressure the design toward a service or indexer.
- **Core asset loop vs interface loop**: the loop must be defined by files and contracts; CLI/TUI can trigger or inspect it but should not hold unique state.
- **Asset-driven loops vs operational channels**: Telegram and email can trigger, notify, and collect clarifications, but durable state still belongs in Markdown assets.
- **Go graph vs Tree-sitter/LSP**: a Gograph-like AST/graph layer may be a strong complement to Tree-sitter and LSP, and could eventually replace both for Go-focused context.
- **Raw code parsing vs richer semantic indexing**: AST-only parsing is fast and robust during broken builds; precise type-aware enrichment is slower but useful before risky changes.
- **Own graph model vs external tool integration**: a built-in Go graph can align tightly with the portable system; wrapping an existing Gograph-like tool may accelerate the first usable version.
- **Mature ubiquitous tools vs focused Go graph**: LSP and Tree-sitter are mature, widely used primitives; a Gograph-like tool is more directly aligned with the target problem but needs evaluation before becoming architectural foundation.
- **Complement vs repetition**: the unresolved question is whether LSP, Tree-sitter, and a Go graph provide distinct context signals or mostly duplicate each other.

## Assumptions

- The target project needs reusable agent collaboration and context preservation.
- The target project may eventually need agent-assisted execution, but not necessarily on day one.
- The target project should not inherit RedWright's full Rails/runtime complexity unless the use case justifies it.
- The most valuable immediate transfer is workflow structure, not code.
- The target system should run inside or against a single project repository.
- The initial repository type is Go.
- The primary persistence surface should be project-local files.
- Databases, if used, should first be considered derived semantic indexes unless a later decision makes them canonical.
- The first phase can work without a CLI if there is a clear asset contract and a runner can consume it.
- A future CLI/TUI should be replaceable without changing the project state model.
- Telegram and email adapters should be replaceable without changing the core loop or artifact model.
- Go code understanding should treat cheap local static analysis and graph extraction as a primary design axis, not a secondary enhancement.
- No final architecture decision should be made from a shallow reading of Gograph alone.
- Gograph-like indexing is highly aligned with the problem, but its relationship with LSP and Tree-sitter remains an open architecture question.
- SQLite can index use cases, concerns, anchors, references, sections, and semantic relationships while Markdown remains canonical content.

## Derived Threads

- Create a lightweight reusable `.agents` protocol template.
- Create a minimal `ops/` starter kit.
- Define a small command/query envelope for the target project.
- Define a local ticket schema independent of Rails.
- Design a context-section format that can later feed an LLM.
- Decide whether the target project needs a board UI, markdown tickets, or both.
- Decide when agent execution should cross from advisory mode into mutation mode.
- Design the `.projectname` hidden directory layout.
- Define which RedWright database-backed concepts become Markdown files.
- Decide whether SQLite is an optional index/cache.
- Explore Dgraph only as a deliberate context graph decision, not as a default dependency.
- Define Go package boundaries for file artifact management, indexing, context assembly, and command execution.
- Define the minimum asset set required for a loop to run without UI.
- Define CLI commands only after the asset loop contract is clear.
- Define TUI as a read/navigation layer over assets, if it is introduced.
- Define Telegram loop-control semantics.
- Define notification configuration.
- Define ticket comment artifacts for blockers, user responses, PRs, diffs, and operational events.
- Define email reporting boundaries.
- Define a context source taxonomy for agent, project, LSP, Tree-sitter, file tree, previous interactions, and Go graph facts.
- Investigate whether a Gograph-like engine can become the primary Go code context layer.
- Avoid assuming Tree-sitter and LSP are mandatory if the Go graph provides better project-local context.
- Build a comparison matrix for Gograph-like graph context vs LSP vs Tree-sitter.
- Identify which information each source uniquely provides.
- Identify which source produces the most LLM-ready context artifacts.
- Define the Markdown semantic index model for SQLite.
- Define multi-dimensional context query semantics, such as use case plus related concern plus priority plus severity.
- Define how context queries map back to Markdown sections by path and line or byte anchors.

## Possible Downstream Artifacts

- Target-project `AGENTS.md`.
- Target-project `.agents/` protocol pack.
- Target-project `ops/README.md`.
- Target-project `ops/tickets/TEMPLATE.md`.
- Target-project command/query semantic contract.
- Target-project work-item lifecycle contract.
- Target-project context capture guide.
- Target-project execution boundary spec.
- Portable Go tool repository structure proposal.
- CLI naming note for `ChrysoCoord` and `chc`.
- `.projectname` directory contract.
- Markdown artifact schema set.
- Persistence decision record comparing pure files, SQLite, and Dgraph.
- Markdown-plus-SQLite semantic index contract.
- Ticket comments artifact contract.
- Telegram operational channel contract.
- Notification configuration contract.
- Email reporting channel note.
- Context source taxonomy.
- Go code graph/indexing decision record.
- Gograph evaluation note.
- Context engine comparison matrix: Go graph vs LSP vs Tree-sitter.

## Open Questions

- What is the other project?
- Is the first goal protocol/context capture, a UI, or actual agent execution?
- Does the other project already have tickets, issues, or a board?
- Should the other project use markdown artifacts first or database-backed state from the beginning?
- What runtime surfaces matter there: CLI, web, chat, or local agent only?
- Should agent execution be read-only/advisory at first, or allowed to mutate files after validation?
- Should `.projectname` be literal per project name or configurable through a manifest?
- Should Markdown files be the canonical source of truth even if SQLite or Dgraph exists?
- Is Dgraph acceptable as an optional advanced mode, or does "portable" imply no external service dependency?
- Should the first executable surface be a loop runner, a CLI wrapper, a daemon, or a library used by another tool?
- What is the minimal file asset contract needed for autonomous loop execution?
- Which loop states must be encoded in Markdown versus derived at runtime?
- What exact directories should exist in `.<projectname>/` on initialization?
- Should code indexes live under `context/`, `indexes/`, `db/`, or a tool-specific directory?
- Should the Go graph be canonical context or a disposable derived index?
- Should the first graph implementation use Go AST only, a Gograph-like model, LSP, Tree-sitter, or a layered model?
- What would Tree-sitter/LSP still provide if a Gograph-like layer becomes primary?
- Do Gograph-like indexing, Tree-sitter, and LSP complement each other or repeat the same information?
- Which source is best for autonomous loop context preparation, not just human navigation?
- What is the minimum SQLite schema for semantic context queries?
- How should query dimensions such as use case, concern, priority, severity, artifact type, status, and code symbol be represented in Markdown?
- How should context ranking work when multiple artifacts match a combined query?
- What events should Telegram notify by default?
- What retry/time/loop thresholds should trigger a user-facing blocker message?
- Should ticket comments be separate files, sections inside ticket files, or both?
- Which notifications belong in Telegram and which belong in email?
