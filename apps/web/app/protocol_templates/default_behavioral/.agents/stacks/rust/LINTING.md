# Rust Quality-Gate Overlay

Apply this overlay with `.agents/LINTING.md`. Repository-owned commands
override these examples.

## Baseline Commands

- Format: `cargo fmt --check`.
- Compile: `cargo check`.
- Test: `cargo test`.

## Configured Extensions

- Use `cargo clippy -- -D warnings`, all-feature or workspace tests, dependency
  audits, and coverage only when configured or relevant to the changed risk.
