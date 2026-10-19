# Rust Architecture

This document describes Rust repository structure and ownership boundaries.

- Follow Cargo's crate layout. Keep reusable behavior in `src/lib.rs` and modules;
  use `src/main.rs` or `src/bin/` for executable assembly when appropriate.
- Introduce workspace crates for genuine package or dependency boundaries, rather
  than mirroring every module with a crate.
- Design APIs around ownership and borrowing. Use traits for useful shared
  behavior or substitution without requiring a trait for every type.
- Use enums to represent mutually exclusive states and exhaustive transitions.
- Isolate unsafe code behind a safe API with documented invariants. Keep FFI
  ownership, lifetimes, and cleanup explicit.
- Choose async execution and shared ownership only when runtime requirements need them.

Reference: [The Rust Book](https://doc.rust-lang.org/book/).
