# Project Context Umbrella Model

## Status
Draft

## Conversation
- `../conv/2026-05-02-project-context-umbrella-model-conv.md`

## Scope
- Define a first operational model where `Project` becomes the root context for boards, tickets, and documents.
- Establish a flexible metadata strategy that avoids early schema rigidity.
- Define pragmatic rollout phases to reduce migration risk.

## Source Context
- Current runtime behavior exposes boards, tickets, and documents without a shared project umbrella.
- Brainstorming identified a need for a stable root context and faster context retrieval for agent workflows.
- The model should stay practical for the current single-repo operating style while preparing for broader use.

## Working Notes

### 1) Root Aggregate: Project
- provisional_status: `keep`
- current issue:
  - Boards, tickets, and documents are operationally useful but context-fragmented.
  - There is no single anchor to express project identity and baseline constraints.
- desired behavior:
  - Introduce `Project` as umbrella aggregate and primary context boundary.
  - Minimal core fields:
    - `name`
    - `description`
    - `root_path`
    - `repo_url`
    - `stack_slug`

### 2) Dynamic Project Attributes
- provisional_status: `keep`
- current issue:
  - Hard-coding many project descriptors in a fixed schema creates early rigidity.
- desired behavior:
  - Add `project_attributes` as a dynamic one-to-many structure.
  - Proposed fields:
    - `project_id`
    - `key`
    - `value`
    - `weight` (1..5)
    - `source`
    - `updated_at`
  - Weight is a ranking aid for context prioritization (for example: stack > framework > libraries > conventions).

### 3) Association Strategy
- provisional_status: `keep`
- current issue:
  - Entity relationships are not optimized for fast context-scoped lookup.
- desired behavior:
  - `boards.project_id`: required.
  - `documents.project_id`: required.
  - `tickets.project_id`: phased strategy.

### 4) Ticket Project Link Phasing
- provisional_status: `keep`
- current issue:
  - Immediate duplication of `project_id` in tickets may be premature.
- desired behavior:
  - Phase 1: derive ticket project through board relationship.
  - Phase 2: optionally persist `tickets.project_id` for query-speed if operationally justified.
  - If persisted, enforce consistency with `boards.project_id`.

### 5) Context Partitioning vs Tenant Semantics
- provisional_status: `keep`
- current issue:
  - The design must avoid conflating context partitioning with full multi-tenancy.
- desired behavior:
  - Treat project scoping as context partitioning, not tenant isolation.
  - Keep model explicit to avoid over-architecting.

## Open Questions
- Should `project_attributes.key` be globally normalized or free-form with conventions only?
- Should `weight` be user-authored, agent-authored, or mixed with source traceability?
- Which integrity layer owns `ticket.project_id == board.project_id` validation if ticket-level project id is introduced?
- Which existing tables require backfill first for safe incremental rollout?

## Out of Scope
- Full migration plan and rollback choreography.
- UI details for project selection/navigation.
- Policy decisions for multi-tenant security boundaries.

## Next Iteration Inputs
- Convert this draft into a stable spec with explicit schema proposal and migration sequence.
- Define validation invariants and ownership boundaries (model vs service layer).
- Define query patterns required by agent runtime flows before locking table/index details.
