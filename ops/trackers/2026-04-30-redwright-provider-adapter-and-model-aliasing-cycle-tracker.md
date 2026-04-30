# Cycle Tracker: RedWright Provider Adapter and Model Aliasing

## Metadata

- cycle_id: `rw-2026-04-30-provider-adapter-model-aliasing`
- status: `in_progress`
- state: `planning`
- updated: `2026-04-30`
- active_slice: `slice-1`
- active_task: `T1.1`

## Slice Progress

### Slice 1: Model Alias Contract and Resolver

- status: `pending`
- branch: `feat/slice-1-model-alias-contract-and-resolver`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 extend config contract with models.aliases mapping`
- [ ] `T1.2 implement resolver support for alias -> provider/model target`
- [ ] `T1.3 add trace fields for model alias and resolved target`

Commits:

- [ ] `<sha> feat(config): add model alias mapping contract and resolver wiring`
- [ ] `<sha> test(config): cover model alias parsing and resolution behavior`

Validation:

- [ ] `<cmd> ruby -Ilib:test test/redwright/app_config_test.rb`
- [ ] `<cmd> ruby -Ilib:test test/redwright/model_resolver_test.rb`

### Slice 2: Provider Adapter Registry

- status: `pending`
- branch: `feat/slice-2-provider-adapter-registry`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 define llm client registry contract for provider lookup`
- [ ] `T2.2 implement openai-compatible adapter path for openai/openrouter/deepseek/kimi`
- [ ] `T2.3 add provider-specific env/base-url resolution rules`

Commits:

- [ ] `<sha> feat(runtime): add provider adapter registry for llm clients`
- [ ] `<sha> test(runtime): validate provider registry resolution and defaults`

Validation:

- [ ] `<cmd> ruby -Ilib:test test/redwright/llm_client_registry_test.rb`

### Slice 3: Runtime Integration Without Behavioral Drift

- status: `pending`
- branch: `feat/slice-3-runtime-integration-with-provider-registry`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 integrate registry into daemon/runtime llm client creation path`
- [ ] `T3.2 preserve non-configured fallback behavior in interpreter`
- [ ] `T3.3 add integration tests for openai parity after wiring changes`

Commits:

- [ ] `<sha> refactor(runtime): route llm client creation through provider registry`
- [ ] `<sha> test(runtime): assert openai parity under registry wiring`

Validation:

- [ ] `<cmd> ruby -Ilib:test test/redwright/daemon_cli_test.rb`
- [ ] `<cmd> ruby -Ilib:test test/redwright/telegram_runtime_handler_test.rb`

### Slice 4: Config DX and Operational Documentation

- status: `pending`
- branch: `feat/slice-4-provider-alias-config-dx`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 update config.example.yml with alias-first model mapping examples`
- [ ] `T4.2 document provider wrapper semantics for openrouter`
- [ ] `T4.3 add validation errors for malformed aliases/provider entries`

Commits:

- [ ] `<sha> docs(config): add alias-first provider model mapping examples`
- [ ] `<sha> test(config): validate malformed alias contract errors`

Validation:

- [ ] `<cmd> ruby -Ilib:test test/redwright/app_config_test.rb`

### Slice 5: Observability and Failure Surfaces

- status: `pending`
- branch: `feat/slice-5-provider-observability-and-guardrails`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 include provider/model alias metadata in llm request tracing`
- [ ] `T5.2 add explicit errors for missing provider api keys`
- [ ] `T5.3 add tests for provider misconfiguration and fallback behavior`

Commits:

- [ ] `<sha> feat(observability): enrich llm trace metadata with provider alias context`
- [ ] `<sha> test(runtime): cover provider configuration failure paths`

Validation:

- [ ] `<cmd> ruby -Ilib:test test/redwright/trace_test.rb`
- [ ] `<cmd> ruby -Ilib:test test/redwright/openai_client_test.rb`

## Event Log

- `2026-04-30 20:00` state=`planning` note=`initialized provider adapter and model aliasing cycle with pr-per-slice and commit-per-task execution policy`
