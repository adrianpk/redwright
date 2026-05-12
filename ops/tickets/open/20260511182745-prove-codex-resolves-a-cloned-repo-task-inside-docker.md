---
id: TKT-20260511182745
title: Prove Codex resolves a cloned repo task inside Docker
status: open
kind: research
severity: high
priority: high
scope: runtime
tags: codex,docker,repo-clone,codeberg,remote-push
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

The goal is narrower than the full managed-worker backend. RedWright does not need to infer the Docker setup in this slice. A handcrafted image is acceptable as long as the proof shows that Codex can run inside the container, clone an existing Codeberg repository, complete a concrete ticket-like coding task, run tests, push a result branch, and return an inspectable result without waiting for human approval.

## Problem
The critical unknown is whether the core execution model works at all: a container with project tools plus Codex, host-injected environment variables, repository cloning inside the container, non-interactive task execution from a ticket-like prompt, validation inside the cloned workspace, branch push to the remote, and inspectable output. RedWright should validate that before wiring kanban movement, ticket lifecycle transitions, runtime setup generation, or backend abstractions around it.

## Expected
- A handcrafted Docker image exists for one initial stack, such as Go, Ruby, Zig, or Elixir.
- The image includes the language/toolchain needed by the sample repository and a runnable Codex CLI or equivalent Codex invocation path.
- Required Codex and Codeberg push environment variables are injected from the host at container startup and are not baked into the image.
- The container receives an existing Codeberg repository URL, target branch or scratch branch name, and ticket-like task prompt.
- The container clones the repository itself into a disposable workspace.
- Codex runs non-interactively and must not block waiting for a human approval prompt.
- The initial task is a Go todo CLI implementation ticket that asks for a mark-as-read capability and tests without prescribing exact file edits.
- The selected Codeberg repository README explains that the repository is a RedWright Codex black-box proof fixture and identifies where RedWright uses it.
- The worker commits the result to the configured branch and pushes that branch to Codeberg.
- The result is inspectable from the host through logs, validation output, repository diff, commit metadata, and pushed branch metadata.
- This slice does not move RedWright tickets between kanban columns and does not need to open a pull request.

## Actual
- RedWright has a broader ticket for a Codex managed-worker backend, but no narrower proof that containerized Codex can clone and modify a repository successfully.
- Docker runtime setup generation is tracked separately and should not block this proof.

## Fix Strategy
- Pick or create one controlled Codeberg repository seeded from `_workspace/Projects/go-todo-agent`.
- Ensure that repository has a README explaining its proof-fixture purpose and its use by the RedWright Codex black-box engine proof.
- Add a hardcoded proof Dockerfile or runtime recipe for that repository's stack.
- Add a local proof command or script that starts the container with explicit environment variables.
- Pass the repository URL, result branch, ticket-like task prompt, validation command, and remote push policy into the container as structured arguments or mounted input.
- Run Codex inside the container in a non-interactive mode suitable for unattended execution.
- Capture container logs, Codex output, validation command output, final repository diff, commit metadata, pushed branch metadata, and structured failure reason.
- Keep the proof isolated from RedWright kanban transitions, ticket movement, PR creation, and automatic Docker inference.

## Validation
- Running the proof command builds or starts the Docker image successfully.
- The container clones the supplied repository into its own workspace.
- The supplied repository has a README that explains the proof-fixture purpose and RedWright usage context.
- Codex completes the task without requiring an interactive approval from a human.
- The container runs the repository's validation command and reports pass or failure clearly.
- The worker pushes the result branch to the configured Codeberg remote when credentials and validation policy allow it.
- The host can inspect the resulting diff, commit, pushed branch, and validation output after the container exits.
- No provider API keys or tokens are written into the image, generated repo files, committed artifacts, pushed commits, or result logs.

## Outcome
Pending implementation.
