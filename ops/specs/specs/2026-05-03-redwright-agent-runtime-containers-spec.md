# RedWright Agent Runtime Containers Specification

## Metadata

- id: `spec-2026-05-03-redwright-agent-runtime-containers`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- scope: `rails-core/project-runtime-containers/ticket-execution/sandbox-readiness`
- derived_from:
  - `ops/specs/drafts/2026-05-03-redwright-agent-runtime-containers-draft.md`
  - `ops/specs/specs/2026-05-03-redwright-project-setup-runnable-saga-spec.md`
  - `ops/specs/specs/2026-05-02-redwright-web-project-initialization-and-agent-workflow-spec.md`

## Problem Statement

RedWright's intended execution model is ticket-first agent work. Agents inspect Rails board state, select eligible tickets by assignment and priority, and execute lifecycle phases such as coding, review, and merge preparation.

Those agents should not depend on the host machine environment. Each project needs an explicit, editable, project-specific Runtime Containers configuration that defines the sandbox where agents perform development work.

The current project setup model already records a broad `runtime_container_profile`, and recent runtime bridge work can pass runtime context from Rails tickets into the runtime. However, the concrete container specification remains mostly implied. That leaves ticket execution unable to know whether the target project has a usable sandbox, which commands to run, which files to mount, or which validation gate proves the agent environment is ready.

## Goals

- make Runtime Containers a first-class project artifact in Rails
- generate an initial Runtime Containers configuration during or after project setup
- preserve generation provenance, assumptions, risks, and missing information
- expose Runtime Containers for inspection, editing, regeneration, comparison, validation, and readiness
- distinguish agent execution containers from production deployment artifacts
- make ticket execution resolve Runtime Containers readiness before sandboxed work starts
- return explicit readiness problems when Runtime Containers are missing, invalid, blocked, or stale
- support at least one useful deterministic generation path for supported stack/archetype combinations
- keep behavior covered by tests and maintain or increase coverage for new code paths

## Non-Goals

- Protocol template management
- Project Protocol CRUD or `AGENTS.md` materialization
- LLM rolling trace file implementation
- production deployment generation
- Kubernetes or remote builder orchestration
- hardened secrets management
- complete Docker/Podman execution engine
- multi-agent scheduling
- role-specific runtime pools beyond preserving model space for later specialization

## Product Concept

`Runtime Containers` is the project-specific configuration used by RedWright agents to execute development work in a sandbox.

It defines the development execution environment for agents, including:

- base image or image family
- language/runtime version
- system packages
- dependency installation commands
- test, lint, build, and formatting commands
- working directory
- repository mount strategy
- cache mount strategy
- environment variable placeholders
- secret placeholders without secret values
- network assumptions
- user and permission expectations
- generated Docker-oriented files
- validation command and validation result
- readiness state
- provenance, assumptions, risks, and missing information

Runtime Containers are not production deployment artifacts. A project may later have production deployment files, but agent runtime containers are optimized for development, testing, review, and merge preparation work.

## Project Runtime Containers Contract

Each project must be able to own one concrete editable Runtime Containers configuration.

The first implementation may use a single project-level configuration for all agent roles. The model must not prevent later specialization for:

- coder environment
- reviewer environment
- merger environment

The configuration must support these minimum fields:

- `profile`
- `status`
- `readiness`
- `base_image`
- `runtime_name`
- `runtime_version`
- `working_directory`
- `system_packages`
- `dependency_commands`
- `test_commands`
- `lint_commands`
- `build_commands`
- `format_commands`
- `repository_mount`
- `cache_mounts`
- `environment`
- `secret_placeholders`
- `network_policy`
- `user_policy`
- `validation_command`
- `validation_status`
- `validation_output_summary`
- `generated_files`
- `provenance`
- `assumptions`
- `missing_information`
- `risks`

Valid readiness states:

- `missing`
- `generated`
- `edited`
- `validated`
- `ready`
- `blocked`

Valid validation states:

- `not_run`
- `passed`
- `failed`
- `skipped`
- `stale`

## Generation Contract

Runtime Containers may be generated from:

- project setup answers
- project type
- language/runtime
- framework
- libraries
- repository files when available
- known stack profiles
- LLM-generated best guess
- later manual Rails edits

Generation must produce structured output, not only raw text.

Generated output must include:

