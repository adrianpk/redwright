# Ticket Workflow

Use tickets for concrete RedWright development work that does not need a full spec, plan, or tracker.

This playbook defines the shared ticket model for RedWright work. The Markdown files under `ops/tickets/` are the repository-local representation of that model. Future RedWright application tickets should preserve the same status and property semantics unless the model is explicitly changed here too.

## Scope

- `ops/tickets/` contains repository-development tickets for building RedWright itself.
- It does not store application tickets managed by RedWright at runtime.
- The model is intentionally shared: one mental model, two possible representations.

## Directory Layout

`ops/tickets/` represents ticket columns with status directories:

```text
ops/tickets/
  TEMPLATE.md
  open/
  ready/
  in_progress/
  reviewing/
  blocked/
  solved/
  closed/
```

The directory is the operational column. The `status` frontmatter must match the directory name and acts as a consistency check.

## File Rules

1. Create ticket files under `ops/tickets/open/`.
2. Use sortable filename format: `YYYYMMDDHHMMSS-<slug>.md` with a UTC timestamp.
3. Use frontmatter fields from `ops/tickets/TEMPLATE.md`.
4. Keep code and repository docs in English.
5. Move ticket files between status directories when status changes.
6. Keep the filename stable after creation unless correcting a timestamp/id mismatch.
7. If scope expands beyond a bounded ticket, promote it to the formal spec/plan/tracker flow.

## Required Properties

- `id`: stable ticket id, `TKT-YYYYMMDDHHMMSS`.
- `title`: short concrete title.
- `status`: lifecycle state.
- `kind`: work category.
- `severity`: impact if unresolved.
- `priority`: execution urgency.
- `scope`: affected area.
- `source`: where the ticket came from.
- `reported_at`: UTC timestamp for initial capture.
- `commits`: list of related commit hashes.

## Status Values

- `open`: captured, but not yet sufficiently refined for execution.
- `ready`: clear enough to execute when someone picks it up.
- `in_progress`: actively being worked.
- `reviewing`: implementation or proposal is ready for review, usually with a PR.
- `blocked`: cannot advance because a dependency, decision, or external condition is missing.
- `solved`: resolved positively, normally by merged implementation.
- `closed`: closed without implemented resolution.

## Status Transitions

- `ops/tickets/open/ -> ops/tickets/ready/`
- `ops/tickets/ready/ -> ops/tickets/in_progress/`
- `ops/tickets/in_progress/ -> ops/tickets/reviewing/`
- `ops/tickets/reviewing/ -> ops/tickets/solved/`
- `ops/tickets/reviewing/ -> ops/tickets/closed/`
- `ops/tickets/open/ -> ops/tickets/closed/`
- `ops/tickets/ready/ -> ops/tickets/closed/`
- `any active directory -> ops/tickets/blocked/`
- `ops/tickets/blocked/ -> ops/tickets/open/`
- `ops/tickets/blocked/ -> ops/tickets/ready/`
- `ops/tickets/blocked/ -> ops/tickets/in_progress/`

When moving a ticket, update the `status` frontmatter in the same change.

Use `solved` when work was done and the issue is resolved. Use `closed` when the ticket is discarded, duplicated, obsolete, moved elsewhere, or answered without implementation.

## Kind Values

- `bug`: incorrect behavior.
- `task`: concrete implementation or maintenance work.
- `cleanup`: simplification, pruning, or hygiene.
- `follow_up`: lightweight item captured from chat, review, or implementation.
- `research`: investigation before execution.
- `decision`: explicit choice needed before execution.

## Severity Values

- `low`: minor inconvenience or cleanup.
- `medium`: noticeable workflow or correctness issue.
- `high`: significant functional, safety, or delivery impact.
- `critical`: blocks essential work or risks data/state integrity.

## Priority Values

- `low`: can wait.
- `normal`: default priority.
- `high`: should be handled soon.
- `urgent`: needs immediate attention.

## Resolution Values

Set `resolution` only when `status` is `solved` or `closed`.

- `fixed`: implemented and resolved.
- `wont_do`: intentionally not doing it.
- `duplicate`: represented by another ticket or artifact.
- `obsolete`: no longer relevant.
- `moved`: moved to spec, plan, tracker, or another ticket.
- `answered`: resolved by clarification without implementation.

## Source Values

- `chat`: captured from user/agent chat.
- `manual_test`: found during manual testing.
- `review`: found during PR or code review.
- `trace`: found from logs, traces, or diagnostics.
- `user_report`: reported as observed behavior.
- `implementation`: discovered while implementing another change.

## Lifecycle Fields

- Set `ready_at` on `open -> ready`.
- Set `started_at` on `ready -> in_progress`.
- Set `reviewed_at` when entering or completing `reviewing`.
- Set `closed_at` only when status becomes `solved` or `closed`.
- Set `branch`, `pr`, and `commits` when implementation work exists.

## Reduced Workflow

1. Capture the ticket in `ops/tickets/open/` with `status: open`.
2. Refine it to `status: ready` when the expected outcome is clear enough to execute.
3. Create a branch from `dev` when implementation starts.
4. Set `status: in_progress`, `started_at`, and `branch`.
5. Implement the change.
6. Set `status: reviewing`, `pr`, and `commits` when the PR is ready.
7. Merge into `dev`.
8. Set `status: solved`, `resolution: fixed`, and `closed_at` after merge.
9. Push ticket metadata updates directly to `dev`; do not open dedicated PRs only for post-merge ticket status metadata.

## Capture Rule

If the user mentions a small or informal task that should not be solved immediately, create an `open` ticket under `ops/tickets/open/` instead of leaving the work buried in chat.
