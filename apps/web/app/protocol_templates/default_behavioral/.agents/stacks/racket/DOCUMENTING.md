# Racket Documentation Overlay

Apply this overlay with `.agents/DOCUMENTING.md` and `.agents/LANGUAGE.md`.

- Keep examples aligned with the actual `#lang`, module paths, collections,
  package name, entry modules, and `raco pkg` workflow.
- Explain whether an example requires package installation, a linked checkout,
  a collection path, or only file-relative modules.
- Use Scribble when the repository owns `.scrbl` manuals or package
  documentation metadata. Keep declarations aligned with exports, contracts,
  module paths, and supported language variants.
- Record manual and setup metadata in `info.rkt` when the package uses the
  Racket documentation installation workflow.
- Document public arity, keywords, return values, contracts, mutation,
  exceptions, parameterization, and side effects.
- For macros, document binding behavior, evaluation order, phase requirements,
  generated definitions, and syntax errors.
