# RedWright User Guide

## Purpose

Use this guide to operate RedWright from the current user-facing surfaces:

- local configuration and project harness choices
- runtime server and foreground stack
- Rails web app
- Telegram commands
- Conversation, Dump, and Quiz context loops
- projects
- boards and tickets
- documents and protocols
- LLM request/response trace files

This guide is practical. It explains what a user can do today and points to reference documents for exact contracts.

## Before You Start

- Work from the repository root.
- Install Ruby dependencies for the root project and the Rails app.
- Keep active configuration in the expected location for the mode you run.
- Treat Telegram and local trace files as local-development surfaces that can contain sensitive project data.

## Guide Map

- [Configure RedWright](configure-redwright.md)
- [Run The Local Stack](run-the-local-stack.md)
- [Use The Web App](use-the-web-app.md)
- [Use Conversation Dumps](use-conversation-dumps.md)
- [Use Telegram](use-telegram.md)
- [Manage Projects](manage-projects.md)
- [Manage Boards And Tickets](manage-boards-and-tickets.md)
- [Manage Specs And Protocol](manage-documents-and-protocols.md)
- [Debug LLM Calls](debug-llm-calls.md)
- [Runtime Containers In Ticket Work](runtime-containers-in-ticket-work.md)

## Page Pattern

Each page uses the same structure:

- `Purpose`: what the page helps you do
- `Before You Start`: required context or setup
- `Steps`: the operating procedure
- `Verify`: how to confirm the result
- `Troubleshooting`: common failure points
- `Related Docs`: deeper references

## Related Docs

- [Documentation Index](../../index.md)
- [What Is RedWright?](../../explanation/what-is-redwright.md)
- [Run RedWright](../run-redwright.md)
- [Application Semantics v1](../../reference/application-semantics-v1.md)
- [Harness Profiles](../../reference/harness-profiles.md)
- [Slash Commands Reference](../../reference/slash-commands.md)
