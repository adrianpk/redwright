---
id: TKT-20260506081604
title: Launch quiz rounds from quiz UI
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: quiz, web, configuration
source: chat
reported_at: 2026-05-06T08:16:04Z
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
The Quizzes UI should allow users to launch a quiz round from the main quiz home, from a project quiz view, or from a use-case-specific quiz card/view.

When launched from a narrower context, the quiz round should be scoped to that context.

Quizzes are intended to reveal, clarify, and surface context. They should not become an unbounded dense specification mechanism.

## Problem
Users need a direct way to start or continue quiz rounds from the relevant quiz UI surface.

At the same time, indiscriminately launching rounds may create excessive question/answer noise if the system allows very large numbers of quiz entries.

## Expected
- The quiz UI should offer a way to launch a new quiz round.
- Launching from the main quiz home should use the current project context.
- Launching from a project quiz view should scope the round to that project.
- Launching from a use-case quiz view/card should scope the round to that use case.
- The system should respect the configured quiz question limit.
- If the configured limit is not known or does not exist, implementation should verify and define the relevant configuration path.
- Users should be able to start or continue a quiz round until the configured limit is reached.
- The UI should avoid encouraging unlimited quiz generation beyond the configured limit.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Inspect existing quiz configuration for a question limit.
- Identify current quiz launch paths and whether project/use-case scoping already exists.
- Add launch controls to the relevant quiz UI surfaces.
- Enforce or surface the configured limit before starting additional rounds.
- Keep dense precision work in specs rather than treating quizzes as unlimited specification storage.

## Validation
- Launch a quiz round from the main quiz home.
- Launch a quiz round scoped to the current project.
- Launch a quiz round scoped to a use case.
- Verify the system respects the configured question limit.
- Verify the UI does not allow or encourage uncontrolled quiz growth past the limit.

## Outcome
Pending implementation.
