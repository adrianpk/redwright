# Harness Profiles

Project **Harness** settings select prepared local profiles for two independent
roles: authoring and ticket proposals. The selection is stored in the Rails
database. Profiles and credential resources are private operator files outside
the repository and every selected project workspace.

## Defaults and Selection

| Role | No profile selected | Explicit profile |
| --- | --- | --- |
| Authoring | Existing Codex-compatible executable and local configuration. | Named Codex or Pi profile. |
| Ticket proposals | Existing direct-API coding model configuration. | Named Codex or Pi profile for the proposal step. |

The authoring role covers specifications, ticket slicing, dump curation and
protocol-reference generation. Rails retains schema/domain validation, revision
checks and file publication. Ticket proposals retain context filtering,
OutputApplier, host validation, local Git finalization and ticket transitions.
Pi receives no shell, inspection, write, MCP or approval tool.

A saved change affects new operations without restarting Rails. Nested calls
and ticket corrections retain their admitted profile, schema, policy, provider/
model request and deadline. Clearing one role restores its default independently.
An unavailable explicit choice fails; it never falls back to another provider.

The page's **Configured selections** are defaults. **Active bindings** shows up
to 20 prepared, running or uncertain operations with their retained choices.
**Available locally** reports local configuration checks; it does not contact a
provider or establish successful authentication. Requested provider/model labels
are distinct from observations made by a completed call.

## Private Registry

The default registry is `~/.config/redwright/harnesses.json`. Set
`REDWRIGHT_HARNESS_PROFILES` in the Rails process environment before startup to
use another file. Use an owner-only regular file, for example mode `0600`.
Symlinks, group/other access, files inside the repository and unknown fields are
rejected. The format is version 1, at most 64 KiB with 64 unique profiles.
Names match `[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}`.

This example uses invented absolute paths. Replace them with existing prepared
resources and an endpoint/model supported by the operator's installation:

```json
{
  "version": 1,
  "profiles": [
    {
      "name": "local-codex",
      "harness": "codex",
      "executable_ref": "/opt/harnesses/codex",
      "protocol_revision": "codex-exec/v1",
      "capabilities": {"structured_output": true}
    },
    {
      "name": "contained-pi",
      "harness": "pi",
      "executable_ref": "/opt/harnesses/pi/pi",
      "protocol_revision": "1.3.0",
      "requested_provider": "example-provider",
      "requested_model": "example-model",
      "thinking": "off",
      "credential_ref": "/opt/harness-resources/auth.json",
      "model_config_ref": "/opt/harness-resources/models.json",
      "capabilities": {
        "structured_output": true,
        "os_read_only_containment": true
      }
    }
  ]
}
```

Every executable reference is an absolute executable file. Codex keeps its
existing `exec` invocation and executable configuration; profile provider/model
labels do not introduce additional Codex model-selection flags. Pi requires an
explicit provider/model, native ELF executable and adjacent package metadata
for `@earendil-works/pi-coding-agent` version `1.3.0`. Launchers and other
versions are rejected. Supported thinking values are `off`, `minimal`, `low`,
`medium`, `high`, `xhigh` and `max`.

The legacy authoring executable defaults to `codex`. Existing
`REDWRIGHT_SPEC_HARNESS`, `REDWRIGHT_DUMP_HARNESS` and
`REDWRIGHT_PROTOCOL_HARNESS` overrides retain their meaning when no explicit
profile is selected. They do not select Pi.

## Pi Static Resources

Credential and model resources must also be private regular files outside the
repository and project workspace, at most 64 KiB each. A selected credential
file contains a static API key for the exact provider:

```json
{
  "example-provider": {"type": "api_key", "key": "REPLACE_WITH_STATIC_API_KEY"}
}
```

OAuth refresh, environment interpolation and credential commands are
unsupported. The credential is copied into private per-call scratch and is
never passed as a command argument. Only the selected provider credential is
copied; unrelated entries are excluded. The registry and the web page carry
profile keys rather than credentials.

A custom endpoint/model can be prepared in `models.json`:

```json
{
  "providers": {
    "example-provider": {
      "baseUrl": "https://model-api.example.test/v1",
      "api": "openai-completions",
      "authHeader": true,
      "models": [
        {"id": "example-model", "name": "Prepared model", "input": ["text"], "contextWindow": 32768, "maxTokens": 4096}
      ]
    }
  }
}
```

