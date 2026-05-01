# Cycle Plan: RedWright Document Canvas and Ticket Reference Model

## Metadata

- cycle_id: `cycle-2026-05-01-redwright-document-canvas-and-ticket-reference-model`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-01`
- updated: `2026-05-01`
- goal: `define and implement a document-canvas model where tickets remain the execution trigger while draft/spec/plan-tracker artifacts become first-class references`
- scope: `feature`
- source_draft: `ops/specs/drafts/2026-05-01-redwright-document-canvas-and-ticket-reference-model-draft.md`
- source_conversation: `ops/specs/drafts/2026-05-01-redwright-document-canvas-and-ticket-reference-model-conv.md`

## Slice List

### Slice 1: Spec Consolidation and Acceptance Contract

- status: `pending`
- branch: `fix/slice-1-document-canvas-spec-consolidation`
- objective: `promote the draft+conversation into a formal spec with explicit phase-one boundaries and acceptance criteria`
- tasks:
- [ ] `T1.1 promote draft and conversation into a formal spec file`
- [ ] `T1.2 formalize phase-one in-scope vs out-of-scope boundaries`
- [ ] `T1.3 formalize acceptance criteria for doc types and ticket-reference behavior`
- [ ] `T1.4 formalize unresolved questions and explicit decision owners`
- acceptance:
- `spec exists and supersedes exploratory wording`
- `phase-one boundaries are explicit and testable`
- `acceptance criteria are implementation-ready`
- planned_commits:
- `docs(spec): promote document-canvas draft into formal phase-one spec`
- PR:
- `tbd`

### Slice 2: Document Domain and Persistence Contract

- status: `pending`
- branch: `fix/slice-2-document-canvas-domain-and-persistence`
- objective: `define document entities, lifecycle states, lineage metadata, and ticket-reference persistence rules`
- tasks:
- [ ] `T2.1 define canonical entities for draft, spec, and plan_tracker`
- [ ] `T2.2 define lifecycle states and allowed transitions per document type`
- [ ] `T2.3 define lineage fields linking spec to source draft`
- [ ] `T2.4 define ticket-to-document reference model and cardinality rules`
- [ ] `T2.5 define migration/backfill constraints for current ticket-only records`
- acceptance:
- `entity and relation contract is explicit and normalized`
- `lineage requirements are non-ambiguous`
- `ticket reference rules prevent overloaded ticket payloads`
- planned_commits:
- `docs(reference): define document-canvas persistence and linkage contract`
- PR:
- `tbd`

### Slice 3: Command/Query Surface and DDD Boundary

- status: `pending`
- branch: `fix/slice-3-document-canvas-command-query-boundary`
- objective: `define DDD-like command/query surface where slash commands remain wrappers over verb-noun runtime operations`
- tasks:
- [ ] `T3.1 define document commands for create/promote/link/list operations`
- [ ] `T3.2 define document queries for browse/read/lineage inspection`
- [ ] `T3.3 define adapter contracts for telegram and tui wrappers`
- [ ] `T3.4 define validation and error taxonomy for command/query payloads`
- acceptance:
- `commands and queries are explicit and channel-agnostic`
- `adapters remain parse-map-render wrappers`
- `runtime contracts are deterministic and testable`
- planned_commits:
- `docs(architecture): define document-canvas command-query boundary`
- PR:
- `tbd`

### Slice 4: UI Information Architecture and Navigation Contract

- status: `pending`
- branch: `fix/slice-4-document-canvas-ui-navigation-contract`
- objective: `define a phase-one UI contract that preserves existing visual language and introduces a simple top navigation for multi-feature growth`
- tasks:
- [ ] `T4.1 define phase-one views for draft/spec/plan_tracker discovery and reading`
- [ ] `T4.2 define a simple top navigation model aligned with existing layout`
- [ ] `T4.3 define visual style constraints: palette, typography, spacing, component behavior`
- [ ] `T4.4 define ticket board integration points and navigation entry paths`
- acceptance:
- `ui contract expands beyond kanban without visual drift`
- `top navigation is simple, predictable, and consistent`
- `style and palette constraints remain aligned to existing product language`
- planned_commits:
- `docs(spec): define document-canvas ui navigation and visual contract`
- PR:
- `tbd`

### Slice 5: Execution Workflow and Ticket Linking Protocol

- status: `pending`
- branch: `fix/slice-5-document-canvas-ticket-linking-protocol`
- objective: `define how tickets reference richer artifacts while remaining the single execution trigger`
- tasks:
- [ ] `T5.1 define mandatory vs optional references at ticket creation time`
- [ ] `T5.2 define update protocol when referenced spec revisions change`
- [ ] `T5.3 define plan_tracker generation and update ownership boundaries`
- [ ] `T5.4 define user-visible feedback model for missing or invalid references`
- acceptance:
- `ticket remains canonical execution unit`
- `references reduce ticket overload without ambiguity`
- `plan_tracker ownership and mutability boundaries are explicit`
- planned_commits:
- `docs(workflow): define ticket-document linking protocol`
- PR:
- `tbd`

### Slice 6: Validation Matrix and Rollout Readiness

- status: `pending`
- branch: `fix/slice-6-document-canvas-validation-and-rollout`
- objective: `define validation matrix, migration safety checks, and rollout criteria for phase one`
- tasks:
- [ ] `T6.1 define scenario matrix for draft->spec promotion and ticket linking`
- [ ] `T6.2 define compatibility checks for existing ticket-only flows`
- [ ] `T6.3 define telemetry and observability expectations for new doc flows`
- [ ] `T6.4 publish rollout gates and rollback expectations`
- acceptance:
- `phase-one validation matrix covers nominal and failure paths`
- `legacy flows remain operational under compatibility rules`
- `rollout and rollback criteria are explicit`
- planned_commits:
- `docs(plan): publish document-canvas validation and rollout gates`
- PR:
- `tbd`

## Global Exit Criteria

- `formal spec is published and approved from the current draft+conversation pair`
- `document entity model and lineage rules are explicit`
- `ticket remains the only execution trigger with artifact references`
- `phase-one ui navigation contract is defined and aligned with existing style language`
- `validation and rollout gates are explicit for implementation phase`
