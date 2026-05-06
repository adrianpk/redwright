---
id: TKT-20260506072409
title: Align RedWright ticket model with ops ticket workflow
status: solved
kind: task
severity: medium
priority: high
scope: web
tags: ticket-model, redwright-app, kanban
source: chat
reported_at: 2026-05-06T07:24:09Z
ready_at: 2026-05-06T08:46:02Z
started_at: 2026-05-06T12:25:17Z
reviewed_at: 2026-05-06T12:32:52Z
closed_at: 2026-05-06T12:42:46Z
resolution: fixed
owner:
branch: fix/ticket-20260506072409-ticket-model-alignment
pr: https://codeberg.org/adrianpk/redwright/pulls/323
commits:
  - 12606d3
  - c00fedd
---

## Context
RedWright is intended to implement an ergonomic way of working. The repository-local ticket workflow now defines a shared ticket model with status directories and frontmatter properties under `ops/tickets/`.

The RedWright application ticket model should converge on the same mental model so the Markdown-based workflow and the app-backed workflow do not require separate status/property concepts.

Alignment quiz notes are being captured in `ops/quiz/2026-05-06-redwright-ticket-model-alignment-quiz-raw.md`.

## Problem
RedWright application tickets may currently diverge from the repository-local ticket workflow in status names, lifecycle properties, or classification fields.

That divergence would create two mental models for the same work-management concept.

## Expected
- RedWright's internal ticket schema should be adapted as directly as possible to the `ops/tickets` model.
- Shared status semantics should include `open`, `ready`, `in_progress`, `reviewing`, `blocked`, `solved`, and `closed`.
- Shared ticket properties should include classification and lifecycle fields equivalent to the repo-local model where applicable.
- Required fields for ticket creation should remain minimal, such as title, body/context, and automatically assigned operational state.
- Accessory metadata fields should be optional and should not block agents from creating or advancing tickets.
- Comments must not be used as metadata storage.
- Tags must use the existing transversal `Tag`/`Tagging` system, not a separate string-based ticket tag model.
- RedWright may keep board columns as the operational source for now, but any aligned status field must be synchronized automatically and predictably.
- Kanban column rendering should not be redesigned yet.
- RedWright may know about additional states internally, but the human-facing rendered columns should remain limited to the columns that matter most for the current workflow.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Compare the current RedWright application ticket schema and status flow against `ops/tickets/TEMPLATE.md` and `.agents/playbooks/ticket-workflow.md`.
- Identify the smallest schema/status adaptation needed to align the app ticket model with the repo-local model.
- Treat this ticket as the model/business alignment unit: schema, model behavior, automatic synchronization, and tests.
- Avoid changing Kanban column rendering in this ticket unless strictly required by the model alignment.
- Keep UI-specific rendering and editing improvements in the related web UI ticket unless a minimal view change is required for model integrity.

## Validation
- Add or update tests proving the RedWright ticket model accepts the shared statuses and properties.
- Verify existing Kanban behavior remains stable.
- Confirm no unrelated UI column redesign is introduced.

## Outcome
Implemented and merged in PR #323.
