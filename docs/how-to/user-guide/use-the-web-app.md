# Use The Web App

## Purpose

Use the Rails web app to inspect and manage projects, boards, tickets, specifications, protocols, protocol templates, dumps, and quizzes.

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
- `Specs`
- `Board`

The top navigation follows this order: `Cases`, `Dumps`, `Quizzes`, `Specs`, `Board`,
and `Protocol`. Admin users also see `Settings` at the end.

4. Capture context with Dumps and Quizzes.

The top navigation provides separate entries, in this order:

- `Dumps` for user-led knowledge capture
- `Quizzes` for RedWright-led questionnaire capture

Closed and curated dumps can be selected as ticket execution context when the context policy and scope match.

5. Use the board.

The board lets you:

- create a ticket
- edit tickets
- move tickets between columns
- archive or delete tickets when authorized

6. Create and approve specifications.

Open `Specs` and select `New`. In the modal, choose a use case when relevant,
describe the feature, and select `Generate`. RW uses the wrapped harness to
produce a draft from project context, optional dumps, and quiz decisions.

Review the generated specification and select `Approve`. The same specification
becomes approved. Use `Edit spec` for changes. For direct authoring, select
`New`, then `Write`, and choose `Save draft` or `Save and approve` without
discovery prerequisites.

Implementation work is managed through Board tickets. Internal trackers organize
their execution and do not appear in the web interface.

7. Use protocols.

The project protocols area reads and edits root `AGENTS.md` and all Markdown
files under the project's `.agents/` directory, including nested and custom files.

8. Use protocol templates.

The protocol templates area lets you inspect common templates and stack templates, then edit their Markdown documents for future project setup runs.

## Verify

- Project pages show links to protocols, specs, and board when those resources exist.
- The top navigation opens Dumps and Quizzes directly, with Dumps first.
- Ticket changes update the board.
- Protocol edits are saved directly to the selected workspace file.
- Template edits affect future project setup composition, not already copied project protocols.

## Troubleshooting

- If assignment is rejected, use an admin user; ticket assignment is admin-gated.
- If a specification save reports an external edit, reload the file before saving.
- If generation is unavailable, check the local harness configuration and session.
- If Protocols is empty, confirm the local project workspace exists and contains protocol Markdown files.

## Related Docs

- [Manage Projects](manage-projects.md)
- [Manage Boards And Tickets](manage-boards-and-tickets.md)
- [Manage Specs And Protocol](manage-documents-and-protocols.md)
- [Use Conversation Dumps](use-conversation-dumps.md)
