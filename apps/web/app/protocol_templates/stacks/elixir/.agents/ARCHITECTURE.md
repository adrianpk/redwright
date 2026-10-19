# Elixir Architecture

This document describes Elixir repository structure and process ownership.

- Organize modules under `lib/` by domain capability; keep Mix configuration in
  `mix.exs` and follow existing application or umbrella boundaries.
- Use ordinary functions and immutable data for computation. Introduce a process
  for state, concurrency, isolation, or lifecycle that actually needs one.
- Let supervision trees express restart ownership. Keep GenServer callbacks
  focused on process state and delegate reusable transformations to functions.
- Separate startup configuration from runtime configuration and access each at
  the appropriate lifecycle boundary.
- Keep external adapters and process messages explicit. Never create atoms from
  arbitrary external strings.

Reference: [Library guidelines](https://hexdocs.pm/elixir/library-guidelines.html).
