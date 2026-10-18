# Ticket Procedure

Use this playbook for repository tickets authorized under
`.agents/ROUTING.md`. `.agents/TICKETS.md` owns the ticket schema, lifecycle,
classification values, delivery boundary, and naming.

## Invocation

Map natural-language ticket requests to these procedure identifiers:

- `capture`: one ticket.
- `capture_round`: several informal items.
- `triage_manual`: classification with user input.
- `triage_auto`: agent classification by explicit request.
- `implement`: ticket-driven delivery.

## Capture

1. Accept a raw description as sufficient input.
2. Ask only when the description is not understandable or contains unrelated
   work that cannot be separated safely.
3. Create the ticket in `open/` with the defaults from `.agents/TICKETS.md`.
4. Report the ticket identifier and path.

## Capture Round

1. Accept a rough list, paragraphs, or short fragments.
2. Split clearly separate items and merge obvious duplicates.
3. Ask only when an item cannot be preserved meaningfully.
4. Create each retained item in `open/`.
5. Report created ticket identifiers and deferred candidates.

## Assisted Capture

1. Ask at most ten questions for the ticket or round.
2. Ask only about description, expected outcome, observed behavior,
   validation, or separability.
3. Create the tickets without preserving the questions as quiz artifacts.

## Manual Triage

1. Select open or unclassified tickets.
2. Ask the minimum questions needed to clarify and classify them.
3. Let the user decide or confirm kind, scope, severity, and priority.
4. Move an actionable ticket to `ready/`; leave unclear tickets in `open/`.

## Automatic Triage

1. Inspect the evidence recorded in each selected ticket.
2. Classify conservatively without inventing facts.
3. Leave a field `unclassified` when critical context is missing.
4. Move a ticket to `ready/` only when its expected outcome is actionable.
5. Add a short rationale only for non-obvious classification.

## Implementation

1. Verify that the ticket is `ready` and that implementation is authorized.
2. Move it to `in_progress` and set the applicable lifecycle fields.
3. Select direct `dev` or branch-and-pull-request delivery under
   `.agents/VERSIONING.md`.
4. Implement and validate the bounded change.
5. Update `CHANGELOG.md` through `changelog-normalize` when the result is a
   release-worthy user-visible outcome.
6. For direct `dev` delivery, record commits and validation, then close the
   ticket as `solved` with resolution `fixed`.
7. For review delivery, move the ticket to `reviewing` and record the branch,
   pull request, commits, and validation.
8. After verified merge, close the ticket as `solved` with resolution `fixed`
   on `dev`.
