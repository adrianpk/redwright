# Use The Web App

## Purpose

Use the Rails web app to inspect and manage projects, boards, tickets, documents, protocols, and protocol templates.

## Before You Start

- Start the local stack with `bundle exec rake app:run:foreground`.
- Open the web app at `http://127.0.0.1:3000`.
- Sign in with a seeded local user or another configured account.

## Steps

1. Open the board list.

The root page opens the board area.

```text
/
```

2. Open a project.

Use the projects area to inspect project metadata:

- name
- description
- root path
- repository
- stack

3. Move from a project to its main areas.

Project pages link to:

- `Protocols`
- `Documents`
- `Board`

4. Use the board.

The board lets you:

- create a ticket
- edit tickets
- move tickets between columns
- archive or delete tickets when authorized

5. Use documents.

The documents area separates:

- drafts
- specs
- plan trackers

Drafts are editable. Specs and plan trackers are read-only in the current web surface.

6. Use protocols.

The project protocols area lets you inspect and edit the Markdown protocol documents attached to a project.

7. Use protocol templates.

The protocol templates area lets you inspect common templates and stack templates, then edit their Markdown documents for future project setup runs.

## Verify

- Project pages show links to protocols, documents, and board when those resources exist.
- Ticket changes update the board.
- Protocol edits are saved and projected to the project workspace.
- Template edits affect future project setup composition, not already copied project protocols.

## Troubleshooting

- If assignment is rejected, use an admin user; ticket assignment is admin-gated.
- If a draft cannot be edited, confirm it is still a draft and not already promoted.
- If protocol file changes do not appear in a workspace, confirm the project has a materialized local workspace.

## Related Docs

- [Manage Projects](manage-projects.md)
- [Manage Boards And Tickets](manage-boards-and-tickets.md)
- [Manage Documents And Protocols](manage-documents-and-protocols.md)
