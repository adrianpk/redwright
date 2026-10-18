# TypeScript Documentation Guidelines

This repository uses Diataxis under `docs/` for durable user-facing and technical documentation:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths.
- `docs/how-to/` for task procedures.
- `docs/reference/` for contracts and exact behavior.
- `docs/explanation/` for rationale and tradeoffs.

## TypeScript examples

- Keep setup and execution examples aligned with the package manager used by the project (`npm`, `pnpm`, `yarn`, or another documented command).
- Keep script examples aligned with actual `package.json` scripts.
- Keep module references aligned with exported names, file paths, and public package entrypoints.
- API/reference docs should describe exported types, functions, config fields, runtime validation behavior, and error contracts.
- Public package APIs should have useful documentation when they are part of the package contract.

## Contract documentation

- Document stable config fields, wire formats, public package APIs, event shapes, persisted data, and error contracts under `docs/reference/`.
- Document architectural rationale, typing tradeoffs, runtime validation decisions, and dependency choices under `docs/explanation/`.
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
