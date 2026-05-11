---
id: TKT-20260511182745
title: Prove Codex resolves a cloned repo task inside Docker
status: open
kind: research
severity: high
priority: high
scope: runtime
tags: codex,docker,repo-clone
source: chat
reported_at: 2026-05-11T18:27:45Z
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
This is the first granular proof under the broader Codex managed-worker direction captured in:

- `ops/conv/dump/2026-05-11-redwright-codex-backend-and-agent-sandboxing-dump-raw.md`
- `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`
- `ops/tickets/open/20260511180900-spike-codex-managed-worker-ticket-backend.md`

The goal is narrower than the full managed-worker backend. RedWright does not need to infer the Docker setup in this slice. A handcrafted image is acceptable as long as the proof shows that Codex can run inside the container, clone a supplied repository, complete a concrete coding task, and return an inspectable result without waiting for human approval.

## Problem
The critical unknown is whether the core execution model works at all: a container with project tools plus Codex, host-injected environment variables, repository cloning inside the container, non-interactive task execution, and inspectable output. RedWright should validate that before wiring kanban movement, ticket lifecycle transitions, runtime setup generation, or backend abstractions around it.

## Expected
- A handcrafted Docker image exists for one initial stack, such as Go, Ruby, Zig, or Elixir.
- The image includes the language/toolchain needed by the sample repository and a runnable Codex CLI or equivalent Codex invocation path.
- Required environment variables are injected from the host at container startup and are not baked into the image.
- The container receives a repository URL, target branch or scratch branch name, and task prompt.
- The container clones the repository itself into a disposable workspace.
- Codex runs non-interactively and must not block waiting for a human approval prompt.
- The task can be an implementation or bug-fix task; it only needs to prove the core loop.
- The result is inspectable from the host through logs and repository diff or committed branch output.
- This slice does not move RedWright tickets between kanban columns and does not need to open a pull request.

## Actual
- RedWright has a broader ticket for a Codex managed-worker backend, but no narrower proof that containerized Codex can clone and modify a repository successfully.
- Docker runtime setup generation is tracked separately and should not block this proof.

## Fix Strategy
- Pick one small public or controlled repository with a deterministic coding task.
- Add a hardcoded proof Dockerfile or runtime recipe for that repository's stack.
- Add a local proof command or script that starts the container with explicit environment variables.
- Pass the repository URL and task prompt into the container as structured arguments or mounted input.
- Run Codex inside the container in a non-interactive mode suitable for unattended execution.
- Capture container logs, Codex output, validation command output, and the final repository diff or branch state.
- Keep the proof isolated from RedWright kanban transitions, ticket movement, PR creation, and automatic Docker inference.

## Validation
- Running the proof command builds or starts the Docker image successfully.
- The container clones the supplied repository into its own workspace.
- Codex completes the task without requiring an interactive approval from a human.
- The container runs the repository's validation command and reports pass or failure clearly.
- The host can inspect the resulting diff or branch output after the container exits.
- No provider API keys or tokens are written into the image, generated repo files, or committed artifacts.

## Outcome
Pending implementation.
