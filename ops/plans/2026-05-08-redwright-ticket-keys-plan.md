# Cycle Plan: RedWright Ticket Keys

## Metadata

- cycle_id: `cycle-2026-05-08-redwright-ticket-keys`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-08`
- source_spec: `ops/specs/specs/2026-05-08-redwright-ticket-keys-spec.md`
- goal: `replace SQLite row IDs as the manual ticket invocation reference with persistent ticket keys`

## Slice List

### Slice 1: Ticket Key Foundation

- status: `planned`
- branch: `fix/ticket-key-rename`
- pr_title: `refactor(tickets): rename external ticket identifier`
- objective: `add RW-prefixed ticket keys and use them for manual agent ticket invocation`
- tasks:
- [ ] `T1.1 document the ticket key behavior and command contract`
- [ ] `T1.2 add ticket key persistence, backfill, validation, and generation`
- [ ] `T1.3 expose ticket keys in board payloads and ticket cards`
- [ ] `T1.4 resolve agent ticket execution by ticket key while keeping numeric compatibility`
- [ ] `T1.5 update the deterministic Go todo scenario reset to print the ticket-key Telegram command`
- acceptance:
- `tickets have unique RW-prefixed ticket keys`
- `manual Telegram command can use /ticket start RW-<n>`
- `the deterministic scenario active project is restored under _workspace/Projects`
- `board UI exposes the ticket key`
- planned_commits:
- `refactor(tickets): rename external ticket identifier`
