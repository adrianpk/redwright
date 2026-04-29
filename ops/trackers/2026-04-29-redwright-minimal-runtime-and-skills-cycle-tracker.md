# Cycle Tracker: RedWright Minimal Runtime and Skills

## Metadata

- owner: `adrianpk`
- status: `draft`
- active_slice: `none`
- plan: `ops/plans/2026-04-29-redwright-minimal-runtime-and-skills-cycle-plan.md`
- spec: `ops/specs/specs/2026-04-29-redwright-minimal-runtime-and-skills-spec.md`

## Slice Progress

### Slice 1: Turn Loop V1 Contract Hardening

- status: `completed`
- branch: `feat/slice-1-turn-loop-v1-contract`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/runtime_state_contract_test.rb && bundle exec ruby -Itest test/redwright/runtime_flow_test.rb`

### Slice 2: Context Packet Builder V1

- status: `completed`
- branch: `feat/slice-2-context-packet-builder-v1`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/iteration_context_packet_builder_test.rb`

### Slice 3: Planner Output Schema V4

- status: `completed`
- branch: `feat/slice-3-planner-output-schema-v4`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/planner_payload_validator_test.rb && bundle exec ruby -Itest test/redwright/llm_intent_interpreter_test.rb`

### Slice 4: Control Plane Slash Router

- status: `completed`
- branch: `feat/slice-4-control-plane-slash-router`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 5: Hint Normalizer and Merge Policy

- status: `completed`
- branch: `feat/slice-5-hint-normalizer-merge-policy`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/hint_normalizer_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 6: Skill Router V1 (Explicit + Inferred)

- status: `completed`
- branch: `feat/slice-6-skill-router-v1`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/skill_router_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 7: Skill Sub-loop Runtime

- status: `completed`
- branch: `feat/slice-7-skill-subloop-runtime`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/skill_subloop_executor_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 8: Clarification Session V2

- status: `completed`
- branch: `feat/slice-8-clarification-session-v2`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/clarification_session_store_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 9: Feedback Loop Integrator (Compile/Test/Lint)

- status: `completed`
- branch: `feat/slice-9-feedback-loop-integrator`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/feedback_normalizer_test.rb && bundle exec ruby -Itest test/redwright/execution_feedback_store_test.rb && bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 10: Bounded Convergence Policy V1

- status: `completed`
- branch: `feat/slice-10-bounded-convergence-policy-v1`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 11: Bootstrap Skills (Repo + Docs)

- status: `completed`
- branch: `feat/slice-11-bootstrap-skills-repo-docs`
- PR: `tbd`
- commits: `pending-push`
- validation: `bundle exec ruby -Itest test/redwright/skill_loader_test.rb && bundle exec ruby -Itest test/redwright/template_source_resolver_test.rb && bundle exec ruby -Itest test/redwright/skill_contract_validator_test.rb`

### Slice 12: Channel Parity and Simulated E2E Matrix

- status: `pending`
- branch: `feat/slice-12-channel-parity-e2e-matrix`
- PR: `tbd`
- commits: `tbd`
- validation: `tbd`

### Slice 13: Session-Project Continuity Policy

- status: `pending`
- branch: `feat/slice-13-session-project-continuity-policy`
- PR: `tbd`
- commits: `tbd`
- validation: `tbd`

## Event Log

- `2026-04-29 00:00` state=`planned` note=`initialized full-cycle planning for minimal runtime evolution with bounded loops, skills activation, and channel parity`
- `2026-04-29 00:00` state=`implementation` slice=`slice-5` note=`added hint normalizer for @hints, merged hint context deterministically into planner input, and enforced slash-over-hint precedence with handler-level tests`
- `2026-04-29 00:00` state=`implementation` slice=`slice-4` note=`added deterministic slash control-plane parsing with precedence before interpretation, mapped slash control commands directly to runtime control flow, and added tests for slash routing and planner-hint rewrites`
- `2026-04-29 00:00` state=`implementation` slice=`slice-3` note=`extended planner payload schema with optional skill contract fields, preserved backward compatibility defaults, and validated strict parser behavior for allowed/invalid skill payload shapes`
- `2026-04-29 00:00` state=`implementation` slice=`slice-2` note=`extended context packet contract with active clarification, normalized failures, last execution results, and patch summary, then validated deterministic bounded truncation behavior`
- `2026-04-29 00:00` state=`implementation` slice=`slice-1` note=`extended RuntimeStateContract with explicit turn phases/transitions and stable transition ids, then traced runtime state transitions and validated guard clauses with contract/flow tests`
