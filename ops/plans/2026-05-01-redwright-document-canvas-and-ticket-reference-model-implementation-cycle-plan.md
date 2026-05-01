# Cycle Plan: RedWright Document Canvas and Ticket Reference Model Implementation

## Metadata

- cycle_id: `cycle-2026-05-01-redwright-document-canvas-and-ticket-reference-model`
- status: `in_progress`
- owner: `adrianpk`
- created: `2026-05-01`
- updated: `2026-05-01`
- goal: `implement document artifacts and ticket references in the web app while preserving ticket-first execution semantics`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-01-redwright-document-canvas-and-ticket-reference-model-spec.md`

## Slice List

### Slice 1: Artifact Domain and Persistence Foundation

- status: `pending`
- branch: `fix/slice-1-document-canvas-domain-foundation`
- objective: `introduce artifact and ticket-reference persistence contracts with model validations`
- tasks:
- [ ] `T1.1 add schema tables for artifacts, artifact relations, and ticket artifact links`
- [ ] `T1.2 add models and validations for artifact types and relation integrity`
- [ ] `T1.3 add ticket-to-artifact association layer`
- [ ] `T1.4 add model tests for type, lineage, and relation constraints`
- acceptance:
- `persistence contract exists and passes model tests`
- `ticket references are optional and validatable`
- planned_commits:
- `feat(web): add document artifact persistence schema`
- `feat(web): add artifact domain models and associations`
- `test(web): add document artifact model coverage`
- PR:
- `tbd`

### Slice 2: Draft CRUD and Promotion Service

- status: `pending`
- branch: `fix/slice-2-draft-crud-and-promotion`
- objective: `implement draft create/read/update/list and draft-to-spec promotion`
- tasks:
- [ ] `T2.1 add document controller actions and routes for draft CRUD`
- [ ] `T2.2 implement promotion service from draft to spec preserving lineage`
- [ ] `T2.3 add request/controller tests for draft CRUD and promotion`
- acceptance:
- `draft CRUD works end-to-end`
- `promotion creates read-only spec with lineage metadata`
- planned_commits:
- `feat(web): add draft CRUD endpoints and views`
- `feat(web): add draft-to-spec promotion flow`
- `test(web): cover draft CRUD and promotion`
- PR:
- `tbd`

### Slice 3: Read Surfaces for Spec and Plan Tracker

- status: `pending`
- branch: `fix/slice-3-spec-plantracker-read-surfaces`
- objective: `implement list/detail read surfaces for spec and plan_tracker`
- tasks:
- [ ] `T3.1 add list/detail filters by artifact type`
- [ ] `T3.2 enforce read-only behavior for spec and plan_tracker`
- [ ] `T3.3 add tests for read/list and edit restrictions`
- acceptance:
- `spec and plan_tracker are listable/readable`
- `edit attempts are rejected in phase one`
- planned_commits:
- `feat(web): add read-only surfaces for spec and plan_tracker`
- `test(web): verify read-only constraints for spec and plan_tracker`
- PR:
- `tbd`

### Slice 4: Artifact Interrelations and Navigation

- status: `pending`
- branch: `fix/slice-4-artifact-interrelations-navigation`
- objective: `implement related-artifact traversal and detail-page navigation`
- tasks:
- [ ] `T4.1 add artifact relation create/query logic`
- [ ] `T4.2 render related artifacts section in detail view`
- [ ] `T4.3 add tests for relation traversal and integrity`
- acceptance:
- `related artifacts are discoverable from any artifact detail page`
- `relation integrity is validated`
- planned_commits:
- `feat(web): add artifact relation traversal and detail navigation`
- `test(web): cover artifact relation integrity and traversal`
- PR:
- `tbd`

### Slice 5: Ticket Reference UX Integration

- status: `pending`
- branch: `fix/slice-5-ticket-reference-ux-integration`
- objective: `enable optional artifact references in ticket create/update flows`
- tasks:
- [ ] `T5.1 add ticket form controls for optional artifact references`
- [ ] `T5.2 render linked artifacts in ticket detail/board context`
- [ ] `T5.3 add tests for optional linking behavior and no-link path`
- acceptance:
- `tickets can be created/updated with or without artifact links`
- `ticket execution semantics remain unchanged`
- planned_commits:
- `feat(web): integrate optional artifact references in ticket flows`
- `test(web): cover ticket artifact linking behavior`
- PR:
- `tbd`

### Slice 6: Top Navigation and Visual Alignment

- status: `pending`
- branch: `fix/slice-6-document-canvas-top-nav-alignment`
- objective: `add simple top navigation entry and align document-canvas UI style to current app language`
- tasks:
- [ ] `T6.1 add top navigation for board and document canvas`
- [ ] `T6.2 align spacing, palette, and typography with existing UI`
- [ ] `T6.3 add UI tests/smoke checks for navigation availability`
- acceptance:
- `navigation is simple and consistent with existing app`
- `document canvas is accessible without disrupting kanban behavior`
- planned_commits:
- `feat(web): add top navigation entry for document canvas`
- `test(web): add navigation smoke coverage`
- PR:
- `tbd`

### Slice 7: Validation Matrix and Runtime Compatibility Closure

- status: `pending`
- branch: `fix/slice-7-document-canvas-validation-closure`
- objective: `close cycle with compatibility verification and scenario matrix`
- tasks:
- [ ] `T7.1 add scenario tests for draft->spec->ticket-reference flow`
- [ ] `T7.2 verify hotfix/minor-task ticket flow remains valid without references`
- [ ] `T7.3 update cycle tracker with final validation evidence`
- acceptance:
- `new and legacy ticket flows pass`
- `final tracker includes validation outcomes`
- planned_commits:
- `test(web): add document-canvas scenario matrix coverage`
- `docs(ops): record document-canvas implementation closure evidence`
- PR:
- `tbd`

## Global Exit Criteria

- `all slices are merged to dev in order`
- `artifact domain contract is implemented with tests`
- `tickets remain the only execution trigger`
- `document canvas is accessible from top navigation`
- `legacy ticket flows remain compatible`
