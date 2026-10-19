# Gleam Architecture

This document describes Gleam repository structure and typed module boundaries.

- Keep application modules under `src/`, tests under `test/`, and package and
  target configuration in `gleam.toml`.
- Organize modules around cohesive behavior. Expose a small public surface and
  use opaque types when callers should not construct a representation directly.
- Use immutable values and custom types for domain state, with explicit variants
  for states that require different data.
- Choose Erlang or JavaScript deliberately. Isolate target-specific IO and
  foreign functions so portability limits are visible.
- Introduce actors and supervision only for actual Erlang runtime needs; ordinary
  transformations should remain functions.

Reference: [Writing Gleam](https://gleam.run/writing-gleam/).
