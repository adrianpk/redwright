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
