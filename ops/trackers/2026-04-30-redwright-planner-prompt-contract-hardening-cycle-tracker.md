# Cycle Tracker: RedWright Planner Prompt Contract Hardening

## Metadata

- cycle_id: `rw-2026-04-30-planner-prompt-contract-hardening`
- status: `in_progress`
- state: `planning`
- updated: `2026-04-30`
- active_slice: `slice-1`
- active_task: `T1.1`

## Slice Progress

### Slice 1: Planner Prompt Contract Hardening

- status: `pending`
- branch: `fix/slice-1-planner-prompt-contract-hardening`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 update planner contract prompt with one canonical full JSON example including all required keys`
- [ ] `T1.2 add explicit field-level semantics and decision rules for intent/control/operational/gaps behavior`
- [ ] `T1.3 add strict output constraints block (no extra keys, no markdown fences, no prose)`
- [ ] `T1.4 extend prompt builder and interpreter tests to lock contract presence and ambiguity handling regressions`

Commits:

- [ ] `<sha> fix(planner): harden output contract with canonical json and field semantics`
- [ ] `<sha> test(planner): lock prompt contract and ambiguity regression coverage`

Validation:

- [ ] `bundle exec ruby -Itest test/redwright/planner_contract_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/planner_prompt_builder_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/planner_payload_validator_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/llm_intent_interpreter_test.rb`

## Event Log

- `2026-04-30 00:00` state=`planning` note=`initialized single-slice cycle for planner prompt contract hardening with one-PR delivery rule`
