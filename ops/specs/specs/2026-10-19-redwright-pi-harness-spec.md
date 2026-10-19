# RedWright Pi Harness

Status: Approved
Approved: maintainer, 2026-10-19; explicit approval of the seven-slice plan, dependency/platform decisions and autonomous Pi-only commits, PRs and controller-owned Rebase + Fast-forward merges into dev.

## Metadata

- status: `approved`
- selection_status: `closed`
- created: `2026-10-19`
- readiness: `approved for the linked seven-slice autonomous Rails delivery`
- scope: `harness-selection/structured-generation/ticket-proposals`

## Related Artifacts

- [Data model](2026-10-19-redwright-pi-harness-spec-model.md)
- [Delivery proposal](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Delivery tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Curated CHR consultation](../../conv/quiz/2026-10-19-redwright-pi-harness-quiz.md)
- [Current specification and ticket file contracts](../../../docs/reference/specification-files.md)
- [Existing sandbox execution proposal](../drafts/2026-05-09-redwright-agent-sandboxed-execution-backend-draft.md)

## Purpose and Review Boundary

Allow RedWright to use Pi alongside Codex while preserving the authority of
RedWright's workflows, file stores, validation and execution controls.

The user requested the CHR consultation and subsequently approved the full
Rails delivery proposal, including storage, interface, dependency and Linux
policy, with autonomous Pi-only execution on 2026-10-19.

The approved initial scope covers existing structured authoring and the model's
bounded ticket-change proposal. A tool-using Pi worker is a distinct execution
capability that needs its own approved contract. Choosing Pi for authoring must
not implicitly give it ownership of shell commands, ticket transitions or Git.

## Evidence and Starting Point

The CHR agent was consulted through Iris on 2026-10-19. Its answer and source
inspection refer to commit `7d3ccda3661853c56df013ef206ac9d07cb230d6`:

- Its approved specification and model are
  `ops/default/spec/stable/codex-pi-harnesses.md` and
  `codex-pi-harnesses-model.md`.
- Three of eight delivery slices were integrated at that snapshot: neutral
  contracts/Codex extraction, retained selection, and native Pi generation.
  Docker workers, interface selectors and final integrated live acceptance were
  outstanding. Those are CHR's state, not delivered RedWright features.
- Its Pi adapter pins 1.3.0, uses RPC and private per-call resources, and
  distinguishes protocol completion from domain acceptance.
- Its inspection extension enforces a narrow tool capability. It does not
  establish an OS sandbox. Its supplied schema is prompt input; callers validate
  JSON and domain shapes. It does not provide generic JSON-Schema enforcement.

RedWright source was inspected at `8d63f6fbe6fb67e0bd7ef26bbfb474735ae43cf1`
with the existing uncommitted Settings work preserved:

| Existing owner | Current contract |
| --- | --- |
| [Specifications::Harness](../../../apps/web/app/services/specifications/harness.rb) | Launches `codex exec` with read-only sandbox, ephemeral execution, output schema, final-output file, a 180-second deadline and a 2 MiB result limit. |
| [Dumps::Harness](../../../apps/web/app/services/dumps/harness.rb) | Reuses that transport with dump-specific instructions and executable override. |
| [Specifications::Slicing::Harness](../../../apps/web/app/services/specifications/slicing.rb) | Reuses it with a bounded ticket-array schema. |
| [ProjectProtocols::ReferenceHarness](../../../apps/web/app/services/project_protocols/reference_harness.rb) | Reuses it with a body-only schema and protocol reference rules. |
| [AgentTicketExecution::LlmContract](../../../apps/web/app/services/agent_ticket_execution/llm_contract.rb) | Requests proposed changes as JSON through the existing provider-backed model path. |
| [ValidationLoop](../../../apps/web/app/services/agent_ticket_execution/validation_loop.rb) | Applies proposals through OutputApplier, runs host validation and limits correction attempts. |
| [RuntimeBridge](../../../apps/web/app/services/runtime_bridge/ticket_execution_bridge.rb) and [Codex proof](../../../lib/redwright/codex_proof/harness.rb) | Separate runtime and proof boundaries; neither is the authoring wrapper. |

The current wrapper validates operation-specific output shapes. Supplying
Codex's schema flag is not evidence that RedWright already runs a general host
JSON-Schema validator. That host check is an explicit requirement for Pi.

## Proposed Ownership

Use sibling Codex and Pi adapters behind one small Ruby structured-call contract.
Operation owners retain prompts, schemas, semantic validators, provenance,
conflict handling and publication. Shared process supervision owns pipe IO,
deadlines, byte limits and process cleanup. Adapters own their commands,
protocols, events and capability descriptions.

Place reusable transport code in the existing Ruby library boundary when both
runtime and Rails callers need it; keep Rails workflows in their current service
modules. Choose concrete module names during approved implementation design.
Neither adapter should construct or depend on the other.

