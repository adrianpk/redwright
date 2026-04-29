# Runtime Modes and Role Constraints v1

## Modes

### Interactive
- Direct Telegram/TUI operation.
- No Docker sandbox.
- Optimized for low latency.

### Factory
- Ticket-driven operation.
- Docker sandbox required.
- Optimized for reproducibility and isolation.

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

## Enforcement
Role constraints are enforced in application handlers, not only by prompt conventions.
