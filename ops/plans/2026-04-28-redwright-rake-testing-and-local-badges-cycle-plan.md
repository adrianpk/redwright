# Cycle Plan: Redwright Rake Testing and Local Badges

## Metadata

- cycle_id: `runtime-cycle-2026-04-28-redwright-rake-testing-and-local-badges`
- status: `draft`
- owner: `adrianpk`
- created: `2026-04-28`
- updated: `2026-04-28`
- goal: `implement deterministic local quality rake tasks and README badges from local artifacts`
- scope: `feature`

## Slice List

### Slice 1: Local Quality Tasks and Badge Rendering

- status: `pending`
- branch: `feat/slice-1-rake-quality-and-local-badges`
- objective: `deliver end-to-end local workflow for quality execution, artifact generation, and README badge refresh`
- tasks:
- [ ] `T1.1 add quality rake tasks (lint/test/all) with strict exit semantics`
- [ ] `T1.2 add artifact writer for tmp/quality status JSON outputs`
- [ ] `T1.3 add badge renderer that updates dedicated README section from local artifacts`
- [ ] `T1.4 add badges:build and badges:refresh orchestration tasks`
- [ ] `T1.5 add tests for artifact schema, status mapping, and README deterministic updates`
- acceptance:
- `local quality commands execute deterministically`
- `badges refresh from local artifacts only`
- `no network dependency for badge generation`
- planned_commits:
- `feat(quality): add deterministic local rake quality tasks and artifact outputs`
- `feat(badges): render readme badges from local quality artifacts`
- `test(quality): validate quality artifact schema and badge regeneration invariants`
- PR:
- `tbd (to be opened from feat/slice-1-rake-quality-and-local-badges)`

## Global Exit Criteria

- required `rake` task surface exists and passes behavior checks
- local artifact contract is implemented under `tmp/quality`
- README badge section is generated from local artifacts
- rerun behavior is deterministic and repository-scoped
