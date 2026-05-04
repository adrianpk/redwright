# Rust Architecture

This document describes Rust repository structure and ownership boundaries.

## Objective

Keep the Rust codebase explicit about ownership, error behavior, and module boundaries without over-abstracting before the design needs it.

## Baseline structure

```text
Cargo.toml    # crate metadata, features, dependencies, and workspace config
src/          # crate source code
src/main.rs   # binary entrypoint when present
src/lib.rs    # library root when present
tests/        # integration tests
examples/     # runnable examples when useful
benches/      # benchmarks when configured
docs/         # user-facing and technical documentation
.agents/      # collaboration and execution rules for this repository
AGENTS.md     # top-level agent operating contract
```

## Boundary rules

- Organize modules around domain behavior and boundary adapters.
- Keep binary entrypoints thin; delegate behavior to library modules.
- Use traits at boundaries where substitution is useful, not as a default abstraction.
- Keep ownership and lifetime decisions visible in public APIs.
- Separate CLI, web, persistence, transport, and domain logic when the project has those concerns.
- Keep feature flags explicit and documented when they affect public behavior.
- Tests should mirror the crate or module boundary being changed.

## Errors and ownership

- Use `Result` for expected failures and preserve useful error context.
- Avoid panics in library code unless the invariant is local and defensible.
- Keep borrowing, cloning, and allocation choices intentional.
- Prefer clear data ownership over lifetime cleverness when public APIs are involved.
- Keep unsafe code out unless the project requires it and the invariant is documented.

## Change discipline

- Structural changes must be explicit in commit scope.
- Do not introduce workspace splits, broad trait hierarchies, or global registries without clear need.
- Prefer direct, readable Rust before abstraction-heavy designs.
