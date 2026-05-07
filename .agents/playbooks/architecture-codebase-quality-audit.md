# Architecture & Codebase Quality Audit and Improvement

Use this playbook for comprehensive architecture and code quality inspections and targeted improvements across the Ruby and Ruby on Rails codebase.

The objective is to improve maintainability, readability, consistency, architectural clarity, and long-term evolution of the system.

## Scope

This workflow supports two modes:

- `audit`: inspect the codebase and produce findings, risks, and recommendations.
- `improve`: inspect the codebase, select actionable improvements, implement them, and validate the result.

Use `audit` mode when the request asks for review, inspection, assessment, findings, or recommendations.

Use `improve` mode when the request or ticket asks to fix, correct, refactor, clean up, improve architecture, reduce complexity, or implement the audit recommendations.

Focus on actionable maintainability risks, unclear boundaries, consistency issues, and architecture decisions that make future development harder.

## Audit Areas

1. Naming consistency
   - Review classes, modules, methods, variables, scopes, services, queries, and domain terminology.
   - Detect ambiguous or generic names such as `Manager`, `Processor`, `Helper`, `Utils`, `Data`, and similar placeholders.

2. Fat models and fat controllers
   - Identify excessive business logic inside models, controllers, callbacks, and concerns.
   - Propose better responsibility distribution where appropriate.

3. Service object architecture
   - Review service object structure, naming, contracts, and responsibility boundaries.
   - Detect procedural or god-service patterns.

4. Callback usage
   - Inspect `before_*`, `after_*`, and transactional callbacks.
   - Detect hidden side effects and implicit execution flows.

5. ActiveRecord usage
   - Review query quality and ORM usage.
   - Detect N+1 issues, query-in-loop patterns, unnecessary loading, misuse of scopes, and inefficient persistence patterns.

6. Architectural boundaries
   - Review separation between domain logic, persistence, orchestration, and presentation layers.
   - Detect leakage between layers.

7. Concern usage
   - Inspect concerns for overuse, hidden coupling, or pseudo-multiple-inheritance behavior.
   - Evaluate whether extraction into proper objects would improve clarity.

8. Error handling strategy
   - Review exception handling consistency.
   - Detect generic rescues, swallowed exceptions, and lack of explicit domain errors.

9. Transaction boundaries
   - Inspect transactional integrity and side effects executed inside transactions.
   - Review consistency guarantees and rollback safety.

10. Ruby idiomatic quality
    - Detect overly procedural or Java-style code.
    - Encourage idiomatic Ruby patterns where they improve clarity and maintainability.

11. Object lifecycle and mutability
    - Review object initialization patterns and mutable state usage.
    - Detect implicit state dependencies.

12. Dependency direction and coupling
    - Detect circular dependencies and improper dependency flow between layers or domains.

13. View layer architecture
    - Inspect ERB, HAML, SLIM, helpers, and view components when present.
    - Detect excessive presentation logic in views or oversized helpers.

14. Routing and controller organization
    - Review route structure and controller responsibilities.
    - Detect over-nesting and multipurpose controllers.

15. Background jobs
    - Review job granularity, idempotency, retry safety, and business logic placement.

16. Test architecture
    - Review test maintainability, reliability, speed, and structure.
    - Detect excessive mocking, brittle factories, redundant coverage, and unclear testing boundaries.

17. Linting and formatting
    - Review RuboCop configuration and overall code style consistency.
    - Detect disabled rules without justification and inconsistent formatting practices.

18. File and module organization
    - Review directory structure and module hierarchy.
    - Ensure organization reflects domain boundaries and system intent.

19. Configuration hygiene
    - Review initializers, environment configuration, constants, feature flags, and application settings.
    - Detect hidden or fragmented configuration logic.

20. Dead abstractions and speculative architecture
    - Detect unnecessary layers, adapters, interfaces, or abstractions introduced without concrete value.
    - Identify opportunities for simplification.

## Audit Procedure

1. Establish the audit scope from the ticket, user request, or repository area.
2. Read the repository architecture and convention docs before judging structure.
3. Inspect code with targeted searches before opening large files.
4. Group findings by severity and category.
5. Prefer concrete file references and examples over broad claims.
6. Distinguish observed evidence from inference.
7. Recommend refactors only when they reduce real complexity, clarify ownership, or remove meaningful risk.
8. Do not propose speculative abstractions as fixes for speculative abstractions.

## Improvement Procedure

1. Establish the implementation scope from the ticket, user request, or approved audit findings.
2. Prefer small, behavior-preserving refactors unless the ticket explicitly authorizes behavior changes.
3. Preserve public contracts, runtime behavior, and data semantics unless changing them is the requested correction.
4. Add or adjust tests when the refactor changes shared contracts, non-trivial control flow, persistence behavior, or previously untested risk.
5. Keep changes focused on the architectural issue being corrected.
6. Avoid opportunistic cleanup outside the selected finding or ticket scope.
7. Validate with the narrowest relevant checks first, then broader checks when the blast radius warrants it.
8. Report what was corrected, what was intentionally left unchanged, and what validation was run.

## Correction Priorities

Prioritize corrections in this order:

1. hidden side effects, unsafe transactions, swallowed errors, or state integrity risks
2. boundary leaks that make behavior hard to reason about or test
3. oversized services, controllers, models, concerns, or helpers that block safe evolution
4. ActiveRecord inefficiencies that are structurally likely to create N+1 or query-loop problems
5. naming and organization issues that obscure domain intent
6. speculative abstractions that can be removed without reducing clarity

## Severity Model

- `critical`: correctness, data integrity, or operational risks that can cause production failure or unsafe state.
- `high`: architecture or maintainability risks that block safe evolution or repeatedly cause defects.
- `medium`: localized design issues that add complexity, coupling, or testing burden.
- `low`: naming, organization, consistency, or style issues with limited immediate impact.

## Deliverables

For `audit` mode, produce an audit report with:

- findings grouped by severity and category
- concrete refactoring recommendations
- architectural risks and maintainability bottlenecks
- suggested conventions and standards for future development
- actionable improvements prioritized by impact and implementation complexity

For `improve` mode, produce an implementation report with:

- corrections implemented
- files changed
- behavior or contract impact
- validation commands and results
- remaining risks or deferred findings

When the work comes from a ticket, update or reference the ticket according to the ticket workflow only if the user explicitly asks for ticket file changes.