- generated file proposals
- structured command metadata
- input signals used
- confidence
- assumptions
- missing information
- risks
- validation command
- validation instructions

The generated result is editable scaffolding. It must not be treated as an irreversible decision.

When LLM output is malformed or unavailable, the system must use deterministic fallback behavior for supported known profiles and explicit planned/blocked output for unsupported profiles.

## First Supported Profile

The first deterministic generation path should support:

- project type: `cli`
- language/runtime: `go`
- framework: `none` or omitted
- libraries: optional, including `urfave/cli`

Minimum expected generated files or file proposals:

- `Dockerfile` or equivalent container file proposal
- optional compose file or runtime metadata projection when useful
- setup command list
- validation command list

Minimum expected commands:

- dependency installation command when needed
- `go test ./...` as validation command
- formatting command when useful

Unsupported stack/archetype combinations must not pretend to be ready. They must produce a generated or blocked Runtime Containers record with missing information, assumptions, and a starter readiness ticket when setup integration reaches that point.

## Rails Management Surface

Rails must expose Runtime Containers management for each project.

Users must be able to:

- inspect current runtime container fields and generated files
- edit structured fields
- inspect provenance, assumptions, missing information, and risks
- regenerate suggestions from current project context
- compare regenerated suggestions against the active project configuration
- accept generated suggestions
- reject generated suggestions
- manually merge generated suggestions
- record validation status
- mark a configuration ready for agent execution when readiness rules allow it

The first implementation may expose this through Rails command/query actions before a full UI is built.

## Readiness Rules

Runtime Containers may be marked `ready` only when:

- required execution fields are present
- generated file proposals are accepted or explicitly skipped
- validation has passed or has been explicitly skipped with a reason
- no blocking risk remains unresolved

Editing commands, generated files, base image, runtime version, mounts, or environment placeholders after validation must mark validation as `stale` until validation is run or explicitly skipped again.

`blocked` means the system cannot safely produce or approve a runtime container configuration without more information or user intervention.

## Ticket Execution Contract

Ticket execution must resolve Runtime Containers readiness before agent work begins when the project requires sandboxed execution.

The resolved runtime context must include:

- project identity
- ticket identity
- Runtime Containers configuration id
- readiness state
- validation state
- workspace root
- repository root
- sandbox strategy
- generated files or materialized file paths
- execution commands

If Runtime Containers are missing, blocked, stale, or not ready, ticket execution must return a structured readiness problem. It must not claim that agent work started.

The first implementation may stop at readiness gating and context resolution. Full Docker or Podman process execution can be implemented later.

## Project Setup Integration

Project setup should create or schedule Runtime Containers work.

For supported stack/archetype combinations, setup should generate an initial Runtime Containers configuration.

For unsupported combinations, setup should record missing information and create a planned readiness task or ticket when board integration is available.

Setup completion may still create the project workspace before Runtime Containers are ready. Later ticket execution must surface the readiness gap.

## Filesystem Projection

Runtime Containers must support materialization into project workspace files later.

Possible projections include:

- `Dockerfile`
- `Containerfile`
- compose files for local agent execution
- RedWright runtime container metadata
- setup scripts

The first implementation may store generated file proposals in Rails and manifest metadata before writing final files. The important contract is that Rails-managed Runtime Containers can become executable workspace files.

## Safety Rules

Runtime Containers must not embed secret values.

They may reference:

- environment variable names
- secret placeholder names
- expected credentials policy

The first implementation is local-development oriented and must not claim production-grade isolation.

## Acceptance Criteria

1. Each project can own a Runtime Containers configuration.
2. Runtime Containers include structured execution fields, generated files, readiness, validation, provenance, assumptions, missing information, and risks.
3. Runtime Containers generation can produce a useful initial Go CLI agent sandbox proposal.
4. Unsupported contexts produce explicit missing-information or blocked records rather than false readiness.
5. Rails exposes Runtime Containers inspection and update through command/query or UI surfaces.
6. Regeneration produces suggestions without blindly overwriting the active configuration.
7. Runtime Containers can be validated or explicitly marked validation-skipped with reason.
8. Editing readiness-critical fields marks validation stale.
9. Ticket execution resolves Runtime Containers readiness before starting sandbox-required work.
10. Missing or blocked Runtime Containers produce actionable readiness errors.
11. Test coverage is maintained or increased for new behavior paths.

