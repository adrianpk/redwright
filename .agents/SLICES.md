# Slice-Based Development Strategy

This document defines delivery strategy for non-trivial work.

## 1. Definitions

- Task: high-level requested work unit
- Slice: smallest meaningful, testable behavior increment
- Commit: atomic versioning unit

## 2. Decomposition rules

Use a single slice only when scope and integration risk are low.
Otherwise decompose into multiple behavior-first vertical slices.

## 3. Slice rules

Each slice must:
- deliver a functional increment
- be testable in isolation
- integrate without breaking existing behavior

## 4. Commit strategy

- Keep commits cohesive and scoped.
- Do not mix unrelated slice concerns in one commit.
- Keep commit subjects aligned with slice task intent.

## 5. Integration

- Integrate slices in safe order.
- Keep repository passing checks after each integrated slice.

## 6. Traceable execution

For approved multi-slice work:
1. Create a dedicated branch: `fix/slice-<n>-<slug>`.
2. Implement only that slice's tasks.
3. Keep a commit list that can be mapped to tracker tasks.
4. Open one PR scoped to that slice.
5. Update `ops/trackers/*` with tasks, commits, and validation outcomes.

## 7. Execution gate

For non-trivial work:
- approve slice plan first
- execute only approved slices
- capture extra ideas as backlog candidates
