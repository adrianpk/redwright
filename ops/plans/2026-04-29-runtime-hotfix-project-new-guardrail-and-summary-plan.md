# Slice Plan: Runtime Hotfix for `/project new` Guardrail and Action Summary

## Metadata

- owner: `adrianpk`
- status: `completed`
- scope: `runtime`
- objective: `prevent project creation when /project new is missing a name and fix invalid action summary counters in human responses`
- tracker: `ops/trackers/2026-04-29-runtime-hotfix-project-new-guardrail-and-summary-tracker.md`

## Slice

### Slice 1: Guardrail + Summary Formatting

- status: `completed`
- branch: `fix/slice-1-project-new-guardrail-and-summary`
- [x] `T1.1 enforce /project new argument contract (missing name -> clarify)`
- [x] `T1.2 block side effects when project name is missing (no dir, no sqlite project, no context mutation)`
- [x] `T1.3 normalize human execution summary counters (always integer succeeded/failed)`
- [x] `T1.4 add regression tests for missing-name clarify and summary formatting`

## Validation

- `/project new` returns clarify and creates no project
- `/project new <name>` still creates and registers correctly
- human summary shows valid integer action counts
- test suite sections for parser/dispatcher/summary rendering pass

## Commit Contract

- single implementation branch
- single PR
- no merge unless all validations pass
