# Rails Documentation

- Use real binstubs and environment names in setup, console, test, and server
  instructions. State the required Ruby, Rails, database, and job adapter versions.
- Describe routes, permitted inputs, response formats, authorization, and
  validation failures for exposed HTTP endpoints.
- Document model invariants, database constraints, and transaction boundaries
  when they affect application behavior or operational recovery.
- Explain job retry semantics, idempotency, scheduling, and required workers.
- Document migrations and deployment steps according to this repository's
  workflow; avoid assuming a personal branch, host, or service manager.

Reference: [Rails Guides](https://guides.rubyonrails.org/).
