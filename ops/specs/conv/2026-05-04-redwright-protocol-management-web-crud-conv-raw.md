# RedWright Protocol Management Web CRUD Raw Capture

## Status

- type: `conversation-raw`
- status: `completed`
- date: `2026-05-04`
- question_count: `26`

## Scope

- The session is only about questionnaire-driven clarification for Protocol management in the Rails web app.
- No implementation work is allowed in this session.
- No files outside `...-conv.md` or `...-conv-raw.md` may be edited.

## Captured Answers

### Answer 1

- Both surfaces are in scope:
  - project-scoped Protocol management
  - global Protocol Template management
- They must not live at the same menu level because their scope differs.
- Project-based Protocols should appear alongside other project-level areas.
- Global Protocol Templates should live under `Settings` as a specific card, not in the top navigation.

### Answer 2

- The discussion is not about redefining what a Protocol is.
- The focus is only the CRUD and management UX in the Rails app.
- `Protocol` is intentionally distinct from `Document` because it governs user-agent interaction rules and technical or behavioral constraints.

### Answer 3

- The specification is considered clear on the data shape.
- `AGENTS.md` maps to a persisted Rails-side Protocol.
- Referenced files under `.agents/` also map to persisted Rails-side Protocols.
- Each project owns several Protocols, not a single monolithic Protocol record in the user-facing CRUD sense.
- The current repository is the reference example for the intended shape.

### Answer 4

- For project-scoped Protocols, the desired surface is closer to `RUD` than unconstrained CRUD.
- Nothing should block creation of a Protocol entry as long as it conforms to canonical protocol types.
- Project creation saga should generate the initial set automatically.
- The web interface should then support tweaking that generated set.

### Answer 5

- For MVP phase one, canonical protocol types are a closed list.
- The canonical set should match the current known files such as `AGENTS.md` and the referenced `.agents/*` files.
- Extending or reducing that set is a possible future decision, but not part of the current scope.

### Answer 6

- Global Protocol Templates should follow the same MVP rule: a closed canonical file set.
- Templates are not free-form arbitrary bundles in this phase.
- Existing protocol draft, spec, and curated conversation artifacts remain valid alignment context even when they are not specifically about the web CRUD.

### Answer 7

- In MVP, project Protocol creation is only for missing entries from the canonical set.
- If a canonical protocol file already exists for the project, the user should only edit it rather than create a duplicate of the same type.
- The constrained workflow is acknowledged as a present workflow fit, not as a claim that it should remain the universal long-term model.

### Answer 8

- In MVP, deleting an existing canonical project Protocol file is allowed.
- A user may later recreate the missing canonical entry.
- Even so, the simpler expected path for many cases is to edit the existing content rather than delete and recreate it.

### Answer 9

- Global Protocol Templates follow the same MVP rule set as project Protocols.
- The canonical set is closed.
- Creation is only for missing canonical entries.
- Existing canonical entries are edited rather than duplicated.
- Deletion is allowed and later recreation is allowed.

### Answer 10

- In `Settings`, phase-one navigation should use two separate cards:
  - `Common Protocol Templates`
  - `Stack Protocol Templates`
- This is preferred for now to avoid an extra navigation step.
- A future revision may consolidate them when `Settings` gains more cards and the navigation tradeoff changes.

### Answer 11

- Stack Protocol Templates should use one screen per stack template rather than one combined cross-stack editor.
- A combined surface would make the current task harder to understand and operate.
- The CRUD must allow creating template sets for new stacks, not only editing the stacks seeded by default.

### Answer 12

- There is no mandatory canonical content skeleton for a newly created stack template set.
- At most, a lightweight placeholder may exist, but showing it is not important.
- The canonical constraint applies to protocol file types, not to prefilled body content.

### Answer 13

- Creating a new stack template set should ask for the stack identity, typically a language or framework name.
- Seeded defaults such as `Rails` may already exist, but the CRUD must support creating additional stack sets.
- After creation, the system should generate an empty entry for each canonical protocol file type.
- The user is expected to edit those generated entries afterward.

### Answer 14

- The user does not want hard restrictions preventing additional or variant template sets.
- A user may create a set such as `Compojure-2` if they want.
- This may later make setup-time or LLM-driven selection more ambiguous, but that ambiguity is considered user-created rather than something the MVP must block.
- The same low-restriction approach applies instead of enforcing a single globally unique `common`-style template set model.

