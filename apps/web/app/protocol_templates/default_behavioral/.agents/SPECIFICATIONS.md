# Specification Contract

This document defines durable workspace specifications and their model
companions. Follow `.agents/DOCUMENTING.md` for canonical locations and
`.agents/LANGUAGE.md` for artifact language.

## Inputs and Stability

- A specification can start directly from sufficient context. Do not create a
  synthetic quiz or dump to satisfy ceremony.
- Link an existing quiz or dump only when it directly informs the
  specification.
- Use a draft while important behavior, boundaries, or decisions remain open.
- Create a stable specification directly when a draft cycle adds no value.
- Promote a draft only when its behavior and boundaries are sufficiently
  decided.
- Create a plan and tracker only after implementation scope is approved.

Typical files are:

```text
ops/<namespace>/spec/drafts/<slug>-draft.md
ops/<namespace>/spec/<slug>.md
```

## Model Companions

When a specification introduces business models, persistence, or durable data
contracts, create a sibling file with the same basename and a `-model.md`
suffix.

Use a model companion for business entities and value objects; lifecycle and
status fields; roles and permissions; stored records, indexes, and uniqueness
rules; queries, migrations, and event mappings; and durable API or message
payloads that mirror stored data.

Keep behavior-only specifications model-free when no durable model changes.
Review model fields together with their stored representation, indexes,
queries, migrations, rules, and external-event mappings. Keep corresponding
fields in a directly comparable order when practical.

## Scope Discipline

- Describe scope through the behavior and contracts the specification defines.
- Add an exclusion only when it prevents a plausible adjacent interpretation.
- Keep exclusions short and consolidate overlapping boundaries.
- Do not mirror the roadmap, backlog, unrelated future features, or obvious
  absences into exclusions.
- A later planned feature is not by itself a reason to list a non-goal.

During consistency review, ask what plausible interpretation each exclusion
prevents. Delete it when it only repeats positive scope or states that the
current work does not implement unrelated work.

## Content Rules

- Preserve explicit decisions, assumptions, constraints, and open questions.
- Mark provisional decisions clearly.
- Add cross-references only between existing artifacts with a direct
  relationship.
- Use semantic status metadata when it adds operational value.
- Do not place state suffixes such as `(Draft)` in titles or headings.
- Promote a model companion with its specification when both form the stable
  contract.
- Complete one consistency pass before promotion or commit.
- Prefer one cohesive specification update over corrective micro-commits.
