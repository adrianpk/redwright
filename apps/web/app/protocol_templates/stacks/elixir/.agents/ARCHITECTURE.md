# Elixir Architecture

This document describes Elixir repository structure and ownership boundaries.

## Objective

Keep the Elixir codebase explicit, supervision-aware, and easy to reason about without replacing simple data transformations with unnecessary processes.

## Baseline structure

```text
lib/          # application modules and supervision tree code
config/       # Mix and runtime configuration
test/         # ExUnit tests
priv/         # runtime assets, migrations, seeds, or static data when used
docs/         # user-facing and technical documentation
.formatter.exs # formatting configuration
mix.exs       # project, dependency, app, and task configuration
.agents/      # collaboration and execution rules for this repository
AGENTS.md     # top-level agent operating contract
```

## Boundary rules

- Keep domain behavior in cohesive modules or contexts with explicit public APIs.
- Prefer pure functions and immutable data transformations for business behavior.
- Use supervised processes only for state, lifecycle, concurrency, or fault-tolerance needs that justify them.
- Keep GenServer callbacks focused on process mechanics; delegate domain decisions to plain functions where practical.
- Keep IO adapters, persistence, external services, and transport concerns separated from pure transformations.
- Keep configuration access close to process startup or adapter boundaries; avoid scattering runtime config reads through core logic.
- Tests should live under `test/` and mirror the module or behavior boundary being changed.

## Supervision and runtime

- Supervision trees should make ownership and restart behavior visible.
- Process names, registries, and dynamic supervisors should be introduced only when runtime behavior requires them.
- Long-running processes should expose clear initialization, state, and failure behavior.
- Message formats between processes should be explicit and tested when they are part of the contract.

## Change discipline

- Structural changes must be explicit in commit scope.
- Prefer extending existing modules and contexts before creating new architectural categories.
- Do not introduce process state, umbrella apps, or broad supervision changes without clear need.
