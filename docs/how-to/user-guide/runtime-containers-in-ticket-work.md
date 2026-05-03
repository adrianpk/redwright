# Runtime Containers In Ticket Work

## Purpose

Understand how Runtime Containers affect ticket execution.

## Before You Start

- Create a project through setup or register an existing project.
- Make sure the project has board tickets.
- Treat Runtime Containers as project-level recipes for creating ticket-scoped execution sandboxes.

## Steps

1. Let project setup initialize runtime container state.

Project setup generates or records Runtime Containers state for the project.

For supported stack profiles, RedWright can generate a more complete initial recipe. For unsupported or weakly covered stacks, it records missing information and may create a readiness ticket.

2. Start ticket execution.

Telegram:

```text
/ticket start <ticket-id>
```

Web/API execution paths use the same ticket-first readiness contract.

3. Read the readiness result.

If the project runtime container recipe is not ready, ticket execution should return a structured readiness problem rather than pretending work started.

4. Resolve readiness gaps.

Use the readiness ticket or command/query management path to supply the missing runtime container information, validation state, or readiness decision.

## Verify

- Ticket execution returns a start result only when required readiness checks pass.
- Blocked execution reports a reason such as missing, blocked, stale, or not ready runtime container state.
- Project manifests include runtime container metadata when local workspace materialization has run.

## Troubleshooting

- If a ticket does not start, inspect the runtime container readiness reason first.
- If the project stack is unsupported, expect a readiness task before automated sandbox execution is possible.
- If runtime container fields changed after validation, validation may be stale and must be recorded again or explicitly skipped with a reason.

## Related Docs

- [RedWright Agent Runtime Containers Specification](../../../ops/specs/specs/2026-05-03-redwright-agent-runtime-containers-spec.md)
- [Manage Boards And Tickets](manage-boards-and-tickets.md)
- [Project Manifest Reference](../../reference/project-manifest.md)
