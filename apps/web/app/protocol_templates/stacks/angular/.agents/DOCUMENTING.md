# Angular Documentation Guidelines

This repository uses Diataxis under `docs/` for durable user-facing and technical documentation:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths.
- `docs/how-to/` for task procedures.
- `docs/reference/` for contracts and exact behavior.
- `docs/explanation/` for rationale and tradeoffs.

## Angular examples

- Keep setup and execution examples aligned with the package manager used by the project (`npm`, `pnpm`, `yarn`, or another documented command).
- Keep command examples aligned with actual `package.json` scripts and Angular workspace commands.
- Keep code references aligned with Angular components, services, routes, guards, interceptors, modules, and standalone APIs used by the project.
- API/reference docs should describe component inputs/outputs, route contracts, service APIs, config fields, runtime validation behavior, and error contracts.
- Public shared UI or library APIs should have useful documentation when they are part of the package contract.

## Contract documentation

- Document stable route behavior, component contracts, service APIs, config fields, API response shapes, and state models under `docs/reference/`.
- Document architectural rationale, state-management tradeoffs, routing decisions, and dependency choices under `docs/explanation/`.
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
