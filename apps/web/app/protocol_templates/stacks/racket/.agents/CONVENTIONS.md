# Racket Conventions

## Names and data

- Use descriptive hyphenated identifiers. Follow the established conventions:
  predicates end in `?`, mutations in `!`, conversions use `->`, and dynamically
  scoped parameters commonly begin with `current-`.
- Prefer immutable values and local bindings. Use `struct` for meaningful data
  shapes; make transparency and exported constructors deliberate API choices.
- Prefer the selected language's libraries before adding packages. Declare
  runtime and build dependencies separately in package metadata.
- Narrow imports and exports when this clarifies ownership. Avoid
  `all-defined-out` for a library whose internal definitions are not its API.

## Control and resources

- Use procedures and data before macros. When macros are needed, preserve
  lexical scope, specify phase dependencies, and report useful syntax errors.
- Use explicit alternatives for ordinary outcomes and exceptions for failures
  at the appropriate boundary. Do not use contract violations as routine
  application validation.
- Catch only the exceptions the boundary can handle. Use managed port helpers
  and scoped parameterization instead of leaking resource or ambient state.
- Use runtime contracts or Typed Racket deliberately; do not add both
  mechanically to every private function.

References: [Racket style guide](https://docs.racket-lang.org/style/),
[contracts](https://docs.racket-lang.org/guide/contracts.html).
