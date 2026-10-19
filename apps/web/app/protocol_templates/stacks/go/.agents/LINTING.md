# Go Validation

- Run `gofmt` on changed Go files and `go test` for affected packages.
- Run `go vet` for the affected package set, using repository-owned commands
  when they already combine these checks.
- Use named table cases and `t.Run` for related input/output scenarios when
  this improves failure diagnostics. Keep tests beside the package they exercise.
- Exercise resource cleanup and error paths; avoid replacing every collaborator
  with a mock when an in-memory implementation is sufficient.
- Use `go test -race` for affected concurrent behavior when the target supports it.
  Add benchmarks or fuzzing for concrete performance or input-space risks.
- Run broader builds and tests when changed package contracts affect dependants.

Reference: [Testing package](https://pkg.go.dev/testing).
