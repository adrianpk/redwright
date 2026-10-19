# Rust Documentation

- Use `///` for public items and `//!` for crate or module orientation.
- Describe ownership, borrowing, errors, panics, and safety requirements where
  they affect callers. Explain feature flags and supported targets.
- Write small runnable rustdoc examples; let doctests verify them unless the
  example genuinely cannot execute in the test environment.
- Link related items with rustdoc links and document public re-exports coherently.
- Keep Cargo commands aligned with actual workspace packages and feature sets.
  State required runtimes for async examples.

Reference: [Rust documentation](https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html).
