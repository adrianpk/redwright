---
id: TKT-20260506072409
title: Align RedWright ticket model with ops ticket workflow
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: ticket-model, redwright-app, kanban
source: chat
reported_at: 2026-05-06T07:24:09Z
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
RedWright is intended to implement an ergonomic way of working. The repository-local ticket workflow now defines a shared ticket model with status directories and frontmatter properties under `ops/tickets/`.

The RedWright application ticket model should converge on the same mental model so the Markdown-based workflow and the app-backed workflow do not require separate status/property concepts.

## Problem
RedWright application tickets may currently diverge from the repository-local ticket workflow in status names, lifecycle properties, or classification fields.

That divergence would create two mental models for the same work-management concept.

## Expected
- RedWright's internal ticket schema should be adapted as directly as possible to the `ops/tickets` model.
- Shared status semantics should include `open`, `ready`, `in_progress`, `reviewing`, `blocked`, `solved`, and `closed`.
- Shared ticket properties should include classification and lifecycle fields equivalent to the repo-local model where applicable.
- Kanban column rendering should not be redesigned yet.
- RedWright may know about additional states internally, but the human-facing rendered columns should remain limited to the columns that matter most for the current workflow.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Compare the current RedWright application ticket schema and status flow against `ops/tickets/TEMPLATE.md` and `.agents/playbooks/ticket-workflow.md`.
- Identify the smallest schema/status adaptation needed to align the app ticket model with the repo-local model.
- Avoid changing Kanban column rendering in this ticket unless strictly required by the model alignment.

## Validation
- Add or update tests proving the RedWright ticket model accepts the shared statuses and properties.
- Verify existing Kanban behavior remains stable.
- Confirm no unrelated UI column redesign is introduced.

## Outcome
Pending implementation.
