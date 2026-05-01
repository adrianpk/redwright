# RedWright Document Canvas and Ticket Reference Model Specification

## Metadata

- id: `spec-2026-05-01-redwright-document-canvas-and-ticket-reference-model`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-01`
- updated: `2026-05-01`
- scope: `web/document-canvas-and-ticket-reference-model`
- derived_from:
  - `ops/specs/drafts/2026-05-01-redwright-document-canvas-and-ticket-reference-model-draft.md`
  - `ops/specs/drafts/2026-05-01-redwright-document-canvas-and-ticket-reference-model-conv.md`

## Problem Statement

Ticket payloads are overloaded when implementing full feature sets. The system needs richer artifacts while preserving ticket-first execution.

## Goals

- introduce first-class artifacts: `draft`, `spec`, and `plan_tracker`
- keep tickets as the only execution trigger
- allow tickets to reference any of those artifacts
- preserve explicit lineage and cross-reference traversal among artifacts
- provide phase-one read surfaces in the web app

## Phase-One Decisions

- `plan_tracker` is agent-owned and read-only in UI for phase one.
- ticket references are optional; tickets can exist without references.
- minimum phase-one CRUD:
  - `draft`: `create/read/update/list`
  - `spec`: `read/list` plus promotion from `draft`
  - `plan_tracker`: `read/list`

## Phase-One Scope

### In Scope

- persistence schema for document artifacts and ticket links
- draft creation/editing/read/listing
- draft-to-spec promotion path
- read/list for `spec` and `plan_tracker`
- artifact interrelations enabling navigation from one artifact to related artifacts
- ticket references to artifacts as optional links

### Out of Scope

- conversational in-app authoring loops
- replacing tickets as execution trigger
- user editing of `plan_tracker` in UI (phase one)

## Domain Contract

### Artifact Types

- `draft`
- `spec`
- `plan_tracker`

### Artifact Lineage and Relations

- each artifact has a stable id and type
- a `spec` promoted from `draft` must keep `source_draft_id`
- artifact relations allow linking `draft <-> spec`, `spec <-> plan_tracker`, and additional typed references
- given any artifact, the system can resolve related artifacts through relation edges

### Ticket References

- tickets may reference zero or more artifacts
- a reference stores ticket id, artifact id, and optional relation role
- reference creation does not alter ticket execution semantics

## UI Contract (Phase One)

- add document-canvas entry in top navigation aligned with existing style language
- provide artifact list and detail screens for all types
- draft detail supports edit/update
- spec and plan_tracker detail are read-only in phase one

## Acceptance Criteria

1. Artifact schema supports three types, lineage metadata, and typed interrelations.
2. Draft CRUD (`create/read/update/list`) is functional via web surface.
3. Spec can be created only through draft promotion in phase one.
4. Spec and plan_tracker are readable/listable but not editable in phase one.
5. Tickets can optionally reference artifacts without changing ticket execution behavior.
6. A related-artifact view can navigate to linked documents from any artifact detail.
7. UI includes a simple top navigation entry for document canvas, visually aligned to existing app style.

## Forward-Looking Notes

- `spec` editing can be enabled in later phases once governance rules are defined.
- `plan_tracker` may become collaborative in later phases with explicit ownership controls.
