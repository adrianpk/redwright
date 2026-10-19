# Ruby Documentation

- Document the public Ruby objects and commands users actually call, including
  keyword arguments, accepted blocks, return values, and raised exceptions.
- State whether methods mutate their receiver, retain supplied objects, or
  transfer responsibility for closing IO resources.
- Keep examples aligned with the supported Ruby version, gem entrypoint, and
  Bundler setup. Do not assume Rails commands in a framework-independent library.
- Explain installation and execution separately from internal implementation.
- Follow existing RDoc or YARD conventions instead of adding another documentation
  tool. Keep examples executable when practical.

Reference: [RDoc markup](https://ruby.github.io/rdoc/RDoc/Markup.html).
