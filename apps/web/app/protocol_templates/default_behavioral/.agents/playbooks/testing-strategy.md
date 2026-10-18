# Testing Strategy

Use this playbook when implementing or reviewing behavior changes.
`.agents/LINTING.md` owns test design and validation policy.

1. Identify the changed behavior, affected boundaries, failure modes, and
   existing tests and timings for repository-native commands.
2. Select the delivery gate and any risk-based techniques under
   `.agents/LINTING.md`; account for expensive setup and duplicated executions.
3. Extend existing coverage or add tests with distinct regression value.
4. Run inexpensive focused checks while implementing. At delivery-set closure,
   run the selected integration and representative journey gate.
5. On failure, reproduce and verify the correction narrowly, then select the
   required rerun under `.agents/LINTING.md`.
6. Run external or deployment checks only with the required authority and safe
   credentials or test mode.
7. Record exact commands, outcomes, evidence category, and any materially
   omitted high-value technique in the active tracker or report.
