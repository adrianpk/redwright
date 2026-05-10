# Application Semantics v1 (Command/Query)

## Scope
Canonical semantic contract for all ingress surfaces.

## Envelope

```json
{
  "kind": "command",
  "name": "MoveTicket",
  "payload": {},
  "execution_context": {
    "runtime": "factory",
    "role": "coder",
    "actor_id": "agent_coder"
  },
  "request_id": "req-uuid"
}
```

`kind` values:
- `command`
- `query`

## Commands (v1)
- `CreateTicket`
- `UpdateTicket`
- `AssignTicket`
- `MoveTicket`
- `StartWorkOnTicket`
- `SubmitTicketPullRequest`
- `ReviewTicketPullRequest`
- `MergeTicketPullRequest`
- `PickNextTicket`
- `OpenQuiz`
- `AdvanceQuiz`
- `OpenDump`
- `AppendDump`
- `DoneDump`
- `CancelDump`
- `CurateDump`

## Queries (v1)
- `GetTicket`
- `GetTickets`
- `GetBoard`
- `GetFactoryStatus`
- `GetExecutionRun`
- `ListQuizzes`
- `ListDumps`
- `ShowDump`

## Execution Context

`runtime`:
- `interactive`
- `factory`

`role`:
- `coder`
- `reviewer`
- `merger`
- `human_operator`

## Validation Rules
1. No execution from raw text.
2. Envelope validation is mandatory.
3. AuthZ check is mandatory before handler invocation.
4. Unsupported command/query must return structured error.

## Error Contract

```json
{
  "error": {
    "code": "unauthorized",
    "message": "actor cannot access ticket",
    "request_id": "req-uuid"
  }
}
```

Recommended error codes:
- `invalid_envelope`
- `invalid_payload`
- `unauthorized`
- `forbidden_transition`
- `unsupported_action`
- `execution_failed`
