# RedWright Pi Harness Cycle Report

Status: awaiting integrated gate
Delivery set: pi-harness
Plan: [Pi Harness plan](../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)

## Delivery State

Slices 1 through 6 are integrated into canonical `dev`. Slice 7 prepares
operator guidance, integrated journey coverage and this evidence map. Its PR
and the controller's final integrated-candidate gate must finish before the
cycle can be closed. T7.3 remains open; focused and pre-merge results are not
substitutes for the exact integrated gate.

| Slice | Canonical PR | Integrated commit |
| --- | --- | --- |
| Slice 1 | [#10](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/10) | `09de3682a9c7ab76d40fae3f0cec37ddcfd53d3e` |
| Slice 2 | [#11](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/11) | `07b22440fc1ae520429382bf44cafaf135c871b5` |
| Slice 3 | [#12](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/12) | `0fdacc95f05b19078f24eb23218a9a4983f4209e` |
| Slice 4 | [#13](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/13) | `cdeb6dbbffcda5cff44fab6b95c4c07a802fb2b1` |
| Slice 5 | [#14](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/14) | `c54eaa3cca7da2673218c7cc9a070afea4cdce39` |
| Slice 6 | [#15](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/15) | `ae01006350d550fca8ad92dd79ab58e895d76ef8` |
| Slice 7 | [#16](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/16) | pending controller integration |

## Acceptance Evidence Map

The following implementation evidence is present. The final gate section below
must attach one exact integrated candidate and matching results before these
mappings establish delivery-set completion.

| Requirement | Delivered behavior and evidence boundary | Focused evidence |
| --- | --- | --- |
| PI-01 | Codex-compatible authoring and the direct-API ticket default work with no Pi profile/resources in the owned fixture. | [Integrated workflow](../../apps/web/test/integration/harness_workflow_test.rb), [structured calls](../../apps/web/test/services/harnesses/structured_call_test.rb). |
| PI-02 | Pi requires an explicit prepared selection; missing profiles, incompatible versions and unavailable capabilities fail without fallback. | [Selection](../../apps/web/test/services/harnesses/selection_test.rb), [Pi resources](../../apps/web/test/services/harnesses/pi_resources_test.rb), [authoring](../../apps/web/test/services/harnesses/authoring_integration_test.rb). |
| PI-03 | Specs, slicing, dump curation and protocol references retain their consumer prompts/domain owners through the shared adapter. | [Authoring consumers](../../apps/web/test/services/harnesses/authoring_integration_test.rb). |
| PI-04 | Existing file/revision authority publishes valid drafts and preserves approved artifacts/status on rejection. | [Authoring publication](../../apps/web/test/services/harnesses/authoring_integration_test.rb), [native draft](../../apps/web/test/integration/pi_harness_acceptance_test.rb). |
| PI-05 | Host Draft 2020-12 validation checks nested constraints, rejects external references and never inserts defaults. | [Schema checks](../../apps/web/test/services/harnesses/structured_call_test.rb), [proposal preflight](../../apps/web/test/services/harnesses/ticket_proposal_integration_test.rb). |
| PI-06 | Only settled final output is accepted; split/interleaved records, invalid streams, incomplete settlement and exit failures reject partial output. | [RPC transport](../../apps/web/test/services/harnesses/pi_transport_test.rb). |
| PI-07 | Deadlines/cancellation reap only owned processes and reject late results. | [Process supervision](../../apps/web/test/services/harnesses/process_supervisor_test.rb), [native cancellation](../../apps/web/test/integration/pi_harness_acceptance_test.rb). |
| PI-08 | Selected static resources enter private scratch; poisoned project discovery cannot add tools, context, credentials or approval UI. | [Resource isolation](../../apps/web/test/services/harnesses/pi_resources_test.rb), [native poisoned-resource proof](../../apps/web/test/integration/pi_harness_acceptance_test.rb). |
| PI-09 | Native Linux x86_64 Bubblewrap containment is verified per call. macOS, launchers, unsupported platforms and controlled inspection are explicitly unsupported. | [OS containment](../../apps/web/test/services/harnesses/linux_sandbox_test.rb), [native proof](../../apps/web/test/integration/pi_harness_acceptance_test.rb). |
| PI-10 | Separate Rails processes observe new defaults; admitted calls/corrections retain bindings and budgets. Owned recovery preserves the original binding. | [Integrated switching/recovery](../../apps/web/test/integration/harness_workflow_test.rb), [selection races](../../apps/web/test/services/harnesses/selection_test.rb), [ticket corrections](../../apps/web/test/services/harnesses/ticket_proposal_integration_test.rb). |
| PI-11 | Shared capacity is two running/uncertain calls; runtime scratch/output stays separate and byte ceilings remain finite. | [Owned operations](../../apps/web/test/services/harnesses/operation_test.rb), [supervision](../../apps/web/test/services/harnesses/process_supervisor_test.rb), [simultaneous native calls](../../apps/web/test/integration/pi_harness_acceptance_test.rb). |
| PI-12 | Private credentials/references are excluded from public settings/argv and sanitized diagnostics. Missing/partial usage is never invented. | [Settings projection](../../apps/web/test/controllers/project_harness_settings_controller_test.rb), [resources](../../apps/web/test/services/harnesses/pi_resources_test.rb), [usage](../../apps/web/test/services/harnesses/pi_transport_test.rb). |
| PI-13 | Selected proposals preserve context/LlmContract, host application, base/path checks, validation and local Git authority. Uncertain effects block replay. | [Proposal workflow](../../apps/web/test/services/harnesses/ticket_proposal_integration_test.rb), [feature-to-ticket journey](../../apps/web/test/integration/harness_workflow_test.rb), [native ticket](../../apps/web/test/integration/pi_harness_acceptance_test.rb). |
| PI-14 | Pinned Pi 1.3.0 uses an owned loopback endpoint and dummy selected static resources for binary/protocol, filesystem and publication proof. Paid provider authentication was not exercised. | [Native acceptance](../../apps/web/test/integration/pi_harness_acceptance_test.rb). |
| PI-15 | The existing guide explains prepared profiles, effective choices, local readiness, compatibility, unknown usage, limits and recovery. | [Configuration steps](../../docs/how-to/user-guide/configure-redwright.md#choose-project-harnesses), [profile reference](../../docs/reference/harness-profiles.md). |

## Measured Evidence before the Final Gate

The Slice 6 integrated head `ae01006350d550fca8ad92dd79ab58e895d76ef8`
passed its ordered controller checks: Rails 619 tests/5,013 assertions in
77.42 seconds; native Pi 6 tests/77 assertions in 10.76 seconds; ticket
metadata, changed Ruby syntax and whitespace. This evidence belongs to that
head, not the future Slice 7 integrated candidate.

The new Slice 7 integrated workflow check passed during implementation:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/integration/harness_workflow_test.rb)
```

Result: 2 tests, 63 assertions, no failures, errors or skips; 3.22 seconds.
One journey changes the web selection from another process, observes separate
active/default choices, generates from the new profile and reconciles a
retained uncertain call using the original lease from another process. The
other generates/approves/slices a feature through real Codex-compatible pipes,
then applies a direct-API proposal, runs real Go checks and reaches reviewing
only after a local commit. All databases, executables and workspaces are owned
fixtures. Provider completion is injected; no paid call is made.

Documentation checks rendered six Markdown files and validated their fenced
JSON examples, balanced fences and 57 local links.

## Exact Integrated Gate

Candidate: pending controller integration.
Gate evidence: pending controller execution.
T7.3: pending exact matching gate evidence and documentation closure.

The unchanged controller command is:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test) && (cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb) && bundle exec rake test && scripts/agent/tickets/check.sh && git diff --check
```

Retain the controller's exact candidate, command, log and outcomes here during
closure. Do not rerun the gate in the implementation worker, infer it from
pre-merge checks, or mark the cycle delivered without its result.

## Remaining Evidence Boundary

Local readiness is not provider authentication. Native acceptance establishes
the pinned binary, protocol, resource isolation, filesystem policy and host
workflow against a controlled endpoint. macOS Pi containment, OAuth refresh,
tool-using workers and paid provider authentication remain unsupported or
unverified as recorded above. Core file, validation, ticket and Git owners
retain their authority.
