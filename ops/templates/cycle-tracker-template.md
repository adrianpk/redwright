# Cycle Tracker: <cycle-title>

## Metadata

- cycle_id: `<cycle-id>`
- status: `in_progress | completed | blocked`
- state: `idle | alignment | planning | executing_slice | validating | awaiting_review | merging | syncing | next_slice | done | blocked`
- updated: `YYYY-MM-DD`
- active_slice: `<slice-id-or-none>`
- active_task: `<task-id-or-none>`

## Slice Progress

### Slice <n>: <slice-title>

- status: `pending | in_progress | completed | blocked`
- branch: `fix/slice-<n>-<slug>`
- PR: `<pr-reference-or-tbd>`
- merge_target: `dev`
- last_sync_commit: `<sha-or-tbd>`

Tasks:

- [ ] `T<n>.1 <task description>`
- [ ] `T<n>.2 <task description>`

Commits:

- [ ] `<sha> <type(scope): subject>`

Validation:

- [ ] `<test or check>`

## Event Log

- `YYYY-MM-DD HH:MM` state=`<state>` note=`<event>`
