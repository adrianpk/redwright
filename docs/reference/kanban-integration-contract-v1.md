# Kanban Integration Contract v1

## Scope
Defines the integration contract between Kanban application surfaces and the runtime Command/Query core.

## Base Path
`/api/v1`

## Authentication
All endpoints require authenticated actor context.

Required headers:
- `Authorization: Bearer <token>`
- `X-Actor-Id: <identity>`
- `X-Request-Id: <request-id>`

## Command Endpoints

### POST `/commands/tickets`
Creates a ticket-oriented command envelope and dispatches it.

Request body:
```json
{
  "name": "MoveTicket",
  "payload": {
    "ticket_id": "RW-42",
    "to_column": "review"
  },
  "execution_context": {
    "runtime": "factory",
    "role": "coder",
    "actor_id": "agent_coder"
  }
}
```

Response (accepted):
```json
{
  "status": "ok",
  "request_id": "req-uuid",
  "result": {}
}
```

## Query Endpoints

### POST `/queries/tickets`
Dispatches ticket query envelopes.

Request body:
```json
{
  "name": "GetTickets",
  "payload": {
    "project_id": "p1",
    "status": "in_review"
  },
  "execution_context": {
    "runtime": "factory",
    "role": "human_operator",
    "actor_id": "user_1"
  }
}
```

Response:
```json
{
  "status": "ok",
  "request_id": "req-uuid",
  "result": {
    "tickets": []
  }
}
```

### POST `/queries/board`
Dispatches board-level queries.

Allowed names:
- `GetBoard`
- `GetFactoryStatus`

## Error Contract
All command/query errors must use the same envelope.

```json
{
  "status": "error",
  "request_id": "req-uuid",
  "error": {
    "code": "unsupported_action",
    "message": "no handler registered for GetBoard"
  }
}
```

Error codes:
- `invalid_envelope`
- `invalid_payload`
- `unsupported_action`
- `unauthorized`
- `forbidden_transition`
- `execution_failed`

## Transport Rules
1. Request handlers must not run domain logic directly.
2. Adapters must map payloads to command/query envelopes before dispatch.
3. All responses must include `request_id`.
4. Runtime role constraints are enforced in handlers, not in transport adapters.
