# Zig Documentation Guidelines

This repository uses Diataxis under `docs/` for durable user-facing and technical documentation:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths.
- `docs/how-to/` for task procedures.
- `docs/reference/` for contracts and exact behavior.
- `docs/explanation/` for rationale and tradeoffs.

## Zig examples

- Keep setup and execution examples in Zig project terms (`zig build`, `zig build test`, `zig test <file>`).
- Keep build examples aligned with actual `build.zig` steps.
- Keep module references aligned with file paths and public declarations.
- API/reference docs should describe structs, functions, error sets, allocation ownership, and returned slice lifetimes.
- Document ownership expectations whenever an API allocates, borrows, or transfers memory.

## Contract documentation

- Document stable file formats, config fields, wire formats, public module APIs, and error contracts under `docs/reference/`.
- Document architectural rationale, memory ownership tradeoffs, and runtime choices under `docs/explanation/`.
- Keep operational runbooks and task procedures under `docs/how-to/`.
- Keep onboarding or guided learning material under `docs/tutorials/`.

## General rules

- Keep all repository docs in English.
- Each document should have one primary intent.
- Split documents when intent changes.
- Preserve technical meaning when reorganizing docs.
- Avoid title/heading suffixes in parentheses.
- Prefer semantic metadata fields over title decoration when state needs to be explicit.
- For structural documentation updates, complete one consistency pass before commit.

## Scope boundary

Diataxis applies to `docs/*` only.
Operational instructions in `.agents/*` are outside Diataxis.
