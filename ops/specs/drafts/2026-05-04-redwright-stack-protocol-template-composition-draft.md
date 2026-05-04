# Stack Protocol Template Composition Draft

Status: Draft
Date: 2026-05-04

## Context

RedWright seeds protocol templates for project initialization. These templates are stack-based rather than strictly language-based, because a project framework can be more operationally relevant than the underlying language alone.

Examples:

- Ruby can be used directly, but Rails projects need Rails-specific architectural and operational rules.
- TypeScript can be used directly, but Angular projects need Angular-specific architectural and operational rules.

## Provisional Decision

Framework-oriented stacks should be seeded as complete, self-contained templates during the initial implementation.

This means:

- `ruby` defines a complete Ruby stack protocol template.
- `rails` defines a complete Rails stack protocol template, including the Ruby guidance that remains relevant for Rails projects.
- `typescript` defines a complete TypeScript stack protocol template.
- `angular` defines a complete Angular stack protocol template, including the TypeScript guidance that remains relevant for Angular projects.

RedWright should not compose framework templates from multiple stack templates at this stage.

## Rationale

Self-contained stack templates keep the initial model simple and predictable:

- A selected stack maps to one complete editable template set.
- The web CRUD does not need to expose provenance or layering between language and framework templates.
- Materialization does not need precedence rules, merge rules, conflict handling, or overlay ordering.
- Users can tune a single project stack template without understanding internal composition mechanics.

The expected duplication between related stacks is acceptable for the current stage.

## Tradeoff

This approach duplicates some guidance between related stacks, especially:

- Ruby and Rails
- TypeScript and Angular

That duplication is deliberate. It favors clarity and operational predictability over abstraction.

## Future Evaluation

Template composition can be revisited later if duplicated guidance becomes stable, repetitive, and costly to maintain.

Possible future options:

- language base template plus framework overlay
- reusable template fragments
- explicit template inheritance
- generated framework templates derived from a language baseline

Any future composition model should be introduced only after the simple self-contained model has been exercised through real project initialization and CRUD editing.
