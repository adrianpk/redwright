# TypeScript Architecture

This document describes TypeScript repository structure and ownership boundaries.

## Objective

Keep the TypeScript codebase strongly typed, modular, and explicit about runtime boundaries without replacing product behavior with generic utility layers.

## Baseline structure

```text
src/             # application and library source
src/index.ts     # package or application entrypoint when present
test/ or tests/  # automated tests
config/          # runtime or build configuration when used
docs/            # user-facing and technical documentation
package.json     # package scripts, dependencies, and metadata
tsconfig.json    # TypeScript compiler configuration
.agents/         # collaboration and execution rules for this repository
AGENTS.md        # top-level agent operating contract
```

## Boundary rules

- Organize modules around product behavior and boundary adapters, not generic utility buckets.
- Keep entrypoints thin and delegate behavior to modules with explicit inputs and outputs.
- Keep domain logic independent from rendering, transport, persistence, and process wiring.
- Make async boundaries visible and keep side effects behind narrow adapters.
- Prefer typed contracts for external API responses, config, persisted data, and cross-module messages.
- Keep runtime validation close to untrusted input boundaries.
- Tests should mirror the module or behavior boundary being changed.

## Type and runtime contracts

- Static types do not replace runtime validation for untrusted input.
- Keep DTOs, domain types, and persistence shapes distinct when their responsibilities differ.
- Prefer explicit result shapes over loosely structured objects.
- Avoid `any`; use `unknown` at boundaries and narrow deliberately.
- Keep exported types intentional and documented when they form a package contract.

## Change discipline

- Structural changes must be explicit in commit scope.
- Do not introduce broad framework layers or state libraries without clear need.
- Prefer extending existing module boundaries before creating new architectural categories.
