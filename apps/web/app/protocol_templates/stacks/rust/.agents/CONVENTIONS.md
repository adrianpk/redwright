# Rust Conventions

This document defines coding rules for Rust application code.

## Dependencies

- Prefer the Rust standard library and existing project tooling before adding dependencies.
- Ask before introducing crates, services, generators, or build tools.
- Keep dependency additions tied to a concrete module or runtime responsibility.
- Avoid dependencies that replace small, local design decisions.

## Code style

- Keep functions short and explicit.
- Prefer expressive types over loosely structured strings or tuples.
- Use `Result` for expected failures.
- Preserve error context at boundary crossings.
- Prefer iterator chains when they stay readable; use named intermediate values when they clarify behavior.
- Keep public APIs documented when they cross crate or module boundaries.

## Module boundaries

- Keep IO adapters separate from core logic.
- Keep parsing, validation, persistence, and rendering in distinct modules when the behavior grows.
- Avoid generic utility modules without a clear owner.
- Use traits for boundaries with real substitution needs.
- Keep public surface area small and intentional.

## Testing

- Use Rust's built-in test framework by default.
- Prefer focused unit tests for local behavior and integration tests under `tests/` for public crate behavior.
- Cover expected failures, parsing edge cases, feature-gated behavior, and boundary contracts.
- Keep tests deterministic and avoid relying on incidental ordering.
- Do not skip tests for behavior changes.

## Anti-patterns

Avoid:
- public APIs shaped by internal convenience
- unnecessary trait abstractions
- broad `unwrap` or `expect` use in library behavior
- hidden global mutable state
- cloning to bypass unclear ownership
- unsafe code without a documented invariant
- broad rewrites that do not reduce current complexity

Prefer:
- explicit types
- small cohesive modules
- contextual errors
- deterministic tests
- local consistency over generic architecture
