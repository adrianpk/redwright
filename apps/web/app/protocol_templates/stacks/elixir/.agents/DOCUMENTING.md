# Elixir Documentation Guidelines

This repository uses Diataxis under `docs/` for durable user-facing and technical documentation:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths.
- `docs/how-to/` for task procedures.
- `docs/reference/` for contracts and exact behavior.
- `docs/explanation/` for rationale and tradeoffs.

## Elixir examples

- Keep setup and execution examples in Elixir project terms (`mix deps.get`, `mix test`, `iex -S mix`).
- Keep task examples aligned with actual Mix tasks.
- Keep module references aligned with Elixir module names and function arity when useful.
- API/reference docs should use module names, function signatures, structs, message shapes, config keys, and return contracts.
- Public module APIs should have useful moduledocs or function docs when they are part of the package contract.

## Contract documentation

- Document stable message formats, config fields, persistence schemas, public module APIs, and process contracts under `docs/reference/`.
- Document architectural rationale, supervision tradeoffs, and runtime choices under `docs/explanation/`.
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
