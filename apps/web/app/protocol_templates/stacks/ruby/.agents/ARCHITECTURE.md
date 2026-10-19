# Ruby Architecture

This document describes Ruby repository structure and object boundaries.

- Use the project's existing layout. Libraries commonly expose a small entrypoint
  under `lib/`; command-line programs keep argument handling in `bin/` or `exe/`.
- Keep classes focused on state and behavior that belong together. Use modules
  for namespacing and cohesive shared behavior.
- Prefer ordinary objects and explicit collaborators over inheritance trees,
  global registries, or metaprogramming that hides method definitions.
- Follow an existing framework's conventions when one is present. Plain Ruby
  projects do not need controller, service, or persistence layers by default.
- Make ownership of IO streams, connections, and background work explicit.
  Keep executable loading separate from importing reusable library code.

Reference: [Ruby syntax](https://docs.ruby-lang.org/en/master/syntax_rdoc.html).
