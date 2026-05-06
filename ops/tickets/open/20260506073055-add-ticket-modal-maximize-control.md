---
id: TKT-20260506073055
title: Add ticket modal maximize control
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: ticket-modal, web, ux
source: chat
reported_at: 2026-05-06T07:30:55Z
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
The RedWright ticket edit modal currently has a close `X` control in the top-right corner.

The current modal size is sometimes useful because it leaves the board visible behind it. At other times, editing would be more comfortable with a larger full-canvas modal.

## Problem
Ticket editing is constrained by a single modal size. Users cannot switch between a board-aware compact modal and a larger editing surface.

## Expected
- The ticket edit modal should include a maximize/minimize control near the existing close control.
- The default/current modal size should remain available.
- Maximized mode should provide a larger full-canvas editing surface.
- Minimized/restored mode should return to the current modal size so the board remains visible behind it.
- The control should support repeated toggling without losing ticket edits.

## Actual
- The modal can be closed but not maximized or restored.

## Fix Strategy
- Identify the current ticket edit modal component and styling.
- Add a maximize/minimize toggle state.
- Add a control near the existing close button.
- Preserve existing modal behavior as the default/restored size.
- Ensure unsaved edits survive toggling.

## Validation
- Open a ticket edit modal.
- Verify the new control maximizes the modal.
- Verify the same control restores the modal to the current size.
- Verify the board remains visible in restored mode.
- Verify ticket edits are preserved while toggling.

## Outcome
Pending implementation.
