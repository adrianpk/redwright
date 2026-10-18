# Rust Conventions Overlay

Apply this overlay with `.agents/CONVENTIONS.md`.

- Prefer the standard library and existing Cargo workspace dependencies before
  adding crates.
- Prefer expressive types over loosely structured strings or tuples.
- Preserve error context when crossing module or adapter boundaries.
- Use iterator chains when they remain readable; use named intermediate values
  when they clarify behavior.
- Keep the public API small and document caller-visible ownership and error
  contracts.
- Use Rust's built-in test framework by default, with focused unit tests for
  local behavior and `tests/` for public crate behavior.
- Test feature-gated behavior when the changed contract depends on a feature.
- Avoid broad `unwrap` or `expect` use in library behavior, cloning that hides
  unclear ownership, and unsafe code without a documented invariant.
