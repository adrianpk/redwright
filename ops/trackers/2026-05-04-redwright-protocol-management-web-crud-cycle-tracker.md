# Cycle Tracker: RedWright Protocol Management Web CRUD

## Metadata

- cycle_id: `cycle-2026-05-04-redwright-protocol-management-web-crud`
- status: `in_progress`
- state: `planning`
- updated: `2026-05-04`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-04-redwright-protocol-management-web-crud-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-04-redwright-protocol-management-web-crud-spec.md`
- source_conversation:
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv.md`
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv-raw.md`

## Slice Progress

### Slice 1: Project Protocol Navigation and Canonical Index

- status: `pending`
- branch: `fix/slice-1-protocol-management-project-index`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 add Protocols top-level navigation alongside Boards and Documents`
- [ ] `T1.2 render project Protocols as a card-based canonical index aligned with the existing Documents interaction model`
- [ ] `T1.3 show AGENTS plus the .agents-backed protocol entries in one unified Protocol view`
- [ ] `T1.4 represent missing canonical entries as empty cards with direct create actions rather than generic add flows`
- [ ] `T1.5 treat PLAYBOOKS as a special card that routes to a dedicated Playbooks subview`
- [ ] `T1.6 add controller and integration coverage for navigation, canonical ordering, and empty-card behavior`

Commits:

- [ ] `<sha> feat(web): add protocols navigation and project index`
- [ ] `<sha> test(web): cover project protocol index navigation`

Validation:

- [ ] `bundle exec bin/rails test <project protocol navigation and index paths>` (tbd)

### Slice 2: Project Protocol Read-Edit Surface and Playbooks

- status: `pending`
- branch: `fix/slice-2-protocol-management-project-editing`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 replace show-then-edit ceremony with a combined read-edit Protocol screen`
- [ ] `T2.2 keep explicit Save while adding autosave behavior and visible last-successful-save feedback`
- [ ] `T2.3 ensure project Protocol creation is limited to missing canonical entries and disallows duplicate canonical types within one project set`
- [ ] `T2.4 allow deletion and later recreation of canonical project Protocol entries`
- [ ] `T2.5 implement the dedicated project Playbooks subview using the fixed canonical set`
- [ ] `T2.6 add tests for project Protocol create, edit, autosave, delete, recreate, and Playbooks flows`

Commits:

- [ ] `<sha> feat(web): add project protocol editing flow`
- [ ] `<sha> feat(web): add project protocol autosave and playbooks`
- [ ] `<sha> test(web): cover project protocol editing flows`

Validation:

- [ ] `bundle exec bin/rails test <project protocol editing and playbooks paths>` (tbd)

### Slice 3: Global Template Administration Surfaces

- status: `pending`
- branch: `fix/slice-3-protocol-management-template-surfaces`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add Settings entry points for Common Protocol Templates and Stack Protocol Templates as separate cards`
- [ ] `T3.2 align Common Protocol Template management with the same card and low-ceremony editing model used for project Protocols`
- [ ] `T3.3 implement one-screen-per-stack template management rather than a combined cross-stack editor`
- [ ] `T3.4 support creating new stack template sets by stack identity and seeding empty canonical entries`
- [ ] `T3.5 apply the fixed-set PLAYBOOKS subview pattern to template management with playbooks treated as common-only in MVP`
- [ ] `T3.6 add tests for template navigation, stack-set creation, duplicate prevention within a set, delete and recreate, and Playbooks routing`

Commits:

- [ ] `<sha> feat(web): add protocol template settings surfaces`
- [ ] `<sha> feat(web): add stack template set creation`
- [ ] `<sha> test(web): cover protocol template management`

Validation:

- [ ] `bundle exec bin/rails test <protocol template surface paths>` (tbd)

### Slice 4: Visual Harmonization and Validation Closure

- status: `pending`
- branch: `fix/slice-4-protocol-management-visual-harmonization`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 harmonize spacing, typography, card treatment, and form hierarchy across Protocols, Protocol Templates, and Playbooks`
- [ ] `T4.2 eliminate any generic scaffold-like or outdated model-form presentation from the new Protocol management surfaces`
- [ ] `T4.3 avoid introducing a disconnected trend-driven redesign that clashes with current Documents and neighboring views`
- [ ] `T4.4 verify that semantic stack cues and save-state feedback remain legible without overcrowding cards`
- [ ] `T4.5 run targeted and full relevant validation from canonical command locations`
- [ ] `T4.6 publish cycle closure artifacts with residual risks and follow-up notes`

Commits:

- [ ] `<sha> feat(web): harmonize protocol management styling`
- [ ] `<sha> test(web): validate protocol management flows`
- [ ] `<sha> docs(ops): close protocol management web CRUD cycle`

Validation:

- [ ] `bundle exec bin/rails test <full relevant protocol management paths>` (tbd)
- [ ] `bundle exec bin/rails test` (tbd)
- [ ] `bundle exec rake test:coverage` (tbd)

## Event Log

- `2026-05-04 00:00` state=`planning` note=`formalized the protocol management web CRUD spec from questionnaire artifacts and initialized the associated cycle plan and tracker for execution planning`
