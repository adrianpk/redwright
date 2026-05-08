# RedWright Web Project Initialization and Agent Workflow

## Status
Draft

## Source Context
- Preserved source (non-versioned area):
  - `ops/tmp/drafts/2026-05-02-redwright-web-project-initialization-and-agent-workflow-spec-source.md`
- Scope focus:
  - Rails web interface and its domain behavior.
  - Telegram as future transport over shared domain commands/queries.

## Scope
- Define the project-centered domain workflow for web initialization and execution.
- Define document lifecycle and ownership rules across Draft, Spec, Plan, Tracking, and Questionnaire.
- Define project initialization order with repository-first semantics and guided alignment opt-in.

## Working Notes

### 1) Product Root and Domain Orientation
- provisional_status: `keep`
- current issue:
  - Domain behavior exists but has fragmented narrative across features.
- desired behavior:
  - `Project` is explicit top-level context for repository, board, tickets, documents, and agent execution.
  - Web UI is primary implementation target; transport parity is deferred but contract-compatible.

### 2) Project Identity Contract
- provisional_status: `keep`
- current issue:
  - Project naming and workspace naming are often conflated.
- desired behavior:
  - Keep distinct concepts:
    - project display name
    - filesystem/workspace directory name
  - Do not force identity equality between display and directory names.

### 3) Document-Centered Workflow
- provisional_status: `keep`
- current issue:
  - Ticket-level context can become overloaded without document references.
- desired behavior:
  - Documents remain first-class project artifacts.
  - Tickets reference documents rather than embedding large context directly.
  - Logical document set includes:
    - questionnaire
    - draft
    - specification
    - plan
    - tracking

### 4) Ownership and Editability Contract
- provisional_status: `keep`
- desired behavior:
  - Questionnaire:
    - shared participation (agent asks, user answers, agent normalizes)
    - visible artifact
  - Draft:
    - user-editable correction point
  - Specification:
    - agent-generated, user-visible, read-only in normal flow
  - Plan:
    - agent-generated, user-visible, read-only in normal flow
  - Tracking:
    - agent-owned, user-visible, read-only

### 5) Document Lifecycle Correlation
- provisional_status: `keep`
- desired behavior:
  - Primary progression:
    - `Questionnaire -> Draft -> Specification -> Plan -> Tracking`
  - Correlation is strong but not unconditional; guided steps may be skipped when user opts out.
  - Plan-to-tracking linkage should remain one-to-one for granular execution visibility.

### 6) Ticket and Board Semantics
- provisional_status: `keep`
- desired behavior:
  - Tickets are Kanban-level work items and may reference full planning chain documents.
  - Tracking granularity should not force frequent board column moves.
  - Board movement stays at meaningful workflow boundaries.

### 7) Project Initialization Ordering (Repository First)
- provisional_status: `keep`
- desired behavior:
  - Required order:
    1. receive project creation intent/name
    2. request repository information
    3. validate/infer/confirm repository details
    4. abort completely on cancellation
    5. create/attach repository
    6. create project/workspace only after repository resolution
    7. ask guided alignment opt-in
    8. skip questionnaire if user declines
    9. run adaptive questionnaire if user accepts
  - Repository resolution is mandatory.
  - Guided alignment is optional.

### 8) Ambiguity and Cancellation Handling
- provisional_status: `keep`
- desired behavior:
  - Ambiguous repository input must enter a focused clarification loop.
  - Clarification scope should resolve repository ambiguity only.
  - Cancellation intent must abort all side effects:
    - no repository creation
    - no project creation
    - no workspace creation
    - no document generation
    - no alignment flow

### 9) Atomicity and Failure Model
- provisional_status: `keep`
- desired behavior:
  - Repository resolution and project creation should be atomic as far as infrastructure allows.
  - If partial success occurs, explicit reconciliation or failed/incomplete markers are required.
  - Avoid hidden half-created project states.

### 10) Optional Alignment Skip Flag
- provisional_status: `explore`
- desired behavior:
  - Future slash-flag support (for example `--no-alignment`) may skip guided alignment only.
  - Must not bypass mandatory repository resolution.

## Open Questions
- Should questionnaire be persisted as full editable document or as structured immutable artifact plus derived draft?
- Which exact state model should represent partial initialization failures?
- Should plan editability remain hard read-only, or allow controlled exceptions with provenance?
- Which command/query contracts should be promoted first to guarantee web/telegram parity without duplicated logic?

## Out of Scope
- Final UI layout for project CRUD/navigation surfaces.
- Transport implementation details for Telegram interaction wiring.
- Prompt-level tuning details unrelated to domain command/query contract.

## Next Iteration Inputs
- Convert this draft into canonical spec + quiz pair under `ops/specs/specs` and `../../conv/quiz/*-quiz.md`.
- Derive execution slices for:
  - project initialization command/query contract
  - questionnaire persistence model
  - draft/spec/plan/tracking orchestration boundaries
  - failure-state and rollback/reconciliation behavior.
