# Repository Architecture

This document describes RedWright repository structure and ownership boundaries.

## Objective

Keep the Rails prototype simple, navigable, and easy to promote without hiding workflow behavior in oversized objects.

## Baseline structure

```
apps/web/      # Rails application
apps/web/app/  # controllers, models, views, services, and protocol templates
apps/web/test/ # Rails tests
ops/           # specs, plans, trackers, artifacts, and curated conversations
docs/          # user-facing and technical documentation
.agents/       # collaboration and execution rules for this repository
AGENTS.md      # top-level agent operating contract
```

## Boundary rules

- Controllers should stay thin and delegate workflows to models, services, or jobs.
- Multi-step workflows, sagas, materializers, runtime container orchestration, and protocol composition belong in focused service modules under `apps/web/app/services/`.
- Active Record models own persistence-backed invariants and associations; they should not become generic orchestration objects.
- Views should render state and local interaction affordances, not business workflows.
- Tests live under `apps/web/test/` and should mirror the behavior boundary being changed.
- Product and user documentation stays in `docs/`.
- Delivery planning, specs, trackers, and cycle records stay in `ops/`.
- Working rules stay in `.agents/` and `AGENTS.md`.

## Change discipline

- Structural changes must be explicit in commit scope.
- Do not introduce additional top-level directories or framework layers without clear need.
- Prefer extending the existing Rails and service-module structure before creating new architectural categories.
