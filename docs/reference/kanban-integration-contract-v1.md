# Kanban Integration Contract v2

## Scope
Defines integration between Rails Kanban surface and runtime Command/Query core under ticket-first execution.

## Base Path
`/api/v1`

## Authentication
All endpoints require authenticated actor context.

Required headers:
- `Authorization: Bearer <token>`
- `X-Actor-Id: <identity>`
- `X-Request-Id: <request-id>`

## Ticket Metadata Contract
Each ticket must support:
- `priority`: `high|medium|low`
- `time_tracking`:
  - `coding_started_at`
  - `coding_stopped_at`
  - `review_started_at`
  - `review_completed_at`
  - `merge_started_at`
  - `merged_at`
  - `elapsed_seconds_total`
  - `elapsed_seconds_by_phase`

## Command Endpoints

### POST `/commands/tickets`
Creates and dispatches ticket commands.

Supported names (MVP):
- `CreateTicket`
- `AssignTicket`
- `MoveTicket`
- `StartTicketExecution`
- `StartLoopExecution`
- `StopLoopExecution`

### POST `/commands/intake`
Transforms ad-hoc ingress request into ticketized work.

Request body:
```json
{
  "name": "IntakeRequestAsTicket",
  "payload": {
    "project_id": "p1",
    "text": "build a simple CLI ping/pong app",
    "source": "telegram"
  }
}
```

Behavior:
- creates ticket,
- sets initial column/status,
- returns created ticket id.

## Query Endpoints

### POST `/queries/tickets`
Dispatches ticket queries.

Supported names (MVP):
- `GetTicket`
- `GetTicketsByProject`
- `GetNextTicketByPriority`

### POST `/queries/board`
Dispatches board-level queries.

Supported names (MVP):
- `GetBoard`
- `GetBoardMetrics`

## Transport Rules
1. Request handlers must not run domain logic directly.
2. Adapters must map payloads to command/query envelopes before dispatch.
3. All responses must include `request_id`.
4. Mutating execution must target a ticket id.

## Error Contract
All command/query errors use same envelope.

```json
{
  "status": "error",
  "request_id": "req-uuid",
  "error": {
    "code": "unsupported_action",
    "message": "no handler registered"
  }
}
```
