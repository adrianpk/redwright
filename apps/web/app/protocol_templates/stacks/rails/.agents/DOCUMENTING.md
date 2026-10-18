# Rails Documentation Guidelines

This repository uses Diataxis under `docs/` for durable user-facing and technical documentation:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths.
- `docs/how-to/` for task procedures.
- `docs/reference/` for contracts and exact behavior.
- `docs/explanation/` for rationale and tradeoffs.

## Rails examples

- Keep setup and execution examples in Rails project terms (`bundle install`, `bin/rails`, `bundle exec rails ...`).
- Keep command examples aligned with actual app entrypoints and binstubs.
- Keep model, controller, route, job, and service references aligned with Rails naming.
- API/reference docs should use Ruby names, method signatures, model fields, routes, and response contracts.
- If generated API docs are used, keep source comments compatible with the selected Ruby documentation tool.

## Contract documentation

- Document routes, request/response contracts, config fields, persistence schemas, background jobs, and public service contracts under `docs/reference/`.
- Document architectural rationale and tradeoffs under `docs/explanation/`.
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