For the existing ticket path, propose replacing only the model-request step.
Keep LlmContract, context shaping, OutputApplier, ValidationLoop, workspace
validation and GitFinalizer in charge of their existing responsibilities.
Do not import CHR's scheduler, claims, ticket database or integration receipts.

## Selection and Compatibility

Propose private, host-prepared named profiles and independent project selections
for `authoring` and `ticket_proposal`. These names describe RedWright's current
call boundaries; they do not mean CHR's tool-using worker role.

1. A profile identifies harness, executable, compatible protocol revision,
   requested provider/model/thinking and private credential references.
2. A project selects a prepared profile. Forms and model output cannot supply
   an arbitrary executable, credential path or shell command.
3. Existing authoring defaults and `REDWRIGHT_SPEC_HARNESS`,
   `REDWRIGHT_DUMP_HARNESS` and `REDWRIGHT_PROTOCOL_HARNESS` behavior remain
   available when no new selection is present. These executable overrides keep
   their existing Codex-compatible meaning; setting one to `pi` is insufficient.
4. The current provider-backed ticket path remains the default when its proposed
   role has no explicit harness selection. Harness and model-provider identities
   remain distinct. Do not relabel the existing direct API backend as Codex.
5. An explicit unknown profile, unavailable executable or unsupported capability
   returns an actionable error before invocation. Never silently choose Codex,
   another provider or a different model after Pi was selected.
6. A single application service resolves selections for callers and any future
   selection interface. A successful change affects new operations without a
   service restart. Installing Pi or provisioning credentials is separate setup.

The delivery proposal selects a project-scoped Harness settings resource and
ProjectHarnessSetting as the canonical Rails selection owner. HarnessOperation
retains admitted bindings. These concrete choices were approved with the delivery plan.
Inspection must show configured selection, active binding and actual readiness
separately; a configuration check does not establish provider authentication.

## Structured Call Contract

Inputs include operation/request identity, purpose, explicit context and
instructions, workspace/evidence scope, output schema, semantic validation
owner, required capabilities, deadline, byte limits and frozen selection.

Outputs include final assistant bytes, technical outcome, optional observed
provider/model and usage, sanitized diagnostics and retained binding identity.
Unknown observations remain absent; they are not inferred from requested values.
Transport success cannot approve a specification or complete a ticket.

Snapshot the selection before the first call in a logical operation. Slicing,
curation, reference updates and ticket correction loops retain that binding
across their nested calls and retries. Later independent requests use current
defaults. A host operation ID is not a Pi session ID.

Retain the operation's schema, policy and workspace authority. Each ticket
proposal records its expected file/base revisions; apply it only against that
base. Record owned application before preparing correction context. External
changes produce a conflict. Retained request IDs do not provide exactly-once
inference or application: reconcile uncertain application/finalization effects
through their existing owners before retrying side effects.

Existing saved operations without harness metadata keep historical behavior.
Do not rewrite active request hashes or switch an interrupted operation because
defaults changed. Mandatory new binding formats must be versioned so an older
executor cannot silently ignore a Pi selection.

## Pi Invocation and Completion

Use Pi 1.3.0 RPC as the proposed initial compatibility target. Validate the
installed version explicitly; do not claim support from an unpinned latest
release. An invocation uses an ephemeral session and explicit model selection.
Send prompt/context through stdin rather than command arguments.

The adapter must correlate command responses, decode UTF-8 records split only
on LF, and drain stdout/stderr while writing. Accept only the owned prompt's
started acknowledgement, completed final assistant output and settled run.
An acknowledgement, intermediate message, tool result or `agent_end` alone
cannot publish a result. Handle rejected or handled-without-run prompts without
waiting forever or returning stale output.

Separate startup failure, unsupported capability, protocol failure, provider
failure, invalid output, cancellation, timeout and uncertain interruption.
The host closes pipes, stops and reaps only its owned process group. Local
termination does not prove remote computation or billing stopped.

## Capabilities and Containment

Define separate capabilities for structured final output, host schema
validation, controlled file inspection, OS read-only containment and measured
usage. Model-side constrained decoding and certified hard token limits are
additional claims that require their own evidence.

Ordinary Pi structured calls expose no tools and disable discovered extensions,
MCP servers, skills, prompt templates, themes and context files. Use explicit
host context and isolated private per-call configuration. Only an explicitly
approved host inspection extension may be enabled for an inspection operation.
Default to no unattended approval UI; an unsupported interaction fails explicitly.

Tool restrictions and a prompt cannot replace an existing OS sandbox guarantee.
The trusted Pi/Node process retains ordinary OS permissions; restricting its
model-facing tools does not restrict every capability of that process.
Before Pi replaces an operation requiring OS read-only containment, provide and
verify an appropriate host/container boundary for the declared platform or
reject that selection. Fail closed before starting the model call.

CHR's `readonly.mjs` relies on Linux `/proc/self/fd`, bounded regular files,
descriptor checks and explicit path exclusions. Reusing it unchanged cannot
establish macOS support. Linux/macOS containment and inspection need separate
evidence; unsupported combinations must be visible during readiness checks.

