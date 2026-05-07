---
name: repo-architecture-audit
description: Audit and improve Ruby and Ruby on Rails architecture and codebase quality for RedWright. Use when a repository ticket, user request, or review asks for architecture audit, codebase quality audit, maintainability inspection, refactoring recommendations, architecture correction, codebase cleanup, naming consistency review, fat model/controller refactor, service object review or refactor, Rails boundary review, ActiveRecord quality review, or long-term architecture risk reduction.
---

# Repository Architecture Audit

Use this skill only inside repositories that follow the RedWright agent workflow.

The source of truth is the repository playbook, not this skill:

- `.agents/playbooks/architecture-codebase-quality-audit.md`
- `.agents/CONVENTIONS.md`
- `.agents/ARCHITECTURE.md`
- `.agents/playbooks/ticket-workflow.md`

## Startup

1. Confirm the repository has `.agents/playbooks/architecture-codebase-quality-audit.md`.
2. Read `.agents/playbooks/architecture-codebase-quality-audit.md` before auditing.
3. Read `.agents/CONVENTIONS.md` and `.agents/ARCHITECTURE.md` before making architectural judgments.
4. If the audit is ticket-driven, read the relevant ticket and `.agents/playbooks/ticket-workflow.md`.

## Operating Rules

1. Determine whether the request is `audit` mode or `improve` mode.
2. In `audit` mode, inspect and recommend without changing production code, tests, docs, or tickets.
3. In `improve` mode, implement focused architecture corrections authorized by the user request or ticket.
4. Prefer targeted repository searches before reading large files.
5. Ground findings in file paths, line references, observed code, or clearly marked inference.
6. Prioritize maintainability risks, unclear ownership, hidden coupling, and unsafe evolution paths.
7. Avoid abstract architecture advice that does not map to concrete repository evidence.

## Audit Flow

1. Identify the requested scope: whole Rails app, specific subsystem, ticket area, or changed files.
2. Build an inspection map of relevant models, controllers, services, views, jobs, tests, routes, and configuration.
3. Inspect the playbook audit areas that apply to the scope.
4. Group findings by severity and category.
5. Recommend concrete refactors or conventions, prioritized by impact and implementation complexity.
6. Report residual uncertainty when a finding needs runtime traces, production data, or broader historical context.

## Improve Flow

1. Identify the selected finding, ticket, or architecture issue to correct.
2. Read the smallest set of files needed to understand behavior and tests.
3. Make behavior-preserving refactors by default.
4. Add or adjust focused tests when the change affects contracts, persistence behavior, branching logic, or integration boundaries.
5. Run relevant validation.
6. Report corrections, changed files, validation, and remaining risks.

## Report Shape

Use this structure unless the user requests another format:

```md
## Findings

- Severity: <critical|high|medium|low>
  Category: <audit category>
  Location: <path:line>
  Evidence: <observed code or behavior>
  Risk: <why it matters>
  Recommendation: <specific next step>

## Architectural Risks

- <risk and affected area>

## Suggested Conventions

- <standard or rule for future work>

## Prioritized Improvements

- <impact>/<complexity>: <action>

## Validation

- <commands or inspection methods used>
```

When reporting in chat, keep the same order but compress sections when the audit is small.

For `improve` mode, use the normal coding-task final shape: summarize the correction, list changed files when useful, and report validation explicitly.
