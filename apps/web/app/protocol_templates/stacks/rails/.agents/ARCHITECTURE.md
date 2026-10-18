# Rails Architecture

This document describes Rails repository structure and ownership boundaries.

## Objective

Keep the Rails application idiomatic, navigable, and easy to evolve without hiding workflows in oversized controllers, models, or callbacks.

## Baseline structure

```text
app/controllers/  # HTTP request handling and response coordination
app/models/       # Active Record models and persistence-backed invariants
app/services/     # application workflows and orchestration objects
app/jobs/         # asynchronous and retryable work
app/views/        # server-rendered UI templates
app/helpers/      # view helpers for presentation logic
config/           # routes, environment configuration, initializers
db/               # migrations, schema, and seeds
test/             # Rails tests
docs/             # user-facing and technical documentation
.agents/          # collaboration and execution rules for this repository
AGENTS.md         # top-level agent operating contract
```

## Boundary rules

- Follow Rails conventions before adding custom framework layers.
- Controllers should stay thin: load state, authorize if applicable, delegate workflows, and return responses.
- Active Record models should own persistence-backed invariants, associations, validations, and simple domain behavior.
- Use service objects for multi-step workflows, sagas, materializers, external integrations, and orchestration that crosses model boundaries.
- Use jobs for asynchronous work, retries, scheduled execution, or operations that should not block the request cycle.
- Views should render state and local interaction affordances, not business workflows.
- Helpers should keep presentation code readable; they should not become workflow containers.
- Concerns should be small and cohesive; avoid using them to hide broad shared behavior.
- Tests should live under `test/` and mirror the Rails boundary being changed.

## Persistence and transactions

- Keep migrations reversible when practical and explicit when not.
- Keep data migrations deliberate and separated from broad schema refactors when risk is meaningful.
- Use transactions around multi-record state changes that must commit atomically.
- Avoid callbacks for complex orchestration unless they enforce a clear persistence invariant.

## Change discipline

- Structural changes must be explicit in commit scope.
- Prefer extending Rails' established app structure before creating new top-level architecture categories.
- Keep application workflows discoverable by package, namespace, or service name.
