# Repository Ticket Contract

This document defines repository-local Markdown tickets for bounded
development work that does not require a full specification, plan, or tracker.
Ticket creation requires authorization under `.agents/ROUTING.md`.

## Scope and Delivery Unit

- Store repository-development tickets under `ops/<namespace>/ticket/`.
- Do not store application runtime tickets there unless the project explicitly
  adopts the same representation.
- Treat one ticket as one focused, independently reviewable delivery unit.
- Split a ticket or promote it to the formal specification, plan, tracker, and
  slice flow when it cannot remain bounded.
- A ticket series can provide a lightweight roadmap, but each ticket remains
  independently reviewable.

## Layout and Identity

```text
ops/<namespace>/ticket/
  TEMPLATE.md
  open/
  ready/
  in_progress/
  reviewing/
  blocked/
  solved/
  closed/
```

- Create a ticket in `open/`.
- Use `YYYYMMDDHHMMSS-<slug>.md` with a UTC timestamp.
- Use the fields from `TEMPLATE.md` when it exists.
- Keep the filename stable unless correcting an identifier or timestamp
  mismatch.
- Keep `status` frontmatter equal to the containing directory.

## Required Metadata

- `id`: `TKT-YYYYMMDDHHMMSS`.
- `title`: short concrete title.
- `status`: lifecycle state.
- `kind`: work category.
- `severity`: impact if unresolved.
- `priority`: execution urgency.
- `scope`: affected area.
- `tags`: comma-separated retrieval labels.
- `source`: origin of the ticket.
- `reported_at`: UTC capture timestamp.
- `commits`: related commit hashes.

For initial capture, default uncertain classification fields to
`unclassified`, leave `tags` empty, and use `source: chat` when applicable.

## Enumerations

Status values are `open`, `ready`, `in_progress`, `reviewing`, `blocked`,
`solved`, and `closed`. Use `solved` for implemented resolution. Use `closed`
for discarded, duplicate, obsolete, moved, or answered work without
implementation.

Kind values are `unclassified`, `bug`, `task`, `cleanup`, `follow_up`,
`research`, and `decision`.

Severity values are `unclassified`, `low`, `medium`, `high`, and `critical`.
Severity measures impact if the issue remains unresolved.

Priority values are `unclassified`, `low`, `normal`, `high`, and `urgent`.
Priority measures scheduling urgency, independently of severity.

Scope values are `unclassified`, `domain`, `api`, `persistence`, `ui`, `ops`,
`docs`, and `infra`.

Source values are `chat`, `manual_test`, `review`, `trace`, `user_report`, and
`implementation`.

Set `resolution` only for `solved` or `closed`. Allowed values are `fixed`,
`wont_do`, `duplicate`, `obsolete`, `moved`, and `answered`.

## Status Transitions

Allowed transitions are:

```text
open -> ready
ready -> in_progress
in_progress -> reviewing
reviewing -> solved
reviewing -> closed
open -> closed
ready -> closed
active -> blocked
blocked -> open
blocked -> ready
blocked -> in_progress
```

Update the directory and `status` frontmatter in the same change.

- Set `ready_at` on `open -> ready`.
- Set `started_at` on `ready -> in_progress`.
- Set `reviewed_at` when entering or completing `reviewing`.
- Set `closed_at` only for `solved` or `closed`.
- Set `branch`, `pr`, and `commits` when implementation work exists.

## Tags

- Use lowercase kebab-case tags separated by commas.
- Keep tags sparse. One is valid, three is the preferred range, and five is
  the maximum.
- Leave tags empty when classification is unclear.

## Delivery and Naming

- Deliver directly through `dev` or through a branch and pull request as
  authorized by `.agents/VERSIONING.md`.
- Branch format: `<type>/ticket-<timestamp>-<short-slug>`.
- Pull-request title: `<type>(ticket-<timestamp>): <short outcome>`.
- Use Conventional Commits for ticket implementation.
- Use the slice pull-request sections defined by `.agents/SLICES.md` when a
  ticket is delivered through review.

Use repository ticket helpers when present. Run the repository ticket
validation command before committing ticket workflow changes.
