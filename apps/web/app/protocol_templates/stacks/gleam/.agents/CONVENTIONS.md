# Gleam Conventions

- Follow `gleam format`, use `snake_case` for functions and values, and meaningful
  custom type and constructor names.
- Model expected failures with `Result`; pattern match exhaustively instead of
  hiding cases behind catch-all branches.
- Use pipelines and `use` where they make data flow clearer. Keep intermediate
  values when they explain a transformation better.
- Avoid `let assert` for untrusted input or ordinary recoverable failures.
- Decode dynamic external values into typed values at the boundary.
- Keep foreign declarations small and make their types and failure behavior agree
  with the actual Erlang or JavaScript implementation.
- Preserve useful compiler warnings; do not silence incomplete code with `todo`
  or `panic` in completed behavior.

Reference: [Gleam language tour](https://tour.gleam.run/).
