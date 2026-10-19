# RedWright Pi Harness Data Model

Status: Approved
Approved: maintainer, 2026-10-19; explicit approval of the seven-slice plan, dependency/platform decisions and autonomous Pi-only commits, PRs and controller-owned Rebase + Fast-forward merges into dev.

## Metadata

- status: `approved`
- selection_status: `closed`
- created: `2026-10-19`
- readiness: `approved Rails storage contract for the linked delivery`

## Related Specification

[Pi Harness](2026-10-19-redwright-pi-harness-spec.md)

## Authority

Keep project identity, feature/ticket state and artifact bodies with their
existing owners. This proposal adds technical configuration and call provenance;
it does not create a ticket store, protocol index or execution scheduler.

Profile files are private host configuration. Project selections contain profile
references and revisions. Existing artifact files remain authoritative for
bodies/statuses, with Rails rows as the current derived indexes. Credentials do
not become document metadata or ProjectAttribute business context.

The delivery proposal uses ProjectHarnessSetting and HarnessOperation as the
canonical Rails owners. These are proposed models/tables, not implemented
columns. The maintainer approved this contract with the plan. No additional workspace configuration store
is created for the same project selections.

## Proposed Rails Representation

[Delivery plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md).

Project has one ProjectHarnessSetting and many HarnessOperation records.
The proposed project_harness_settings table contains:

| Column | Type and constraint |
| --- | --- |
| project_id | Required foreign key and unique index; one settings image per project. |
| authoring_profile, ticket_proposal_profile | Nullable strings, at most 128 bytes; null restores the role's existing default. |
| lock_version | Required integer, default 0; canonical optimistic selection revision. |
| mutation_receipts_json | Required bounded JSON text, default empty array; up to 128 exact request/result receipts. |
| changed_by, changed_at | Existing authorized actor reference and UTC time, nullable before an explicit change. |
| created_at, updated_at | Standard Rails timestamps. |

The proposed harness_operations table contains:

| Column | Type and constraint |
| --- | --- |
| project_id | Required foreign key; preserve retained operations when project deletion is restricted. |
| operation_key | Required string, at most 128 bytes; unique composite index with project_id. |
| purpose, role | Required bounded enums for existing authoring/slicing/curation/reference/ticket-proposal calls. |
| state | Prepared, running, completed, failed, cancelled, timed_out or uncertain; technical state, never ticket approval/completion. |
| selection_revision | Required retained revision or explicit legacy/default provenance. |
| binding_json, binding_digest | Required non-secret binding, at most 16 KiB, plus canonical SHA-256 digest. |
| contract_digest | Retained schema/policy digest; cannot change on resume. |
| workspace_revision_json | Bounded workspace/base references for each proposal; records only owned baseline changes. |
| attempts_json | Bounded call outcomes/application receipt references under the existing caller attempt limit. |
| private_run_ref | Opaque host-owned reference; private resolved resources remain in its protected bundle. |
| started_at, finished_at | Nullable owned-call lifecycle timestamps. |
| created_at, updated_at | Standard Rails timestamps; index project/state/created_at for admission and retention. |

Validate enums, JSON shape, byte limits and digests in the model/service; add
database uniqueness, foreign keys and applicable size/state checks. No raw
prompt, credential or document body belongs in these records. Serialize shared
two-call capacity admission across processes without holding a write transaction
for the lifetime of inference. Persist exact owned-call identity in bounded
attempt metadata so recovery cannot release another process's admission.

Use original create-table migrations for these new entities. Extend the existing
separate-database preparation/copy path to preserve the new tables; do not reset
or automatically switch an existing preview database. Fixtures verify existing
Factory rows and file associations survive preparation.

Selection receipts expire after seven days. Replaying an expired request must
still pass its original revision guard or return stale/expired. Operation
retention is bounded to 1,024 per project; reclaim only terminal, unreferenced
records older than 30 days. Active/uncertain recovery state is not discarded for
capacity. The exact bounds and initial Linux policy are in the delivery plan.

## Prepared Harness Profile

