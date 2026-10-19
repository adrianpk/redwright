# Portable Project Directory Layout

Historical capture from 2026-05-17. Repository structure, capabilities, and
proposals below describe that snapshot; they do not define current behavior.

## Metadata

- date: `2026-05-17`
- status: `draft`
- topic: portable project-local hidden directory layout
- provisional root name: `.projectname/`
- working command/product name: `ChrysoCoord`
- CLI command: `chc`

## Intent

Define an ergonomic hidden project-local directory for a portable, file-based RedWright-inspired system.

The directory should support autonomous loops from stored assets. CLI and TUI surfaces may later dispatch or inspect loops, but they must not become the source of truth.

The working system name is `ChrysoCoord`. The CLI command is `chc`.

Name origin:

- `Chryso` comes from Chrysocolla, a cyan/turquoise mineral stone close to Go's visual language.
- `Coord` comes from coordination/coordinator.
- The name should evoke a distributed runtime coordinating agents, workers, or cooperating nodes.

## Constraints

- No web UI.
- No official UI surface in the first phase.
- Markdown artifacts are first-class.
- State should be project-local.
- The system is implemented in Go.
- The first target codebases are Go projects.
- Prefer one or two directory levels.
- Avoid deeper nesting unless a later workflow proves it is necessary.

## Proposed Layout

```text
.projectname/
  manifest.md
  config.yml

  agents/
    AGENTS.md
    ARCHITECTURE.md
    CONVENTIONS.md
    INVARIANTS.md
    PLAYBOOKS.md
    ROUTING.md

  docs/
    architecture.md
    conventions.md
    glossary.md
    project.md
    runtime.md

  specs/
    drafts/
    accepted/
    archived/

  tickets/
    open/
    ready/
    in_progress/
    reviewing/
    blocked/
    solved/
    closed/

  comments/
    tickets/

  context/
    agent.md
    project.md
    file-tree.md
    interactions.md
    code-graph.md
    lsp.md
    treesitter.md

  dumps/
    raw/
    curated/

  quizzes/
    raw/
    curated/

  playbooks/
    default.md
    validation.md
    refactor.md
    release.md

  reports/
    runs/
    audits/

  indexes/
    code-graph/
    sqlite/
    dgraph/

  runtime/
    runs/
    locks/
    traces/

  notifications/
    telegram.md
    email.md
```

## Directory Responsibilities

### Root Files

`manifest.md` describes the project identity, workspace assumptions, and current operating status.

`config.yml` stores local tool configuration. It should not contain secrets.

### `agents/`

Agent and collaboration rules.

This directory is the portable equivalent of RedWright's `AGENTS.md` and `.agents/` protocol set.

### `docs/`

Durable project knowledge.

Examples:

- architecture overview,
- conventions,
- glossary,
- runtime notes,
- stable project explanations.

### `specs/`

Formal and semi-formal work definitions.

Suggested states:

- `drafts/`
- `accepted/`
- `archived/`

### `tickets/`

Operational work items.

Tickets are the main loop unit.

Suggested lifecycle:

- `open/`
- `ready/`
- `in_progress/`
- `reviewing/`
- `blocked/`
- `solved/`
- `closed/`

### `comments/`

Durable operational conversation records.

Initial use:

- ticket comments,
- blocker clarifications,
- user replies,
- PR notifications,
- diff summaries,
- loop progress notes.

Ticket comments may later move inside ticket files if that proves more ergonomic, but a separate comment area keeps high-volume operational conversation from making ticket files too noisy.

### `context/`

Curated or generated context assets prepared for LLM use.

Initial context files:

- `agent.md`
- `project.md`
- `file-tree.md`
- `interactions.md`
- `code-graph.md`
- `lsp.md`
- `treesitter.md`

The Go code graph may eventually replace or reduce the need for LSP and Tree-sitter context, but that remains undecided.

### `dumps/`

Free-form conversation and knowledge captures.

Suggested subdirectories:

- `raw/`
- `curated/`

### `quizzes/`

Question-driven context capture.

Suggested subdirectories:

- `raw/`
- `curated/`

### `playbooks/`

Repeatable operating procedures.

Examples:

- validation,
- refactor,
- release,
- default loop behavior.

### `reports/`

Human-readable outputs from runs, audits, and cycle summaries.

Suggested subdirectories:

- `runs/`
- `audits/`

### `indexes/`

Derived indexes and query accelerators.

Candidates:

- `code-graph/`
- `sqlite/`
- `dgraph/`

These should be treated as derived or optional at first, not canonical state.

### `runtime/`

Transient or operational execution state.

Suggested subdirectories:

- `runs/`
- `locks/`
- `traces/`

Runtime state may be partly ephemeral. Durable outcomes should be promoted into tickets, reports, specs, dumps, or context assets.

### `notifications/`

Channel configuration and notification policy notes.

Initial files:

- `telegram.md`
- `email.md`

Telegram is intended for fast loop control, blocker clarification, and operational notifications.

Email is intended for progress summaries, reports, and lower-urgency notifications.

## Source-of-Truth Rule

Canonical state should begin as Markdown files.

Indexes, SQLite databases, Dgraph data, traces, and runtime files should initially be treated as derived, rebuildable, or operational artifacts unless a later decision record promotes one of them to canonical state.

## Markdown Plus SQLite Index Direction

The preferred persistence shape is emerging as:

```text
Markdown files = canonical content
SQLite = semantic index, references, query dimensions, and retrieval layer
```

SQLite should not store large canonical text chunks. It should store enough information to query and retrieve the right Markdown artifacts or sections.

Likely indexed concepts:

- artifact path,
- artifact type,
- stable id,
- title,
- status,
- use case,
- concerns or themes,
- priority,
- severity,
- comments,
- notification events,
- frontmatter,
- section anchors,
- line or byte ranges,
- links,
- references,
- related code symbols,
- run/report pointers,
- semantic edges.

Prompt context assembly can then run combined queries, for example: retrieve material for use case `X`, related to concern `Y`, with priority `A`, and severity `B`. The query result points back to canonical Markdown sections.

## Open Questions

- Should `.projectname` be literal or configured from a manifest?
- Should `config.yml` be YAML, TOML, or Markdown frontmatter?
- Should `context/` contain individual Markdown files or subdirectories per context source?
- Should `indexes/` live under `context/` instead?
- Should `runtime/` be committed, ignored, or split between committed and ignored paths?
- Which files are required for a loop to run with no UI?
- What is the minimum SQLite schema for querying Markdown artifacts by use case, concern, priority, severity, references, and semantic relationships?
- Should query dimensions live in frontmatter, inline Markdown, or both?
- Should ticket comments be separate files under `comments/tickets/`, sections inside ticket files, or both?
- Should notification policy live in Markdown, config, or both?
- Which Telegram events are default-on versus configurable?
