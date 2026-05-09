# Debug LLM Calls

## Purpose

Inspect what RedWright sent to the LLM and what it received back, especially when testing behavior from Telegram.

## Before You Start

- Use this only for local debugging.
- The trace file can contain prompt text, user text, project context, and raw model output.
- Enable payload fields only when you need them.

## Steps

1. Enable LLM file tracing in the active config.

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

2. Restart the runtime process.

Configuration is loaded on startup.

3. Trigger an LLM-backed interaction.

Telegram examples:

```text
/project new trace-test
```

or:

```text
/ticket start RW-10
```

4. Inspect the trace file.

```bash
jq . .log/llm.ndjson
```

For live inspection:

```bash
tail -f .log/llm.ndjson
```

5. Correlate request and response.

Use `llm_call_id` to pair:

- `llm_request`
- `llm_response`

Use `trace_id` to connect the LLM call to the Telegram reply trace.

## Verify

Each LLM-backed turn should produce at least:

- one `llm_request`
- one `llm_response`
- matching `llm_call_id`
- `source_channel`
- `action`
- model metadata
- payload size metadata

For Telegram, expected metadata includes:

- `source_channel: "telegram"`
- `session_id`
- `actor_identifier`
- `project_ref` when project context is available
- `project_root` when project context is available

For agent ticket execution, inspect the request payload for these context
sections:

- `ticket`
- `project`
- `repository_tree`
- `relevant_files`
- `tests`
- `operational_setup`
- `protocol_files`
- `protocol_model`
- `previous_interactions`
- `validation_feedback` on retry attempts

For context-shaped requests, inspect `policy_decision` on request and response
trace records. Expected fields include:

- `policy_name`
- `work_family`
- `confidence`
- `fallback`
- `included_layers`
- `included_context_sections`
- `omitted_context_sections`
- `omission_reasons`

Omission reasons use the format
`context_layer_not_in_policy:<layer>:<policy>`.

Responses are normalized before application when they are close to the expected
contract. For example, recoverable aliases such as `ready`, `changes`, and
`commands[].cmd` can be normalized into the agent ticket execution response
contract and recorded in diagnostics.

## Troubleshooting

- If `.log/llm.ndjson` does not exist, confirm tracing is enabled and restart the runtime.
- If the file exists but no new lines are written, confirm the interaction actually reached an LLM path.
- If payload fields are missing, confirm `include_payloads` and the specific field toggle are both enabled.
- If an agent ticket blocks with an invalid LLM response, inspect the response
  diagnostics to see whether contract validation failed before output
  application.
- If expected context is missing from a provider request, inspect
  `policy_decision.omitted_context_sections` and `omission_reasons` before
  changing the context composer.
- If a retry attempt behaves unexpectedly, inspect `previous_interactions` and
  `validation_feedback` in the request payload.
- If the file grows too large, lower `max_bytes` or `keep_files`.
- If sensitive data was captured, stop the runtime and remove local trace files.

## Related Docs

- [LLM Context Shaping](../../reference/llm-context-shaping.md)
- [LLM Rolling Trace File Specification](../../../ops/specs/specs/2026-05-03-redwright-llm-rolling-trace-file-spec.md)
- [Use Telegram](use-telegram.md)
