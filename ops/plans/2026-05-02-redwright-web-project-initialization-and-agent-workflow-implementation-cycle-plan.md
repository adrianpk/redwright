# Cycle Plan: RedWright Web Project Initialization and Agent Workflow Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-web-project-initialization-and-agent-workflow`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-02`
- updated: `2026-05-02`
- goal: `implement repository-first project initialization and document-owned agent workflow contract in web domain`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-02-redwright-web-project-initialization-and-agent-workflow-spec.md`

## Slice List

### Slice 1: Project Initialization Domain Command Contract

- status: `pending`
- branch: `fix/slice-1-project-init-domain-command-contract`
- objective: `introduce explicit project initialization command contract and orchestration entrypoint`
- tasks:
- [ ] `T1.1 define project initialization command input/output contract`
- [ ] `T1.2 implement repository-first orchestration service skeleton`
- [ ] `T1.3 add unit tests for command validation and deterministic command result shape`
- acceptance:
- `project initialization has an explicit command boundary with deterministic result contract`
- planned_commits:
- `feat(web): add project initialization command contract`
- `test(web): cover project initialization command contract`

### Slice 2: Repository Resolution, Ambiguity, and Cancellation Semantics

- status: `pending`
- branch: `fix/slice-2-repository-resolution-and-cancellation`
- objective: `enforce repository-first resolution with explicit ambiguity and cancellation handling`
- tasks:
- [ ] `T2.1 implement repository resolver for explicit/implicit repository inputs`
- [ ] `T2.2 implement focused ambiguity clarification result states`
- [ ] `T2.3 implement cancellation semantic path with no-side-effect guarantee`
- acceptance:
- `repository ambiguity and cancellation outcomes are explicit and test-covered`
- planned_commits:
- `feat(web): enforce repository resolution before project creation`
- `test(web): cover repository ambiguity and cancellation semantics`

### Slice 3: Atomic Initialization and Failure-State Reconciliation

- status: `pending`
- branch: `fix/slice-3-atomic-initialization-failure-reconciliation`
- objective: `codify atomicity behavior and explicit failure/incomplete state handling`
- tasks:
- [ ] `T3.1 define initialization transaction boundary and reconciliation hooks`
- [ ] `T3.2 implement explicit failed/incomplete outcome states for partial success paths`
- [ ] `T3.3 add regression tests for partial repository/project/workspace failures`
- acceptance:
- `partial initialization states are explicit, observable, and safe`
- planned_commits:
- `feat(web): add initialization atomicity and reconciliation states`
- `test(web): cover initialization failure and rollback paths`

### Slice 4: Document Lifecycle and Ownership Policy Enforcement

- status: `pending`
- branch: `fix/slice-4-document-lifecycle-ownership-enforcement`
- objective: `enforce lifecycle and editability boundaries for questionnaire/draft/spec/plan/tracking`
- tasks:
- [ ] `T4.1 add lifecycle state/transition guards for document progression`
- [ ] `T4.2 enforce ownership and editability policy (draft editable, spec/plan/tracking read-only)`
- [ ] `T4.3 add tests for allowed/blocked transitions and policy enforcement`
- acceptance:
- `document lifecycle and ownership rules are enforced in domain behavior`
- planned_commits:
- `feat(web): enforce document lifecycle and ownership policy`
- `test(web): cover document lifecycle and editability invariants`

### Slice 5: Ticket-Document-Tracking Integration Semantics

- status: `pending`
- branch: `fix/slice-5-ticket-document-tracking-integration`
- objective: `bind ticket semantics to document chain and keep board movement at meaningful boundaries`
- tasks:
- [ ] `T5.1 enforce ticket references to document chain entities with project consistency`
- [ ] `T5.2 add tracking progress integration without forced board state churn`
- [ ] `T5.3 add tests for ticket/board/tracking boundary semantics`
- acceptance:
- `tracking granularity and board status semantics stay decoupled and consistent`
- planned_commits:
- `feat(web): align ticket-board-tracking workflow semantics`
- `test(web): cover ticket document-chain and tracking boundary behavior`

### Slice 6: Web Entry Flow and Operational Closure

- status: `pending`
- branch: `fix/slice-6-web-entry-flow-and-closure`
- objective: `wire web entry flow to new domain commands and close cycle with full validation evidence`
- tasks:
- [ ] `T6.1 connect web project creation entrypoint to initialization command service`
- [ ] `T6.2 add guided alignment opt-in/opt-out behavior after successful repository resolution`
- [ ] `T6.3 run full validation and coverage matrix, update tracker with merged PR evidence`
- acceptance:
- `web entry behavior follows repository-first contract and cycle evidence is auditable`
- planned_commits:
- `feat(web): wire project initialization web flow to domain command contract`
- `docs(ops): close project initialization workflow cycle with validation evidence`

## Global Exit Criteria

- `repository resolution is mandatory and evaluated before project creation`
- `ambiguity and cancellation outcomes are explicit and side-effect-safe`
- `partial initialization failures are visible with reconciliation-safe states`
- `document lifecycle ownership policy is enforced and test-covered`
- `ticket/board/tracking behavior boundaries are consistent and test-covered`
- `coverage is maintained or improved against baseline`

## Validation Command Context

- `bundle exec rake test:coverage` must be executed from repository root (`~/Projects/redwright/redwright`).
