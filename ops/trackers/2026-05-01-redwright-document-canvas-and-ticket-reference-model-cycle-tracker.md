# Cycle Tracker: RedWright Document Canvas and Ticket Reference Model

## Metadata

- cycle_id: `cycle-2026-05-01-redwright-document-canvas-and-ticket-reference-model`
- status: `in_progress`
- state: `planning`
- updated: `2026-05-01`
- active_slice: `slice-1`
- active_task: `T1.1`

## Slice Progress

### Slice 1: Spec Consolidation and Acceptance Contract

- status: `in_progress`
- branch: `dev`
- PR: `n/a`
- merge_target: `dev`
- last_sync_commit: `379f087`

Tasks:

- [ ] `T1.1 promote draft and conversation into a formal spec file`
- [ ] `T1.2 formalize phase-one in-scope vs out-of-scope boundaries`
- [ ] `T1.3 formalize acceptance criteria for doc types and ticket-reference behavior`
- [ ] `T1.4 formalize unresolved questions and explicit decision owners`

Commits:

- [ ] `<sha> docs(spec): promote document-canvas draft into formal phase-one spec`

Validation:

- [ ] `spec quality check against source draft and conversation notes`

### Slice 2: Document Domain and Persistence Contract

- status: `pending`
- branch: `fix/slice-2-document-canvas-domain-and-persistence`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 define canonical entities for draft, spec, and plan_tracker`
- [ ] `T2.2 define lifecycle states and allowed transitions per document type`
- [ ] `T2.3 define lineage fields linking spec to source draft`
- [ ] `T2.4 define ticket-to-document reference model and cardinality rules`
- [ ] `T2.5 define migration/backfill constraints for current ticket-only records`

Commits:

- [ ] `<sha> docs(reference): define document-canvas persistence and linkage contract`

Validation:

- [ ] `schema and lifecycle coherence review`

### Slice 3: Command/Query Surface and DDD Boundary

- status: `pending`
- branch: `fix/slice-3-document-canvas-command-query-boundary`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 define document commands for create/promote/link/list operations`
- [ ] `T3.2 define document queries for browse/read/lineage inspection`
- [ ] `T3.3 define adapter contracts for telegram and tui wrappers`
- [ ] `T3.4 define validation and error taxonomy for command/query payloads`

Commits:

- [ ] `<sha> docs(architecture): define document-canvas command-query boundary`

Validation:

- [ ] `adapter wrapper-only contract review`

### Slice 4: UI Information Architecture and Navigation Contract

- status: `pending`
- branch: `fix/slice-4-document-canvas-ui-navigation-contract`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 define phase-one views for draft/spec/plan_tracker discovery and reading`
- [ ] `T4.2 define a simple top navigation model aligned with existing layout`
- [ ] `T4.3 define visual style constraints: palette, typography, spacing, component behavior`
- [ ] `T4.4 define ticket board integration points and navigation entry paths`

Commits:

- [ ] `<sha> docs(spec): define document-canvas ui navigation and visual contract`

Validation:

- [ ] `ui consistency review against current web surface`

### Slice 5: Execution Workflow and Ticket Linking Protocol

- status: `pending`
- branch: `fix/slice-5-document-canvas-ticket-linking-protocol`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 define mandatory vs optional references at ticket creation time`
- [ ] `T5.2 define update protocol when referenced spec revisions change`
- [ ] `T5.3 define plan_tracker generation and update ownership boundaries`
- [ ] `T5.4 define user-visible feedback model for missing or invalid references`

Commits:

- [ ] `<sha> docs(workflow): define ticket-document linking protocol`

Validation:

- [ ] `ticket execution trigger invariants review`

### Slice 6: Validation Matrix and Rollout Readiness

- status: `pending`
- branch: `fix/slice-6-document-canvas-validation-and-rollout`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 define scenario matrix for draft->spec promotion and ticket linking`
- [ ] `T6.2 define compatibility checks for existing ticket-only flows`
- [ ] `T6.3 define telemetry and observability expectations for new doc flows`
- [ ] `T6.4 publish rollout gates and rollback expectations`

Commits:

- [ ] `<sha> docs(plan): publish document-canvas validation and rollout gates`

Validation:

- [ ] `phase-one rollout readiness review`

## Event Log

- `2026-05-01 16:10` state=`planning` note=`initialized cycle plan and tracker from draft+conversation pair; queued ui contract with simple top navigation aligned to existing style language`
