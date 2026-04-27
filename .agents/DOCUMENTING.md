# Documentation Guidelines

This repository uses Diataxis under `docs/`:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths
- `docs/how-to/` for task procedures
- `docs/reference/` for contracts and exact behavior
- `docs/explanation/` for rationale and tradeoffs

## Ruby-first documentation rules

- Keep setup and execution examples in Ruby project terms (`bundle install`, `bundle exec ...`).
- Keep CLI examples aligned with this repository entrypoints (`bin/` or `exe/` as defined by the project).
- API/reference docs should use Ruby naming and signatures.
- If API docs are generated, keep source comments compatible with YARD style.

## General rules

- Keep all repository docs in English.
- Each document should have one primary intent.
- Split documents when intent changes.
- Preserve technical meaning when reorganizing docs.

## Scope boundary

Diataxis applies to `docs/*` only.
Operational instructions in `.agents/*` are outside Diataxis.
