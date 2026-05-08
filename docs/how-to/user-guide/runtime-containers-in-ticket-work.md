# Runtime Containers In Ticket Work

## Purpose

Understand how Runtime Containers and operational setup affect ticket execution.

## Before You Start

- Create a project through setup or register an existing project.
- Make sure the project has board tickets.
- Treat Runtime Containers as project-level recipes for creating ticket-scoped execution sandboxes.
- Treat `.rw/agent` as the project-local operational setup directory for agent
  ticket execution. It is not the production container definition.

## Steps

1. Let project setup initialize runtime container state.

Project setup generates or records Runtime Containers state for the project.

For supported stack profiles, RedWright can generate a more complete initial recipe. For unsupported or weakly covered stacks, it records missing information and may create a readiness ticket.

The project workspace may also contain:

```text
.rw/agent/Dockerfile
.rw/agent/runtime-setup.json
```

`runtime-setup.json` can provide validation commands for agent ticket work. If
metadata is absent, RedWright falls back to validation commands from the project
runtime container record.

2. Start ticket execution.

Telegram:

```text
/ticket start <ticket-key>
```

Web/API execution paths use the same ticket-first readiness contract.

3. Read the readiness result.

If the project runtime container recipe or operational setup is not ready,
ticket execution should return a structured readiness problem rather than
pretending work started.

If no validation commands are available, ticket execution blocks with a
structured `validation_commands_missing` result.

4. Resolve readiness gaps.

Use the readiness ticket or command/query management path to supply the missing
runtime container information, validation commands, validation state, or
readiness decision.

5. Reset the deterministic manual scenario when testing locally.

```bash
make agent-ticket-scenario-reset
make agent-ticket-scenario-inspect
```

The reset command prepares the Go todo CLI scenario. The inspect command
confirms the active project matches the reference workspace before a Telegram
ticket execution run.

## Verify

- Ticket execution returns a start result only when required readiness checks pass.
- Blocked execution reports a reason such as missing, blocked, stale, or not ready runtime container state.
- Validation runs the commands resolved from `.rw/agent/runtime-setup.json` or
  runtime container metadata.
- Project manifests include runtime container metadata when local workspace materialization has run.
- `make agent-ticket-scenario-inspect` reports no filesystem differences outside
  `.git` after a reset.

## Troubleshooting

- If a ticket does not start, inspect the runtime container readiness reason first.
- If the project stack is unsupported, expect a readiness task before automated sandbox execution is possible.
- If runtime container fields changed after validation, validation may be stale and must be recorded again or explicitly skipped with a reason.
- If validation commands are missing, add them to `.rw/agent/runtime-setup.json`
  or to the runtime container record.

## Related Docs

- [RedWright Agent Runtime Containers Specification](../../../ops/specs/specs/2026-05-03-redwright-agent-runtime-containers-spec.md)
- [Manage Boards And Tickets](manage-boards-and-tickets.md)
- [Project Manifest Reference](../../reference/project-manifest.md)
