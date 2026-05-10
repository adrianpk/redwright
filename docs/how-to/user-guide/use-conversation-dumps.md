# Use Conversation Dumps

## Purpose

Use Conversation to capture project knowledge through two complementary loops.

## Concepts

`Conv` is the navigation entry for conversation-based context capture.

Conversation contains two related tools:

- `Quiz`: a RedWright-led questionnaire. Use it when you want RedWright to ask
  structured questions and help uncover missing project or use-case context.
- `Dump`: a user-led capture flow. Use it when you already have context in your
  head and want to write it down as short notes without turning it into a spec,
  ticket, or plan yet.

Quiz is for discovery. Dump is for preserving what you already know.

A dump starts as one or more rough entries. RedWright stores the raw text,
polishes each entry for readability, and can later curate the completed dump
into a summary with concepts, decisions, tradeoffs, assumptions, open questions,
and possible downstream artifacts.

Closed and curated dumps can become context for later ticket execution. Active
or uncurated dumps are kept visible to the user but are not silently injected
into unrelated work.

Later, Conversation captures can become source material for drafts, specs,
plans, trackers, or derived tickets. Today, they are preserved as reusable
context and can inform ticket execution once curated.

## Before You Start

- Start the local stack with `bundle exec rake app:run:foreground`.
- Open the web app at `http://127.0.0.1:3000`.
- Select the project that should own the captured context.

## Steps

1. Open `Conv` from the top navigation.

`Conv` is the entry point for both Dump and Quiz.

2. Open Dump.

Use `New Dump` for project-wide context, or `For Use Case` when the notes belong to a specific use case.

3. Add entries while the dump is capturing.

Each entry is stored as raw input and a polished version. The polishing step keeps the user intent, corrects wording, redacts obvious secrets, and stores possible tags.

4. Finish or cancel the dump.

Use `Done` to close capture. Use `Cancel` when the dump should not be used.

5. Curate a completed dump.

Use `Curate` after capture is closed. Curated dumps receive a central topic, summary, key concepts, decisions or preferences, tradeoffs, assumptions, downstream artifact hints, open questions, and tags.

## Verify

- Conversation shows separate cards for Dump and Quiz.
- Active dumps show `capturing` capture status.
- Completed dumps show `closed` capture status.
- Curated dumps show `curated` curation status and include curated body content.
- Agent ticket context can include only closed and curated dumps whose scope and topic match the request policy.

## Troubleshooting

- If a dump is not available to ticket execution, confirm it is closed and curated.
- If a dump was captured for a use case, it is selected only for tickets in that use case.
- If curation falls back, inspect the dump warnings and LLM trace configuration.
- If sensitive values appear in raw input, edit or remove the source entry before relying on the dump as durable context.

## Related Docs

- [Use The Web App](use-the-web-app.md)
- [Use Telegram](use-telegram.md)
- [LLM Context Shaping](../../reference/llm-context-shaping.md)
- [Slash Commands Reference](../../reference/slash-commands.md)
