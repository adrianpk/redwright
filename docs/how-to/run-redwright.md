# Run RedWright

This guide shows the shortest local run flow.

## 1) Start Server

```bash
bin/rake server:run
```

## 2) Use a Client

TUI client:

```bash
bin/rake tui
```

Telegram client:

```bash
bin/rake telegram
```

## 3) Check Server Health

```bash
bin/rake server:status
bin/rake server:ping
bin/rake server:ctl:status
```