## Validation, Publication and Resource Bounds

Parse final JSON and validate the full supplied schema in the host, followed by
the current domain validators. Reject unknown fields, invalid required values,
wrong types, oversized output and non-JSON text where the schema disallows them.
Do not salvage partial streams or extract a plausible JSON fragment from prose.

Only a complete, valid result reaches existing file-store locks, revision checks
and atomic publication. Failure preserves the previous document and its status.
Ticket proposals must pass the existing contract before OutputApplier runs.
Model output cannot select validation policy or authorize publication.

Preserve the existing 180-second and 2 MiB authoring bounds, the 128 KB context
ceiling where currently enforced, and the slicing limit of 20 tickets. Other
callers retain their stricter operation limits. Before implementation, fix finite
input, RPC-record, aggregate-stream, diagnostic, concurrency and retained-artifact
limits in the same contract; accepted JSON must never be truncated to fit.
RPC record limits must accommodate the largest permitted encoded result plus
its envelope. Any stricter profile allowance must be explicit, rather than
silently reducing the advertised 2 MiB result allowance.

Pi retries/compaction must fit the host deadline and attempt policy. A backend
change cannot reset attempts or create another capacity pool. Usage may be
observed without being certified for hard budget enforcement. A role requiring
an unavailable enforcement capability must be rejected.

Use only the selected credentials, private temporary runtime state and sanitized
bounded diagnostics. Do not copy the operator's entire home or environment.
Static credentials are the proposed initial support; OAuth refresh requires a
separate explicit owner and verified refresh/concurrency contract.

## Acceptance Criteria

| ID | Observable evidence |
| --- | --- |
| PI-01 | Existing Codex authoring works with Pi absent and no new selection. |
| PI-02 | Pi selection is explicit; missing profiles, incompatible versions and capability failures cannot silently fall back. |
| PI-03 | Specs, slicing, dumps and protocol references use the shared resolved adapter with their original prompts and domain checks. |
| PI-04 | A valid Pi result is saved through the current file/revision authority; invalid output preserves existing artifacts and status. |
| PI-05 | Full host schema validation catches failures beyond JSON syntax and shallow shape checks. |
| PI-06 | Interleaved/split records, early exit, late completion, provider failure and missing settlement never publish partial output. |
| PI-07 | Cancellation and deadlines stop/reap owned resources without accepting a late result or affecting another call. |
| PI-08 | Poisoned project/user resources cannot introduce tools, credentials, context, model changes or approval UI into the admitted call. |
| PI-09 | Required OS containment and inspection capabilities are verified per platform; unsupported Linux/macOS combinations fail before invocation. |
| PI-10 | New operations see selection changes; nested calls, retries and recovery retain the original binding and budgets. |
| PI-11 | Two concurrent operations keep separate runtime state/output and obey shared finite capacity and stream limits. |
| PI-12 | Credentials and private references stay outside versioned files, model argv and readable diagnostics; missing usage remains unknown. |
| PI-13 | The proposed ticket-proposal integration preserves LlmContract, context shaping, OutputApplier, validation and Git authority. |
| PI-14 | A real pinned Pi binary is tested with owned files and a controlled endpoint; a separately authorized provider smoke test reports its actual evidence boundary. |
| PI-15 | User guidance explains prepared profiles, effective selection, compatibility, errors and the difference between selection and active work. |

Use real owned subprocess/pipe/filesystem fixtures for the technical boundary
and focused Rails integration checks for artifact/ticket authority. Fixture
success is not paid-provider, arbitrary-model or Docker-worker certification.

## Approved Delivery Decisions

The maintainer approved the linked delivery decisions:

1. Include authoring and the existing ticket proposal step, with independent
   defaults and host-owned application/validation.
2. Use ProjectHarnessSetting and HarnessOperation in Active Record, and a
   project-scoped Rails Harness settings resource.
3. Deliver tool-free Pi on Linux through a verified Bubblewrap policy. Reject
   Pi on macOS until an equivalent platform policy is proved.
4. Pin Pi 1.3.0 with selected static resources. Use an owned loopback model for
   required real-binary proof; paid authentication remains separately authorized.
5. Add json_schemer 2.5.0 and implement the exact finite limits in the plan.

All five decisions are approved for this execution set. Unrelated Settings/Setup
commits, service/database switches and paid provider requests remain outside
that authority.

## Upstream References

- [Pi 1.3.0 RPC](https://github.com/earendil-works/pi/blob/v1.3.0/packages/coding-agent/docs/rpc.md)
- [Pi 1.3.0 CLI and resource controls](https://github.com/earendil-works/pi/blob/v1.3.0/packages/coding-agent/docs/cli.md)

Upstream facts, CHR's implementation and the proposed RedWright behavior are
separate evidence categories. This document does not claim Pi is integrated.
