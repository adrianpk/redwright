# Cycle Tracker: RedWright LLM Rolling Trace File

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-llm-rolling-trace-file`
- status: `planned`
- state: `planned`
- updated: `2026-05-04`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-03-redwright-llm-rolling-trace-file-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-llm-rolling-trace-file-spec.md`
- source_draft: `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`

## Slice Progress

### Slice 1: Rolling Trace File Foundation

- status: `pending`
- branch: `fix/slice-1-llm-rolling-trace-file`
- PR: `not_opened`
- merge_target: `dev`
- last_sync_commit: `none`

Tasks:

- [ ] `T1.1 add tracing.llm_file configuration parsing and defaults`
- [ ] `T1.2 implement a small rolling NDJSON writer for LLM trace events`
- [ ] `T1.3 thread stable llm_call_id correlation through request and response trace calls`
- [ ] `T1.4 extend trace call payloads to carry project, ticket, session, actor, source, and context-size metadata when available`
- [ ] `T1.5 apply bounded payload inclusion and basic redaction before persistence`
- [ ] `T1.6 add tests for disabled behavior, enabled writes, correlation, rotation, redaction, and non-fatal writer failures`

Commits:

- [ ] `feat(runtime): add llm rolling trace file config`
- [ ] `feat(runtime): write llm rolling trace events`
- [ ] `test(runtime): cover llm rolling trace file`

Validation:

- [ ] `ruby -Itest test/redwright/app_config_test.rb test/redwright/trace_test.rb` (pending)
- [ ] `ruby -Itest test/redwright/project_setup_prompt_renderer_test.rb test/redwright/telegram_runtime_handler_test.rb` (pending)
- [ ] `bundle exec bin/rails test test/integration/project_setup_telegram_e2e_test.rb` (pending)

## Coverage Guard

- baseline_coverage: `not_run`
- target_rule: `new trace-file behavior must be covered by targeted tests`
- final_coverage: `pending`
- tuning_needed: `pending`
- tuning_evidence: `pending`

## Event Log

- `2026-05-04` state=`planned` note=`promoted the LLM rolling trace file draft into a one-slice spec, plan, and tracker focused on config-driven NDJSON persistence, correlation, rotation, redaction, and non-fatal writer behavior`
