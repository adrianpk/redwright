# RedWright Project Context Umbrella Model Specification

## Metadata

- id: `spec-2026-05-02-redwright-project-context-umbrella-model`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-02`
- updated: `2026-05-02`
- scope: `web/project-context-model`
- derived_from:
  - `ops/specs/drafts/2026-05-02-project-context-umbrella-model-draft.md`
  - `ops/specs/drafts/2026-05-02-project-context-umbrella-model-conv.md`

## Problem Statement

Boards, tickets, and documents currently operate without a stable project umbrella, which fragments context and increases lookup complexity for both users and runtime workflows.

## Goals

- introduce `Project` as first-class context root
- associate boards and documents directly to project
- define phased strategy for ticket project binding
- enable dynamic project metadata without rigid schema expansion
- preserve fast project-scoped queries for runtime orchestration

## Scope

### In Scope

- `projects` domain model and persistence
- dynamic `project_attributes` model with weighted relevance
- required `project_id` on boards and document artifacts
- phased contract for ticket project linkage
- integrity invariants for project consistency

### Out of Scope

- multi-tenant security model
- project-switching UX flows
- conversational loop behavior details for `/project new`

## Domain Contract

### Project

Required fields:
- `name`
- `description`
- `root_path`
- `repo_url`
- `stack_slug`

### Project Attributes

- one-to-many dynamic metadata keyed by `project_id`
- fields:
  - `key`
  - `value`
  - `weight` (`1..5`)
  - `source`
  - `updated_at`

Interpretation:
- `weight` indicates relevance priority for runtime context composition
- `source` captures provenance (`user`, `agent`, `system`)

### Entity Association Rules

- `boards.project_id` is required
- `document_artifacts.project_id` is required
- ticket linkage is phased:
  - phase one: project inferred via `tickets.board_id -> boards.project_id`
  - phase two: optional direct `tickets.project_id` for query acceleration

### Consistency Invariants

If phase-two ticket linkage is enabled:
- `tickets.project_id` must match `boards.project_id`
- updates that move ticket across boards must preserve project consistency

## Query Contract

- project-scoped lookup must be supported for:
  - boards
  - tickets (derived in phase one, direct in phase two if enabled)
  - document artifacts
  - project attributes ordered by relevance

## Delivery Policy

- plan/tracker are initially agent-owned operational artifacts
- editing policy may be opened later with explicit governance

## Acceptance Criteria

1. `Project` persistence and model exist with required fields and validations.
2. `project_attributes` persistence exists with key/value/weight/source contract and validation for weight range.
3. Boards and document artifacts require valid `project_id`.
4. Ticket project context is available through board derivation in phase one.
5. Optional phase-two direct `tickets.project_id` path is specified with invariants and tests when implemented.
6. Runtime can produce project-scoped context without ambiguous ownership.

## Open Questions

- should `project_attributes.key` remain free-form or move to a constrained catalog?
- when should phase-two `tickets.project_id` be activated based on measured query pressure?
- should weight be editable by users, agents, or both in initial UI/API surface?
