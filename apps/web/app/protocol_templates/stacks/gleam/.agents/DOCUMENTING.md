# Gleam Documentation

- Use `////` module documentation and `///` public item documentation. Describe
  custom type variants, opaque construction APIs, and `Result` error variants.
- Keep examples aligned with the configured target, supported Gleam version,
  and actual package imports.
- Document target-specific restrictions and external runtime dependencies at
  foreign-function boundaries.
- Explain process ownership and supervision requirements for actor APIs.
- Generate package reference documentation with `gleam docs build`; keep task
  and installation instructions separate from API contracts.

Reference: [Writing Gleam](https://gleam.run/writing-gleam/).
