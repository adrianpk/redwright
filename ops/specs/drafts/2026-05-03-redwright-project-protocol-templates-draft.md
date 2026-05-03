# RedWright Project Protocol Templates Draft

## Status

- type: `spec-draft`
- date: `2026-05-03`
- source: alignment conversation about reusable project operating documents, stack overlays, and project-specific protocol copies

## 1. Scope

This draft defines the product need for managing project Protocols in the Rails application.

It does not define the persistence schema, controller structure, database migrations, routing implementation, or final UI layout.

## 2. Terminology

The product term for the operating document set is `Protocol`.

A Protocol is the project-specific set of agent-facing operating instructions, conventions, context, and guardrails that bias how agents and humans work inside a project.

`Protocol` is preferred over `governance` because it is shorter, more executable, and fits both UI language and code naming without sounding like an organizational compliance feature.

## 3. Problem Statement

RedWright projects need reusable agent operating patterns without copying the same common rules into every project by hand.

Some protocol content is general across stacks, such as expected agent behavior, execution discipline, invariants, lifecycle rules, documentation rules, and collaboration boundaries.

Other protocol content is stack- or framework-shaped, such as Rails conventions, React conventions, linting commands, testing commands, architecture boundaries, migrations, jobs, packages, deployment shape, or tenancy-specific expectations.

Each concrete project may also need local adjustments that should not mutate the shared template used by other projects.

## 4. Product Need

The Rails application needs three distinct protocol management surfaces:

1. Common Protocol template management.
2. Stack-based Protocol template management.
3. Project Protocol editing for the concrete non-template copy attached to a project.

These are distinct product responsibilities even if an implementation later shares internal models, views, or services.

## 5. Common Protocol Templates

Common Protocol templates define reusable rules expected to apply across projects regardless of stack.

They should cover responsibilities such as:

- agent behavior
- execution discipline
- collaboration invariants
- documentation placement rules
- delivery lifecycle
- request routing
- task slicing
- versioning policy
- reporting and handoff expectations

The purpose is to avoid repeating stable operational behavior in every stack profile and every project.

## 6. Stack Protocol Templates

Stack Protocol templates define stack- or framework-specific protocol content.

They should cover responsibilities such as:

- language and framework conventions
- repository architecture expectations
- linting, formatting, test, build, and dev commands
- dependency policy
- module and boundary rules
- data, migration, job, queue, frontend, or deployment conventions when relevant

Stack templates are overlays. They should add or replace stack-shaped slots instead of duplicating the common Protocol template by default.

The system does not need one stack template for every possible technology. It should support templates for common or strategically important stacks, while allowing the setup flow to proceed without a matching stack template.

## 7. Project Protocols

A Project Protocol is the concrete non-template version associated with one project.

It may be created from:

- a common Protocol template
- one or more stack Protocol templates
- LLM synthesis during project setup
- user-provided answers
- later manual edits in the Rails application

After creation, the Project Protocol belongs to the project. Editing it should tune that project only and should not mutate the source templates.

The application should preserve enough provenance to explain where the initial Project Protocol came from, such as selected templates, versions, setup answers, LLM confidence, alternatives considered, and human approval when available.

## 8. Project Bootstrap Contract

The `/project new` setup cycle should be able to select Protocol inputs before or during project materialization.

During final project initialization, the system should be able to:

- infer a suitable common Protocol template
- infer suitable stack Protocol templates when project context is sufficient
- ask the user when selection confidence is low or the choice is consequential
- proceed without a stack template when none applies
- propose synthesized project-specific Protocol content when templates are insufficient
- create and associate the resulting Project Protocol with the new project

The initial selection does not need to be perfect. The resulting Project Protocol remains editable from the Rails application.

## 9. Navigation Need

The Rails application should expose Protocols as a first-class project area alongside existing project surfaces such as Boards and Docs.

The UI language should use `Protocols`.

The Protocols area should let users inspect and edit the concrete Project Protocol for the current project.

The application should also expose administration surfaces for common Protocol templates and stack Protocol templates.

## 10. Filesystem Materialization

Project Protocols should be materializable to repository files for tool interoperability and user convenience.

The expected filesystem shape is:

- `AGENTS.md`
- `.agents/`
- `.agents/*.md`

This materialization allows a user to operate the same project directly with Codex or other agent tools that read filesystem instructions.

The Rails Project Protocol remains the product-level source of truth when the project is managed by RedWright. Filesystem materialization is an operational projection that should be syncable or regenerable according to a later implementation contract.

## 11. Desired Behavior

- Users can manage common Protocol templates once and reuse them across projects.
- Users can manage stack Protocol templates without duplicating the common Protocol template.
- New projects receive a concrete Project Protocol during setup.
- Project Protocols can be edited independently after creation.
- Setup can choose, combine, skip, or synthesize Protocol inputs based on available context.
- Protocols appear as a first-class project concept in the Rails app.
- Project Protocols can be exported or materialized into `AGENTS.md` and `.agents/` files.

## 12. Out of Scope

- database schema design
- Rails controller, route, or view implementation
- exact merge algorithm for common and stack templates
- conflict resolution semantics between templates
- filesystem sync implementation
- template marketplace or remote template distribution
- full governance/compliance model

## 13. Open Questions

- Should project setup create one composed Project Protocol document or preserve editable slots per protocol responsibility?
- Should stack Protocol templates support multiple overlays per project, such as `rails` plus `react` plus `multi_tenant`?
- Should filesystem materialization be manual, automatic, or policy-driven per project?
- Should edited Project Protocols receive update suggestions when their source templates change?
- What provenance detail is required in the first product slice?

## 14. Next Iteration Inputs

- define the minimum Protocol slots needed for the first Rails UI slice
- define the first common Protocol template responsibilities
- define the first stack Protocol templates worth shipping
- define how `/project new` records template selection and confidence
- define the materialization contract for `AGENTS.md` and `.agents/`
