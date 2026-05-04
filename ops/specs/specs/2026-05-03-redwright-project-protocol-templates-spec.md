# RedWright Project Protocol Templates Specification

## Metadata

- id: `spec-2026-05-03-redwright-project-protocol-templates`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- scope: `rails-core/project-protocols/template-seeding/filesystem-materialization/agent-guidance`
- derived_from:
  - `ops/specs/drafts/2026-05-03-redwright-project-protocol-templates-draft.md`
  - `ops/specs/conv/2026-05-03-redwright-project-protocol-templates-conv.md`

## Problem Statement

RedWright needs a project-level operational instruction system for agents that is persistent, editable, and reusable across projects without forcing users to hand-author the same guidance every time.

Today, practical agent guidance already exists in repositories as `AGENTS.md` and related files under `.agents/`. That pattern works for Codex-style agent operation, but it is not yet a first-class product concept inside Rails. The current gap is that project setup can create a project, workspace, and later runtime recipe, but it does not yet create or manage the project's operational protocol as structured product state.

RedWright also needs that protocol state to remain compatible with external tools that operate directly on cloned repositories. This means the system cannot stop at Rails persistence alone. It must also materialize repository files automatically so external agents can operate against the same protocol shape.

## Goals

- make `Protocols` a first-class project area in Rails
- model a Project Protocol as a family of operational Markdown documents rather than a single monolithic blob
- keep Rails persistence as the canonical source of truth
- materialize protocol files automatically into repository-root `AGENTS.md` and `.agents/*`
- generate an initial Project Protocol during `/project new`
- apply common behavior templates by default
- apply stack-specific templates when available, including multiple overlays when the real project shape requires them
- synthesize a minimal project protocol when no suitable stack template exists
- keep `AGENTS.md` lightweight and relatively uniform across projects
- keep most project and stack variation in `.agents/*`
- preserve file-level addressability so users and agents can reference a specific playbook or protocol file
- support future near-term CRUD for common templates and stack templates without forcing that administration surface into the first project-facing slice

## Non-Goals

- Runtime Containers readiness gating
- hook-based protocol enforcement
- Anthropic-specific harness-control strategies
- bidirectional sync from repository files back into Rails
- user-facing provenance inspection in the first slice
- protocol regeneration as a first-slice user action
- non-blocking review-status layers after setup
- exhaustive template coverage across all technologies
- final persistence schema or controller design

## Product Concept

`Protocols` is the project-specific operational guidance surface for agents and LLMs.

It is distinct from `Documents`.

- `Documents` hold project and feature information.
- `Protocols` hold operational guidance that shapes how agents work in that project.

It is also distinct from `Runtime Containers`.

- `Runtime Containers` define where agent work executes.
- `Protocols` define how agent work should be carried out.

The first implementation should stay close to the working repository pattern already used successfully in this project:

- `AGENTS.md`
- `.agents/`
- `.agents/*.md`
- `PLAYBOOKS.md` as an index over concrete playbooks

The goal is not to claim that this is the final ideal protocol topology. The goal is to automate a familiar, proven operating shape with minimal friction.

## Project Protocol Contract

Each project must own one concrete editable Project Protocol.

That Project Protocol must be represented as a document family, not only as one text field.

Minimum behavioral expectations:

- `AGENTS.md` always exists
- `AGENTS.md` is the canonical root entrypoint
- `AGENTS.md` stays lightweight and broadly homogeneous across projects
- detailed and variable guidance lives primarily under `.agents/*`
- `PLAYBOOKS.md` exists as a generated index over concrete playbook files
- playbooks remain individually addressable files

The first implementation should keep the same baseline file skeleton for every project.

Variation should happen through content, not through frequent changes to which files exist.

## Protocol Document Modeling

Rails must not treat the filesystem projection as the only place where protocol structure exists.

The Rails-side model must carry a meaningful counterpart for the protocol family, including at least:

- document identity
- ordering
- Markdown content
- whether the document is part of the common or behavioral layer versus the stack-specific layer
- document-level provenance

This distinction should not be left entirely to ad hoc inference from file names or content, even if the projected files make the difference intuitively visible.

## Template Layers

The protocol system needs three conceptual layers:

1. common behavior guidance
2. stack-oriented overlays
3. project-specific editable copy

Common behavior guidance covers stable expectations such as:

- execution discipline
- collaboration invariants
- lifecycle
- documenting rules
- routing rules
- slicing and handoff expectations

Stack-oriented overlays cover language, framework, and subsystem expectations such as:

- conventions
- architecture boundaries
- test, lint, and build expectations
- framework-specific operational rules

