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
- `Harness` for prepared authoring and ticket-proposal profile selections

The top navigation follows this order: `Cases`, `Dumps`, `Quizzes`, `Specs`, `Board`,
`Protocol`, and `Harness`. Admin users also see `Settings` at the end.

4. Capture context with Dumps and Quizzes.

The top navigation provides separate entries, in this order:

- `Dumps` for user-led knowledge capture
- `Quizzes` for RedWright-led questionnaire capture

Dump documents can be selected as ticket execution context when the context policy, scope, and topic match.

5. Use the board.

The board lets you:

- create a ticket
- edit tickets
- move tickets between columns
- archive or delete tickets when authorized

6. Create and approve specifications.

Open `Specs` and select `New`. In the modal, choose the feature's use case,
describe the feature, and select `Generate`. RW uses the wrapped harness to
produce a draft from project context, optional dumps, and quiz decisions.

Review the generated specification and select `Approved` on its status switch.
Click the document to edit its Markdown; leaving the editor saves it in place.
The selected Draft/Approved state is retained. For direct authoring, select
`New`, then `Write`, choose the status, and select `Save` without discovery
prerequisites. Document actions appear in the header; Save stays below the editor.

Implementation work is managed through Board tickets. Internal trackers organize
their execution and do not appear in the web interface.

Each use case is one feature with one specification. `Regenerate` incorporates
later discovery into it before execution starts. After approval, `Build tickets`
revises slicing while preserving retained ticket identities and obsolete history.
Once execution starts, use a linked corrective case for contract changes.

7. Use protocols.

The project protocols area reads and edits root `AGENTS.md` and all Markdown
files under the project's `.agents/` directory, including nested and custom files.

8. Use protocol templates.

The protocol templates area lets you inspect common templates and stack templates, then edit their Markdown documents for future project setup runs.

9. Select project harness defaults.

Open **Harness** to choose **Authoring** and **Ticket proposals** independently.
Local readiness checks prepared resources without contacting providers. Saved
defaults apply to new operations; active bindings retain their admitted choice.
Use the role's default option to clear a choice. See
[Configure RedWright](configure-redwright.md#choose-project-harnesses) for the
setup and verification steps, and [Harness Profiles](../../reference/harness-profiles.md)
for limits and recovery.

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
