# Rust Conventions

- Use `rustfmt`, standard naming conventions, and derives when they express the
  type's real semantics.
- Return `Result` for recoverable failures and use `?` to propagate them. Reserve
  panics for violated invariants; avoid unconditional `unwrap` on external input.
- Prefer borrowing when ownership is unnecessary. Clone deliberately rather than
  using clones to conceal an unclear lifetime or sharing model.
- Use slices and iterators for suitable inputs and transformations. Avoid adding
  lifetimes, generic parameters, or trait bounds without a concrete API need.
- Let RAII and `Drop` manage resources; handle fallible flush or shutdown explicitly
  before destruction when success matters.
- Document each unsafe operation's safety argument at its boundary.

Reference: [The Rust Book](https://doc.rust-lang.org/book/).
