---
id: TKT-20260506081044
title: Add use case management UI
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: use-cases, web, crud
source: chat
reported_at: 2026-05-06T08:10:44Z
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
Quizzes currently handles the concept of use cases, but use cases should not be created or administered from the Quizzes surface itself.

RedWright needs a UI surface to manage use cases consistently with the rest of the site.

This likely requires a short quiz alignment session before implementation. It should not need more than a few questions unless hidden model complexity appears.

## Problem
Use cases exist as a meaningful namespace for questions and project context, but there is no dedicated CRUD UI for managing them.

Without a clear management surface, Quizzes may become overloaded with use-case administration concerns.

## Expected
- Add a CRUD UI for managing use cases.
- The UI should be consistent with the rest of the RedWright web site.
- Use cases should function primarily as namespaces for organizing related questions/context.
- Quizzes should consume/use use cases, not own their creation and administration.
- The implementation should remain simple unless specific fields prove useful.

## Actual
- Use cases are represented through Quizzes behavior, but no dedicated use-case administration surface is available.

## Fix Strategy
- Run a short quiz alignment session to confirm the minimal use-case management model and UI.
- Draft or specify the result only if the quiz reveals enough complexity to justify it.
- Identify existing use-case data shape and relationships.
- Add standard CRUD screens/actions for use cases.
- Keep the first UI close to the site's existing CRUD patterns.
- Avoid adding extra fields unless they clearly support current workflows.

## Validation
- Create, view, update, and delete or archive a use case through the web UI.
- Verify Quizzes can use existing use cases without owning their administration.
- Verify the UI follows existing RedWright CRUD patterns.

## Outcome
Pending design and implementation.
