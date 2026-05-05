# RedWright Protocol Management Web CRUD Quiz Notes

## Status

- type: `quiz-notes`
- status: `living`
- date: `2026-05-04`
- related_raw: `ops/quiz/2026-05-04-redwright-protocol-management-web-crud-quiz-raw.md`

## Purpose

These notes preserve the curated outcome of the questionnaire about Protocol management in the Rails web app.

They are not an implementation plan and not a raw transcript.

## Context

- The session was explicitly limited to questionnaire-driven clarification.
- No implementation work was allowed during the session.
- The intended focus was the Rails web CRUD and management experience for Protocols rather than the already-established Protocol concept itself.
- Existing Protocol draft, spec, and quiz artifacts were treated as valid alignment context.

## Convergences

- `Protocols` and `Protocol Templates` are both in scope for the web management surface.
- Their navigation placement must reflect their different scope:
  - project-scoped `Protocols` belong alongside other project-facing areas
  - global `Protocol Templates` belong under `Settings`
- `Protocols` should become a top-level navigation entry alongside `Boards` and `Documents`.
- The top-level Protocol index should follow the same card-oriented visual language already used for `Documents`.
- The project Protocol index should show the `AGENTS` entry and the `.agents/*`-backed entries together in one view.
- The CRUD should stay focused on Rails-side protocol entities, not on filesystem-path-first semantics.
- Filesystem materialization is an important downstream concern, but it should not define the primary UX model of the Rails CRUD.
- For MVP, canonical protocol file types are a closed set derived from the established `AGENTS.md` plus `.agents/*` operating shape already used in this repository.
- Creation of project Protocol entries is only meaningful for missing canonical entries.
- Existing canonical entries should be edited rather than duplicated.
- Deleting a canonical entry is allowed, and later recreation is allowed.
- The same closed-set and no-duplicate rule should apply to global Protocol Template management in MVP.
- The first project-facing Protocol UX should avoid unnecessary ceremony:
  - no separate read-only show page
  - view and edit on the same screen
- The edit surface should preserve an explicit `Save` action.
- The edit surface should also support autosave, with a last-successful-save indicator.
- An autosave interval of about 30 seconds is considered sufficient for MVP.
- Missing canonical entries should appear as empty cards in the grid rather than as a generic add flow or as normal cards with a `missing` label.
- Empty cards should include a subtle missing/empty cue and a direct action to create that specific canonical entry.
- `PLAYBOOKS` is a special entry that should act as a link into a separate playbooks view rather than being edited inline with the rest of the protocol cards.
- The separate `PLAYBOOKS` view should also use a fixed canonical set in MVP.
- The same `PLAYBOOKS` card plus subview pattern should repeat in global template-management surfaces for consistency of interaction.
- Stack template management should use one screen per stack template rather than one combined cross-stack administrative editor.
- The CRUD must support creating stack template sets beyond the seeded defaults.
- Creating a new stack template set should ask for the stack identity and then generate empty entries for each canonical protocol type.
- There is no mandatory canonical content skeleton for new entries; the constraint is on protocol type coverage, not on prefilled body text.
- The user does not want hard restrictions that prevent variant or additional stack template sets even if that can later make template selection more ambiguous.
- `Stack` information is important and should be represented semantically rather than only inferred from names.
- Last-edited metadata is useful in edit context, but not important on the cards themselves.

## Template Shape Decisions

- `Common Protocol Templates` and `Stack Protocol Templates` should appear as separate cards in `Settings` for now, to avoid adding an extra navigation step.
- A future revision may consolidate those entries if the `Settings` area grows and the navigation tradeoff changes.
- `Common` and `Stack` remain the only meaningful top-level template categories.
- Playbooks are not a third standalone category.
- Playbooks conceptually belong either to the `common` side or, if ever needed, to the `stack` side.
- Based on the current repository playbooks, the practical MVP decision is to treat `PLAYBOOKS` as `common` only.

## Playbook Classification Estimate

- The current playbooks under `.agents/playbooks/*` are overwhelmingly `common`.
- `questionnaires`, `spec-draft-conversation-workflow`, `ticket-workflow`, `plan-driven-workflow`, and `slice-delivery` are clearly cross-stack operational behavior.
- `branching-and-pr-flow` and `release-alignment` are also best treated as `common` because they describe repository process rather than stack-specific technical rules.
- None of the current playbooks read as genuinely stack-specific in the same way that `ARCHITECTURE` or `CONVENTIONS` can.

## UX Direction

- `Protocols` are a distinct product concept, but the interaction model should intentionally stay close to the current `Documents` experience.
- Cards are preferred over a more administrative table for MVP, even though a table remains a plausible future refinement.
- The current repository operating shape should be reflected directly enough that users can recognize the familiar `AGENTS` plus `.agents/*` nesting.
- The user wants the product to replicate the current working mental model first, and only later revisit flexibility or reduction if real usage justifies it.

## Open Questions

- Whether the eventual model should allow reducing the canonical protocol set rather than only extending it.
- Whether stack-scoped playbooks will ever become necessary enough to justify deviating from the `common-only` MVP rule.
- How a future setup flow should resolve ambiguity when users create multiple overlapping stack template sets such as framework variants or version-specific forks.
- Whether the later UX should move from cards to a more compact administrative table once protocol volume grows.

## Provisional Decisions

- `keep`: `Protocols` is a dedicated top-level project-facing area in the Rails web app.
- `keep`: `Protocol Templates` is a global `Settings` concern, not a top-nav concern.
- `keep`: project Protocol management and template management should share the same basic interaction pattern.
- `keep`: canonical protocol types are fixed in MVP.
- `keep`: creation is limited to missing canonical entries, not duplicate entries of the same type.
- `keep`: delete is allowed for both project Protocol entries and template entries.
- `keep`: editing is direct and low-ceremony, without a separate show-only step.
- `keep`: autosave plus explicit save should coexist.
- `keep`: `PLAYBOOKS` should remain a separate subview rather than an inline editing block.
- `keep`: `PLAYBOOKS` should be treated as `common` only in MVP.
- `keep`: stack template sets can be created beyond seeded defaults.
- `keep`: stack sets may remain loosely restricted even if that introduces future ambiguity.

## Deferred

- any implementation plan, routes, models, controllers, or UI code changes
- exact persistence changes needed to represent semantic stack metadata
- future relaxation or reduction of the canonical protocol set
- stack-specific playbook support beyond the MVP decision
- later UX compaction or refactoring once the management surface grows
