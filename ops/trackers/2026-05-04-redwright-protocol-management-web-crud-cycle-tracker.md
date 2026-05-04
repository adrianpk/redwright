# Cycle Tracker: RedWright Protocol Management Web CRUD

## Metadata

- cycle_id: `cycle-2026-05-04-redwright-protocol-management-web-crud`
- status: `implemented_pending_review`
- state: `slice_4_implemented`
- updated: `2026-05-04`
- active_slice: `Slice 4`
- active_task: `none`
- source_plan: `ops/plans/2026-05-04-redwright-protocol-management-web-crud-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-04-redwright-protocol-management-web-crud-spec.md`
- source_conversation:
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv.md`
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv-raw.md`

## Slice Progress

### Slice 1: Project Protocol Navigation and Canonical Index

- status: `merged`
- branch: `fix/slice-1-protocol-management-project-index`
- PR: `#292 https://codeberg.org/adrianpk/redwright/pulls/292`
- merge_target: `dev`
- last_sync_commit: `41019ce`

Tasks:

- [x] `T1.1 add Protocols top-level navigation alongside Boards and Documents`
- [x] `T1.2 render project Protocols as a card-based canonical index aligned with the existing Documents interaction model`
- [x] `T1.3 show AGENTS plus the .agents-backed protocol entries in one unified Protocol view`
- [x] `T1.4 represent missing canonical entries as empty cards with direct create actions rather than generic add flows`
- [x] `T1.5 treat PLAYBOOKS as a special card that routes to a dedicated Playbooks subview`
- [x] `T1.6 add controller and integration coverage for navigation, canonical ordering, and empty-card behavior`

Commits:

- [x] `957fccf feat(web): add protocols navigation and project index`
- [x] `8b3145d test(web): cover project protocol index navigation`

Validation:

- [x] `bundle exec bin/rails test test/controllers/project_protocols_controller_test.rb test/controllers/projects_controller_test.rb` (pass)

### Slice 2: Project Protocol Read-Edit Surface and Playbooks

- status: `merged`
- branch: `fix/slice-2-protocol-management-project-editing`
- PR: `#293 https://codeberg.org/adrianpk/redwright/pulls/293`
- merge_target: `dev`
- last_sync_commit: `d9142d0`

Tasks:

- [x] `T2.1 replace show-then-edit ceremony with a combined read-edit Protocol screen`
- [x] `T2.2 keep explicit Save while adding autosave behavior and visible last-successful-save feedback`
- [x] `T2.3 ensure project Protocol creation is limited to missing canonical entries and disallows duplicate canonical types within one project set`
- [x] `T2.4 allow deletion and later recreation of canonical project Protocol entries`
- [x] `T2.5 implement the dedicated project Playbooks subview using the fixed canonical set`
- [x] `T2.6 add tests for project Protocol create, edit, autosave, delete, recreate, and Playbooks flows`

Commits:

- [x] `45e9dc4 feat(web): add direct project protocol editing flow`
- [x] `3d655a0 test(web): cover project protocol editing flows`

Validation:

- [x] `bundle exec bin/rails test test/controllers/project_protocols_controller_test.rb test/controllers/projects_controller_test.rb` (pass)

### Slice 3: Global Template Administration Surfaces

- status: `merged`
- branch: `fix/slice-3-protocol-management-template-surfaces`
- PR: `#294 https://codeberg.org/adrianpk/redwright/pulls/294`
- merge_target: `dev`
- last_sync_commit: `17f3e5e`

Tasks:

- [x] `T3.1 add Settings entry points for Common Protocol Templates and Stack Protocol Templates as separate cards`
- [x] `T3.2 align Common Protocol Template management with the same card and low-ceremony editing model used for project Protocols`
- [x] `T3.3 implement one-screen-per-stack template management rather than a combined cross-stack editor`
- [x] `T3.4 support creating new stack template sets by stack identity and seeding empty canonical entries`
- [x] `T3.5 apply the fixed-set PLAYBOOKS subview pattern to template management with playbooks treated as common-only in MVP`
- [x] `T3.6 add tests for template navigation, stack-set creation, duplicate prevention within a set, delete and recreate, and Playbooks routing`

