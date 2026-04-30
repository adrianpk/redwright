# Cycle Tracker: RedWright Kanban RBAC and DnD Interaction Hardening

## Metadata

- cycle_id: `rw-2026-04-30-kanban-rbac-dnd`
- status: `in_progress`
- state: `planning`
- updated: `2026-04-30`
- active_slice: `slice-1`
- active_task: `T1.1`

## Slice Progress

### Slice 1: Instance Admin Bootstrap and Role Model

- status: `pending`
- branch: `feat/slice-1-instance-admin-and-role-model`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `52db091`

Tasks:

- [ ] `T1.1 add fixed role taxonomy (admin, programmer, reviewer, merger, qa) and user-role relation`
- [ ] `T1.2 enforce first-user bootstrap as sole instance admin`
- [ ] `T1.3 enforce rule that agent-role users cannot hold admin`
- [ ] `T1.4 add tests for bootstrap/admin exclusivity and invalid role combinations`

Commits:

- [ ] `<sha> feat(auth): enforce single-admin bootstrap and fixed role taxonomy`
- [ ] `<sha> test(auth): cover role constraints and first-user admin rules`

Validation:

- [ ] `<cmd> role and bootstrap model tests`

### Slice 2: RBAC Gates for Ticket Governance

- status: `pending`
- branch: `feat/slice-2-ticket-rbac-gates`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 restrict ticket assignment to admin`
- [ ] `T2.2 restrict archive and delete ticket actions to admin`
- [ ] `T2.3 keep create/edit available to authenticated users under current MVP policy`
- [ ] `T2.4 add controller tests for allowed/blocked role paths`

Commits:

- [ ] `<sha> feat(authz): gate ticket governance actions behind admin role`
- [ ] `<sha> test(authz): add ticket action authorization coverage`

Validation:

- [ ] `<cmd> ticket authorization controller tests`

### Slice 3: Kanban DnD Semantics (Columns Locked)

- status: `pending`
- branch: `feat/slice-3-kanban-dnd-semantic-hardening`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 hide column reorder handle from UI and keep reorder logic disabled/commented`
- [ ] `T3.2 harden ticket drag-drop transition handling to ensure status/column updates always apply`
- [ ] `T3.3 add bottom drop zones shown only during drag gesture: A (archive), D (delete)`
- [ ] `T3.4 wire archive/delete drop zones to turbo-stream board updates`

Commits:

- [ ] `<sha> feat(web): harden ticket drag semantics and add archive-delete drop zones`
- [ ] `<sha> test(web): cover drag transition and drop-zone actions`

Validation:

- [ ] `<cmd> kanban drag interaction tests`

### Slice 4: Ticket Modal Workflow and Card Interaction Cleanup

- status: `pending`
- branch: `feat/slice-4-ticket-modal-interaction-cleanup`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 make full ticket card clickable to open edit modal`
- [ ] `T4.2 remove explicit edit/archive/delete button controls from card body`
- [ ] `T4.3 preserve subtle assignee marker at bottom-right`
- [ ] `T4.4 add controller/view tests for modal open and update flow`

Commits:

- [ ] `<sha> feat(web): streamline ticket card interactions and modal entry`
- [ ] `<sha> test(web): cover modal entry and ticket update flow`

Validation:

- [ ] `<cmd> modal interaction tests`

## Event Log

- `2026-04-30 13:00` state=`planning` note=`initialized RBAC + drag semantics hardening cycle after kanban MVP alignment`
