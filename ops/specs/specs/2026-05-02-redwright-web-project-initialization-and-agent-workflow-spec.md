# RedWright Web Project Initialization and Agent Workflow Specification

## Metadata

- id: `spec-2026-05-02-redwright-web-project-initialization-and-agent-workflow`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-02`
- updated: `2026-05-02`
- scope: `web/project-initialization-and-document-workflow`
- derived_from:
  - `ops/specs/drafts/2026-05-02-redwright-web-project-initialization-and-agent-workflow-draft.md`
  - `ops/tmp/drafts/2026-05-02-redwright-web-project-initialization-and-agent-workflow-spec-source.md`

## Problem Statement

Project initialization, document progression, and agent execution semantics need a unified domain contract for the Rails web system so that repository setup, project context creation, document lifecycle, ticket workflow, and tracking behavior remain deterministic and transport-agnostic.

## Goals

- establish `Project` as explicit top-level context boundary for web execution
- enforce repository-first project initialization ordering
- define the canonical document lifecycle and ownership model
- define ticket/board/tracking semantics without overloading Kanban states
- keep Telegram and future channels aligned to the same command/query contract

## Scope

### In Scope

- web-domain behavior for project initialization
- repository resolution/confirmation/cancellation semantics
- document lifecycle: questionnaire, draft, specification, plan, tracking
- ownership and editability rules per document type
- ticket and board semantics with tracking granularity boundaries
- failure/atomicity expectations for initialization path

### Out of Scope

- final UI design for project CRUD/navigation surfaces
- Telegram transport implementation details
- prompt-copy wording and non-domain UX microcopy
- full migration rollout plan for unrelated legacy features

## Domain Contract

### Project as Root Context

`Project` is the umbrella aggregate for:
- repository linkage
- workspace identity
- documents
- board
- tickets

Minimum identity distinction:
- project display name and filesystem directory/workspace name are separate fields and must not be force-coupled.

### Document Taxonomy

Logical document classes:
- questionnaire
- draft
- specification
- plan
- tracking

Documents are first-class project artifacts and may be referenced by tickets.

### Ownership and Editability Rules

- questionnaire:
  - shared participation (agent asks, user answers, agent normalizes)
  - visible artifact
- draft:
  - user-editable correction point
- specification:
  - agent-generated, user-visible, read-only in normal flow
- plan:
  - agent-generated, user-visible, read-only in normal flow
- tracking:
  - agent-owned, user-visible, read-only

### Lifecycle Correlation

Primary progression:

`Questionnaire -> Draft -> Specification -> Plan -> Tracking`

This is a strong correlation, not an unconditional hard requirement for all flows. Guided alignment can be skipped by explicit user decision.

Plan-to-tracking mapping should remain one-to-one at task/slice granularity.

### Ticket and Board Semantics

- tickets represent Kanban-level work units and may reference full document chains
- tracking captures internal granular progress
- board movement occurs at meaningful workflow boundaries, not every tracking update

## Initialization Contract

### Canonical Ordering

Required sequence:
1. receive project creation intent and name
2. request repository information
3. validate/infer/confirm repository input
4. if cancellation intent, abort without side effects
5. create/attach repository
6. create project/workspace only after repository resolution succeeds
7. ask guided alignment opt-in
8. if declined, finish initialization without questionnaire
9. if accepted, execute adaptive questionnaire flow

### Repository Requirement

Repository resolution is mandatory for initialization completion.

Supported forms may include URL/repository identifiers per current system capability. If input is ambiguous, system must enter a focused clarification loop for repository resolution only.

### Cancellation Semantics

Cancellation intent during repository resolution must abort:
- repository creation
- project creation
- workspace creation
- document creation
- alignment flow

### Atomicity and Failure Handling

Initialization should be atomic as far as infrastructure allows. If partial success occurs, system must provide explicit reconciliation or failed/incomplete status visibility; hidden half-created states are not acceptable.

### Optional Skip Flag (Future)

A future flag (for example `--no-alignment`) may skip guided alignment only. It must not bypass repository resolution.

## Query and Command Boundary

Web and Telegram must converge on the same domain-level commands/queries for:
- project initialization
- repository resolution
- document lifecycle transitions
- ticket state and tracking progression

Transport-specific behavior must not fork domain semantics.

## Acceptance Criteria

1. A formal initialization sequence exists with repository-first semantics and explicit cancellation behavior.
2. Document lifecycle and ownership/editability rules are explicit and non-ambiguous.
3. Ticket/board/tracking behavior boundaries are explicit and compatible with existing Kanban semantics.
4. Failure-state/atomicity expectations are codified for partial initialization scenarios.
5. Spec is implementation-ready as input for slice planning without relying on prompt-level interpretation.

## Open Questions

- Should questionnaire persistence be editable artifact, immutable structured record, or hybrid model?
- Which state model should represent partial initialization failures (`failed`, `incomplete`, `needs_reconcile`)?
- Are any controlled exceptions needed for plan editability with provenance logging?
- Which command/query layer should be formalized first to guarantee web/transport parity?

