# Ruby Conventions

- Use `snake_case` for methods and variables, `CamelCase` for classes and modules,
  `?` for predicates, and `!` for a meaningfully dangerous alternative.
- Prefer Enumerable operations and blocks when they clarify intent. Use explicit
  iteration when it makes mutation, early exits, or resource handling clearer.
- Use keyword arguments for optional settings whose position would be ambiguous.
  Keep the distinction between `nil`, `false`, and a missing value deliberate.
- Rescue specific expected exceptions near a boundary that can handle them;
  avoid rescuing `Exception` or turning all failures into `nil`.
- Use block-based resource APIs or `ensure` to release resources reliably.
- Avoid changing core classes globally. Use explicit delegation before dynamic
  method interception; document any metaprogramming that forms a public API.

Reference: [Ruby methods](https://docs.ruby-lang.org/en/master/syntax/methods_rdoc.html).
