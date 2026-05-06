---
id: TKT-20260506214835
title: Standardize visual button style and placement
status: open
kind: task
severity: medium
priority: normal
scope: web
tags: ui-polish,buttons,visual-consistency
source: chat
reported_at: 2026-05-06T21:48:35Z
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
The web UI has accumulated visual inconsistencies across forms and pages. This ticket should improve consistency without becoming a full redesign of the whole site.

## Problem
Button placement and labels are inconsistent. Some form actions appear at the bottom left while others appear at the bottom right. Some buttons use action-plus-object labels such as `Delete Use Case`, while others use short action labels such as `Save`. Buttons also look too small and visually dated, closer to default desktop controls than to the site palette.

## Expected
- Form/page actions must appear consistently at the bottom right when they directly affect the current form or page.
- Button labels prefer short action verbs such as `Save` or `Delete` when the current object is clear from the surrounding context.
- Button sizing, padding, color, border, hover, and destructive styling follow one uniform visual system.
- The button style is harmonious with the current RedWright palette and does not look like default legacy desktop controls.

## Actual
- Primary and destructive actions appear in different locations across screens.
- Button labels mix `Action Noun` and `Action` patterns without a clear rule.
- Button sizing and styling are small and visually inconsistent with the rest of the application.

## Fix Strategy
- Audit the main Rails web forms and modal footers for button placement and label patterns.
- Define a small local button convention in CSS and apply it to existing `.ticket-action` usages where appropriate.
- Keep the scope to visual consistency and button ergonomics; do not redesign complete page layouts.

## Validation
- Run targeted controller/view tests for touched screens.
- Run `bundle exec bin/rails test` from `apps/web`.
- Manually verify representative forms and modals for action alignment, label consistency, sizing, and palette fit.

## Outcome
Pending implementation.
