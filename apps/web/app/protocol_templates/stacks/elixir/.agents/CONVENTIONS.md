# Elixir Conventions

- Use pattern matching, guards, and multiple function clauses for meaningful
  shapes. Keep fallback clauses from hiding invalid states.
- Return tagged tuples such as `{:ok, value}` and `{:error, reason}` for expected
  failures. Use `with` for dependent steps and pipelines for readable transforms.
- Use structs for stable domain data and keep function names consistent with
  Elixir's `?` and `!` conventions.
- Distinguish recoverable domain errors from process failures handled by
  supervision. Avoid rescuing every exception into a success-shaped value.
- Give calls, messages, and timeouts clear contracts. Prefer explicit
  synchronization over assumptions about process scheduling.
- Reserve macros for syntax or compile-time needs that functions cannot express.

Reference: [Naming conventions](https://hexdocs.pm/elixir/naming-conventions.html).
