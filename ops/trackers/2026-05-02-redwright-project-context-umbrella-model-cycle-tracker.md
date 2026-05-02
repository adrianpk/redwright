# Cycle Tracker: RedWright Project Context Umbrella Model Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-project-context-umbrella-model`
- status: `in_progress`
- state: `awaiting_review`
- updated: `2026-05-02`
- active_slice: `Slice 2`
- active_task: `T2.3`
- source_plan: `ops/plans/2026-05-02-redwright-project-context-umbrella-model-implementation-cycle-plan.md`

## Slice Progress

### Slice 1: Project Domain and Schema Foundation

- status: `completed`
- branch: `fix/slice-1-project-domain-schema-foundation`
- PR: `#tbd`
- merge_target: `dev`
- last_sync_commit: `a146df4`

Tasks:

- [x] `T1.1 create projects migration with required fields and indexes`
- [x] `T1.2 add Project model with validation contract`
- [x] `T1.3 add model tests for project required fields and uniqueness constraints`

Commits:

- [x] `b451303 feat(web): add project domain persistence foundation`
- [x] `48d77ff test(web): add project model validation coverage`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/models/project_test.rb (pass)`

### Slice 2: Dynamic Project Attributes

- status: `completed`
- branch: `fix/slice-2-project-attributes-dynamic-metadata`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `c08b5aa`

Tasks:

- [x] `T2.1 create project_attributes migration and associations`
- [x] `T2.2 add validation for weight range and source presence`
- [x] `T2.3 add model tests for key/value/weight/source semantics`

Commits:

- [x] `477778f feat(web): add project attributes persistence and project association`
- [x] `7e5f6f8 feat(web): validate project attribute weight range and source presence`
- [x] `d1f0602 test(web): cover project attribute validation and associations`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/models/project_attribute_test.rb (pass)`

### Slice 3: Board Project Binding

- status: `pending`
- branch: `fix/slice-3-board-project-binding`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add project_id to boards with migration/backfill strategy`
- [ ] `T3.2 enforce board->project association and validation`
- [ ] `T3.3 add board model/controller tests for required project context`

Commits:

- [ ] `<sha> feat(web): require project ownership for boards`
- [ ] `<sha> test(web): cover board project binding rules`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/models/board_test.rb test/controllers/boards_controller_test.rb`

### Slice 4: Document Project Binding

- status: `pending`
- branch: `fix/slice-4-document-project-binding`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 add project_id to document_artifacts with migration/backfill`
- [ ] `T4.2 enforce artifact->project association and scoped queries`
- [ ] `T4.3 add tests for project-scoped artifact access`

Commits:

- [ ] `<sha> feat(web): bind document artifacts to projects`
- [ ] `<sha> test(web): cover project-scoped document artifact behavior`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/models/document_artifact_test.rb test/controllers/document_artifacts_controller_test.rb`

### Slice 5: Ticket Project Context Derivation (Phase One)

- status: `pending`
- branch: `fix/slice-5-ticket-project-context-derivation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 add ticket-level project context resolver through board`
- [ ] `T5.2 expose project context in runtime/query surfaces`
- [ ] `T5.3 add tests for derived project consistency in ticket flows`

Commits:

- [ ] `<sha> feat(web): derive ticket project context through board association`
- [ ] `<sha> test(web): verify ticket project context derivation`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/models/ticket_test.rb test/controllers/tickets_controller_test.rb`

### Slice 6: Query and Invariant Hardening

- status: `pending`
- branch: `fix/slice-6-project-scope-query-and-invariant-hardening`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 add project-scoped query helpers for boards/tickets/documents/attributes`
- [ ] `T6.2 formalize invariant checks for optional future tickets.project_id`
- [ ] `T6.3 add regression tests for cross-project isolation by context`

Commits:

- [ ] `<sha> feat(web): add project-scoped query and invariant helpers`
- [ ] `<sha> test(web): add project context isolation regression coverage`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/models/project_test.rb test/models/ticket_test.rb test/models/document_artifact_test.rb`

### Slice 7: Operational Closure and Documentation Sync

- status: `pending`
- branch: `fix/slice-7-project-context-operational-closure`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 run focused validation matrix for project-scoped flows`
- [ ] `T7.2 update tracker with merged PR references and validation evidence`
- [ ] `T7.3 sync relevant docs if contract details changed during implementation`

Commits:

- [ ] `<sha> docs(ops): record project context implementation closure evidence`

Validation:

- [ ] `focused matrix pass recorded in tracker`

## Event Log

- `2026-05-02` state=`planned` note=`spec, implementation plan, and tracker initialized from draft and curated conversation; cycle is ready for Slice 1 branch/PR execution`
- `2026-05-02` state=`awaiting_review` note=`Slice 1 completed with project persistence migration, project model validations, and model coverage`
- `2026-05-02` state=`awaiting_review` note=`Slice 2 completed with project_attributes persistence, model validation contract, and focused model coverage`
