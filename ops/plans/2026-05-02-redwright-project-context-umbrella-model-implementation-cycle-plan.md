# Cycle Plan: RedWright Project Context Umbrella Model Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-project-context-umbrella-model`
- status: `completed`
- owner: `adrianpk`
- created: `2026-05-02`
- updated: `2026-05-02 (closure)`
- goal: `establish project as umbrella context for boards, tickets, and documents with dynamic project attributes`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-02-redwright-project-context-umbrella-model-spec.md`

## Slice List

### Slice 1: Project Domain and Schema Foundation

- status: `completed`
- branch: `fix/slice-1-project-domain-schema-foundation`
- objective: `introduce projects table/model and baseline validations`
- tasks:
- [ ] `T1.1 create projects migration with required fields and indexes`
- [ ] `T1.2 add Project model with validation contract`
- [ ] `T1.3 add model tests for project required fields and uniqueness constraints`
- acceptance:
- `project persistence contract is validated`
- planned_commits:
- `feat(web): add project domain persistence foundation`
- `test(web): add project model validation coverage`

### Slice 2: Dynamic Project Attributes

- status: `completed`
- branch: `fix/slice-2-project-attributes-dynamic-metadata`
- objective: `add weighted key/value project metadata`
- tasks:
- [ ] `T2.1 create project_attributes migration and associations`
- [ ] `T2.2 add validation for weight range and source presence`
- [ ] `T2.3 add model tests for key/value/weight/source semantics`
- acceptance:
- `project dynamic metadata is persisted and validated`
- planned_commits:
- `feat(web): add project attributes dynamic metadata model`
- `test(web): cover project attribute validation and associations`

### Slice 3: Board Project Binding

- status: `completed`
- branch: `fix/slice-3-board-project-binding`
- objective: `bind boards to project as required ownership context`
- tasks:
- [ ] `T3.1 add project_id to boards with migration/backfill strategy`
- [ ] `T3.2 enforce board->project association and validation`
- [ ] `T3.3 add board model/controller tests for required project context`
- acceptance:
- `boards cannot exist without project`
- planned_commits:
- `feat(web): require project ownership for boards`
- `test(web): cover board project binding rules`

### Slice 4: Document Project Binding

- status: `completed`
- branch: `fix/slice-4-document-project-binding`
- objective: `bind document artifacts to project context`
- tasks:
- [ ] `T4.1 add project_id to document_artifacts with migration/backfill`
- [ ] `T4.2 enforce artifact->project association and scoped queries`
- [ ] `T4.3 add tests for project-scoped artifact access`
- acceptance:
- `document artifacts are project-scoped by contract`
- planned_commits:
- `feat(web): bind document artifacts to projects`
- `test(web): cover project-scoped document artifact behavior`

### Slice 5: Ticket Project Context Derivation (Phase One)

- status: `completed`
- branch: `fix/slice-5-ticket-project-context-derivation`
- objective: `provide ticket project context via board linkage without ticket schema change`
- tasks:
- [ ] `T5.1 add ticket-level project context resolver through board`
- [ ] `T5.2 expose project context in runtime/query surfaces`
- [ ] `T5.3 add tests for derived project consistency in ticket flows`
- acceptance:
- `ticket project context is available and consistent in phase one`
- planned_commits:
- `feat(web): derive ticket project context through board association`
- `test(web): verify ticket project context derivation`

### Slice 6: Query and Invariant Hardening

- status: `completed`
- branch: `fix/slice-6-project-scope-query-and-invariant-hardening`
- objective: `harden project-scoped query paths and prepare phase-two ticket binding contract`
- tasks:
- [ ] `T6.1 add project-scoped query helpers for boards/tickets/documents/attributes`
- [ ] `T6.2 formalize invariant checks for optional future tickets.project_id`
- [ ] `T6.3 add regression tests for cross-project isolation by context`
- acceptance:
- `project-scoped lookup is explicit and test-covered`
- `phase-two invariant contract is codified for safe adoption`
- planned_commits:
- `feat(web): add project-scoped query and invariant helpers`
- `test(web): add project context isolation regression coverage`

### Slice 7: Operational Closure and Documentation Sync

- status: `completed`
- branch: `fix/slice-7-project-context-operational-closure`
- objective: `close implementation cycle with operational evidence and docs sync`
- tasks:
- [ ] `T7.1 run focused validation matrix for project-scoped flows`
- [ ] `T7.2 update tracker with merged PR references and validation evidence`
- [ ] `T7.3 sync relevant docs if contract details changed during implementation`
- acceptance:
- `cycle evidence is complete and auditable`
- planned_commits:
- `docs(ops): record project context implementation closure evidence`

## Global Exit Criteria

- `all slices merged to dev in sequence`
- `boards and documents are strictly project-scoped`
- `ticket project context is available through phase-one derivation`
- `dynamic project attributes are validated and queryable`
- `project-scoped runtime context retrieval is test-covered`
