---
id: TKT-20260507065222
title: Audit architecture and codebase quality
status: reviewing
kind: task
severity: medium
priority: normal
scope: web
tags: architecture,code-quality,audit,maintainability,ruby
source: chat
reported_at: 2026-05-07T06:52:22Z
ready_at: 2026-05-07T06:56:00Z
started_at: 2026-05-07T06:56:00Z
reviewed_at: 2026-05-07T07:02:41Z
closed_at:
resolution:
owner: 
branch: refactor/ticket-20260507065222-architecture-quality-audit
pr: https://codeberg.org/adrianpk/redwright/pulls/339
commits:
  - 8c9a4f7
  - a63acf7
---

## Context
The Ruby and Ruby on Rails codebase has evolved through multiple feature slices, runtime flows, web UI additions, ticket workflow alignment, and operational scripts. A dedicated architecture and code quality audit is needed to identify maintainability risks, consistency gaps, and refactoring opportunities before they become harder to address.

This ticket captures the audit request as a reference artifact and implementation task. The expected output is not only an audit report: the work must also make concrete architecture and code quality improvements where the audit identifies high-value, bounded changes. Follow-up tickets, specs, or targeted refactoring plans should be created only for larger changes that cannot be completed safely in this ticket.

## Problem
The codebase may contain architectural drift, naming inconsistencies, unclear boundaries, overgrown Rails objects, hidden callback behavior, inefficient ActiveRecord usage, weak error-handling conventions, test architecture friction, or speculative abstractions. These issues can reduce readability, maintainability, delivery speed, and long-term evolution of the system.

## Expected
- Perform a comprehensive architecture and code quality inspection across the Ruby and Ruby on Rails codebase.
- Group findings by severity and category.
- Provide concrete refactoring recommendations.
- Identify architectural risks and maintainability bottlenecks.
- Suggest conventions and standards for future development.
- Prioritize actionable improvements by impact and implementation complexity.
- Implement concrete refactors and cleanup changes that improve architecture, readability, consistency, or maintainability within a safe bounded scope.
- Preserve behavior while improving structure, with tests updated or added where behavior boundaries are touched.

## Audit Scope
- Naming consistency across classes, modules, methods, variables, scopes, services, queries, and domain terminology.
- Ambiguous or generic names such as `Manager`, `Processor`, `Helper`, `Utils`, `Data`, and similar terms.
- Fat models, fat controllers, callbacks, concerns, and excessive business logic in Rails objects.
- Service object structure, naming, contracts, responsibility boundaries, procedural patterns, and god-service risks.
- Callback usage, including `before_*`, `after_*`, transactional callbacks, hidden side effects, and implicit execution flows.
- ActiveRecord query quality, ORM usage, N+1 risks, query-in-loop patterns, unnecessary loading, scope misuse, and inefficient persistence patterns.
- Architectural boundaries between domain logic, persistence, orchestration, presentation, runtime, LLM, project setup, and repository workflow code.
- Concern usage, hidden coupling, pseudo-multiple-inheritance behavior, and possible replacement with explicit objects.
- Error handling strategy, generic rescues, swallowed exceptions, and missing explicit domain errors.
- Transaction boundaries, side effects inside transactions, rollback safety, and consistency guarantees.
- Ruby idiomatic quality, overly procedural or Java-style code, and opportunities for clearer Ruby patterns.
- Object lifecycle, initialization patterns, mutable state, and implicit state dependencies.
- Dependency direction, coupling, circular dependencies, and improper flow between layers or domains.
- View layer architecture in ERB templates and helpers, including excessive presentation logic.
- Routing and controller organization, including over-nesting and multipurpose controllers.
- Background job granularity, idempotency, retry safety, and business logic placement.
- Test architecture, including maintainability, reliability, speed, structure, excessive mocking, brittle factories, redundant coverage, and unclear testing boundaries.
- Linting and formatting, RuboCop or equivalent configuration, disabled rules without justification, and inconsistent formatting practices.
- File and module organization, directory structure, module hierarchy, and alignment with domain boundaries.
- Configuration hygiene in initializers, environment configuration, constants, feature flags, and application settings.
- Dead abstractions, speculative architecture, unnecessary adapters, unnecessary interfaces, and simplification opportunities.

## Actual
- No current consolidated architecture and code quality audit artifact exists for the full Ruby/Rails codebase.
- Architectural and maintainability risks are currently discovered opportunistically during feature work or review.
- Known or discovered issues are not yet being converted into a focused improvement pass that actually changes the code.

## Fix Strategy
- Inspect the repository structure and identify the relevant Ruby, Rails, test, configuration, and operational code areas.
- Review representative and high-risk code paths before broad low-signal style concerns.
- Produce a written audit report with findings grouped by severity and category.
- For each finding, include concrete file references, risk description, recommendation, and suggested follow-up shape.
- Implement the highest-impact bounded refactors discovered during the audit, prioritizing changes that improve naming, responsibility boundaries, dependency direction, Rails object size, query clarity, error handling, or test maintainability without broad behavior risk.
- Split only large, risky, or multi-cycle remediation items into focused follow-up tickets, specs, or planned slices after the initial improvement pass.

## Validation
- Audit report exists in the repository location selected during triage.
- Findings include severity, category, file references, and concrete recommendations.
- Recommendations are prioritized by impact and implementation complexity.
- Concrete code changes are implemented for the selected high-value architecture and code quality improvements.
- Existing behavior remains covered by the relevant test suite, with new or updated tests where refactors touch observable behavior.
- Follow-up work is captured as separate tickets or planning artifacts only when too large or risky for this ticket.
- Repository ticket checks pass after status or metadata changes.
- 2026-05-07: Ruby syntax checks passed for changed service files.
- 2026-05-07: Targeted Rails tests passed with 64 runs, 564 assertions, 0 failures.
- 2026-05-07: Full Rails suite passed with 392 runs, 2530 assertions, 0 failures.

## Outcome
Implementation is ready for review in PR #339. The audit artifact was added at `ops/artifacts/2026-05-07-architecture-codebase-quality-audit.md`, and bounded refactors were implemented for mention capture, command/query payload readers, document promotion transaction/error handling, and quiz entry counting.
