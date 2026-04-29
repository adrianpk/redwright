# Operational vs Task Intent Model

RedWright separates two intent classes:

- operational intent: control/routing commands for runtime behavior,
- task intent: software-engineering work requests.

This boundary reduces accidental execution ambiguity.

## Operational Intent

Operational intent governs runtime state transitions and context control.

Examples:

- project selection and creation (`/project ...`),
- repository operations (`/repo ...`),
- flow control (`/pause`, `/resume`, `/cancel`),
- planning/trace/session hints.

Operational intent is expected to be deterministic and bounded.

## Task Intent

Task intent carries implementation work goals.

Examples:

- create a CLI,
- fix a failing test,
- refactor module boundaries,
- generate docs/spec slices.

Task intent can pass through LLM interpretation and iterative execution loops.

## Why This Split Exists

Without a split, a single free-form message can ambiguously request both control and implementation, causing:

- wrong project targeting,
- unsafe execution routing,
- unstable continuation behavior.

The split allows runtime to resolve context/control first, then execute task intent within the selected scope.

## Slash Commands as Deterministic Signals

Slash commands are explicit control signals that bypass weak natural-language ambiguity.

They are not a replacement for natural language tasks; they are routing anchors.

## Interaction Rule

- resolve operational scope first,
- then execute task intent in the resolved scope,
- keep control actions bounded and auditable in persistence.

This preserves autonomy while keeping runtime behavior predictable.