Supported API identifiers are `openai-completions`, `openai-responses`,
`anthropic-messages` and `google-generative-ai`. The selected static endpoint
and model are snapshotted; arbitrary credential headers, discovery commands or
provider configuration are rejected. `model_config_ref` is optional when the
exact provider/model is built into the prepared Pi distribution. An optional
`model_config_revision` must match the canonical selected snapshot digest.
Replacing the selected model configuration or executable invalidates a retained
binding rather than silently changing an existing operation.

## Containment and Evidence

Pi is supported on Linux x86_64 with Bubblewrap and the required native runtime
libraries. macOS and unsupported executable/platform combinations fail before
model invocation. Each call verifies the filesystem policy before starting Pi.
The namespace mounts only explicit executable/runtime, certificate and resolver
resources read-only, with private writable scratch. It exposes no host project
workspace, entire home, runtime socket directory or Docker socket. Context is
supplied explicitly. Discovery, sessions, extensions, skills, prompt templates,
MCP, context-file loading and approval UI are disabled.

Network access to the selected model endpoint remains available. Pi's offline
flag controls discovery; it is not a claim of network isolation. Per-call
scratch is removed and the owned process is reaped after success or failure.
The existing Codex sandbox behavior remains unchanged.

A profile capability flag is a declaration, not measured proof. Pi's adapter
verifies containment and observed provider/model through its protocol. Usage
is `known`, `partial` or `unknown` according to actual returned fields; absent
usage is never reported as zero or inferred from requested settings. Codex
transport does not currently report observed provider/model or measured usage.

## Limits and Recovery

| Boundary | Limit |
| --- | --- |
| Logical authoring / selected ticket deadline | 180 seconds, including setup and cleanup; nested calls/corrections share it. |
| Ticket correction attempts | At most 3 per operation. |
| Shared running/uncertain calls | 2 per application database. |
| Encoded request / schema / decoded result | 1 MiB / 64 KiB / 2 MiB; stricter caller limits still apply. |
| Caller context / slicing | Existing 128 KiB context bounds / at most 20 tickets. |
| RPC record / aggregate stdout / stderr | 16 MiB / 64 MiB / 2 MiB. |
| Retained diagnostics | At most 256 KiB sanitized data per stream per call. |
| Retained binding / workspace reference | 16 KiB each. |
| Selection retry receipts | 128 per project, retained seven days; full unexpired capacity rejects new changes. |
| Retained operations | 1,024 per project; only unreferenced terminal operations older than 30 days can be reclaimed. |
| Ticket workspace capture | 4,096 entries and 64 MiB, including ignored files; symlinks are not followed. |

| Result | Operator action |
| --- | --- |
| Stale selection / conflicting request identity | Reload Harness, inspect the current selection and submit the intended change with a new request identity. Exact retries retain their original result. |
| Unavailable profile, resource, platform or containment | Correct the prepared local resource named by the profile, then check readiness again. Saving does not install software or weaken containment. |
| Unsupported version/authentication/resource shape | Prepare the supported native version and static resource format. A locally available profile can still fail authentication during a real call. |
| Invalid output / schema / domain result | Inspect the bounded failure evidence. Host validation prevents publication; transport success is insufficient. |
| Workspace/base conflict | Inspect outside edits and regenerate against the current base; do not overwrite them with the old proposal. |
| Capacity / retention full | Resolve the existing retained work or wait for eligible retention expiry. Changing a default does not release active capacity. |
| Uncertain application or finalization | Inspect the existing host file, validation and Git owners' evidence before reconciliation. Do not retry inference, clear rows, or reuse a new request ID to replay effects. |

Private resolved bindings are stored under
`~/.local/state/redwright/harness-operations`, or `REDWRIGHT_HARNESS_STATE` when
set in the Rails environment. Keep this directory owner-only and preserve it
with the owning Rails database during recovery. Tokens and private references
are excluded from the public settings projection. Ticket attempt bases and
result receipts contain hashes/revisions rather than proposal bodies.

There is no automatic stale-process or timeout-based reconciliation. An
uncertain effect retains capacity until its owner establishes the outcome.
Request identity does not provide exactly-once inference or application.

## Related Documentation

- [Configure RedWright](../how-to/user-guide/configure-redwright.md)
- [Use the Web App](../how-to/user-guide/use-the-web-app.md)
- [Model Providers and Aliases](../how-to/configure-model-providers-and-aliases.md)
