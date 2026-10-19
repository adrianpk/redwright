# Rust Validation

- Run `cargo fmt --check` and `cargo check` for affected packages and features.
- Run relevant `cargo test` tests, including integration tests and doctests when
  public APIs change.
- Use `cargo clippy` with the repository's selected targets and lint policy;
  avoid introducing warning denial independently of the project's toolchain policy.
- Exercise ownership-sensitive cleanup, error variants, and feature-gated behavior.
- Validate supported feature combinations and targets when the change affects
  conditional compilation. `--all-features` alone may be invalid for mutually
  exclusive features.
- Use Miri or additional unsafe-code checks when configured and relevant.

Reference: [Cargo Clippy](https://doc.rust-lang.org/cargo/commands/cargo-clippy.html).
