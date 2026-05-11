---
id: TKT-20260511180906
title: Automate Docker agent runtime setup provisioning
status: open
kind: task
severity: high
priority: high
scope: project_setup
tags: docker,runtime-setup,agent-sandbox
source: chat
reported_at: 2026-05-11T18:09:06Z
ready_at:
started_at:
reviewed_at:
closed_at:
resolution:
owner: 
branch:
pr:
commits: []
---

## Context
This is slice 3 of the agent execution roadmap captured in:

- `ops/conv/dump/2026-05-11-redwright-codex-backend-and-agent-sandboxing-dump-raw.md`
- `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`

Ticket execution needs a repeatable Docker-based runtime setup that RedWright can generate, validate, and reuse. Initial project-specific tuning is acceptable, but repeated ticket execution should not depend on direct operator intervention after the setup has been accepted.

## Problem
The project setup flow must materialize the agent runtime configuration instead of creating self-referential tickets about future setup work. RedWright needs a runtime setup that tells managed workers how to provision a ticket workspace, build or select the Docker image, mount only the required runtime paths, and validate that the environment is usable. The ticket must decide whether `.rw` is the source of truth for this metadata and Docker configuration, or whether `.rw` stores generated artifacts derived from an internal runtime model.

## Expected
- Project setup generates a Docker-based agent runtime configuration under `.rw` or the agreed RedWright project metadata location.
- The implementation explicitly defines whether `.rw` owns the editable source of truth or only contains generated runtime artifacts.
- The generated setup distinguishes the agent execution environment from application production or development containers.
- RedWright can build or validate the agent runtime before assigning tickets to managed workers.
- The setup supports a user fine-tuning pass when stack detection is incomplete, then reuses the accepted configuration for later tickets.
- Ticket execution can use the generated setup with either the Codex managed-worker backend or the native engine backend once both exist.
- The setup flow does not create placeholder tickets that ask future agents to design the runtime from scratch.

## Actual
- Docker agent runtime setup is not yet generated and validated as a reusable project artifact.
- The existing project setup direction can leave planning artifacts instead of materializing the runtime configuration needed for future ticket execution.

## Fix Strategy
- Define the generated runtime setup files and their ownership under `.rw`.
- Decide and document the source-of-truth model for runtime metadata before wiring ticket execution to it.
- Add a runtime setup generator that detects common project stacks and emits a conservative Docker configuration.
- Add a validation command that builds or dry-runs the generated Docker setup and reports actionable missing information.
- Add a review/update path for project-specific fine tuning without replacing the whole setup.
- Connect ticket execution to the accepted runtime setup instead of ad hoc Docker commands.
- Keep provider credentials and host RedWright secrets outside generated project files unless explicitly declared as runtime injection policy.

## Validation
- Running project setup on a representative repository creates deterministic `.rw` agent runtime files.
- The generated Docker setup validates successfully for a supported stack or reports a specific missing prerequisite.
- Re-running setup is idempotent and does not overwrite accepted fine tuning without an explicit update path.
- A ticket execution dry run can read the generated setup and prepare an isolated worker environment.

## Outcome
Pending implementation.