The first product-facing surface does not need to expose separate CRUD for common and stack templates yet, but that follow-up should remain near-term rather than distant backlog.

## Setup Contract

`/project new` must always create an initial Project Protocol.

The first slice should not create a project without protocols and should not introduce a proposal-review stage before the protocol becomes active.

Setup should:

- create the project record in Rails
- derive the Project Protocol from common behavior defaults
- apply stack overlays when available
- allow multiple overlays when the real project shape requires them
- synthesize minimal project-specific protocol content when stack coverage is missing
- persist the Project Protocol in Rails
- materialize the protocol files in the project workspace

Unknown or unsupported stacks must not result in missing protocol files.

When template coverage is missing, a minimal generated protocol is preferable to empty or omitted guidance.

## Filesystem Materialization

Filesystem materialization is part of the first formal scope.

Rails remains the source of truth. The repository files are a one-way operational projection in the first phase.

Required expectations:

- protocol files are written automatically when the project is created
- protocol files are updated automatically when the Rails-backed Project Protocol changes
- protocol files live at the repository root and under `.agents/`, matching the current working pattern exactly
- users are not asked to run a manual sync step

Manual edits to projected files may exist for external-tool usage, but they are not canonical. Later Rails-side edits may overwrite them.

No re-import contract is required in the first phase.

## Guidance Semantics

Protocols are strong operational guidance, not a hard readiness gate in this iteration.

The expected operating model is similar to how Codex follows `AGENTS.md` and related files in this repository today.

This specification intentionally does not depend on hook-based enforcement.

That boundary is not framed as hostility toward Anthropic services. It is a practical platform decision: RedWright should not base this part of the software factory on agent ecosystems that appear less compatible with harness-style systems.

## UX Direction

The first Protocols UX should be:

- document-oriented
- Markdown-based
- opinionated
- low-configuration

The first project-facing surface should focus on editing the concrete Project Protocol attached to a project.

It should not initially expose:

- explicit provenance controls
- protocol regeneration actions
- protocol review-status layers
- high-configurability composition controls

This is an ergonomics choice, not a restriction for its own sake. The system should help users operate with fewer levers, not push them into a configuration-heavy interface.

## Playbook Policy

The first version should materialize the full baseline playbook set for every project.

It should not attempt to infer which playbooks are "necessary" per project during the first slice.

The baseline playbook set itself should remain stable across projects in the first phase. Predictability and homogeneity are preferred over early optimization.

The value of the playbook split is not only structural. It also supports targeted file references, for example:

- read only `AGENTS.md`
- read `AGENTS.md` and referenced files
- read one specific playbook

This reduces unnecessary context filler for agent interactions.

## Initial Stack Seeds

Initial stack-template seeds should reflect the real working stacks of the core development team rather than pretending to be exhaustive.

The initial seed candidates are:

- `Go`
- `Ruby`
- `TypeScript`
- `Elixir`
- `Gleam`
- `Zig`
- `Rust`
- `Rails`
- `Angular`

Coverage quality may be uneven across those seeds because team familiarity is uneven. That is acceptable for the first phase. Future template CRUD should let users refine or extend stack coverage according to their own needs.

## Acceptance Criteria

1. Rails exposes `Protocols` as a distinct project area from `Documents`.
2. Each project owns one concrete Project Protocol represented as multiple Markdown documents.
3. `/project new` always creates a Project Protocol.
4. Rails persists Project Protocol state as the canonical source of truth.
5. Rails models protocol documents with at least identity, ordering, Markdown content, document-level provenance, and common-versus-stack distinction.
6. The first Project Protocol uses a stable baseline file skeleton across projects.
7. `AGENTS.md` is always present and acts as the canonical root document.
8. `AGENTS.md` remains lightweight, with most variation pushed into `.agents/*`.
9. `PLAYBOOKS.md` is generated as an index over concrete playbook files.
10. The baseline playbook set is materialized for every project in the first phase.
11. Project setup applies common behavior defaults and available stack overlays.
12. Project setup can apply multiple stack overlays when the project shape requires them.
13. Missing stack-template coverage produces minimal synthesized protocol content rather than missing protocols.
14. Protocol files are materialized automatically into the repository root and `.agents/`.
15. Protocol file projection is one-way from Rails to filesystem in the first phase.
16. The first editing surface is Markdown-oriented and focused on concrete Project Protocols.
17. The first slice does not require protocol review states, hook-based enforcement, or explicit regeneration actions.
18. The initial stack-template seeds include the agreed reference set and are treated as intentionally selective rather than exhaustive.
