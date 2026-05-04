# RedWright Protocol Management Web CRUD Specification

## Metadata

- id: `spec-2026-05-04-redwright-protocol-management-web-crud`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-04`
- updated: `2026-05-04`
- scope: `rails-web/protocols/protocol-templates/playbooks/crud-ux`
- derived_from:
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv.md`
  - `ops/specs/conv/2026-05-04-redwright-protocol-management-web-crud-conv-raw.md`

## Problem Statement

RedWright already has a Protocol concept and a repository-shaped protocol model centered on `AGENTS.md`, `.agents/*`, and `PLAYBOOKS`.

What remains underdefined is the Rails web management surface for that protocol system.

The current gap is not about inventing what Protocols are. It is about defining a coherent CRUD experience for:

- project-scoped Protocols
- global Protocol Templates
- playbook access inside those two surfaces

That experience must remain compatible with the current product language and operating model, while avoiding both visual inconsistency and low-quality generic form design.

## Goals

- expose `Protocols` as a first-class top-level Rails web area alongside `Boards` and `Documents`
- expose global Protocol Template management under `Settings`, not in the main top navigation
- provide a card-based CRUD experience aligned with the current `Documents` interaction model
- manage Protocol entries as a closed canonical set in MVP
- allow users to create missing canonical entries, edit existing entries, delete entries, and recreate them later
- keep creation constrained enough to preserve the current operating model without introducing duplicate entries of the same canonical type
- allow stack template administration beyond the seeded default stacks
- treat `PLAYBOOKS` as a dedicated subview with its own fixed canonical set in MVP
- preserve a direct, low-ceremony editing flow with read and edit combined in one screen
- support explicit save plus autosave
- define a professional visual standard that is harmonious with the current product rather than visually disconnected from it

## Non-Goals

- redefining the Protocol domain concept
- redesigning filesystem materialization semantics
- introducing a new open-ended protocol taxonomy for MVP
- implementing an unconstrained arbitrary-file manager
- adding a generic 2006-style model-driven admin CRUD
- adding a visually trendy but inconsistent 2026 form language that clashes with the current application
- defining backend persistence or route details in this specification

## Product Areas

The web management scope is split into two distinct areas.

### Project Protocols

Project Protocols are project-scoped and belong in the main product navigation.

They are part of the same user-facing level as existing project-oriented areas such as `Boards` and `Documents`.

### Protocol Templates

Protocol Templates are global administration surfaces and belong under `Settings`.

They must not occupy the same main-navigation level as project Protocols because their scope is different.

For MVP, `Settings` should expose two separate entry cards:

- `Common Protocol Templates`
- `Stack Protocol Templates`

This avoids an unnecessary extra navigation hop in the first version.

## Project Protocol UX

### Navigation

- The top navigation must include `Protocols` alongside `Boards` and `Documents`.
- Entering `Protocols` opens a card-based index.

### Index Shape

- The index must reflect the familiar repository operating shape.
- `AGENTS` and the `.agents/*`-backed entries appear together in one Protocol index view.
- `PLAYBOOKS` appears as a special card that leads to a dedicated Playbooks subview.

### Card Model

- MVP uses cards rather than a table.
- This is an intentional consistency choice with the existing `Documents` surface.
- The card model should not be built around filesystem-path-first semantics.
- Semantic information matters more than raw projected path details in the primary UX.

### Missing Entries

- Missing canonical Protocol entries must appear as empty cards rather than through a generic add flow only.
- Empty cards must visually read as intentionally absent, using a subtle missing or empty treatment.
- Empty cards must include a direct action to create that specific canonical entry.

### Editing Flow

- Opening an existing Protocol entry must not introduce a separate read-only show screen.
- Reading and editing happen in the same view.
- The interaction should be low-ceremony and close to the current `Documents` model.

### Save Model

- The editing surface must retain an explicit `Save` action.
- It must also support autosave.
- Autosave cadence of about 30 seconds is sufficient for MVP.
- The edit view must show a clear last-successful-save indicator.

## Protocol Template UX

Protocol Templates should repeat the same interaction model as project Protocols as much as practical.

### Common Templates

- `Common Protocol Templates` is a global template-management area under `Settings`.
- It follows the same card-based and low-ceremony editing model as project Protocols.

### Stack Templates

- `Stack Protocol Templates` is a sibling area under `Settings`.
- Management must be one screen per stack template set, not a single cross-stack bulk editor.
- The product must support creating stack template sets beyond seeded defaults.

### New Stack Set Flow

Creating a new stack template set must:

- ask for the stack identity
- support both language-shaped and framework-shaped stack names
- create an empty entry for each canonical protocol file type
- let the user edit those entries afterward

The MVP constraint is on canonical protocol types, not on prefilled body content. A placeholder may exist, but there is no mandatory canonical content skeleton.

