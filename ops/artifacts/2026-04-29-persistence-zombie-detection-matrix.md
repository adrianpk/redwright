# Persistence Zombie Detection Matrix (Slice 2)

## Method

- static SQL pattern scan over `lib/` for reads/writes
- callsite counters across `lib/` and `test/`
- this is candidate-level triage, final remove/migrate decisions happen in later slices

## Classification Summary

- active: 17
- write_only_candidate: 2

## Candidate Tables

- alignment_question_dependencies: write_only_candidate -> verify_runtime_consumer_or_remove
- alignment_artifact_links: write_only_candidate -> verify_runtime_consumer_or_remove

## Notes

- false positives are possible for dynamic SQL construction.
- cross-check decisions against runtime integration tests before schema removals.
