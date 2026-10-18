# Specification Procedure

Use this playbook to create, refine, or promote an authorized specification.
`.agents/SPECIFICATIONS.md` owns specification structure, scope, stability, and
model-companion rules.

1. Inspect the available context and directly related quiz, dump, or existing
   specification artifacts.
2. Select a draft or stable destination according to
   `.agents/SPECIFICATIONS.md`.
3. Create or update the specification with its behavior, boundaries,
   decisions, constraints, assumptions, and open questions.
4. Create or update the sibling model companion when the specification changes
   durable models, persistence, or stored contracts.
5. Cross-check model concepts against their stored representation and external
   mappings.
6. Apply the exclusion test and remove boundaries that do not prevent a
   plausible misinterpretation.
7. Run one full consistency pass across the specification, model companion,
   and direct references.
8. Promote the specification and model companion together when their stable
   conditions are satisfied.
9. Create a plan and tracker only under separate implementation-planning
   authorization.