### Answer 15

- For project-scoped Protocol UX, table-style presentation is a plausible alternative.
- However, phase-one should use cards for consistency with the current `Documents` surface and to avoid changing metaphor again right now.
- A future revision may revisit a more administrative table layout.

### Answer 16

- The Rails CRUD should not center its UI model around filesystem paths.
- Materialization into repository files is a separate concern and should not define the primary CRUD semantics.
- Stack information is important and should be represented semantically, not only inferred from naming.
- Last-edited timestamp is not important on the card itself, though it may appear inside the expanded edit view.
- There is no meaningful `missing` state label for a card.
- If a canonical protocol entry is absent, the absence should appear as an empty slot rather than as a normal card marked missing.

### Answer 17

- When a canonical protocol entry is absent, the UI should render an empty card in the grid rather than only a generic add button.
- That empty card should include a subtle visual indicator that the entry is currently missing or empty.
- The empty state should offer a direct action to create that specific canonical protocol entry.

### Answer 18

- Existing protocol cards should not introduce a separate read-only show step before editing.
- Viewing and editing should happen in the same screen.
- The goal is to avoid unnecessary ceremony in the protocol management flow.

### Answer 19

- `Protocol Templates` should follow the same interaction pattern as project Protocols.
- Use cards.
- Use empty cards for missing canonical entries.
- Open directly into a combined read-edit view.
- Do not add a separate show-only screen.

### Answer 20

- The edit surface should keep an explicit `Save` action.
- It should also support autosave behavior, ideally through Turbo Streams.
- An indicator of the last successful save should be visible in the editing view.
- Autosave every 30 seconds is considered sufficient for MVP.

### Answer 21

- The visual interaction model for `Protocols` should intentionally mirror the current `Documents` experience.
- `Protocols` are a distinct product concept, but they are still close enough to another document-like artifact that reusing that presentation model is preferred.
- This implies dedicated document-style navigation rather than inline expansion inside the index grid.

### Answer 22

- The top navigation should gain a new `Protocols` entry alongside `Boards` and `Documents`.
- That entry should lead to a card-based Protocol index view.
- The Protocol index should show `AGENTS` plus the `.agents/*`-backed protocol entries together in one view.
- The `PLAYBOOKS` card is special: it should act as a link into a separate view.
- That separate Playbooks view should then render one card per playbook.

### Answer 23

- The separate `PLAYBOOKS` view should also use a fixed canonical set for MVP.
- This is preferred to avoid introducing behavioral differences from the personal operating scheme being replicated in RedWright.

### Answer 24

- The `PLAYBOOKS` interaction pattern should also exist in global template management surfaces.
- `Common Protocol Templates` and `Stack Protocol Templates` should repeat the same `PLAYBOOKS` card plus subview pattern.
- Repeating the same structure is preferred for simplicity of the interaction model.

### Answer 25

- Playbooks are not a third independent template category.
- A playbook belongs either to the `common` side or to the `stack` side when applicable.
- The current inclination is that playbooks are mostly `common`.
- `Common` content defines agent behavior and interaction rules.
- `Stack` content is more about stack-specific conventions or architecture.

### Answer 26

- For MVP, `PLAYBOOKS` should be treated as `common` only.

## Analysis Notes

### Playbook Classification Estimate

- Based on the current `.agents/playbooks/*` contents, the playbooks in this repository are overwhelmingly `common`.
- `questionnaires`, `spec-draft-conversation-workflow`, `ticket-workflow`, `plan-driven-workflow`, and `slice-delivery` are clearly cross-stack operational behavior.
- `branching-and-pr-flow` and `release-alignment` are also best treated as `common` in the current repository shape, even though they are repository-process-specific rather than technology-specific.
- None of the current playbooks read as meaningfully `stack`-specific in the same way that `ARCHITECTURE` or `CONVENTIONS` can be.
- Current estimate for MVP:
  - treat playbooks as `common` by default
  - do not require stack-scoped playbooks in the first web CRUD slice
  - leave room for future stack playbooks only if real examples appear later

## Closing Note

- The questionnaire ended early by sufficiency rather than by budget exhaustion.
- The resulting alignment is intended to feed a curated `...-conv.md` artifact directly, without requiring a separate draft artifact first.
