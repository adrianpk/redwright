# Cycle Tracker: RedWright Operational Command Model

## Metadata

- owner: `adrianpk`
- status: `in_progress`
- active_slice: `slice-2`
- plan: `ops/plans/2026-04-29-redwright-operational-command-model-cycle-plan.md`

## Slice Progress

### Slice 1: Micro-loop Nil Outcome Crash Fix

- status: `completed`
- branch: `fix/slice-1-micro-loop-nil-outcome-crash`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 2: Operational Intent Taxonomy V1

- status: `completed`
- branch: `feat/slice-2-operational-intent-taxonomy-v1`
- PR: `tbd`
- commits: `pending`
- validation: `planner payload schema + validator tests`

### Slice 3: Slash Command Set Expansion

- status: `pending`
- branch: `feat/slice-3-slash-command-set-expansion`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 4: Natural-Language Parity Router

- status: `pending`
- branch: `feat/slice-4-natural-language-parity-router`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb && bundle exec ruby -Itest test/redwright/cross_channel_parity_matrix_test.rb`

### Slice 5: Project and Repo Lifecycle Integration

- status: `pending`
- branch: `feat/slice-5-project-repo-lifecycle-integration`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/telegram_context_resolver_test.rb && bundle exec ruby -Itest test/redwright/server_runtime_dispatcher_test.rb`

### Slice 6: Undo Semantics V1

- status: `pending`
- branch: `feat/slice-6-undo-semantics-v1`
- PR: `tbd`
- commits: `pending`
- validation: `undo contract tests`

### Slice 7: Skill Loop Control Commands

- status: `pending`
- branch: `feat/slice-7-skill-loop-control-commands`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/skill_subloop_executor_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 8: Cross-Channel Operational Parity Matrix

- status: `pending`
- branch: `feat/slice-8-cross-channel-operational-parity-matrix`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/cross_channel_parity_matrix_test.rb && bundle exec ruby -Itest test/redwright/simulated_ingress_matrix_test.rb`

## Event Log

- `2026-04-29 14:10` state=`planned` note=`cycle created to stabilize operational command semantics across slash and natural-language routing`
- `2026-04-29 15:43` state=`implementation` slice=`slice-1` note=`fixed micro-loop nil-outcome crash path and added regression coverage for recoverable-error refine->clarify early-exit`
- `2026-04-29 15:44` validation=`bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`
- `2026-04-29 15:53` state=`implementation` slice=`slice-2` note=`defined operational intent taxonomy fields in planner contract/schema, added backward-compatible validator defaults, and enforced separation rules between control and operational intents`
- `2026-04-29 15:53` validation=`bundle exec ruby -Itest test/redwright/planner_payload_validator_test.rb && bundle exec ruby -Itest test/redwright/llm_intent_interpreter_test.rb`
