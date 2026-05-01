# Cycle Tracker: RedWright Document Canvas and Ticket Reference Model Implementation

## Metadata

- cycle_id: `cycle-2026-05-01-redwright-document-canvas-and-ticket-reference-model`
- status: `in_progress`
- state: `executing_slice`
- updated: `2026-05-01`
- active_slice: `Slice 1`
- active_task: `T1.1`

## Slice Progress

### Slice 1: Artifact Domain and Persistence Foundation

- status: `in_progress`
- branch: `fix/slice-1-document-canvas-domain-foundation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `b55927e`

Tasks:

- [ ] `T1.1 add schema tables for artifacts, artifact relations, and ticket artifact links`
- [ ] `T1.2 add models and validations for artifact types and relation integrity`
- [ ] `T1.3 add ticket-to-artifact association layer`
- [ ] `T1.4 add model tests for type, lineage, and relation constraints`

Commits:

- [ ] `<sha> feat(web): add document artifact persistence schema`
- [ ] `<sha> feat(web): add artifact domain models and associations`
- [ ] `<sha> test(web): add document artifact model coverage`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/models`

### Slice 2: Draft CRUD and Promotion Service

- status: `pending`
- branch: `fix/slice-2-draft-crud-and-promotion`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 add document controller actions and routes for draft CRUD`
- [ ] `T2.2 implement promotion service from draft to spec preserving lineage`
- [ ] `T2.3 add request/controller tests for draft CRUD and promotion`

Commits:

- [ ] `<sha> feat(web): add draft CRUD endpoints and views`
- [ ] `<sha> feat(web): add draft-to-spec promotion flow`
- [ ] `<sha> test(web): cover draft CRUD and promotion`

Validation:

- [ ] `controller and integration tests for draft CRUD and promotion`

### Slice 3: Read Surfaces for Spec and Plan Tracker

- status: `pending`
- branch: `fix/slice-3-spec-plantracker-read-surfaces`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add list/detail filters by artifact type`
- [ ] `T3.2 enforce read-only behavior for spec and plan_tracker`
- [ ] `T3.3 add tests for read/list and edit restrictions`

Commits:

- [ ] `<sha> feat(web): add read-only surfaces for spec and plan_tracker`
- [ ] `<sha> test(web): verify read-only constraints for spec and plan_tracker`

Validation:

- [ ] `read/list and restriction tests`

### Slice 4: Artifact Interrelations and Navigation

- status: `pending`
- branch: `fix/slice-4-artifact-interrelations-navigation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 add artifact relation create/query logic`
- [ ] `T4.2 render related artifacts section in detail view`
- [ ] `T4.3 add tests for relation traversal and integrity`

Commits:

- [ ] `<sha> feat(web): add artifact relation traversal and detail navigation`
- [ ] `<sha> test(web): cover artifact relation integrity and traversal`

Validation:

- [ ] `relation traversal and integrity tests`

### Slice 5: Ticket Reference UX Integration

- status: `pending`
- branch: `fix/slice-5-ticket-reference-ux-integration`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 add ticket form controls for optional artifact references`
- [ ] `T5.2 render linked artifacts in ticket detail/board context`
- [ ] `T5.3 add tests for optional linking behavior and no-link path`

Commits:

- [ ] `<sha> feat(web): integrate optional artifact references in ticket flows`
- [ ] `<sha> test(web): cover ticket artifact linking behavior`

Validation:

- [ ] `ticket linking optional-path tests`

### Slice 6: Top Navigation and Visual Alignment

- status: `pending`
- branch: `fix/slice-6-document-canvas-top-nav-alignment`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 add top navigation for board and document canvas`
- [ ] `T6.2 align spacing, palette, and typography with existing UI`
- [ ] `T6.3 add UI tests/smoke checks for navigation availability`

Commits:

- [ ] `<sha> feat(web): add top navigation entry for document canvas`
- [ ] `<sha> test(web): add navigation smoke coverage`

Validation:

- [ ] `navigation smoke checks`

### Slice 7: Validation Matrix and Runtime Compatibility Closure

- status: `pending`
- branch: `fix/slice-7-document-canvas-validation-closure`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 add scenario tests for draft->spec->ticket-reference flow`
- [ ] `T7.2 verify hotfix/minor-task ticket flow remains valid without references`
- [ ] `T7.3 update cycle tracker with final validation evidence`

Commits:

- [ ] `<sha> test(web): add document-canvas scenario matrix coverage`
- [ ] `<sha> docs(ops): record document-canvas implementation closure evidence`

Validation:

- [ ] `scenario matrix pass`

## Event Log

- `2026-05-01 17:15` state=`executing_slice` note=`spec and implementation plan initialized from latest draft and conversation; proceeding with Slice 1 code implementation`
