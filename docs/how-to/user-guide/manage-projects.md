# Manage Projects

## Purpose

Create, inspect, switch, and recover project context in RedWright.

## Before You Start

- Start the local stack.
- Decide whether you are creating a new local project or cloning/registering an existing repository.
- For Telegram, make sure the chat has an active project context before ticket work.

## Steps

1. Create a project from Telegram.

```text
/project new hello-cli
```

2. Continue answering setup questions until the setup completes.

Project setup creates or updates:

- project record
- board
- starter ticket
- project documents
- project protocols
- runtime containers recipe state
- local workspace and `.redwright/manifest.yml` when materialized

3. Create a project from the web app.

Open:

```text
/projects/new
```

Provide:

- project name
- directory name
- repository input
- guided alignment choice

4. Clone and register an existing repository from Telegram.

```text
/repo clone <remote-url>
/repo clone <remote-url> as <project-name>
```

5. List or inspect current project context from Telegram.

```text
/project list
/project where
```

6. Open the project in the web app.

From a project page, continue to:

- protocols
- documents
- board

## Verify

- The project appears in the web app project list.
- The project has a board.
- The project has project protocol documents.
- The workspace contains `.redwright/manifest.yml` when materialized locally.
- Telegram `/project where` returns the expected context.

## Troubleshooting

- If web project creation rejects repository input, provide a URL, SSH git URL, or owner/repo style input.
- If Telegram loses context, use `/project list` and then create or switch context again.
- If runtime SQLite was reset, bootstrap again so project state can be rehydrated from manifests.

## Related Docs

- [Bootstrap Project Context](../bootstrap-project-context.md)
- [Clone And Register Project](../clone-and-register-project.md)
- [Recover Runtime State After DB Reset](../recover-runtime-state-after-db-reset.md)
- [Project Manifest Reference](../../reference/project-manifest.md)
