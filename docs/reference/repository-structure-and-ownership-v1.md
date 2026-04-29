# Repository Structure and Ownership v1

## Goal
Define a factory-ready repository structure with explicit module ownership boundaries.

## Target Directory Map

```text
apps/
  web/                    # Rails UI + auth + kanban presentation

core/
  application/            # command/query handlers and application services
  domain/                 # entities, value objects, policies, invariants
  ports/                  # outbound and inbound interfaces

adapters/
  ingress/
    telegram/             # telegram -> command/query mapping
    tui/                  # tui -> command/query mapping
    web/                  # rails/web -> command/query mapping
  egress/
    git/                  # git provider adapter
    sandbox/              # docker/podman sandbox adapter
    llm/                  # llm provider adapter
    persistence/          # repository implementations

runtime/
  interactive/            # low-latency direct runtime orchestration
  factory/                # ticket-driven sandbox runtime orchestration

test/
  unit/
  integration/
  e2e/
```

## Ownership Rules

1. `core/domain` owns business invariants and transition rules.
2. `core/application` owns command/query orchestration and policy execution.
3. `core/ports` owns integration contracts consumed by adapters.
4. `adapters/*` translate external protocols to/from core contracts.
5. `runtime/*` coordinates execution flow and lifecycle, without owning domain rules.
6. `apps/web` owns UI, human auth, and board/ticket presentation concerns.

## Dependency Direction

Allowed:
1. `apps/*` -> `core/*`
2. `adapters/*` -> `core/*`
3. `runtime/*` -> `core/*` and `adapters/*`

Not allowed:
1. `core/*` -> `apps/*`
2. `core/domain` -> `adapters/*` or `runtime/*`
3. `core/application` -> concrete egress implementations

## Backward Compatibility Rule

Existing runtime entrypoints remain valid during migration. Compatibility shims may route legacy paths into the new structure until migration is complete.
