# Runtime Execution and Role Constraints v2

## Execution Modes

### Single Ticket
- Execute one selected ticket lifecycle.
- Lifecycle phases: `coding -> review -> merge`.
- Stops after ticket terminal state.

### Loop
- Continuously picks next eligible ticket.
- Selection baseline: assigned tickets first, then highest priority.
- Repeats lifecycle until stop condition.

## Ticket-First Rule
All mutating execution must target a ticket.

If ingress request has no ticket:
1. Create/derive ticket.
2. Place ticket in correct board column.
3. Start lifecycle execution under selected mode.

## Role Constraints

### Coder
- Can mutate code and open PRs.
- Cannot merge PRs.

### Reviewer
- Can review PRs and emit approval/rejection.
- Cannot merge or author implementation commits.

### Merger
- Can merge approved PRs and perform merge cleanup.
- Cannot author implementation commits.

## MVP Runtime Topology
- One bot.
- One runtime agent process.
- Team/pool model is deferred.

## Enforcement
Role constraints and ticket-first policy are enforced in application handlers, not only by prompt conventions.
