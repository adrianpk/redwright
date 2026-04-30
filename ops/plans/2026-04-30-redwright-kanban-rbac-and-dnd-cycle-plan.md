# Cycle Plan: RedWright Kanban RBAC and DnD Interaction Hardening

## Metadata

- cycle_id: `rw-2026-04-30-kanban-rbac-dnd`
- status: `approved`
- owner: `adrianpk`
- created: `2026-04-30`
- updated: `2026-04-30`
- goal: `stabilize kanban interaction semantics and introduce minimal identity/authorization constraints for instance-level ownership`
- scope: `feature`

## Slice List

### Slice 1: Instance Admin Bootstrap and Role Model

- status: `pending`
- branch: `feat/slice-1-instance-admin-and-role-model`
- objective: `enforce one-admin bootstrap per instance and formalize fixed role taxonomy`
- tasks:
- [ ] `T1.1 add fixed role taxonomy (admin, programmer, reviewer, merger, qa) and user-role relation`
- [ ] `T1.2 enforce first-user bootstrap as sole instance admin`
- [ ] `T1.3 enforce rule that agent-role users cannot hold admin`
- [ ] `T1.4 add tests for bootstrap/admin exclusivity and invalid role combinations`
- acceptance:
- `exactly one admin user can exist in this version`
- `first registered user is assigned admin automatically`
- `agent-role users are blocked from admin assignment`
- planned_commits:
- `feat(auth): enforce single-admin bootstrap and fixed role taxonomy`
- `test(auth): cover role constraints and first-user admin rules`
- PR:
- `tbd`

### Slice 2: RBAC Gates for Ticket Governance

- status: `pending`
- branch: `feat/slice-2-ticket-rbac-gates`
- objective: `apply minimal RBAC checks on assignment/archive/delete flows`
- tasks:
- [ ] `T2.1 restrict ticket assignment to admin`
- [ ] `T2.2 restrict archive and delete ticket actions to admin`
- [ ] `T2.3 keep create/edit available to authenticated users under current MVP policy`
- [ ] `T2.4 add controller tests for allowed/blocked role paths`
- acceptance:
- `non-admin users cannot assign/archive/delete`
- `admin can perform assignment/archive/delete`
- planned_commits:
- `feat(authz): gate ticket governance actions behind admin role`
- `test(authz): add ticket action authorization coverage`
- PR:
- `tbd`

### Slice 3: Kanban DnD Semantics (Columns Locked)

- status: `pending`
- branch: `feat/slice-3-kanban-dnd-semantic-hardening`
- objective: `deliver deterministic ticket drag behavior with archive/delete drop zones while keeping column reorder disabled`
- tasks:
- [ ] `T3.1 hide column reorder handle from UI and keep reorder logic disabled/commented`
- [ ] `T3.2 harden ticket drag-drop transition handling to ensure status/column updates always apply`
- [ ] `T3.3 add bottom drop zones shown only during drag gesture: A (archive), D (delete)`
- [ ] `T3.4 wire archive/delete drop zones to turbo-stream board updates`
- acceptance:
- `column reorder is not available in UI`
- `dragging a ticket between columns reliably updates status`
- `A/D drop zones appear only during drag and execute corresponding actions`
- planned_commits:
- `feat(web): harden ticket drag semantics and add archive-delete drop zones`
- `test(web): cover drag transition and drop-zone actions`
- PR:
- `tbd`

### Slice 4: Ticket Modal Workflow and Card Interaction Cleanup

- status: `pending`
- branch: `feat/slice-4-ticket-modal-interaction-cleanup`
- objective: `make ticket click open edit modal and remove explicit edit/archive/delete card buttons`
- tasks:
- [ ] `T4.1 make full ticket card clickable to open edit modal`
- [ ] `T4.2 remove explicit edit/archive/delete button controls from card body`
- [ ] `T4.3 preserve subtle assignee marker at bottom-right`
- [ ] `T4.4 add controller/view tests for modal open and update flow`
- acceptance:
- `clicking a ticket opens modal edit view`
- `archive/delete is only available through drag drop zones`
- `assignee remains visible as subtle @marker on card`
- planned_commits:
- `feat(web): streamline ticket card interactions and modal entry`
- `test(web): cover modal entry and ticket update flow`
- PR:
- `tbd`

## Global Exit Criteria

- `identity model includes fixed roles and single-admin bootstrap`
- `rbac gates protect assignment/archive/delete governance actions`
- `kanban drag semantics are deterministic with visible drag-only A/D zones`
- `ticket modal workflow is clean and card interaction model is consistent`
