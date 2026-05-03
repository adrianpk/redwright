# Configure RedWright

## Purpose

Configure RedWright so the runtime can load providers, models, Telegram settings, paths, and optional local LLM trace output.

## Before You Start

- Run commands from the repository root.
- Use `dev` mode for local development unless you intentionally want home-directory state.
- Keep provider credentials in environment variables where possible.

## Steps

1. Bootstrap local runtime paths if they do not exist.

```bash
bundle exec rake bootstrap
```

2. Edit the active configuration file.

Dev mode:

```text
_workspace/config/redwright/config.yml
```

Real mode:

```text
~/.config/redwright/config.yml
```

3. Configure runtime behavior.

```yaml
runtime:
  loop_interval_ms: 1000
  blocked_retry_attempts: 2
  queue_drain_mode: "all"
```

4. Configure Telegram when using the Telegram adapter.

```yaml
telegram:
  bot_token: "${TELEGRAM_BOT_TOKEN}"
  poll_interval_seconds: 1
  allowed_chat_ids: []
  send_json_envelope: false
```

5. Configure project paths.

```yaml
paths:
  default_projects_root: "~/redwright"
```

In dev mode, RedWright uses `_workspace/Projects` even when this value is present.

6. Configure model aliases and role candidates.

```yaml
models:
  aliases:
    llm/default:
      provider: openrouter
      name: openrouter/auto
  coding:
    - name: llm/default
  non_coding:
    - name: llm/default
```

7. Configure provider credentials.

Set one or more provider API keys in the process environment:

```bash
export OPENAI_API_KEY="..."
export OPENROUTER_API_KEY="..."
export DEEPSEEK_API_KEY="..."
export KIMI_API_KEY="..."
```

RedWright currently supports these provider keys:

| Provider | `provider` value | API key env var | Default base URL |
| --- | --- | --- | --- |
| OpenAI | `openai` | `OPENAI_API_KEY` | `https://api.openai.com/v1` |
| OpenRouter | `openrouter` | `OPENROUTER_API_KEY` | `https://openrouter.ai/api/v1` |
| DeepSeek | `deepseek` | `DEEPSEEK_API_KEY` | `https://api.deepseek.com/v1` |
| Kimi | `kimi` | `KIMI_API_KEY` | `https://api.moonshot.ai/v1` |

Optional base URL overrides:

```bash
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENROUTER_BASE_URL="https://openrouter.ai/api/v1"
export DEEPSEEK_BASE_URL="https://api.deepseek.com/v1"
export KIMI_BASE_URL="https://api.moonshot.ai/v1"
```

8. Use aliases to switch providers without changing runtime code.

OpenAI example:

```yaml
models:
  aliases:
    llm/default:
      provider: openai
      name: gpt-5.2
  coding:
    - name: llm/default
  non_coding:
    - name: llm/default
```

OpenRouter example:

```yaml
models:
  aliases:
    llm/default:
      provider: openrouter
      name: openrouter/auto
  coding:
    - name: llm/default
  non_coding:
    - name: llm/default
```

DeepSeek example:

```yaml
models:
  aliases:
    llm/default:
      provider: deepseek
      name: deepseek-chat
  coding:
    - name: llm/default
  non_coding:
    - name: llm/default
```

Kimi example:

```yaml
models:
  aliases:
    llm/default:
      provider: kimi
      name: moonshot-v1-32k
  coding:
    - name: llm/default
  non_coding:
    - name: llm/default
```

9. Enable local LLM trace output only when you need it.

```yaml
tracing:
  llm_file:
    enabled: true
    path: "./.log/llm.ndjson"
    max_bytes: 10485760
    keep_files: 5
    include_payloads: true
    include_system_prompt: false
    include_user_text: true
    include_raw_output: true
```

## Verify

Start the runtime. Configuration errors fail fast during startup.

```bash
bundle exec rake server:run
```

For Telegram, verify that the bot token is available to the process:

```bash
printenv TELEGRAM_BOT_TOKEN
```

## Troubleshooting

- If startup reports a missing config file, run `bundle exec rake bootstrap`.
- If Telegram does not poll, confirm `TELEGRAM_BOT_TOKEN` is set or the token is present in config.
- If model calls fail, confirm the selected alias resolves to a supported provider and that the matching API key exists in the environment.
- If a provider uses a custom endpoint, set the matching `*_BASE_URL` override before startup.
- If `.log/llm.ndjson` does not appear, confirm `tracing.llm_file.enabled: true`, restart the runtime, and trigger a request that actually reaches the LLM.

## Related Docs

- [Configure Model Providers And Aliases](../configure-model-providers-and-aliases.md)
- [LLM Rolling Trace File Specification](../../../ops/specs/specs/2026-05-03-redwright-llm-rolling-trace-file-spec.md)
