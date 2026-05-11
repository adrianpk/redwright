---
id: TKT-20260511180900
title: Spike Codex managed worker ticket backend
status: open
kind: research
severity: high
priority: high
scope: runtime
tags: codex,managed-worker,ticket-execution
source: chat
reported_at: 2026-05-11T18:09:00Z
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
This is slice 2 of the agent execution roadmap captured in:

- `ops/conv/dump/2026-05-11-redwright-codex-backend-and-agent-sandboxing-dump-raw.md`
- `ops/specs/drafts/2026-05-11-redwright-reusable-agent-sandbox-behavior-draft.md`

RedWright needs a pragmatic managed-worker backend for ticket execution while the native engine is still being refined. This slice validates whether Codex can run inside an isolated execution environment, receive a ticket task, work against a cloned repository workspace, and return structured execution output.

## Problem
The Codex managed-worker approach is still a feasibility hypothesis. RedWright should not treat it as an available ticket backend until a small proof shows how Codex is invoked, how credentials are scoped, how the repository is cloned, how the branch/workspace is isolated, and how the result is returned to the host runtime.

## Expected
- A minimal managed-worker backend can invoke Codex inside an isolated execution environment.
- The worker receives a bounded task packet containing ticket context, repository location, target branch policy, and validation expectations.
- The worker clones or prepares its own workspace instead of mutating the host's current checkout.
- Required credentials are injected narrowly for this backend and are not copied into generated project setup files.
- RedWright receives a structured task result with status, event log, changed files or diff summary, validation output, and failure reason when applicable.
- The spike clearly records whether this backend is viable for a later production implementation.

## Actual
- RedWright does not yet have a proven Codex managed-worker ticket backend.
- The current docs describe the desired boundary and feasibility requirements, but the execution path has not been exercised.

## Fix Strategy
- Define the smallest backend adapter contract needed for ticket execution.
- Create a local spike command or service object that starts an isolated execution environment with Codex available.
- Pass a single low-risk ticket task into the worker as structured input.
- Let the worker clone or prepare a scratch repository workspace and create an isolated branch or equivalent working state.
- Capture stdout, stderr, event output, repository diff, validation command output, and final status.
- Record explicit failure modes for missing credentials, Codex invocation errors, validation failures, and no-diff outcomes.

## Validation
- A local spike can run against a throwaway or tiny repository task without changing the host checkout.
- The spike reports success, blocked, auth failure, execution failure, and validation failure as distinct outcomes.
- `git status` in the host repository remains clean except for intentional RedWright changes.
- The final spike note states whether Codex-in-worker ticket execution is viable, viable with constraints, or not viable.

## Outcome
Pending implementation.
