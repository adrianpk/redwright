# Configure Model Providers and Aliases

Use `models.aliases` in `config.yml` to decouple logical model ids from concrete model versions.

Example:

```yaml
models:
  aliases:
    "openai/codex":
      provider: "openai"
      name: "gpt-5.2"
    "openrouter/coder":
      provider: "openrouter"
      name: "anthropic/claude-3.7-sonnet"

  coding:
    - provider: "openai"
      name: "openai/codex"
```

Operational rule:

- runtime/agents reference logical ids (`openai/codex`, `openrouter/coder`)
- concrete versions are changed only in `models.aliases`

OpenRouter wrapper semantics:

- `provider: "openrouter"` is treated as an OpenAI-compatible wrapper endpoint
- RedWright sends requests to `OPENROUTER_BASE_URL` (or default `https://openrouter.ai/api/v1`)
- OpenRouter then resolves the final upstream model behavior according to user setup

Provider environment variables:

- `OPENAI_API_KEY`
- `OPENROUTER_API_KEY`
- `DEEPSEEK_API_KEY`
- `KIMI_API_KEY`
- optional `*_BASE_URL` overrides for each provider
