# Cycle Tracker: RedWright Kanban RBAC and DnD Interaction Hardening

## Metadata

- cycle_id: `rw-2026-04-30-kanban-rbac-dnd`
- status: `completed`
- state: `closed`
- updated: `2026-04-30`
- active_slice: `none`
- active_task: `none`

## Slice Progress

### Slice 1: Instance Admin Bootstrap and Role Model

- status: `completed`
- branch: `feat/slice-1-instance-admin-and-role-model`
- PR: `#177`
- merge_target: `dev`
- last_sync_commit: `7df1661`

Tasks:

- [x] `T1.1 add fixed role taxonomy (admin, programmer, reviewer, merger, qa) and user-role relation`
- [x] `T1.2 enforce first-user bootstrap as sole instance admin`
- [x] `T1.3 enforce rule that agent-role users cannot hold admin`
- [x] `T1.4 add tests for bootstrap/admin exclusivity and invalid role combinations`

Commits:

- [x] `3f04fa2 feat(auth): enforce single-admin bootstrap and fixed role taxonomy`
- [x] `71c6a7c test(auth): cover role constraints and first-user admin rules`

Validation:

- [x] `<cmd> cd apps/web && bundle exec bin/rails test test/models/user_test.rb test/controllers/users_controller_test.rb`

### Slice 2: RBAC Gates for Ticket Governance

- status: `completed`
- branch: `feat/slice-2-ticket-rbac-gates`
- PR: `#178`
- merge_target: `dev`
- last_sync_commit: `725c760`

Tasks:

- [x] `T2.1 restrict ticket assignment to admin`
- [x] `T2.2 restrict archive and delete ticket actions to admin`
- [x] `T2.3 keep create/edit available to authenticated users under current MVP policy`
- [x] `T2.4 add controller tests for allowed/blocked role paths`

Commits:

- [x] `3d90200 feat(authz): gate ticket governance actions behind admin role`
- [x] `8037694 test(authz): add ticket action authorization coverage`

Validation:

- [x] `<cmd> cd apps/web && bundle exec bin/rails test test/models/user_test.rb test/controllers/users_controller_test.rb test/controllers/tickets_controller_test.rb`

### Slice 3: Kanban DnD Semantics (Columns Locked)

- status: `completed`
- branch: `feat/slice-3-kanban-dnd-semantic-hardening`
- PR: `#179`
- merge_target: `dev`
- last_sync_commit: `8af2cd2`

Tasks:

- [x] `T3.1 hide column reorder handle from UI and keep reorder logic disabled/commented`
- [x] `T3.2 harden ticket drag-drop transition handling to ensure status/column updates always apply`
- [x] `T3.3 add bottom drop zones shown only during drag gesture: A (archive), D (delete)`
- [x] `T3.4 wire archive/delete drop zones to turbo-stream board updates`

Commits:

- [x] `f355631 feat(web): harden ticket drag semantics and add archive-delete drop zones`
- [x] `7c0355d test(web): cover drag transition and drop-zone actions`

Validation:

- [x] `<cmd> cd apps/web && bundle exec bin/rails test test/controllers/boards_controller_test.rb test/controllers/tickets_controller_test.rb test/controllers/columns_controller_test.rb test/models/ticket_test.rb test/models/user_test.rb test/controllers/users_controller_test.rb`

### Slice 4: Ticket Modal Workflow and Card Interaction Cleanup

- status: `completed`
- branch: `feat/slice-4-ticket-modal-interaction-cleanup`
- PR: `#180`
- merge_target: `dev`
- last_sync_commit: `7b97216`

Tasks:

- [x] `T4.1 make full ticket card clickable to open edit modal`
- [x] `T4.2 remove explicit edit/archive/delete button controls from card body`
- [x] `T4.3 preserve subtle assignee marker at bottom-right`
- [x] `T4.4 add controller/view tests for modal open and update flow`

Commits:

- [x] `f355631 feat(web): streamline ticket card interactions and modal entry`
- [x] `a73064d test(web): cover modal entry and ticket update flow`

Validation:

- [x] `<cmd> cd apps/web && bundle exec bin/rails test test/controllers/boards_controller_test.rb test/controllers/tickets_controller_test.rb test/controllers/columns_controller_test.rb test/models/ticket_test.rb test/models/user_test.rb test/controllers/users_controller_test.rb`

## Event Log

- `2026-04-30 13:00` state=`planning` note=`initialized RBAC + drag semantics hardening cycle after kanban MVP alignment`
- `2026-04-30 14:20` state=`completed` note=`all four slices merged to dev with single-pr-per-slice workflow`
