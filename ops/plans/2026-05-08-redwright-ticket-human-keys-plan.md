# Cycle Plan: RedWright Ticket Human Keys

## Metadata

- cycle_id: `cycle-2026-05-08-redwright-ticket-human-keys`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-08`
- source_spec: `ops/specs/specs/2026-05-08-redwright-ticket-human-keys-spec.md`
- goal: `replace SQLite row IDs as the manual ticket invocation reference with persistent human-readable ticket keys`

## Slice List

### Slice 1: Ticket Human Key Foundation

- status: `planned`
- branch: `fix/slice-1-ticket-human-keys`
- pr_title: `feat(slice-1): add ticket human keys`
- objective: `add RW-prefixed ticket keys and use them for manual agent ticket invocation`
- tasks:
- [ ] `T1.1 document the human key behavior and command contract`
- [ ] `T1.2 add ticket human key persistence, backfill, validation, and generation`
- [ ] `T1.3 expose human keys in board payloads and ticket cards`
- [ ] `T1.4 resolve agent ticket execution by human key while keeping numeric compatibility`
- [ ] `T1.5 update the deterministic Go todo scenario reset to print the human-key Telegram command`
- acceptance:
- `tickets have unique RW-prefixed human keys`
- `manual Telegram command can use /ticket start RW-<n>`
- `the deterministic scenario active project is restored under _workspace/Projects`
- `board UI exposes the human key`
- planned_commits:
- `feat(tickets): add human-key ticket invocation`
