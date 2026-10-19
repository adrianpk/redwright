# Rails Architecture

This document describes Rails repository structure and responsibility boundaries.

- Follow the application's Rails layout and autoloading conventions. Controllers
  coordinate requests; models own domain behavior and persistence rules; views
  and helpers render presentation.
- Keep associations, validations, and scopes with their Active Record models.
  Use database constraints for integrity that must survive concurrent writers.
- Extract an ordinary Ruby object when a workflow has an independent
  responsibility; do not require a service layer for every model operation.
- Use Active Job for work that should run asynchronously. Design retries around
  idempotent operations and make external side effects explicit.
- Keep multi-record invariants inside transactions. Coordinate external systems
  after commit when their work depends on a successful database commit.
- Keep concerns cohesive and avoid callbacks that conceal unrelated workflows.

Reference: [Rails Guides](https://guides.rubyonrails.org/).
