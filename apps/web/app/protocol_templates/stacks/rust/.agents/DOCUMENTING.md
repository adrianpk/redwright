# Rust Documentation Guidelines

This repository uses Diataxis under `docs/` for durable user-facing and technical documentation:
https://diataxis.fr

## Categories

- `docs/tutorials/` for learning paths.
- `docs/how-to/` for task procedures.
- `docs/reference/` for contracts and exact behavior.
- `docs/explanation/` for rationale and tradeoffs.

## Rust examples

- Keep setup and execution examples in Rust project terms (`cargo build`, `cargo test`, `cargo run`).
- Keep feature examples aligned with actual Cargo features.
- Keep module references aligned with crate, module, trait, struct, enum, and function names.
- API/reference docs should describe public types, trait contracts, error behavior, feature flags, and ownership expectations.
- Public crate APIs should have useful rustdoc when they are part of the package contract.

## Contract documentation

- Document stable file formats, config fields, wire formats, public crate APIs, feature flags, and error contracts under `docs/reference/`.
- Document architectural rationale, ownership tradeoffs, and runtime choices under `docs/explanation/`.
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
