# Manage Boards And Tickets

## Purpose

Use the Kanban board as the operating surface for ticket-first work.

## Before You Start

- Create or select a project.
- Open the project's board from the web app or use Telegram ticket commands.
- Use an admin account when assigning tickets through the web app.

## Steps

1. Open a project board in the web app.

From the project page, select `Board`.

2. Create a ticket.

Use `New ticket` from the board.

Required field:

- title

Optional fields:

- description
- priority
- assignee
- status column
- use case
- comments

3. Move a ticket.

Move tickets between board columns in the web app. The board updates affected columns.

Common execution columns are:

- backlog
- in progress
- review
- blocked
- done

4. Archive or delete tickets.

Archive and delete operations require admin authorization.

5. Start tickets from Telegram.

```text
/ticket list
/ticket pick
/ticket start <ticket-key>
```

Use the human-readable ticket key shown on the board, for example `RW-10`.
Do not use the database row id as the operator-facing ticket reference.

6. Let ticket execution resolve readiness and completion.

When starting ticket execution, RedWright resolves required project context,
workspace boundaries, operational setup, validation commands, and runtime
container readiness before claiming work started.

If execution succeeds, RedWright commits the agent changes and moves the ticket
to review. If execution cannot continue, RedWright moves the ticket to blocked
with a structured reason.

## Verify

- New tickets appear in the selected board column.
- Priority and assignee values are visible on the ticket.
- Ticket keys such as `RW-10` are visible for external invocation.
- Use case scope and comments remain attached after save.
- Telegram ticket commands return an acknowledgement, followed later by a final
  execution result.
- Completed agent ticket execution creates a branch/commit and moves the ticket
  to review.

## Troubleshooting

- If assignment fails in the web app, switch to an admin user.
- If no ticket is picked, check assignment, priority, status, and board visibility.
- If ticket execution does not start, inspect the returned readiness or context problem.
- If a ticket is blocked with `validation_commands_missing`, add validation
  commands to the operational setup or runtime container metadata.
- If a ticket needs more project context, update the project protocol, use case,
  documents, or ticket description before retrying.

## Related Docs

- [Kanban Integration Contract v2](../../reference/kanban-integration-contract-v1.md)
- [Ticket Visibility Policy v1](../../reference/ticket-visibility-policy-v1.md)
- [Runtime Execution And Role Constraints v2](../../reference/runtime-modes-and-roles-v1.md)
