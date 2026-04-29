# Ingress and Runtime Policy v1

## Scope
Defines ingress policies for dual-bot operation and runtime partitioning.

## Runtime Mapping

1. `interactive` runtime
- Intended for direct operator workflows.
- Supported ingress: Telegram interactive bot, TUI.
- No sandbox required.

2. `factory` runtime
- Intended for ticket-driven autonomous workflows.
- Supported ingress: factory control bot, API/web orchestration.
- Sandbox required for mutating execution.

## Dual-Bot Policy

### Interactive Bot
- Channel purpose: project-scoped ad-hoc execution.
- Runtime target: `interactive`.
- Allowed command/query classes:
  - direct operational requests
  - local project context checks

### Factory Bot
- Channel purpose: board/ticket orchestration.
- Runtime target: `factory`.
- Allowed command/query classes:
  - ticket lifecycle commands
  - factory status and queue visibility queries

## Identity and Access

1. Bots must map to explicit actor identities.
2. Actor identity must map to role constraints.
3. Visibility policy evaluation must run before handler dispatch.

## Enforcement Rules

1. Ingress adapter must declare target runtime explicitly.
2. Runtime-role mismatch must fail with structured error.
3. Interactive ingress must not impersonate factory roles.
4. Factory ingress must not bypass ticket visibility policy.

## Error Contract

On policy violation:

```json
{
  "status": "error",
  "error": {
    "code": "unauthorized",
    "message": "runtime role mismatch for ingress"
  }
}
```

## Observability Requirements

Each ingress event must emit:
- runtime
- ingress channel identifier
- actor identity
- request id
- decision outcome (`allowed` | `denied`)
