# Elixir Conventions

This document defines coding rules for Elixir application code.

## Dependencies

- Prefer Elixir, Erlang/OTP, and existing project tooling before adding dependencies.
- Ask before introducing new Hex packages, services, code generators, or build tools.
- Keep dependency additions tied to a concrete module or runtime responsibility.
- Avoid dependencies that replace small, local design decisions.

## Code style

- Keep functions small and explicit.
- Prefer pattern matching and guards for shape validation when they improve clarity.
- Use tagged tuples for expected outcomes when callers need to branch on success or failure.
- Use structs for stable domain shapes.
- Use pipelines for readable transformations; do not force pipelines when intermediate names clarify intent.
- Prefer `with` for linear expected-failure flows.
- Keep public APIs documented when they cross module or context boundaries.

## Processes and state

- Do not use GenServer when a plain function or data structure is enough.
- Keep process state minimal and explicit.
- Keep process messages typed by shape and covered by tests when they are part of the boundary.
- Avoid hiding domain behavior inside callbacks.
- Prefer supervision for lifecycle guarantees, not as a generic organization mechanism.

## Testing

- Use ExUnit for application behavior.
- Prefer focused tests around public module APIs and process boundary behavior.
- Cover expected failures, pattern-match branches, timeout paths, and restart-relevant behavior when applicable.
- Use deterministic tests for concurrent behavior; avoid timing-sensitive assertions when a stronger synchronization point is available.
- Do not skip tests for behavior changes.

## Anti-patterns

Avoid:
- processes used as generic mutable objects
- hidden runtime config reads deep inside domain logic
- catch-all pattern matches that hide invalid input
- broad contexts that mix unrelated responsibilities
- speculative macros without active use
- broad rewrites that do not reduce current complexity

Prefer:
- explicit module contracts
- pure transformations where possible
- small supervised components
- deterministic ExUnit tests
- local consistency over generic architecture
