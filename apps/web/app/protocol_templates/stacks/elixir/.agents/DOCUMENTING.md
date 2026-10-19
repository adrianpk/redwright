# Elixir Documentation

- Use `@moduledoc`, `@doc`, and `@spec` for public module contracts where useful.
  Document function arity, tagged results, and expected exceptions.
- Include doctests for small deterministic examples and explain process ownership,
  call timeouts, messages, and supervision behavior when they affect callers.
- Distinguish compile-time and runtime configuration; show actual Mix tasks and
  application startup commands.
- Document whether an API starts, links, monitors, or requires an existing process.
- Use the existing ExDoc setup when present rather than another documentation stack.

Reference: [Writing documentation](https://hexdocs.pm/elixir/writing-documentation.html).
