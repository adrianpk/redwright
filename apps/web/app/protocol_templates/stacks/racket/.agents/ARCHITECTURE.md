# Racket Architecture

## Modules and languages

- Preserve the chosen `#lang`. Use the smallest appropriate language for a
  module without implicitly converting Typed Racket or a domain language.
- Organize modules around cohesive responsibilities and explicit `require` and
  `provide` boundaries. Keep implementation details outside the public exports.
- Keep an executable entrypoint separate from reusable modules when importing
  a library should not start the application or acquire external resources.
- For a package, declare its metadata and dependencies in `info.rkt`; distinguish
  collections, modules, and package installation in commands and documentation.

## Boundaries and expansion

- Prefer immutable data and ordinary procedures for domain transformations.
  Give necessary mutation and dynamic parameters a clear owner and extent.
- Use contracts where checking and blame protect a public boundary. Keep
  representation exposure, such as `struct-out`, intentional.
- Introduce macros for syntax, binding, or evaluation requirements that
  procedures cannot express. Keep expansion-time dependencies explicit.
- Separate filesystem, network, port, and process effects from reusable logic
  when that makes ownership and testing clearer.

References: [Modules](https://docs.racket-lang.org/guide/module-basics.html),
[contracts](https://docs.racket-lang.org/guide/contracts.html).
