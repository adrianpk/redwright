# Documentation Guidelines

This repository uses Diataxis under `docs/` for durable user-facing and technical documentation:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths
- `docs/how-to/` for task procedures
- `docs/reference/` for contracts and exact behavior
- `docs/explanation/` for rationale and tradeoffs

## Operational documents

- `ops/specs/` stores formal specs, drafts, and curated alignment conversations.
- `ops/plans/` stores cycle plans.
- `ops/trackers/` stores execution trackers.
- `ops/artifacts/` stores durable cycle outputs and reports.
- Do not mix operational delivery records into `docs/` unless they become durable product documentation.

## Ruby and Rails examples

- Keep setup and execution examples in Ruby/Rails project terms (`bundle install`, `bundle exec ...`, `bundle exec rails ...`).
- Keep app examples aligned with `apps/web`.
- Keep CLI examples aligned with repository entrypoints when they exist.
- API/reference docs should use Ruby naming and signatures.
- If API docs are generated, keep source comments compatible with YARD style.

## General rules

- Keep all repository docs in English.
- Each document should have one primary intent.
- Split documents when intent changes.
- Preserve technical meaning when reorganizing docs.
- Avoid title/heading suffixes in parentheses (for example `(Draft)`).
- Prefer semantic metadata fields (for example `Status`) over title decoration when state needs to be explicit.
- For structural documentation updates, complete one consistency pass before commit.
- Prefer one cohesive commit per documentation iteration; avoid corrective micro-commits caused by partial updates.

## Scope boundary

Diataxis applies to `docs/*` only.
Operational instructions in `.agents/*` are outside Diataxis.