Commits:

- [x] `4244cba feat(web): add protocol template settings surfaces`
- [x] `73d6d11 test(web): cover protocol template management`

Validation:

- [x] `bundle exec bin/rails test test/controllers/project_protocol_templates_controller_test.rb` (pass)

### Slice 4: Visual Harmonization and Validation Closure

- status: `implemented`
- branch: `fix/slice-4-protocol-management-visual-harmonization`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `17f3e5e`

Tasks:

- [x] `T4.1 harmonize spacing, typography, card treatment, and form hierarchy across Protocols, Protocol Templates, and Playbooks`
- [x] `T4.2 eliminate any generic scaffold-like or outdated model-form presentation from the new Protocol management surfaces`
- [x] `T4.3 avoid introducing a disconnected trend-driven redesign that clashes with current Documents and neighboring views`
- [x] `T4.4 verify that semantic stack cues and save-state feedback remain legible without overcrowding cards`
- [x] `T4.5 run targeted and full relevant validation from canonical command locations`
- [x] `T4.6 publish cycle closure artifacts with residual risks and follow-up notes`

Commits:

- [ ] `<sha> feat(web): harmonize protocol management styling`
- [ ] `<sha> docs(ops): close protocol management web CRUD cycle`

Validation:

- [x] `bundle exec bin/rails test test/controllers/project_protocols_controller_test.rb test/controllers/project_protocol_templates_controller_test.rb test/controllers/projects_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `bundle exec rake test:coverage` (pass, coverage 91.6)

## Event Log

- `2026-05-04 00:00` state=`planning` note=`formalized the protocol management web CRUD spec from questionnaire artifacts and initialized the associated cycle plan and tracker for execution planning`
- `2026-05-04 15:18` state=`slice_1_implemented` note=`added project-scoped Protocols navigation, built the canonical card index with missing-entry create actions and dedicated Playbooks routing, and validated controller coverage on fix/slice-1-protocol-management-project-index`
- `2026-05-04 16:19` state=`slice_1_pr_open` note=`opened Codeberg PR #292 from fix/slice-1-protocol-management-project-index into dev`
- `2026-05-04 16:32` state=`slice_1_merged` note=`merged PR #292 into dev`
- `2026-05-04 16:45` state=`slice_2_implemented` note=`collapsed project Protocol show and edit into one screen, added autosave with visible last-save state, enabled delete and recreate for canonical entries, and validated the project Protocol controller flows on fix/slice-2-protocol-management-project-editing`
- `2026-05-04 17:02` state=`slice_2_pr_open` note=`opened Codeberg PR #293 from fix/slice-2-protocol-management-project-editing into dev`
- `2026-05-04 17:10` state=`slice_2_merged` note=`merged PR #293 into dev`
- `2026-05-04 17:24` state=`slice_3_implemented` note=`introduced Settings-based template entry cards, per-stack template set management, new stack-set creation with empty canonical entries, common-only Playbooks routing, and template entry delete/recreate coverage on fix/slice-3-protocol-management-template-surfaces`
- `2026-05-04 17:49` state=`slice_3_pr_open` note=`opened Codeberg PR #294 from fix/slice-3-protocol-management-template-surfaces into dev`
- `2026-05-04 18:05` state=`slice_3_merged` note=`merged PR #294 into dev`
- `2026-05-04 18:31` state=`slice_4_implemented` note=`harmonized the Protocol and Template surfaces with clearer chips, calmer card hierarchy, stronger form focus states, compact Settings navigation, and completed the targeted, full-suite, and coverage validations on fix/slice-4-protocol-management-visual-harmonization`
