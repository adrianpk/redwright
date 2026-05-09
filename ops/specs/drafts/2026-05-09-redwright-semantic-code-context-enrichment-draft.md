# RedWright Semantic Code Context Enrichment Draft

## Metadata

- id: `draft-2026-05-09-redwright-semantic-code-context-enrichment`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-09`
- updated: `2026-05-09`
- scope: `llm-context/tree-sitter/semantic-code-context`

## Summary

Tree-sitter style context is useful as a compact structural map for LLM requests, but it should be treated as orientation context rather than a replacement for concrete file content, tests, ticket intent, or validation feedback.

The current semantic code section helps the model understand which files and symbols likely matter. It can reduce search cost and help the model choose smaller, better-targeted changes. The recent agent-ticket context pruning regression also showed its limit: symbols alone did not give the model enough grounded source context to produce reliable patches.

## Current Role

Semantic code context can help the LLM identify:

- likely entrypoints
- domain types
- functions and methods that look relevant
- test files and source files worth inspecting
- broad code organization without sending every file in full

For implementation work, the expected relationship is:

```text
semantic code context = map
concrete files/tests = ground truth
ticket and feedback = objective
```

The map can improve navigation, but it must not replace the ground truth or objective.

## Enrichment Candidates

Potential future improvements should be evaluated from real traces before expanding the payload:

- include lightweight call relationships for selected symbols
- include symbol signatures when available
- include class/module nesting for languages that use it
- include imports/dependencies for selected files
- include test-to-source hints when tests reference known symbols
- include changed-symbol hints after validation failures
- include parser confidence or fallback mode per file

These enrichments should stay compact and policy-selectable. They should not turn semantic context into a duplicate copy of source files.

## Evaluation Criteria

An enrichment is worth adding only if it improves at least one observable outcome:

- fewer invalid or non-applicable patches
- better first-attempt file targeting
- fewer validation retry cycles
- smaller provider prompts without losing correctness
- clearer trace evidence explaining why a file or symbol was selected

Trace review should compare the selected semantic context against final patches, validation feedback, and omitted context. If the model still needs the full file content for correctness, the fix should be in context policy selection rather than in semantic context expansion.
