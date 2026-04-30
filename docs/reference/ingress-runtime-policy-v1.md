# Ingress and Runtime Policy v2

## Scope
Defines unified ingress policy for one bot and one ticket-centric runtime surface.

## Unified Runtime Mapping
- Telegram, TUI, and Rails all map to the same Command/Query core.
- No ingress path may bypass ticket semantics for mutating work.

## Ticketization Policy

1. If request references ticket explicitly:
- Resolve ticket.
- Execute in `single_ticket` mode unless user requests `loop`.

2. If request has no ticket:
- Create ticket from intent.
- Assign project/board context.
- Place in workflow column according to intent.

3. Special handling:
- `new project` requests must create a board and a setup ticket.

## Notifications Policy
- Runtime emits ticket progress updates to Telegram by default.
- Notification channel/mode becomes configurable in later slices.

## Identity and Access
1. Actor identity is mandatory for each command/query.
2. Ticket visibility policy must pass before dispatch.
3. Priority-based selection must still respect assignment/visibility rules.

## Error Contract
On policy violation:

```json
{
  "status": "error",
  "error": {
    "code": "unauthorized",
    "message": "ticket visibility policy denied"
  }
}
```

## Observability Requirements
Each ingress event must emit:
- ticket id (or ticket creation event id)
- execution mode (`single_ticket|loop`)
- actor identity
- request id
- decision outcome (`allowed|denied`)