| Field | Proposed representation and constraint |
| --- | --- |
| name | Unique non-secret key in bounded private host configuration. |
| harness | Explicit enum `codex` or `pi`; direct API defaults retain their existing separate identity. |
| executable_ref | Host-prepared executable identity, unavailable to model-supplied configuration. |
| protocol_revision | Supported adapter contract, initially proposed as Pi 1.3.0. |
| requested_provider, requested_model | Exact Pi provider/model; legacy Codex defaults may remain explicitly unresolved. |
| thinking | Optional supported selection; rejection is explicit when unsupported. |
| credential_ref | Private reference with no credential bytes or readable diagnostic copy. |
| model_config_ref | Optional private custom-model definition with a non-secret semantic revision. |
| capabilities | Host-verified structured output, inspection, containment and accounting evidence. |
| revision | Digest of non-secret semantic profile data; excludes raw credentials. |

Profile availability and actual provider authentication are distinct readiness
facts. Constructors do not install executables or start live model calls.

## Project Selection Image

| Field | Proposed ProjectHarnessSetting contract |
| --- | --- |
| project_ref | Existing project identity; cannot select another project's defaults. |
| authoring_profile | Optional prepared-profile key for shared artifact authoring. |
| ticket_proposal_profile | Proposed optional key for the existing model proposal step. |
| revision | One coherent revision of the complete selection image. |
| changed_by, changed_at | Existing authorized actor reference and accepted change time. |
| request_id, request_digest | Bounded retry evidence for the exact mutation and expected revision. |

An omitted change preserves the field; an explicit clear restores the existing
role's default. Unknown non-null references fail. Validate actor, profiles,
capabilities and readiness before atomic publication. Serialize admissions
against changes so an operation sees one complete old or new image. Reject stale
updates, preserve unrelated settings and make identical lost-response retries
idempotent. Define receipt retention without adding another workflow ledger.

## Retained Operation Binding

| Field | Retained representation and lifecycle |
| --- | --- |
| schema_version | Versioned binding format; mandatory semantics cannot be ignored by old executors. |
| operation_id, purpose | Existing owning operation identity plus authoring/slicing/curation/reference/ticket-proposal purpose. |
| project_ref | Existing workspace/project authority. |
| schema_digest, policy_revision | Retained output and application policy for this operation. |
| workspace_ref | Owned workspace identity and starting base; correction attempts record changes made by the host. |
| selection_revision | Complete configuration revision read at admission, or explicit legacy provenance. |
| profile, profile_revision, harness | Frozen prepared selection; no fresh resolution halfway through retries. |
| requested_provider, requested_model, thinking | Requested values, distinct from observations and CLI defaults. |
| executable_ref, protocol_revision | Prepared launch identity and compatible transport. |
| capabilities_ref | Evidence for the requested tool/containment/validation/accounting profile. |
| binding_hash | Canonical digest of non-secret binding semantics. |

Retain this binding within the operation's existing private state/artifact owner
before its first model call. Nested calls and ticket correction attempts refer
to the same binding. Retries preserve current request/attempt guards; retaining
a binding does not authorize replay after an uncertain interruption.

Existing operations without these fields use historical rules and retain their
bytes/hashes. Reading them does not migrate or resume them. An incompatible
mandatory format must fail before launching another backend. Ephemeral Pi calls
do not supply durable provider-session continuation.

## Per-call Evidence

| Field | Contract |
| --- | --- |
| request_id, operation_id, attempt | Existing call ownership and correction attempt. |
| binding_ref | Frozen operation selection, without exposing private references. |
| input_digest, schema_digest | Provenance of caller context and output contract. |
| base_state_ref | Expected file/workspace revisions for this proposal; conflicts prevent blind application. |
| technical_outcome | Started, completed, failed, cancelled, timed_out, protocol_error or uncertain. |
| validation_outcome | Separate schema/domain validity, written by the original caller. |
| output_digest, artifact_ref | Host-validated result reference; no second authoritative document body. |
| observed_provider, observed_model | Optional verified observations; never inferred from the requested model. |
| usage, usage_status | Optional measured counters and known/partial/unknown status. |
| started_at, finished_at | Owned call timestamps, not inferred human work duration. |
| diagnostics_ref | Bounded private sanitized evidence with declared retention. |

Do not put credentials, prompts, raw private context or temporary absolute paths
in user-facing projections or versioned product artifacts. Keep process success,
valid output and domain completion distinct throughout queries and rendering.

## Open Decisions

The specification and linked plan propose the role scope, Rails storage,
Linux containment, schema validator and exact limits as one reviewable contract.
The maintainer approved implementation in the isolated delivery checkout.
Existing database resets and preview switches remain outside that authority.
