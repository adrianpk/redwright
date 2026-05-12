package main

import (
  "bytes"
  "path/filepath"
  "testing"
)

func TestAddCommand(t *testing.T) {
  path := filepath.Join(t.TempDir(), "todo.txt")
  t.Setenv("TODO_FILE", path)

  var stdout bytes.Buffer
  var stderr bytes.Buffer
  if code := run([]string{"add", "write proof fixture"}, &stdout, &stderr); code != 0 {
    t.Fatalf("run returned %d, want 0; stderr=%q", code, stderr.String())
  }
  if got := stdout.String(); got != "added: 1\n" {
    t.Fatalf("stdout = %q, want %q", got, "added: 1\n")
  }

  tasks, err := loadTasks(path)
  if err != nil {
    t.Fatalf("load tasks: %v", err)
  }
  if len(tasks) != 1 || tasks[0].Text != "write proof fixture" || tasks[0].Done {
    t.Fatalf("tasks = %#v", tasks)
  }
}

func TestListCommand(t *testing.T) {
  path := filepath.Join(t.TempDir(), "todo.txt")
  t.Setenv("TODO_FILE", path)
  if err := saveTasks(path, []Task{{Text: "first"}, {Text: "second"}}); err != nil {
    t.Fatalf("seed tasks: %v", err)
  }

  var stdout bytes.Buffer
  var stderr bytes.Buffer
  if code := run([]string{"list"}, &stdout, &stderr); code != 0 {
    t.Fatalf("run returned %d, want 0; stderr=%q", code, stderr.String())
  }
  if got := stdout.String(); got != "1. [ ] first\n2. [ ] second\n" {
    t.Fatalf("stdout = %q", got)
  }
}
