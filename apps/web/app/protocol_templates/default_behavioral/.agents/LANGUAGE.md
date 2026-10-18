# Repository Language Rules

This document defines language and locale boundaries for versioned artifacts.

## Repository Content

- Keep repository content in English unless the repository explicitly requires
  localized content.
- This includes code, names, comments, configuration, documentation, examples,
  quoted text, test data, commit metadata, pull-request text, and operational
  artifacts.
- Use neutral English examples unless a product requirement defines another
  language or locale.

## Technical English

- Write README files, documentation, agent instructions, operational artifacts,
  configuration text, examples, commit metadata, and pull-request text in clear
  technical English.
- Prefer short sentences, active voice, one instruction or topic per sentence,
  and consistent terminology.
- Keep necessary domain terms. Define abbreviations or specialized terms when
  their meaning is not clear from the repository context.
- Apply ASD-STE100 Simplified Technical English principles when practical. This
  is a writing goal, not a claim of certified or complete ASD-STE100 compliance.
- When localized content is required, keep the surrounding technical material
  in English unless the repository explicitly requires broader localization.

## Conversation Boundary

- Conversation language does not determine repository language or locale.
- Localized product content does not change the language of surrounding code,
  documentation, metadata, or operational artifacts.

## Commit Check

Before committing, inspect staged natural-language content and remove unintended
non-English text.
