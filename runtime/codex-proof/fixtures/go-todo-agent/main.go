package main

import (
  "bufio"
  "fmt"
  "io"
  "os"
  "strings"
)

type Task struct {
  Text string
  Done bool
}

func main() {
  os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(args []string, stdout io.Writer, stderr io.Writer) int {
  if len(args) == 0 {
    fmt.Fprintln(stderr, "usage: todo <add|list> [task]")
    return 2
  }

  tasks, err := loadTasks(todoFilePath())
  if err != nil {
    fmt.Fprintf(stderr, "load tasks: %v\n", err)
    return 1
  }

  switch args[0] {
  case "add":
    if len(args) < 2 || strings.TrimSpace(args[1]) == "" {
      fmt.Fprintln(stderr, "usage: todo add <task>")
      return 2
    }
    tasks = append(tasks, Task{Text: strings.TrimSpace(args[1])})
    if err := saveTasks(todoFilePath(), tasks); err != nil {
      fmt.Fprintf(stderr, "save tasks: %v\n", err)
      return 1
    }
    fmt.Fprintf(stdout, "added: %d\n", len(tasks))
    return 0
  case "list":
    for index, task := range tasks {
      marker := " "
      if task.Done {
        marker = "x"
      }
      fmt.Fprintf(stdout, "%d. [%s] %s\n", index+1, marker, task.Text)
    }
    return 0
  default:
    fmt.Fprintf(stderr, "unknown command: %s\n", args[0])
    return 2
  }
}

func todoFilePath() string {
  if path := os.Getenv("TODO_FILE"); path != "" {
    return path
  }
  return "todo.txt"
}

func loadTasks(path string) ([]Task, error) {
  file, err := os.Open(path)
  if os.IsNotExist(err) {
    return nil, nil
  }
  if err != nil {
    return nil, err
  }
  defer file.Close()

  var tasks []Task
  scanner := bufio.NewScanner(file)
  for scanner.Scan() {
    parts := strings.SplitN(scanner.Text(), "\t", 2)
    if len(parts) != 2 {
      continue
    }
    tasks = append(tasks, Task{Done: parts[0] == "done", Text: parts[1]})
  }
  return tasks, scanner.Err()
}

func saveTasks(path string, tasks []Task) error {
  file, err := os.Create(path)
  if err != nil {
    return err
  }
  defer file.Close()

  for _, task := range tasks {
    status := "open"
    if task.Done {
      status = "done"
    }
    if _, err := fmt.Fprintf(file, "%s\t%s\n", status, task.Text); err != nil {
      return err
    }
  }
  return nil
}
