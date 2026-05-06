---
id: TKT-20260506073634
title: Preserve ticket modal rounded corners with scroll
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: ticket-modal, web, ux
source: chat
reported_at: 2026-05-06T07:36:34Z
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
The ticket modal can contain enough content to require scrolling when it is not maximized.

A scroll metaphor is acceptable when content exceeds the available modal height.

## Problem
The modal's current scrollbar visually breaks the rounded corners of the modal.

This makes the modal feel visually rough even if the scrolling behavior itself is acceptable.

## Expected
- The ticket modal may remain scrollable when content requires it.
- Scroll behavior should not visually break the modal's rounded corners.
- The modal should preserve a polished rounded-corner boundary in normal and overflow states.
- Any scrollbar styling or overflow containment should fit the existing web UI style.

## Actual
- The visible scrollbar cuts through or disrupts the modal's rounded corners.

## Fix Strategy
- Inspect the ticket modal container and inner scroll regions.
- Move scrolling to an inner content area if needed.
- Ensure the outer modal shell keeps `overflow: hidden` or equivalent rounded-corner containment.
- Adjust scrollbar styling only as much as needed to preserve the modal shape.

## Validation
- Open a ticket modal with enough content to scroll.
- Verify the content can still scroll.
- Verify the modal's rounded corners remain visually intact.
- Verify the fix works in the current modal size and does not regress close/edit controls.

## Outcome
Pending implementation.
