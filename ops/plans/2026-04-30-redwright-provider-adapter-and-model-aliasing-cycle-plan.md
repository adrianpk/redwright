# Cycle Plan: RedWright Provider Adapter and Model Aliasing

## Metadata

- cycle_id: `rw-2026-04-30-provider-adapter-model-aliasing`
- status: `approved`
- owner: `adrianpk`
- created: `2026-04-30`
- updated: `2026-04-30`
- goal: `decouple runtime agents from provider-specific model references by introducing provider adapters and logical model aliases`
- scope: `feature`

## Slice List

### Slice 1: Model Alias Contract and Resolver

- status: `pending`
- branch: `feat/slice-1-model-alias-contract-and-resolver`
- objective: `introduce logical model ids and central alias resolution from yaml to provider/model targets`
- tasks:
- [ ] `T1.1 extend config contract with models.aliases mapping`
- [ ] `T1.2 implement resolver support for alias -> provider/model target`
- [ ] `T1.3 add trace fields for model alias and resolved target`
- acceptance:
- `roles can reference stable ids such as openai/codex`
- `resolved provider/model is deterministic and visible in trace logs`
- planned_commits:
- `feat(config): add model alias mapping contract and resolver wiring`
- `test(config): cover model alias parsing and resolution behavior`
- PR:
- `tbd`

### Slice 2: Provider Adapter Registry

- status: `pending`
- branch: `feat/slice-2-provider-adapter-registry`
- objective: `replace hardcoded provider switch with a central adapter registry`
- tasks:
- [ ] `T2.1 define llm client registry contract for provider lookup`
- [ ] `T2.2 implement openai-compatible adapter path for openai/openrouter/deepseek/kimi`
- [ ] `T2.3 add provider-specific env/base-url resolution rules`
- acceptance:
- `runtime no longer hardcodes openai in provider dispatch`
- `supported providers resolve through one adapter registry`
- planned_commits:
- `feat(runtime): add provider adapter registry for llm clients`
- `test(runtime): validate provider registry resolution and defaults`
- PR:
- `tbd`

### Slice 3: Runtime Integration Without Behavioral Drift

- status: `pending`
- branch: `feat/slice-3-runtime-integration-with-provider-registry`
- objective: `wire interpreter/runtime creation through registry while preserving existing openai behavior`
- tasks:
- [ ] `T3.1 integrate registry into daemon/runtime llm client creation path`
- [ ] `T3.2 preserve non-configured fallback behavior in interpreter`
- [ ] `T3.3 add integration tests for openai parity after wiring changes`
- acceptance:
- `existing openai-based execution continues to work with no behavior regressions`
- `provider selection is centralized and role-driven`
- planned_commits:
- `refactor(runtime): route llm client creation through provider registry`
- `test(runtime): assert openai parity under registry wiring`
- PR:
- `tbd`

### Slice 4: Config DX and Operational Documentation

- status: `pending`
- branch: `feat/slice-4-provider-alias-config-dx`
- objective: `publish clear config examples and constraints for logical model ids and provider wrappers`
- tasks:
- [ ] `T4.1 update config.example.yml with alias-first model mapping examples`
- [ ] `T4.2 document provider wrapper semantics for openrouter`
- [ ] `T4.3 add validation errors for malformed aliases/provider entries`
- acceptance:
- `users can map one logical id to concrete provider/model in one place`
- `config errors are explicit and actionable`
- planned_commits:
- `docs(config): add alias-first provider model mapping examples`
- `test(config): validate malformed alias contract errors`
- PR:
- `tbd`

### Slice 5: Observability and Failure Surfaces

- status: `pending`
- branch: `feat/slice-5-provider-observability-and-guardrails`
- objective: `improve diagnosability and guardrails for multi-provider runtime calls`
- tasks:
- [ ] `T5.1 include provider/model alias metadata in llm request tracing`
- [ ] `T5.2 add explicit errors for missing provider api keys`
- [ ] `T5.3 add tests for provider misconfiguration and fallback behavior`
- acceptance:
- `failed provider setup surfaces clear error context`
- `trace envelopes expose logical id and resolved provider/model`
- planned_commits:
- `feat(observability): enrich llm trace metadata with provider alias context`
- `test(runtime): cover provider configuration failure paths`
- PR:
- `tbd`

## Global Exit Criteria

- `agents can reference logical model ids instead of concrete version strings`
- `provider/model resolution is centralized in yaml and resolver logic`
- `runtime supports openai/openrouter/deepseek/kimi through adapter registry`
- `openai behavior remains backward-compatible`
