# Elixir Validation

- Run `mix format --check-formatted`, affected `mix test <path>` tests, and
  compilation using the project's configured warnings policy.
- Use ExUnit for behavior and doctests for executable public examples.
- Start supervised test processes with ExUnit helpers so cleanup follows the test
  lifecycle. Synchronize with messages or monitors rather than sleeps.
- Use `async: true` only when tests do not share mutable global state or resources.
- Exercise failure and restart paths when changing supervision or process state.
- Run Credo, Dialyzer, or coverage tasks only when configured by the project.

Reference: [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html).
