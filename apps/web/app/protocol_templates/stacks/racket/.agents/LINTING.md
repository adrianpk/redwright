# Racket Validation

Use the repository's selected Racket distribution and commands. Substitute
actual module paths in these examples.

```text
raco make <module.rkt>
raco test <module.rkt>
```

- Use RackUnit unless the project already establishes another framework.
- Put tests that need enclosing private definitions in `module+ test`.
  Use separate modules for public or package integration behavior.
- For a repository organized around test submodules, `raco test -x .` runs
  those submodules recursively without running modules that lack them.
- Validate both expansion and runtime behavior when changing a macro.
- Isolate ports, parameters, temporary files, and process state. Avoid
  dependency on module import order or effects from another test.
- Build Scribble documentation or run package setup when exports, examples,
  dependencies, or collection structure change.

References: [raco test](https://docs.racket-lang.org/raco/test.html),
[RackUnit](https://docs.racket-lang.org/rackunit/).
