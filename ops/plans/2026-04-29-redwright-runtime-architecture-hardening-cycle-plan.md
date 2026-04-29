# Cycle Plan: RedWright Runtime Architecture Hardening

## Metadata

- owner: `adrianpk`
- status: `planned`
- scope: `runtime`
- objective: `reduce architectural concentration in telegram handler and CLI wiring, tighten operational structure, and preserve runtime behavior through intensive regression testing`
- tracker: `ops/trackers/2026-04-29-redwright-runtime-architecture-hardening-cycle-tracker.md`

## Slice List

### Slice 1: Freeze Runtime Behavior with Coverage Expansion

- status: `completed`
- branch: `feat/slice-1-runtime-hardening-test-baseline`
- [ ] `T1.1 add characterization tests for /project new missing-name guardrail and no-side-effects`
- [ ] `T1.2 add characterization tests for action summary format and counters across success/failure mixes`
- [ ] `T1.3 extend cross-channel parity tests for control commands and clarify boundaries`
- [ ] `T1.4 add runtime error-path tests for recoverable/non-recoverable classification`

### Slice 2: Extract Telegram Runtime Message Rendering and Summary Logic

- status: `completed`
- branch: `feat/slice-2-telegram-message-renderer-extraction`
- [ ] `T2.1 extract human message rendering from telegram handler into dedicated component`
- [ ] `T2.2 extract execution summary formatting into dedicated formatter with deterministic counters`
- [ ] `T2.3 keep json envelope semantics unchanged`
- [ ] `T2.4 add focused unit tests for renderer/formatter edge cases`

### Slice 3: Extract Telegram Runtime Control and Clarification Routing

- status: `completed`
- branch: `feat/slice-3-telegram-control-routing-extraction`
- [ ] `T3.1 extract slash/control parsing and intent-to-control mapping from telegram handler`
- [ ] `T3.2 extract clarification cancellation policy and scope resolution`
- [ ] `T3.3 preserve stop/pause/resume behavior and control terminal reasons`
- [ ] `T3.4 add integration tests covering direct control, inferred control, and no-active-confirmation paths`

### Slice 4: Decompose CLI Command Wiring from lib/redwright.rb

- status: `completed`
- branch: `feat/slice-4-cli-command-decomposition`
- [ ] `T4.1 split CLI subcommand handlers into dedicated command classes/modules`
- [ ] `T4.2 keep command interface and exit codes backward compatible`
- [ ] `T4.3 keep daemon/server bootstrap wiring behavior unchanged`
- [ ] `T4.4 add command-level tests for usage/error paths and representative happy paths`

### Slice 5: Ops and Repo Hygiene Consolidation

- status: `completed`
- branch: `fix/slice-5-ops-structure-hygiene`
- [x] `T5.1 normalize docs/spec references and remove stale reference mismatches`
- [x] `T5.2 decide and apply one canonical policy for handoff artifacts (tracked vs ignored)`
- [x] `T5.3 review and clean obvious non-runtime operational clutter while preserving auditability`
- [x] `T5.4 run full regression suite and parity/invariant gates before closure`
- [x] `T5.5 reduce slash-command fragility: route canonical operational slashes through deterministic runtime path and normalize planner control/operational taxonomy conflicts`

### Slice 6: Deterministic Read-Only Operational Slash Routing

- status: `completed`
- branch: `fix/slice-6-deterministic-readonly-operational-routing`
- [x] `T6.1 route /project list|where and /repo status as operational slash kinds`
- [x] `T6.2 execute read-only operational slash commands via server dispatcher without planner/flow execution`
- [x] `T6.3 add regression tests for router classification and dispatcher read-only command behavior`

### Slice 7: Runtime Control Taxonomy Closure

- status: `completed`
- branch: `fix/slice-7-runtime-control-taxonomy-closure`
- [x] `T7.1 close remaining control vs operational taxonomy ambiguity paths in interpreter handoff`
- [x] `T7.2 add parity tests for direct slash and inferred control precedence with deterministic outcomes`
- [x] `T7.3 update runtime docs/contracts for final control routing invariants`

## Validation Matrix

- `bundle exec rake test`
- `bundle exec rake test:invariants`
- `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`
- `bundle exec ruby -Itest test/redwright/server_runtime_dispatcher_test.rb`
- `bundle exec ruby -Itest test/redwright/cross_channel_parity_matrix_test.rb`
- `bundle exec ruby -Itest test/redwright/server_client_recovery_parity_test.rb`
- `bundle exec ruby -Itest test/redwright/runtime_flow_test.rb`

## Exit Criteria

- Telegram runtime handler reduced in responsibility with extracted collaborators.
- CLI wiring decomposed while preserving command behavior and exit contracts.
- No regression in runtime behavior across telegram/tui/server parity paths.
- Hotfix-targeted behavior is validated by deterministic regression tests.
- Ops/docs/repo structure is consistent with one explicit artifact policy.
