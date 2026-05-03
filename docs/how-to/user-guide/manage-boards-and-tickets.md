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
- linked documents

3. Move a ticket.

Move tickets between board columns in the web app. The board updates affected columns.

4. Archive or delete tickets.

Archive and delete operations require admin authorization.

5. Pick or start tickets from Telegram.

```text
/ticket list
/ticket pick
/ticket start <ticket-id>
```

6. Let ticket execution resolve readiness.

When starting ticket execution, RedWright resolves required project context and runtime container readiness before claiming work started.

## Verify

- New tickets appear in the selected board column.
- Priority and assignee values are visible on the ticket.
- Linked documents remain attached after save.
- Telegram ticket commands return either ticket details or a structured reason when work cannot start.

## Troubleshooting

- If assignment fails in the web app, switch to an admin user.
- If no ticket is picked, check assignment, priority, and board visibility.
- If ticket execution does not start, inspect the returned readiness or context problem.
- If a ticket needs more project context, attach related documents or update the project protocol before retrying.

## Related Docs

- [Kanban Integration Contract v2](../../reference/kanban-integration-contract-v1.md)
- [Ticket Visibility Policy v1](../../reference/ticket-visibility-policy-v1.md)
- [Runtime Execution And Role Constraints v2](../../reference/runtime-modes-and-roles-v1.md)
