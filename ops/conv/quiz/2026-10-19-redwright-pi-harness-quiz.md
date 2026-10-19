# RedWright Pi Harness Consultation

## Metadata

- status: `curated research`
- created: `2026-10-19`
- source: `user-requested Iris consultation with the CHR agent`

## Related Specification

[Pi Harness](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
and its [model](../../specs/specs/2026-10-19-redwright-pi-harness-spec-model.md).

These are curated technical questions and answers from the peer consultation,
not a user questionnaire. CHR recommendations are not maintainer approval of
RedWright scope. The original exchange remains in Iris.

## Question: What was specified and what is actually delivered?

The CHR agent inspected `7d3ccda3661853c56df013ef206ac9d07cb230d6` and
identified its approved spec/model, plan and tracker under
`ops/default/{spec/stable,plan,tracker}/codex-pi-harnesses*`.

Three of eight slices were integrated: neutral contracts/Codex extraction,
selection and retained bindings, and native Pi generation. Docker workers,
Web/TUI/Telegram controls and final integrated acceptance remained outstanding.
The agent inspected retained validation evidence and canonical PRs; it did not
run tests, call a provider or modify CHR during this consultation.

Recorded activity also identifies Slice 3 closure and Slice 4 activation. This
is a dated evidence boundary, not a claim about later controller progress.

## Question: How are Codex and Pi separated?

CHR has sibling `internal/harness/codex` and `internal/harness/pi` packages,
neutral contracts in `internal/harness/contracts.go` and shared process owners
under `internal/harness/process`. Core retains prompts/schemas/domain parsing;
app resolves prepared selections. Structured generation and tool-using worker
commands are separate capabilities.

Private profiles identify executable, provider/model and resources. Project role
references change through one service. A logical operation retains its original
binding across nested calls/retries; new operations can use changed defaults.
Its versioned worker invocation format prevents old executors from ignoring new
mandatory harness fields. None of this requires another ticket database.

## Question: What does Pi execution require?

The generation adapter pins Pi 1.3.0, invokes RPC with an ephemeral session and
explicit provider/model, and sends prompt/schema through stdin. It prepares
private per-call state rather than using automatic project resource discovery.
Exact setup is in `internal/harness/pi/generation_setup.go`, `resources.go` and
`generation.go`.

Its bounded LF/UTF-8 decoder and process owner handle interleaved records,
backpressure, diagnostics and cancellation. Prompt acknowledgement and
`agent_end` are insufficient; settlement and completed final assistant output
are required. The result does not certify task completion. Observed usage is
not hard token-budget enforcement, and absent usage is unknown.

Host operation recovery is distinct from resuming a Pi conversation. These
calls use `--no-session`. The delivered credential path supports selected static
API-key resources; OAuth refresh is rejected until an explicit refresh owner
and concurrency protocol exist.

## Question: Does CHR provide OS read-only containment or strict schemas?

No OS sandbox equivalence was established. The optional host-owned inspection
tool exposes bounded list/find/read, with descriptor/path checks and exclusions.
Native Pi/Node retains ordinary OS process permissions. Its Linux descriptor
checks use `/proc/self/fd`; macOS support is not established.

See `internal/harness/pi/{generation_files.go,inspection_events.go,readonly.mjs}`.
The real-binary test checks tool exposure, resource discovery and forbidden file
access through that tool. It does not establish filesystem/network namespaces.

Likewise, `generationTransportRequest` appends the schema to the prompt. The
transport returns final bytes; caller parsing decides JSON/domain validity.
There is no generic strict JSON-Schema validator or constrained decoder there.
RedWright needs its own complete schema validation before artifact publication.
An operation requiring OS containment needs a verified boundary or rejection.

## Question: Can the existing ticket proposal reuse generation?

CHR confirmed this interpretation in the follow-up: the ticket's model step can
reuse the structured-call adapter with its own purpose/profile and retained
binding. OutputApplier, ValidationLoop and GitFinalizer keep their authority.
Validate domain paths and the expected workspace base as well as JSON Schema.
Reconcile uncertain application/finalization before retrying side effects;
operation IDs do not provide exactly-once inference or application. Transport
record limits must account for the encoded form of the allowed final result.

## Question: What validation evidence exists?

The agent reports canonical PRs 412, 413 and 414 merged. For Slice 3 it verified
retained evidence for candidate `23bafd38e143105c003075d71125455713e23696`:
`make verify`, focused Pi transport/generation/binding checks, focused race
checks, a pinned real Pi inspection test and whitespace validation passed.

The real Pi test used an owned loopback model endpoint and disposable files.
It checked allowed reads, denied paths/file types and poisoned discovery
resources. That is real binary/protocol evidence, not paid-provider, arbitrary
model, Docker-worker or kernel sandbox proof. Scheduled/full live acceptance
remained separate.

A recorded backpressure test timeout was traced to costly diagnostic redaction;
the delivered prefilter correction retained byte bounds and assertions. This is
a reminder to test actual pipe pressure and redaction costs together.

## Provisional RedWright Convergences

1. Reuse the current structured-call seam through sibling adapters; preserve
   operation prompts, full host schema checks and domain publication authority.
2. Preserve Codex-only operation and current direct API ticket defaults.
3. Freeze selection per operation, separate requested/observed metadata and keep
   process, validation and task-completion outcomes distinct.
4. Reuse a structured call for the current ticket proposal if that scope is
   approved; host application/validation remains authoritative.
5. Do not copy Linux inspection code as macOS support or tool restrictions as
   an OS sandbox. Do not import CHR's scheduler or budget certification claims.

## Open Questions

The paired draft owns the pending product scope, settings storage/interface,
platform containment, initial provider/model and validation dependency/limits.
These remain maintainer decisions. No implementation plan, tickets or execution
authority follows from the peer's technical recommendations.

The user's subsequent slicing request produced a concrete
[delivery proposal](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
and [tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md).
They propose Rails persistence, both existing call roles, Linux Bubblewrap,
Pi 1.3.0 and json_schemer 2.5.0. The maintainer approved these RedWright delivery decisions and autonomous
Pi-only execution on 2026-10-19; they were not inferred from CHR's consultation.
