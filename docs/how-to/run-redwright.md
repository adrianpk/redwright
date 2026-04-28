# Run RedWright

This guide shows the shortest local run flow.

## 1) Start Server

```bash
bundle exec ruby bin/redwright server run --dev
```

## 2) Use a Client

TUI client:

```bash
bundle exec ruby bin/redwright daemon run --dev --ingress tui --once
```

Telegram client:

```bash
bundle exec ruby bin/redwright daemon run --dev --ingress telegram --once
```

## 3) Check Server Health

```bash
bundle exec ruby bin/redwright server status --dev
bundle exec ruby bin/redwright server ping --dev
bundle exec ruby bin/redwright server ctl status --dev
```