## Canonical Set Rules

For MVP, both project Protocols and Protocol Templates operate on a closed canonical set.

### Core Rules

- creation is for missing canonical entries only
- duplicate entries of the same canonical type are not allowed within one managed set
- existing entries are edited rather than duplicated
- deletion is allowed
- deleted canonical entries may later be recreated

### Project Protocol Sets

Each project starts from an initial generated set created by project initialization, and the web surface then supports tweaking that set.

### Template Sets

The same closed-set rule applies inside template sets.

However, the product should not aggressively restrict users from creating additional stack template sets that may overlap semantically. Ambiguity created by user-defined variants is acceptable in MVP rather than heavily policed by the product.

## Playbooks

`PLAYBOOKS` is not a third independent template category.

It is part of the Protocol system and should be reached through the Protocol surfaces rather than through a separate top-level Settings card.

### Interaction Model

- `PLAYBOOKS` appears as a special card within the relevant Protocol or Protocol Template surface
- opening that card leads to a dedicated Playbooks subview
- the Playbooks subview also uses cards
- the Playbooks subview also uses a fixed canonical set in MVP

### MVP Classification

For MVP, playbooks should be treated as `common` only.

This is justified by the current repository playbooks, which are overwhelmingly behavioral and cross-stack rather than stack-specific.

## Visual Design Direction

This slice requires explicit visual discipline.

The goal is not merely “functional CRUD.” The goal is a management experience that looks intentional, professional, and harmonized with the current product.

### Required Style Outcomes

- visual consistency with the current Rails app
- clear harmony with existing `Documents` and adjacent surfaces
- no generic scaffold-like admin forms
- no stale model-driven form layouts that look disconnected from the current product
- no hyper-modern redesign that visually abandons the current app language
- a professional level of design judgment

### Practical Standard

The visual result should feel as if it was designed by a product designer who understands the current system rather than by a generator emitting default CRUD forms.

The target is:

- professional
- intentional
- calm
- coherent
- aligned with existing spacing, typography, and interaction patterns

### Anti-Patterns

Do not produce:

- default Rails CRUD scaffolding aesthetics
- arbitrary field stacks with no layout care
- a one-off futuristic surface that breaks harmony with the rest of the app
- visual novelty pursued at the expense of consistency

## Semantic Data Expectations

The primary management surface should not treat projected repository paths as its central user-facing model.

Instead, the UX should emphasize the semantic role of entries, including where relevant:

- whether an entry belongs to `common` or `stack`
- stack identity where applicable
- editable content state

Last-edited metadata is optional in cards and more appropriate inside the edit context.

## Acceptance Criteria

1. Rails exposes `Protocols` as a top-level navigation item alongside `Boards` and `Documents`.
2. Entering `Protocols` opens a card-based project Protocol index.
3. The project Protocol index presents `AGENTS` and `.agents/*`-backed entries together in one view.
4. `PLAYBOOKS` appears as a card that opens a dedicated Playbooks subview.
5. The Playbooks subview uses its own fixed canonical set in MVP.
6. Protocol editing combines read and edit in one screen rather than a show page followed by edit.
7. The editing surface provides explicit `Save`.
8. The editing surface also provides autosave with a visible last-save indicator.
9. Missing canonical entries appear as empty cards with a subtle missing treatment and a direct creation action.
10. Project Protocol creation is limited to missing canonical entries of the fixed MVP set.
11. Existing canonical project Protocol entries cannot be duplicated within the same project set.
12. Project Protocol deletion is allowed and recreation is allowed.
13. `Protocol Templates` are managed under `Settings`, not in the main top navigation.
14. `Settings` exposes separate cards for `Common Protocol Templates` and `Stack Protocol Templates`.
15. `Common Protocol Templates` follow the same core interaction pattern as project Protocols.
16. `Stack Protocol Templates` are managed one stack set per screen rather than in one combined cross-stack editor.
17. The product supports creating stack template sets beyond seeded defaults.
18. Creating a new stack template set creates empty canonical entries for the fixed MVP protocol types.
19. Template sets also disallow duplicate entries of the same canonical type within one set.
20. Template entries may be deleted and recreated later.
21. Playbooks are treated as `common` only in MVP.
22. The visual result is harmonious with the existing product and does not resemble generic scaffold CRUD.
23. The visual result does not introduce a trend-driven redesign that breaks consistency with current surfaces.

## Open Questions

- Whether a future version should relax the closed canonical set for project Protocols.
- Whether a future version should reduce the canonical set rather than only extend it.
- Whether stack-specific playbooks will ever justify moving beyond the MVP `common-only` rule.
- How a future setup flow should resolve ambiguous user-defined stack template variants.
- Whether a future larger management surface should shift from cards to a denser administrative table.
