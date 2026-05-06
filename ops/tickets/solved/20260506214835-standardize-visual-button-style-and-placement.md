---
id: TKT-20260506214835
title: Standardize visual button style and placement
status: solved
kind: task
severity: medium
priority: normal
scope: web
tags: ui-polish,buttons,visual-consistency
source: chat
reported_at: 2026-05-06T21:48:35Z
ready_at:
started_at: 2026-05-06T21:55:09Z
reviewed_at: 2026-05-06T21:57:05Z
closed_at: 2026-05-06T22:16:50Z
resolution: fixed
owner: 
branch: fix/ticket-20260506214835-button-consistency
pr: https://codeberg.org/adrianpk/redwright/pulls/337
commits:
  - 824f57b
  - 97aeba4
  - c540b94
  - e1ce9a2
  - b228468
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
- 2026-05-07: `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb test/controllers/use_cases_controller_test.rb` from `apps/web` passed with 23 runs, 188 assertions, 0 failures.
- 2026-05-07: `bundle exec bin/rails test` from `apps/web` passed with 389 runs, 2519 assertions, 0 failures.

## Outcome
Implementation was merged in PR #337. Button styling now uses larger shared `.ticket-action` sizing, right-aligned form action rows, harmonized destructive styling, shorter labels where the surrounding context is clear, consistent auth/password form button styling, normalized Use Case Save/Delete button width, and a connected New Quiz use case dropdown action.
