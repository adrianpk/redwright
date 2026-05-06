---
id: TKT-20260506120227
title: Expose aligned ticket model in web UI
status: ready
kind: task
severity: medium
priority: high
scope: web
tags: ticket-model, redwright-app, web-ui
source: chat
reported_at: 2026-05-06T12:02:27Z
ready_at: 2026-05-06T12:02:27Z
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
The RedWright application ticket model is being aligned with the repository-local `ops/tickets` workflow so the Markdown workflow and app-backed workflow share one mental model.

The alignment quiz clarified that the UI is vital, but the model/business alignment and the web UI work may be delivered as separate focused tickets.

Related model ticket: `TKT-20260506072409`.

Alignment quiz notes: `ops/quiz/2026-05-06-redwright-ticket-model-alignment-quiz-raw.md`.

## Problem
If the aligned ticket fields exist only in the database/model layer, the human-facing RedWright UI may still feel like a different ticket system.

That would preserve the same two-map problem the model alignment is intended to reduce.

## Expected
- The ticket web UI should expose the aligned ticket model in a practical, low-friction way.
- The UI should not add more board columns to the regular board view.
- Optional metadata should not make ticket creation or editing heavy.
- Structured metadata should be visible or editable where useful, without turning comments into metadata.
- Ticket tags should use the existing transversal `Tag`/`Tagging` system.
- Status or lifecycle information should feel automatic and predictable rather than requiring users or agents to manually reconcile duplicate state.

## Actual
- To be verified after the model/business alignment ticket is implemented.

## Fix Strategy
- Build on the model fields and synchronization introduced by `TKT-20260506072409`.
- Decide which aligned fields need direct UI controls and which should be read-only lifecycle information.
- Preserve the current primary board column shape unless later user testing proves additional visibility is needed.
- Avoid adding convoluted show/hide column behavior in the first UI pass.

## Validation
- Verify ticket creation remains lightweight.
- Verify ticket editing can view or update relevant aligned metadata without using comments as metadata.
- Verify tags are persisted through `Tag`/`Tagging`.
- Verify the regular board view does not gain extra default columns.

## Outcome
Pending implementation.
