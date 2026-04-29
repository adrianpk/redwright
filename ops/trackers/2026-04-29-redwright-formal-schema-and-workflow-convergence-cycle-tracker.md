# Cycle Tracker: RedWright Formal Schema and Workflow Convergence

## Metadata

- owner: `adrianpk`
- status: `draft`
- active_slice: `none`
- plan: `ops/plans/2026-04-29-redwright-formal-schema-and-workflow-convergence-cycle-plan.md`
- spec: `ops/specs/specs/2026-04-29-redwright-minimal-runtime-and-skills-spec.md`

## Slice Progress

### Slice 1: Planner JSON Schema V1 (Closed Contract)

- status: `pending`
- branch: `feat/slice-1-planner-json-schema-v1`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/planner_payload_validator_test.rb && bundle exec ruby -Itest test/redwright/llm_intent_interpreter_test.rb`

### Slice 2: Clarification-First Routing Determinism

- status: `pending`
- branch: `feat/slice-2-clarification-first-routing`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/clarification_session_store_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 3: Control Intent and Clarification Boundary

- status: `pending`
- branch: `feat/slice-3-control-clarification-boundary`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 4: Workflow Convergence and Retry Policy for Action Macros

- status: `pending`
- branch: `feat/slice-4-workflow-convergence-macro-retry`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/action_normalizer_test.rb && bundle exec ruby -Itest test/redwright/runtime_flow_test.rb`

### Slice 5: Telegram Runtime E2E Contract and Observability

- status: `pending`
- branch: `feat/slice-5-telegram-runtime-e2e-contract`
- PR: `tbd`
- commits: `pending`
- validation: `bundle exec ruby -Itest test/redwright/simulated_ingress_matrix_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

## Event Log

- `2026-04-29 12:00` state=`planned` note=`created five-slice convergence cycle for strict schema enforcement and clarification/control workflow determinism`
