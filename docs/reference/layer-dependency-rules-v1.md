# Layer Dependency Rules v1

## Scope
Defines allowed and forbidden dependency directions for the factory-ready repository layout.

## Layers
- `core/domain`
- `core/application`
- `core/ports`
- `adapters/*`
- `runtime/*`
- `apps/*`

## Allowed Directions
1. `apps/*` -> `core/*`
2. `adapters/*` -> `core/*`
3. `runtime/*` -> `core/*`
4. `runtime/*` -> `adapters/*`
5. `core/application` -> `core/domain`
6. `core/application` -> `core/ports`

## Forbidden Directions
1. `core/*` -> `apps/*`
2. `core/domain` -> `core/application`
3. `core/domain` -> `adapters/*`
4. `core/domain` -> `runtime/*`
5. `core/application` -> `adapters/*`
6. `core/application` -> `runtime/*`
7. `core/ports` -> `adapters/*`
8. `core/ports` -> `runtime/*`

## Enforcement
Dependency direction is validated by automated tests scanning Ruby `require` and `require_relative` statements inside these layer roots.

During migration, missing layer directories are treated as non-applicable and do not fail checks.
