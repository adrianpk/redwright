# Slash Commands Reference

## Scope

This document describes slash command forms currently interpreted by the Telegram runtime input layer.

## Control Commands

- `/pause` -> task control `pause`
- `/resume` -> task control `resume`
- `/cancel` -> task control `stop`

Task-scoped aliases:

- `/task pause`
- `/task resume`
- `/task cancel`

## Project Commands

- `/project new <name>`
- `/project switch <name-or-alias>`
- `/project list`
- `/project where`

Notes:

- `new` and `switch` map to planner hints, then runtime/project resolution applies.
- `new` creates workspace project directory and registers project metadata.

## Repository Commands

- `/repo clone <url>`
- `/repo clone <url> as <name>`
- `/repo status`
- `/repo undo`

Notes:

- `clone` creates/registers a project and writes manifest when missing.
- `undo` is guarded and only allowed for safe git-only last-task cases.

## Planning Commands

- `/plan start`
- `/plan continue`
- `/plan stop-and-apply`
- `/continue`
- `/status`

These map to planner hints (semantic routing), not direct primitive execution.

## Conversation Commands

Quiz commands:

- `/quiz`
- `/quiz for <use-case-name>`
- `/quiz list`

Dump commands:

- `/dump`
- `/dump for <use-case-name>`
- `/dump list`
- `/dump show <dump-slug-or-id>`
- `/dump done`
- `/dump curate`
- `/dump cancel`

Notes:

- `/quiz` opens or continues a project quiz.
- `/quiz for <use-case-name>` opens or continues a use-case quiz.
- `/dump` opens or continues a project dump.
- `/dump for <use-case-name>` opens or continues a use-case dump.
- While editing a dump, each non-command Telegram message replaces its complete Markdown body.
- `/dump done` marks the document ready and exits editing.
- `/dump curate` polishes the same document through the wrapped harness; errors preserve it.
- `/dump cancel` exits editing without discarding content already saved.

## Ticket Commands

- `/ticket list`
- `/ticket pick`
- `/ticket start <ticket-key>`

Notes:

- `ticket-key` is the human-readable ticket key shown on the board, such as
  `RW-10`.
- `/ticket start` runs asynchronously: Telegram receives an initial
  acknowledgement, and RedWright sends a final completed or blocked result when
  execution ends.
- A completed agent ticket run moves the ticket to review after validation and
  commit.
- A blocked agent ticket run moves the ticket to blocked with a structured
  reason.

## Trace Commands

- `/trace on`
- `/trace off`
- `/trace status`

These map to planner hints for runtime trace handling.

## Skills Commands

- `/skills`
- `/skill <name>`
- `/skill stop-and-apply`

`/skill <name>` triggers explicit skill mode for the turn.

## Help Command

- `/help`

Returns a planner hint to show command guidance.
